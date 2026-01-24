# Ralph Architecture & Technical Overview

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Core Components](#core-components)
3. [Learning System Architecture](#learning-system-architecture)
4. [Session Tracking System](#session-tracking-system)
5. [Data Flow](#data-flow)
6. [File Structure](#file-structure)
7. [Technical Details](#technical-details)
8. [Integration Points](#integration-points)

---

## System Architecture

### High-Level Overview

Ralph is an autonomous AI agent loop built on top of **Claude Code CLI**. It runs Claude repeatedly in a loop, with each iteration being a fresh Claude instance that:

1. Reads the PRD (Product Requirements Document)
2. Learns from previous iterations via multiple memory layers
3. Implements the highest priority incomplete task
4. Runs quality checks
5. Commits if checks pass
6. Documents learnings for future iterations
7. Exits when all tasks complete

```
┌─────────────────────────────────────────────────────────┐
│                     Ralph Main Loop                     │
│                    (ralph.sh)                           │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │  Iteration N: Fresh Claude Instance  │
    │  (receives prompt.md via stdin)      │
    └──────────┬───────────────────────────┘
               │
               ├─► Read prd.json
               ├─► Read progress.txt (4 learning layers)
               ├─► Read git history
               ├─► Implement task
               ├─► Run quality checks
               ├─► Commit if passing
               ├─► Update prd.json
               └─► Write to progress.txt
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │   Post-Iteration: Session Capture    │
    │   (capture-session-id.sh)            │
    └──────────┬───────────────────────────┘
               │
               ├─► Log to session-history.txt
               └─► Extract insights (background)
                   │
                   ▼
    ┌──────────────────────────────────────┐
    │   Background: Insight Extraction     │
    │   (extract-insights.sh)              │
    └──────────┬───────────────────────────┘
               │
               └─► Save to insights/iteration-N-[session].md
```

### Design Principles

1. **Fresh Context Per Iteration** - Each iteration starts with clean context to prevent overflow
2. **File-Based Memory** - All state persists via files (git, progress.txt, prd.json, session logs)
3. **Structured Learning** - Four-layer learning system with increasing detail
4. **Graceful Degradation** - Session tracking fails gracefully if Claude logs unavailable
5. **Non-Blocking Operations** - Insight extraction runs in background to not slow iterations
6. **Idempotency** - Safe to re-run, handles branch changes, archives previous runs

---

## Core Components

### 1. ralph.sh - Main Orchestrator

**Purpose**: Runs the iteration loop, manages state, coordinates post-iteration tasks

**Key Responsibilities**:
- Iterate up to MAX_ITERATIONS times
- Pipe `prompt.md` to Claude Code CLI
- Detect completion signal (`<promise>COMPLETE</promise>`)
- Archive previous runs when branch changes
- Capture session IDs after each iteration
- Trigger insight extraction
- Track session history

**Flow**:
```bash
for i in $(seq 1 $MAX_ITERATIONS); do
  # 1. Run Claude with prompt.md
  OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | claude 2>&1 | tee /dev/stderr)

  # 2. Capture session ID
  SESSION_ID=$("$SCRIPT_DIR/capture-session-id.sh")

  # 3. Log session to history
  echo "Iteration $i: $SESSION_ID ($(date))" >> session-history.txt

  # 4. Extract insights (background, non-blocking)
  ./extract-insights.sh "$SESSION_ID" "insights/iteration-$i-$SESSION_ID.md" &

  # 5. Check for completion
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    exit 0
  fi
done
```

**State Management**:
- Detects branch changes via `.last-branch` file
- Archives old runs to `archive/[date]-[branch-name]/`
- Initializes `progress.txt` and `session-history.txt` if missing
- Creates `insights/` directory automatically

### 2. prompt.md - Agent Instructions

**Purpose**: Instructions given to each Claude iteration

**Structure**:
1. **Task Overview** - What Ralph should do
2. **Learning Protocol** - How to read previous learnings (CRITICAL)
3. **Implementation Steps** - Step-by-step workflow
4. **Quality Requirements** - Type checks, linting, tests
5. **Progress Report Format** - How to document learnings
6. **Session Capture** - How to capture session ID

**Key Innovation**: Instructs agent to capture its own session ID:
```markdown
**Session**: [run: ./scripts/ralph/capture-session-id.sh to get current session ID]
```

This creates a self-documenting loop where agents log their own conversation IDs.

### 3. capture-session-id.sh - Session ID Finder

**Purpose**: Find the current Claude Code CLI session ID

**How It Works**:
```bash
# 1. Normalize current directory path
PROJECT_PATH=$(pwd | sed 's/\//-/g')
# Example: /Users/neil/Documents/GitHub/PDP
# Becomes: -Users-neil-Documents-GitHub-PDP

# 2. Locate Claude project directory
CLAUDE_PROJECT_DIR="$HOME/.claude/projects/$PROJECT_PATH"
# Example: ~/.claude/projects/-Users-neil-Documents-GitHub-PDP

# 3. Find most recent .jsonl file (current session)
LATEST_SESSION=$(ls -t "$CLAUDE_PROJECT_DIR"/*.jsonl 2>/dev/null | head -1)

# 4. Extract session ID from filename
SESSION_ID=$(basename "$LATEST_SESSION" .jsonl)
echo "$SESSION_ID"
```

**Critical Detail**: Path normalization requires preserving the leading dash:
- ❌ Wrong: `sed 's/\//-/g' | sed 's/^-//'` (strips leading dash)
- ✅ Correct: `sed 's/\//-/g'` (preserves leading dash)

### 4. parse-conversation.sh - Conversation Analyzer

**Purpose**: Parse Claude Code CLI's JSONL conversation logs to extract structured information

**Extracts**:
- ❌ Errors encountered (from tool-result entries)
- 📝 Files written (Write tool calls)
- ✏️ Files edited (Edit tool calls)
- 💻 Bash commands executed (with descriptions)
- 🔀 Git commits made
- 🎯 Key decisions (from assistant messages)
- ✅ Quality checks run

**Technology**: Uses `jq` (JSON processor) to query JSONL logs

**Example Query**:
```bash
# Extract all errors
jq -r 'select(.type == "tool-result" and .result.error != null) |
  "\(.timestamp | split("T")[1]): \(.name) - \(.result.error)"' conversation.jsonl

# Extract files written
jq -r 'select(.type == "tool-use" and .name == "Write") |
  .input.file_path' conversation.jsonl | sort -u
```

### 5. extract-insights.sh - Auto-Insight Extractor

**Purpose**: Automatically extract key learnings from conversation logs

**Extraction Categories**:
1. **Errors/Failures** - What went wrong
2. **Files Modified** - What changed
3. **Patterns Discovered** - Mentions of "use", "pattern", "approach", "should"
4. **Important Notes/Gotchas** - Mentions of "must", "important", "warning", "careful"

**How It Works**:
```bash
# Create temp files for each category
TMP_ERRORS=$(mktemp)
TMP_FILES=$(mktemp)
TMP_PATTERNS=$(mktemp)
TMP_GOTCHAS=$(mktemp)

# Extract patterns from assistant messages
jq -r 'select(.type == "assistant" and .message.content != null) |
  .message.content |
  if type == "string" then
    select(. | test("(use|pattern|approach|should use|always|never)"; "i")) |
    split("\n")[] |
    select(length > 20 and length < 150)
  else empty end' conversation.jsonl | \
  grep -iE "(use|pattern|approach|should|always|never)" | \
  head -10 > $TMP_PATTERNS

# Combine and format output
{
  echo "### Auto-Extracted Insights (from conversation $SESSION_ID)"
  echo ""
  [ -s "$TMP_ERRORS" ] && echo "**Errors Encountered:**" && cat "$TMP_ERRORS"
  [ -s "$TMP_PATTERNS" ] && echo "**Patterns Discovered:**" && cat "$TMP_PATTERNS"
  # ... etc
} > output.md
```

**Performance**: Runs in background to not block iteration loop

---

## Learning System Architecture

### Four-Layer Learning Model

Ralph's learning system has four layers, each serving a specific purpose:

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Codebase Patterns                             │
│ Location: Top of progress.txt                          │
│ Purpose: Consolidated wisdom, project conventions      │
│ Speed: Instant (always read first)                     │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 2: Progress Entries with Session IDs             │
│ Location: progress.txt (append-only log)               │
│ Purpose: Structured learnings per iteration            │
│ Speed: Fast (text file, tail for recent entries)       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 3: Git Commit History                            │
│ Location: Git repository                               │
│ Purpose: Actual code changes, diffs                    │
│ Speed: Medium (git log, git show)                      │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 4: Conversation Logs ✨                          │
│ Location: ~/.claude/projects/[project]/*.jsonl         │
│ Purpose: Full context, detailed debugging              │
│ Speed: Slower (JSONL parsing, optional deep dive)      │
└─────────────────────────────────────────────────────────┘
```

### Layer 1: Codebase Patterns

**Format**:
```markdown
# Ralph Progress Log

## Codebase Patterns (ALWAYS READ FIRST!)

**Multi-tenant architecture:**
- All routes scoped under `/orgs/[orgId]`
- All queries filter by `organizationId`

**Convex patterns:**
- NEVER use `.filter()` - always use `.withIndex()`
- Always include args and returns validators
- Use `Id<"tableName">` types, not `string`

**Quality checks:**
- Run `npm run check-types` before committing
- Run `npx ultracite fix` for linting/formatting
```

**Purpose**: Quick reference for project-wide conventions. Agent reads this FIRST every iteration.

**Update Strategy**:
- Initially seeded with known patterns
- Updated when patterns discovered across multiple iterations
- Kept concise (< 50 lines)

### Layer 2: Progress Entries

**Format**:
```markdown
## 2026-01-11 15:30 - US-001 - Add search input
**Iteration**: 1
**Commit**: a1b2c3d4
**Session**: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6
**Status**: Complete

### What was done
- Created SearchInput component using shadcn Input
- Added to admin players page header
- Connected to URL params for persistence

### Learnings for future iterations
**Patterns discovered:**
- Use `useRouter()` and `useSearchParams()` for URL state
- shadcn components already styled with org theme

**Gotchas encountered:**
- Server components can't use hooks - need client components
- Must add 'use client' directive at top

**Mistakes made:**
- Initially forgot to import useRouter
- Had to add client directive after first error

### Next iteration should
- Add team filter dropdown (US-002)
- Use same URL param pattern
```

**Purpose**: Detailed iteration logs with structured sections

**Key Fields**:
- **Session ID**: Links to full conversation log
- **Commit hash**: Links to actual code changes
- **Learnings**: What worked, what didn't
- **Mistakes**: Explicitly documented to avoid repetition

### Layer 3: Git History

**Usage**:
```bash
# View recent commits
git log --oneline -10

# See actual code changes
git show a1b2c3d4

# Compare two commits
git diff a1b2c3d4 e5f6g7h8
```

**Purpose**: Ground truth for "what actually changed"

**Why Important**: Progress entries explain WHY, git shows WHAT

### Layer 4: Conversation Logs

**Location**: `~/.claude/projects/-Users-neil-Documents-GitHub-PDP/*.jsonl`

**Format**: JSON Lines (JSONL) - one JSON object per line

**Content**:
```json
{"type":"user","message":"...","timestamp":"2026-01-11T15:30:45.123Z"}
{"type":"assistant","message":"...","timestamp":"2026-01-11T15:30:46.456Z"}
{"type":"tool-use","name":"Read","input":{...},"timestamp":"..."}
{"type":"tool-result","result":{...},"timestamp":"..."}
```

**Purpose**:
- Full detailed context when needed
- Error debugging
- Pattern mining
- Understanding decision rationale

**Access Methods**:
1. **Automatic**: `extract-insights.sh` runs after each iteration
2. **Manual**: `parse-conversation.sh <session-id>` for structured analysis
3. **Direct**: `cat *.jsonl | jq '...'` for custom queries

---

## Session Tracking System

### Architecture

```
┌────────────────────────────────────────────────────────┐
│  Iteration Completes                                   │
└───────────────────┬────────────────────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────────────────────┐
│  capture-session-id.sh                                 │
│  - Find latest .jsonl in Claude project dir            │
│  - Extract session ID from filename                    │
│  - Output: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6        │
└───────────────────┬────────────────────────────────────┘
                    │
                    ├─► session-history.txt
                    │   (append session with timestamp)
                    │
                    └─► extract-insights.sh (background)
                            │
                            ▼
                        insights/iteration-N-[session].md
```

### Session History File

**Location**: `scripts/ralph/session-history.txt`

**Format**:
```
# Ralph Session History
# Tracks Claude conversation IDs for each iteration
---
Iteration 1: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6 (Sat Jan 11 15:30:45 PST 2026)
Iteration 2: a46a6193-3441-460d-9464-b20439283e35 (Sat Jan 11 16:00:12 PST 2026)
Iteration 3: d2cbb88b-dd74-4add-a7e2-8d2230ab38a6 (Sat Jan 11 16:30:58 PST 2026)
```

**Purpose**:
- Quick reference for all session IDs
- Iteration-to-session mapping
- Historical timeline

### Insights Directory

**Location**: `scripts/ralph/insights/`

**Structure**:
```
insights/
├── iteration-1-71aaf1aa.md
├── iteration-2-a46a6193.md
└── iteration-3-d2cbb88b.md
```

**Content Example**:
```markdown
### Auto-Extracted Insights (from conversation 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6)

**Errors Encountered:**
- Edit failed: File not found at path/to/file.tsx
- Bash failed: Command failed: npm run check-types

**Files Modified:**
- apps/web/src/app/orgs/[orgId]/admin/players/page.tsx
- apps/web/src/components/SearchInput.tsx

**Patterns Discovered:**
- Use useRouter() and useSearchParams() for URL state
- shadcn components already styled with org theme
- Server components can't use hooks - need client components

**Important Notes/Gotchas:**
- Must add 'use client' directive at top for components using hooks
- Important to run type checks before committing

**Full conversation available at:**
`/Users/neil/.claude/projects/-Users-neil-Documents-GitHub-PDP/71aaf1aa.jsonl`

**Parse with:**
`./scripts/ralph/parse-conversation.sh 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6`
```

---

## Data Flow

### Iteration N Data Flow

```
START: ralph.sh iteration N begins
│
├─► Read Inputs
│   ├─► prd.json (which tasks incomplete?)
│   ├─► progress.txt (what did we learn?)
│   │   ├─► Layer 1: Codebase Patterns
│   │   ├─► Layer 2: Recent progress entries
│   │   └─► Layer 3: Git commits (via git log)
│   └─► Layer 4: Previous session logs (optional)
│       └─► insights/iteration-N-1-[session].md
│
├─► Claude Code CLI Execution
│   ├─► Receives prompt.md via stdin
│   ├─► Implements task
│   ├─► Uses tools: Read, Write, Edit, Bash, etc.
│   └─► All tool calls logged to ~/.claude/projects/.../[session-id].jsonl
│
├─► Write Outputs
│   ├─► Code files (via Write/Edit tools)
│   ├─► Git commit (if checks pass)
│   ├─► prd.json updated (task marked complete)
│   └─► progress.txt appended (learnings documented)
│
└─► Post-Iteration (ralph.sh)
    ├─► capture-session-id.sh
    │   └─► Returns: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6
    │
    ├─► Append to session-history.txt
    │   └─► "Iteration N: 71aaf1aa... (timestamp)"
    │
    └─► extract-insights.sh (background) &
        └─► Creates: insights/iteration-N-71aaf1aa.md
```

### Cross-Iteration Learning Flow

```
Iteration 1
├─► Discovers: "Must use 'use client' for components with hooks"
├─► Documents in progress.txt
└─► Creates: insights/iteration-1-71aaf1aa.md

Iteration 2
├─► Reads progress.txt
├─► Sees: "Must use 'use client' for components with hooks"
├─► Applies pattern correctly from the start
├─► Discovers: "URL params persist with useRouter()"
├─► Documents additional learning
└─► Creates: insights/iteration-2-a46a61.md

Iteration 3
├─► Reads progress.txt (now has learnings from 1 & 2)
├─► Applies both patterns
├─► Encounters error: Type check fails
├─► Investigates using: parse-conversation.sh a46a61...
│   └─► Finds in Iteration 2's conversation: exact error solution
├─► Fixes issue
└─► Documents: "Always check previous sessions for error patterns"
```

---

## File Structure

### Complete Directory Layout

```
scripts/ralph/
├── Core Scripts (Executable)
│   ├── ralph.sh                        # Main loop orchestrator
│   ├── capture-session-id.sh           # Session ID finder
│   ├── parse-conversation.sh           # Conversation analyzer
│   ├── extract-insights.sh             # Auto-insight extractor
│   ├── create-prd-interactive.sh       # PRD creator
│   └── validate-prd.sh                 # PRD validator
│
├── Configuration
│   ├── prompt.md                       # Agent instructions
│   ├── prd.json                        # Current PRD (gitignored)
│   └── prd.json.example                # Template
│
├── State Files (Auto-Generated)
│   ├── progress.txt                    # Append-only learning log
│   ├── session-history.txt             # Session ID timeline
│   ├── .last-branch                    # Branch tracking for archiving
│   │
│   ├── insights/                       # Auto-extracted insights
│   │   ├── iteration-1-[session].md
│   │   ├── iteration-2-[session].md
│   │   └── iteration-3-[session].md
│   │
│   └── archive/                        # Previous runs
│       ├── 2026-01-11-feature-name/
│       │   ├── prd.json
│       │   └── progress.txt
│       └── 2026-01-10-other-feature/
│
├── Examples
│   ├── examples/
│   │   ├── player-search.prd.json
│   │   ├── coach-dashboard-improvements.prd.json
│   │   └── simple-ui-fix.prd.json
│
└── Documentation
    ├── README.md                       # Main documentation
    ├── ARCHITECTURE.md                 # This file
    ├── QUICKSTART.md                   # Getting started guide
    ├── LEARNING_SYSTEM.md              # Learning architecture
    ├── PRD_CREATION_GUIDE.md           # How to create PRDs
    ├── CLAUDE_CODE_CLI_WORKFLOW.md     # vs Amp CLI comparison
    ├── GITHUB_INTEGRATION_IDEAS.md     # Future GitHub integration
    ├── LEARNING_COMPARISON.md          # vs Amp thread URLs
    ├── CONVERSATION_HISTORY_INTEGRATION.md
    ├── CONVERSATION_INTEGRATION_COMPLETE.md
    └── PHASE_COMPLETION_SUMMARY.md
```

### File Ownership

| File | Created By | Modified By | Purpose |
|------|-----------|-------------|---------|
| `ralph.sh` | Developer | Developer | Main loop script |
| `prompt.md` | Developer | Developer | Agent instructions |
| `prd.json` | Developer | Ralph/Agent | Task list |
| `progress.txt` | Ralph | Agent | Learnings log |
| `session-history.txt` | Ralph | Ralph | Session timeline |
| `insights/*.md` | Ralph | extract-insights.sh | Auto-insights |
| `.last-branch` | Ralph | Ralph | Branch tracking |
| `archive/*` | Ralph | Ralph | Previous runs |

---

## Technical Details

### Path Normalization

**Challenge**: Claude Code CLI stores projects with normalized paths

**Example**:
- Working directory: `/Users/neil/Documents/GitHub/PDP`
- Normalized path: `-Users-neil-Documents-GitHub-PDP`
- Full path: `~/.claude/projects/-Users-neil-Documents-GitHub-PDP/`

**Implementation**:
```bash
# Convert path: /Users/neil/Documents/GitHub/PDP
# Step 1: Replace / with -
PROJECT_PATH=$(pwd | sed 's/\//-/g')
# Result: -Users-neil-Documents-GitHub-PDP

# IMPORTANT: Do NOT strip the leading dash!
# ❌ Wrong: sed 's/\//-/g' | sed 's/^-//'
# ✅ Correct: sed 's/\//-/g'
```

**Why the leading dash matters**: The Claude Code CLI directory structure actually uses the leading dash as part of the directory name.

### JSONL Format

**Format**: JSON Lines - one JSON object per line (not a JSON array)

**Example**:
```jsonl
{"type":"user","message":"Add search to players page","timestamp":"2026-01-11T15:30:45.123Z"}
{"type":"assistant","message":"I'll add a search input...","timestamp":"2026-01-11T15:30:46.456Z"}
{"type":"tool-use","name":"Write","input":{"file_path":"..."},"timestamp":"..."}
```

**Parsing with jq**:
```bash
# Each line is a separate JSON object
jq 'select(.type == "tool-use")' file.jsonl

# Get all tool names
jq -r 'select(.type == "tool-use") | .name' file.jsonl

# Filter and transform
jq -r 'select(.type == "assistant" and .message.content != null) |
  .message.content |
  select(. | test("pattern"; "i"))' file.jsonl
```

**Performance Considerations**:
- JSONL files can be large (10K+ lines for complex iterations)
- Use `head`/`tail` to limit output
- Extract to temp files before processing
- Run in background to not block iterations

### Background Processing

**Pattern**:
```bash
# Launch background process
./extract-insights.sh "$SESSION_ID" "$OUTPUT_FILE" 2>/dev/null &

# Continue immediately without waiting
echo "💡 Insights being extracted to: $OUTPUT_FILE"
```

**Why Non-Blocking**:
- Insight extraction can take 1-5 seconds
- Iterations should start immediately
- Insights ready by next iteration anyway
- Failures logged but don't block progress

**Cleanup**: Background processes exit naturally when complete

### Error Handling

**Graceful Degradation**:
```bash
# Session capture - fails gracefully
SESSION_ID=$(./capture-session-id.sh 2>/dev/null || echo "unknown")
if [ "$SESSION_ID" != "unknown" ]; then
  # Proceed with session tracking
else
  # Continue without session tracking
fi
```

**Principle**: Session tracking is a feature, not a requirement. Ralph works without it.

---

## Integration Points

### 1. Claude Code CLI

**Integration**: Pipe prompt to stdin
```bash
cat prompt.md | claude
```

**Challenges**:
- No programmatic API access
- Must parse stdout for completion signal
- Session ID only available via filesystem

**Solutions**:
- Use `<promise>COMPLETE</promise>` as completion signal
- Capture session ID post-iteration via filesystem
- Parse JSONL logs for detailed analysis

### 2. Git

**Integration**: Standard git commands
```bash
git status
git log --oneline -10
git show <commit-hash>
git commit -m "..."
```

**Ralph's Usage**:
- Agent reads git log for recent commits
- Agent commits code after quality checks
- Ralph archives by branch using git info

### 3. Project Build Tools

**Integration**: Via Bash tool
```bash
npm run check-types
npm run check
npm test
npx ultracite fix
```

**Quality Gate**: Ralph only commits if these pass

### 4. File System

**Paths Used**:
- `~/.claude/projects/[normalized-path]/` - Conversation logs
- `scripts/ralph/` - Ralph installation
- Working directory - Project files

**Permissions**: Standard user permissions, no sudo required

---

## Performance Characteristics

### Iteration Speed

**Typical Iteration**:
- Claude execution: 30-180 seconds (depends on task complexity)
- Session capture: <1 second
- Insight extraction: 1-5 seconds (background)
- **Total blocking time**: 30-180 seconds

**Optimization**: Insight extraction runs in background, doesn't add to iteration time

### Memory Usage

**Files Sizes**:
- `prd.json`: <10 KB (typically)
- `progress.txt`: 1-50 KB (grows over time)
- `session-history.txt`: <5 KB
- JSONL conversation: 100 KB - 5 MB per iteration
- Insight files: 1-10 KB each

**Disk Space**: ~5-20 MB per Ralph run (mostly JSONL logs)

### Scalability

**Limits**:
- Max iterations: Configurable (default 10, tested up to 100)
- Max user stories: No hard limit (tested with 50+)
- progress.txt size: Can grow large (consider rotating at 1000 lines)

**Best Practices**:
- Archive previous runs (automatic by branch)
- Limit Codebase Patterns section to <50 lines
- Read only recent progress entries (last 3-5)

---

## Security Considerations

1. **Session Logs**: Contain full conversation context including code
   - Stored in user's home directory
   - Standard file permissions
   - Never transmitted externally by Ralph

2. **PRD Content**: May contain sensitive project details
   - Gitignored by default
   - Keep in private repositories

3. **Credentials**: Never include in PRD or prompt.md
   - Use environment variables
   - Keep .env files gitignored

4. **Code Commits**: Ralph commits directly to branch
   - Review commits before pushing to remote
   - Use feature branches, not main

---

## Troubleshooting

### Session ID Capture Fails

**Symptom**: `SESSION_ID` is "unknown"

**Causes**:
1. Claude project directory not found
2. No .jsonl files in directory
3. Path normalization incorrect

**Debug**:
```bash
# Check normalized path
PROJECT_PATH=$(pwd | sed 's/\//-/g')
echo "$PROJECT_PATH"
# Should be: -Users-neil-Documents-GitHub-PDP

# Check directory exists
ls -la ~/.claude/projects/$PROJECT_PATH/

# Check for .jsonl files
ls -lt ~/.claude/projects/$PROJECT_PATH/*.jsonl | head -5
```

**Solution**: Fix path normalization (remove `sed 's/^-//'`)

### Insight Extraction Shows No Data

**Symptom**: Insight files are empty or minimal

**Causes**:
1. Conversation log has no errors (actually a good thing!)
2. jq queries not matching content
3. JSONL format changed

**Debug**:
```bash
# Test jq parsing
cat ~/.claude/projects/.../*.jsonl | jq '.' | head -20

# Check what's in the log
cat ~/.claude/projects/.../*.jsonl | jq '.type' | sort | uniq -c
```

### Parse Conversation Fails

**Symptom**: "Conversation file not found"

**Causes**:
1. Path normalization incorrect
2. Session ID invalid
3. JSONL file deleted

**Solution**: Verify session ID exists in session-history.txt

---

## Future Enhancements

Potential improvements to Ralph architecture:

1. **GitHub Integration**: Sync PRD with GitHub Issues
2. **Web Dashboard**: Visual interface for monitoring progress
3. **Parallel Execution**: Run multiple stories in parallel
4. **Smart Routing**: Automatically determine task size and split if needed
5. **Pattern Mining**: ML-based pattern extraction from conversations
6. **Cross-Project Learning**: Share patterns across Ralph installations

See `GITHUB_INTEGRATION_IDEAS.md` for detailed GitHub integration concepts.

---

## Summary

Ralph's architecture is built on several key principles:

1. **Simplicity**: Bash scripts + Claude CLI + file-based state
2. **Reliability**: Graceful degradation, idempotent operations
3. **Observability**: Four-layer learning system with full conversation logs
4. **Performance**: Non-blocking operations, fresh context per iteration
5. **Maintainability**: Clear separation of concerns, well-documented

The session tracking system adds a fourth learning layer that bridges the gap between structured progress logs and full conversation context, making Ralph more effective at learning from mistakes and discovering patterns over time.
