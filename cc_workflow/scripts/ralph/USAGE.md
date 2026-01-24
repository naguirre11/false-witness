# Ralph for Claude Code CLI

Ralph is an autonomous AI agent loop that runs Claude Code CLI repeatedly until all PRD items are complete. Each iteration is a fresh Claude instance with clean context. Memory persists via a **four-layer learning system**: git history, `progress.txt`, `prd.json`, and full conversation logs.

**Adapted from**: [Original Ralph by snarktank](https://github.com/snarktank/ralph) (designed for Amp CLI)

---

## 🚀 First Time Setup

**Choose your path:**

### Option A: Guided Setup (Recommended)
```bash
./init.sh
```
Interactive script that customizes Ralph for your project.

### Option B: Manual Setup
See [SETUP.md](./SETUP.md) for step-by-step instructions.

**Both options configure:**
- Quality check commands for your project
- Browser testing credentials (if needed)
- Project-specific coding patterns

---

## 📚 Documentation

- **[SETUP.md](./SETUP.md)** - Setup instructions
- **[QUICKSTART.md](./QUICKSTART.md)** - Getting started guide
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical overview
- **[LEARNING_SYSTEM.md](./LEARNING_SYSTEM.md)** - How Ralph learns
- **[flowchart/](./flowchart/)** - Interactive visualization

---

## What is Ralph?

Ralph automates feature development by:
1. Reading a PRD (Product Requirements Document) in JSON format
2. Picking the highest priority incomplete task
3. Implementing that task autonomously
4. Running quality checks (typecheck, lint, tests)
5. Committing if checks pass
6. Updating the PRD to mark the task complete
7. Repeating until all tasks are done

## Prerequisites

✅ **Already installed in this project:**
- ✅ `jq` - JSON processor for parsing PRD files
- ✅ Git repository
- ✅ Claude Code CLI (`claude` command)

## Quick Start

### 1. Create a PRD file

Create `scripts/ralph/prd.json` with your user stories. See `prd.json.example` for format:

```json
{
  "projectName": "My Feature",
  "branchName": "ralph/my-feature",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add dark mode toggle",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [
        "Toggle appears in settings page",
        "Clicking toggle switches theme",
        "Theme persists across sessions"
      ]
    }
  ]
}
```

### 2. Run Ralph

```bash
# From your project root directory
./scripts/ralph/ralph.sh 10
```

The `10` parameter is the maximum number of iterations (default: 10).

### 3. Monitor Progress

Ralph will:
- Create the feature branch if it doesn't exist
- Work through each user story in priority order
- Update `scripts/ralph/prd.json` as tasks complete
- Log progress to `scripts/ralph/progress.txt`
- Commit working code automatically

## Files

### Core Scripts
| File | Purpose |
|------|---------|
| `ralph.sh` | Main loop that runs Claude Code CLI repeatedly |
| `capture-session-id.sh` | Finds current Claude conversation ID |
| `parse-conversation.sh` | Analyzes conversation logs for errors, patterns |
| `extract-insights.sh` | Auto-extracts learnings from conversations |
| `create-prd-interactive.sh` | Interactive PRD creator |
| `validate-prd.sh` | Validates PRD task sizing |

### Configuration
| File | Purpose |
|------|---------|
| `prompt.md` | Instructions given to each Claude instance |
| `prd.json` | User stories with completion status (gitignored) |
| `prd.json.example` | Example PRD format |

### State Files (Auto-Generated)
| File/Directory | Purpose |
|----------------|---------|
| `progress.txt` | Append-only log of learnings with session IDs |
| `session-history.txt` | Timeline of all Claude conversation IDs |
| `insights/` | Auto-extracted insights per iteration |
| `archive/` | Previous runs archived by date and branch |

## How It Works

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code CLI instance** with clean context. Memory persists through a **four-layer learning system**:

1. **Codebase Patterns** (top of `progress.txt`) - Consolidated wisdom, always read first
2. **Progress Entries** (`progress.txt`) - Structured learnings per iteration with session IDs
3. **Git History** - Actual code changes via `git log` and `git show`
4. **Conversation Logs** (`~/.claude/projects/`) - Full conversation context for deep dives

This prevents context overflow and allows Ralph to learn from mistakes across many iterations.

### Session Tracking

After each iteration, Ralph automatically:
- Captures the Claude conversation ID (e.g., `71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6`)
- Logs it to `session-history.txt` with timestamp
- Extracts insights in the background to `insights/iteration-N-[session].md`
- Links session IDs in progress entries for reference

**Deep dive into any iteration:**
```bash
# Parse a conversation for errors, files changed, patterns
./scripts/ralph/parse-conversation.sh <session-id>

# Extract insights manually
./scripts/ralph/extract-insights.sh <session-id>
```

### Small Tasks Are Key

Each PRD item should be completable in one Claude Code context window. If a task is too big, Claude runs out of context before finishing.

✅ **Right-sized stories:**
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

❌ **Too big (split these):**
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### Quality Checks

Ralph only commits code that passes quality checks. Configure these in your `prompt.md`:
- Type checking: `npm run check-types`
- Linting: `npm run check`
- Tests: `npm test` (if applicable)

### Stop Condition

When all user stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and exits.

## Customizing for Your Project

### 1. Edit prompt.md

The `prompt.md` file contains instructions for each Claude iteration. Customize it:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

### 2. Update Quality Checks

Modify the quality requirements in `prompt.md` to match your project:

```markdown
## Quality Requirements

- Type check: `npm run check-types`
- Lint: `npm run check`
- Format: `npx ultracite fix`
- Tests: `npm test` (if you have tests)
```

### 3. Add Codebase Context

Add project-specific patterns to `progress.txt` (or have Ralph discover them):

```
## Codebase Patterns
- Use Convex queries for all data fetching
- Never use `.filter()` - always use indexes
- All routes scoped under `/orgs/[orgId]`
- Run `npx ultracite fix` before committing
```

## Debugging

Check current state:

```bash
# See which stories are done
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat scripts/ralph/progress.txt

# Check git history
git log --oneline -10

# View session history
cat scripts/ralph/session-history.txt

# Parse a specific iteration's conversation
./scripts/ralph/parse-conversation.sh <session-id>

# View auto-extracted insights
cat scripts/ralph/insights/iteration-1-*.md
```

### Deep Dive into Errors

If an iteration failed or produced unexpected results:

```bash
# 1. Find the session ID from session-history.txt or progress.txt
SESSION_ID="71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6"

# 2. Parse the full conversation
./scripts/ralph/parse-conversation.sh $SESSION_ID

# This shows:
# - All errors encountered
# - Files modified
# - Bash commands run
# - Git commits made
# - Key decisions

# 3. Search for specific content
cat ~/.claude/projects/-Users-neil-Documents-GitHub-PDP/$SESSION_ID.jsonl | \
  jq 'select(.message.content | contains("error"))'
```

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `scripts/ralph/archive/YYYY-MM-DD-feature-name/`.

## Example Workflow

```bash
# 1. Create your PRD
cat > scripts/ralph/prd.json << 'EOF'
{
  "projectName": "Add Player Search",
  "branchName": "ralph/add-player-search",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add search input to players page",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [
        "Search input appears at top of players list",
        "Searches by player name",
        "Updates results in real-time"
      ]
    },
    {
      "id": "US-002",
      "title": "Add filter by team dropdown",
      "priority": 2,
      "passes": false,
      "acceptanceCriteria": [
        "Dropdown shows all teams",
        "Filters players by selected team",
        "Works with search input"
      ]
    }
  ]
}
EOF

# 2. Run Ralph
./scripts/ralph/ralph.sh 10

# 3. Watch it work
# Ralph will:
# - Create ralph/add-player-search branch
# - Implement US-001 (search input)
# - Run quality checks
# - Commit if passing
# - Mark US-001 as passes: true
# - Move to US-002 (filter dropdown)
# - Continue until both are complete
```

## Differences from Original Ralph

This version is adapted for Claude Code CLI instead of Amp CLI:

| Feature | Original (Amp) | This (Claude Code) |
|---------|---------------|-------------------|
| CLI Command | `amp` | `claude` |
| Thread Tracking | Thread URLs | ✅ **Session IDs + Full JSONL logs** |
| Learning Layers | 3 layers | ✅ **4 layers (added conversation logs)** |
| Insight Extraction | Manual | ✅ **Automatic after each iteration** |
| Skills System | ✅ Global skills | ❌ Not implemented |
| Browser Testing | ✅ Required | ⚠️ Recommended (if available) |
| Context Management | `autoHandoff` | Manual (smaller tasks) |

**Key Enhancement**: Our version has **superior conversation tracking** with automatic session capture, insight extraction, and full JSONL conversation logs stored locally.

## Tips for Success

1. **Start Small** - Test Ralph with a simple 1-2 story PRD first
2. **Keep CI Green** - Broken code compounds across iterations
3. **Review Progress** - Check `progress.txt` between runs
4. **Size Tasks Right** - Each story should complete in one context
5. **Monitor Quality** - Watch for linting/type errors accumulating

## Troubleshooting

### Ralph keeps failing on the same story
- The story might be too large - split it into smaller tasks
- Check `progress.txt` for learnings about what's blocking it
- Review the git log to see what Ralph attempted

### Quality checks won't pass
- Run the checks manually to see what's failing
- Add the fix to `progress.txt` as a learning
- Or manually fix and let Ralph continue with next story

### Ralph created a branch but I want to change it
- Update `branchName` in `prd.json`
- Ralph will archive the old run and start fresh

## References

- [Original Ralph](https://github.com/snarktank/ralph)
- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Claude Code CLI](https://claude.ai/code)

## Support

Ralph is an experimental tool. For best results:
- Keep tasks small and well-defined
- Monitor progress between iterations
- Be ready to intervene if needed
- Learn from the progress log
