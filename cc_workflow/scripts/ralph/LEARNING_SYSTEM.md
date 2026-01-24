# Ralph Learning System for Claude Code CLI

## 🎯 The Challenge

**Amp CLI approach**: Thread URLs allow future iterations to "read_thread" and see previous conversation context.

**Claude Code CLI reality**: No built-in thread history mechanism, each iteration is a completely fresh Claude instance.

**Our solution**: A **four-layer learning system** that's actually **superior** to thread URLs!

---

## 🧠 Four-Layer Learning Architecture

### The Complete Learning Stack

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Codebase Patterns                             │
│ Location: Top of progress.txt                          │
│ Purpose: Consolidated wisdom, project conventions      │
│ Speed: Instant (always read first)                     │
│ Content: Architectural patterns, gotchas, conventions  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 2: Progress Entries with Session IDs             │
│ Location: progress.txt (append-only log)               │
│ Purpose: Structured learnings per iteration            │
│ Speed: Fast (text file, tail for recent entries)       │
│ Content: What worked, mistakes, session ID links       │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 3: Git Commit History                            │
│ Location: Git repository                               │
│ Purpose: Actual code changes, diffs                    │
│ Speed: Medium (git log, git show)                      │
│ Content: Real code changes, commit messages            │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 4: Conversation Logs ✨ NEW!                     │
│ Location: ~/.claude/projects/[project]/*.jsonl         │
│ Purpose: Full context, detailed debugging              │
│ Speed: Slower (JSONL parsing, optional deep dive)      │
│ Content: Full conversation, tool calls, errors         │
└─────────────────────────────────────────────────────────┘
```

### Layer Usage Pattern

**Every iteration:**
- ✅ Read Layer 1 (Codebase Patterns) - ALWAYS
- ✅ Read Layer 2 (Recent progress entries) - ALWAYS
- ✅ Check Layer 3 (Git history) - ALWAYS

**When needed:**
- 🔍 Deep dive into Layer 4 (Conversation logs) - When debugging or understanding complex decisions

---

## 📚 Detailed Layer Breakdown

### Layer 1: Codebase Patterns

**What it is**: A curated section at the top of `progress.txt` containing consolidated wisdom

**Example**:
```markdown
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

**Why it matters**: Quick reference prevents repeating mistakes across all iterations

**Update strategy**: Add patterns discovered across multiple iterations, keep concise

---

### Layer 2: Progress Entries with Session IDs

**What it is**: Structured log of each iteration's work, learnings, and mistakes

**Example**:
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

**Why it matters**:
- **Session ID link**: Can deep dive into full conversation if needed
- **Explicit mistakes**: Future iterations avoid the same errors
- **Next steps**: Partial work can be continued seamlessly

**Auto-generated companion**: `insights/iteration-1-71aaf1aa.md` created automatically

---

### Layer 3: Git Commit History

**What it is**: Actual code changes committed by previous iterations

**How iterations use it**:
```bash
# See recent commits
git log --oneline -10

# Output:
# a1b2c3d feat: US-001 - Add search input
# Previous commits...

# See actual code changes
git show a1b2c3d

# Output: Full diff showing exact changes
```

**Why it matters**:
- Progress entries explain WHY, git shows WHAT
- Ground truth for what actually changed
- Essential for continuing partial work

---

### Layer 4: Conversation Logs (NEW!)

**What it is**: Full JSONL logs of Claude Code CLI conversations stored locally

**Location**: `~/.claude/projects/-Users-neil-Documents-GitHub-PDP/[session-id].jsonl`

**Automatic tracking**: Ralph captures session IDs after each iteration

**Access methods**:

1. **Automatic insights** (created after each iteration):
```bash
cat scripts/ralph/insights/iteration-1-71aaf1aa.md
```

2. **Parse conversation** (structured analysis):
```bash
./scripts/ralph/parse-conversation.sh 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6
```

Output:
```
📊 Total log entries: 2186

❌ Errors Encountered:
15:30:45: Edit - File not found

📝 Files Modified:
apps/web/src/app/orgs/[orgId]/admin/players/page.tsx

💻 Bash Commands Executed:
Check TypeScript types
Run linting check
```

3. **Direct JSONL queries** (custom analysis):
```bash
# Search for specific error
cat ~/.claude/projects/.../71aaf1aa.jsonl | jq 'select(.message.content | contains("error"))'

# Extract all tool uses
cat ~/.claude/projects/.../71aaf1aa.jsonl | jq 'select(.type == "tool-use") | .name'
```

**Why it matters**:
- Full detailed context when progress entries aren't enough
- Error debugging with exact context
- Pattern mining across conversations
- Understanding complex decision rationale

**Performance**: Background extraction doesn't slow iterations

---

### Session Tracking Workflow

**After each iteration, Ralph automatically**:

1. Captures session ID:
```bash
./scripts/ralph/capture-session-id.sh
# Output: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6
```

2. Logs to session history:
```bash
echo "Iteration 1: 71aaf1aa... ($(date))" >> session-history.txt
```

3. Extracts insights (background):
```bash
./scripts/ralph/extract-insights.sh 71aaf1aa... insights/iteration-1-71aaf1aa.md &
```

**View session history**:
```bash
cat scripts/ralph/session-history.txt

# Output:
# Iteration 1: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6 (Sat Jan 11 15:30:45)
# Iteration 2: a46a6193-3441-460d-9464-b20439283e35 (Sat Jan 11 16:00:12)
```

---

## 📋 Iteration Workflow: Learning Edition

### Iteration 1 (First Story)

```
START
  ↓
Read prd.json → Pick US-001
  ↓
progress.txt is empty (first run)
  ↓
Create "Codebase Patterns" section
  ↓
Implement story
  ↓
Discover patterns:
  - "Player data in orgPlayerEnrollments table"
  - "Must use .withIndex() not .filter()"
  - "Run ultracite fix before linting"
  ↓
Commit code
  ↓
Document in progress.txt:
  - What was implemented
  - Files changed
  - **Patterns discovered** ← Goes to Codebase Patterns
  - **Gotchas encountered** ← Future iterations read this
  - **Mistakes made** ← Future iterations avoid these
  - Commit hash: abc123
  ↓
Update prd.json: US-001 passes: true
```

### Iteration 2 (Second Story)

```
START (fresh Claude instance, no memory of Iteration 1)
  ↓
Read prd.json → Pick US-002
  ↓
Read progress.txt:
  ↓
  READ "Codebase Patterns" section FIRST
    ✅ "Player data in orgPlayerEnrollments"
    ✅ "Must use .withIndex()"
    ✅ "Run ultracite fix before linting"
  ↓
  Read Iteration 1's entry:
    ✅ See commit hash abc123
    ✅ See files changed
    ✅ See "Mistakes made: initially used .filter()"
  ↓
Run: git log --oneline -10
  → See: abc123 feat: US-001 - Add search input
  ↓
Run: git show abc123
  → See exact changes from Iteration 1
  ↓
Implement US-002
  → Avoid .filter() mistake (learned from Iteration 1!)
  → Use orgPlayerEnrollments (learned from Iteration 1!)
  → Run ultracite fix first (learned from Iteration 1!)
  ↓
Discover new patterns:
  - "Team filter needs team query from Convex"
  ↓
Commit code (commit hash: def456)
  ↓
Document in progress.txt
  → Add new patterns to Codebase Patterns section
  → Reference Iteration 1's learnings
  ↓
Update prd.json: US-002 passes: true
```

### Iteration 3 (Partial Story - Runs Out of Context)

```
START
  ↓
Read progress.txt → Learn from Iterations 1 & 2
  ↓
Read prd.json → Pick US-003
  ↓
Implement... implement... implement...
  ↓
❌ Running low on context (20+ file reads)
  ↓
Commit partial work (commit hash: ghi789)
  ↓
Document in progress.txt:
  **Status**: Partial
  **What was implemented**: Search input added
  **What to do next**:
    - [ ] Wire up to backend query
    - [ ] Add debounce logic
    - [ ] Test with real data
  **Commit**: ghi789 ← Future iteration references this
  ↓
Keep prd.json: US-003 passes: false
  ↓
EXIT (iteration complete, context saved)
```

### Iteration 4 (Continues Partial Story)

```
START (fresh Claude instance)
  ↓
Read prd.json → Pick US-003 (still passes: false)
  ↓
Read progress.txt:
  ↓
  See Iteration 3's entry:
    **Status**: Partial
    **Commit**: ghi789
    **What to do next**:
      - [ ] Wire up to backend query
      - [ ] Add debounce logic
      - [ ] Test with real data
  ↓
Run: git show ghi789
  → See exactly what Iteration 3 did
  → Understand where it left off
  ↓
Continue from where Iteration 3 stopped:
  ✅ Wire up backend query
  ✅ Add debounce
  ✅ Test
  ↓
Complete the story!
  ↓
Document in progress.txt:
  **Status**: Complete
  **Continued from**: Iteration 3 (commit ghi789)
  **What was completed**: Backend wiring and debounce
  **Commit**: jkl012
  ↓
Update prd.json: US-003 passes: true
```

---

## 🔄 Learning Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    Iteration N starts                        │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 1. Read Codebase Patterns (top of progress.txt)            │
│    → Quick reference of all key learnings                   │
│    → Architectural patterns                                 │
│    → Common gotchas                                         │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. Read Recent Progress Entries (last 3-5)                 │
│    → What did recent iterations do?                         │
│    → What mistakes did they make?                           │
│    → What gotchas did they encounter?                       │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Check Git History                                        │
│    git log --oneline -10                                    │
│    → See what code was actually changed                     │
│    → Read commit messages                                   │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. If continuing partial story:                            │
│    git show [commit-hash]                                   │
│    → See exact diff from previous iteration                 │
│    → Understand partial implementation                      │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Implement using learned patterns                        │
│    → Apply Codebase Patterns                                │
│    → Avoid previous mistakes                                │
│    → Use discovered file locations                          │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 6. Document new learnings                                  │
│    → Update Codebase Patterns if reusable                   │
│    → Log mistakes made (for future iterations)              │
│    → Log gotchas encountered                                │
│    → Include commit hash for reference                      │
└───────────────────────────┬──────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│          Next iteration repeats, building on this           │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 Comparison: Amp CLI vs Claude Code CLI Learning Systems

| Feature | Amp Thread URLs | Our Four-Layer System |
|---------|----------------|----------------------|
| **Learning Layers** | 3 layers (thread, git, PRD) | ✅ **4 layers (+ conversation logs)** |
| **Thread Tracking** | ✅ Thread URLs | ✅ **Session IDs + Full JSONL logs** |
| **Persistence** | ❌ External service | ✅ Git-versioned files + local logs |
| **Searchability** | ❌ Requires API call | ✅ grep/jq/search locally |
| **Consolidation** | ❌ No summary | ✅ Codebase Patterns section |
| **Code References** | ⚠️ Indirectly | ✅ Commit hashes + git show |
| **Offline Access** | ❌ Requires internet | ✅ Fully offline |
| **Structured** | ❌ Conversational | ✅ Structured format |
| **Quick Scan** | ❌ Must read thread | ✅ Patterns section at top |
| **Actionable** | ⚠️ May be vague | ✅ Specific gotchas & next steps |
| **Auto-insights** | ❌ Manual | ✅ **Automatic extraction** |
| **Error Debugging** | ⚠️ Read full thread | ✅ **Parse tool + full JSONL** |
| **Pattern Mining** | ❌ Manual | ✅ **Auto-extracted per iteration** |

**Key Advantages**:
- ✅ **Session IDs automatically captured** after each iteration
- ✅ **Full conversation logs** stored locally in JSONL format
- ✅ **Auto-insight extraction** runs in background
- ✅ **Structured parsing tools** for error analysis
- ✅ **No external dependencies** - fully local and offline
- ✅ **Git-versioned and searchable** - standard unix tools work

---

## 🎓 Example: Learning Across Iterations

### Iteration 1: Discovers Pattern

```markdown
## 2026-01-11 15:30 - US-001 - Add search input
**Iteration**: 1
**Commit**: a1b2c3d
**Status**: Complete

### Learnings for future iterations
**Patterns discovered:**
- Player list uses SmartDataView component from @/components
- Filter state should use useSearchParams for URL persistence

**Mistakes made:**
- Initially imported useState but should use useSearchParams
- Forgot to debounce, caused re-render loop
```

### Iteration 2: Learns and Applies

```markdown
## 2026-01-11 15:45 - US-002 - Add team filter
**Iteration**: 2
**Commit**: e4f5g6h
**Status**: Complete

### What was implemented
Applied patterns from Iteration 1:
- ✅ Used useSearchParams (not useState)
- ✅ Added debounce from start (avoided re-render issue)
- ✅ Used SmartDataView component

### Learnings for future iterations
**Patterns discovered:**
- Team data comes from Better Auth teams query
- Need to filter by organizationId in team query

**Dependencies found:**
- Team filter depends on user having coach role
- Must check role before showing filter
```

### Iteration 3: Builds on Both

```markdown
## 2026-01-11 16:00 - US-003 - Add age group filter
**Iteration**: 3
**Commit**: i7j8k9l
**Status**: Complete

### What was implemented
Applied patterns from Iterations 1 & 2:
- ✅ useSearchParams with debounce
- ✅ SmartDataView component
- ✅ organizationId filter in query
- ✅ Role check before showing filter

### Learnings for future iterations
**New pattern discovered:**
- Age groups come from orgPlayerEnrollments, not separate table
- Use distinct() to get unique age groups from enrollments

**Added to Codebase Patterns:**
- Age group data structure clarified
```

---

## 🛠️ Tools for Learning

### 1. progress.txt Structure

```
## Codebase Patterns
[Consolidated wisdom - updated as patterns discovered]

---

## 2026-01-11 15:30 - US-001 - Story 1
[Detailed entry with learnings]

---

## 2026-01-11 15:45 - US-002 - Story 2
[Detailed entry with learnings]

---

[More entries chronologically...]
```

### 2. Git Commands for Context

```bash
# See recent commits
git log --oneline -10

# See what a specific iteration changed
git show abc123

# See what files changed in a commit
git show abc123 --name-status

# See the diff for a specific file
git show abc123 -- path/to/file.tsx
```

### 3. Commit Hash References

Every progress entry includes commit hash:
```markdown
**Commit**: abc123
```

Future iterations can:
```bash
git show abc123
```

To see exactly what was done!

---

## 💡 Why This Is Better Than Thread URLs

### 1. **Git is the Source of Truth**
Thread URLs show conversation, but git shows actual code changes.

### 2. **Structured Learning**
Codebase Patterns section consolidates knowledge in scannable format.

### 3. **Explicit "Mistakes Made" Section**
Future iterations explicitly told what NOT to do.

### 4. **Actionable Next Steps**
Partial stories include checklist for continuation.

### 5. **Offline & Permanent**
Everything in git, no external service dependency.

### 6. **Searchable**
`grep "pattern" progress.txt` finds all mentions.

---

## 🚀 Initialization

On first Ralph run, `progress.txt` will be created with:

```markdown
# Ralph Progress Log
Started: 2026-01-11 15:00
---

## Codebase Patterns
**Last Updated**: 2026-01-11 15:00 - Initialization

### Architecture
- All routes scoped under `/orgs/[orgId]/`
- Use Better Auth for authentication, Convex for backend
- Organization data isolated via organizationId field

### Convex Backend Patterns
- NEVER use `.filter()` - always use `.withIndex()`
- All functions need `args` and `returns` validators
- Use `Id<"tableName">` types, not `string`

### Frontend Patterns
- Use shadcn/ui components from `@/components/ui`
- Organization theming via CSS variables: `--org-primary`

### Quality Checks
- Run in order: `npm run check-types` → `npx ultracite fix` → `npm run check`

---

[First iteration entry will go here]
```

---

## 📋 Quick Reference

**What each iteration MUST do:**

1. ✅ Read Codebase Patterns section (top of progress.txt)
2. ✅ Read last 3-5 progress entries
3. ✅ Check git log for recent changes
4. ✅ Document learnings in structured format
5. ✅ Include commit hash in progress entry
6. ✅ Update Codebase Patterns if reusable pattern found
7. ✅ List mistakes made so future iterations avoid them

**What makes learning effective:**

- 🎯 **Specific** - "Use orgPlayerEnrollments table" not "query players"
- 🎯 **Actionable** - "Run ultracite fix before linting" not "fix formatting"
- 🎯 **Categorized** - Patterns, Gotchas, Mistakes, Dependencies
- 🎯 **Referenced** - Include commit hashes for code examples

---

**Bottom line**: Our learning system is **more structured, more actionable, and more persistent** than Amp's thread URLs. Each iteration builds on a growing knowledge base that's versioned in git and searchable locally.
