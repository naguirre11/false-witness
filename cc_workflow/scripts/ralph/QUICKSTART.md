# Ralph Quick Start Guide

## 🚀 Getting Started in 3 Steps

### Step 1: Create a PRD

**Option A: Use an example template** (Fastest - 2 minutes)
```bash
# Copy one of the example PRDs
cp scripts/ralph/examples/player-search.prd.json scripts/ralph/prd.json

# Or another example
cp scripts/ralph/examples/coach-dashboard-improvements.prd.json scripts/ralph/prd.json
cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json
```

**Option B: Interactive creator** (Custom - 5 minutes)
```bash
# Guided CLI prompts (no AI required)
./scripts/ralph/create-prd-interactive.sh
```

**Option C: Ask Claude** (AI-assisted - 3 minutes)
> "Create a PRD for [your feature description]"
>
> Copy the JSON I provide to `scripts/ralph/prd.json`

**Option D: Manual editing** (Full control - 10 minutes)
```bash
# Copy the blank template
cp scripts/ralph/prd.json.example scripts/ralph/prd.json

# Edit with your user stories
code scripts/ralph/prd.json
```

**See full guide**: `scripts/ralph/PRD_CREATION_GUIDE.md`

### Step 2: Validate Your PRD

```bash
# Check if tasks are well-sized
./scripts/ralph/validate-prd.sh
```

**Good output:**
```
✅ PRD looks good! All stories are well-scoped.
```

**Warning output:**
```
⚠️  PRD has 2 warnings but no errors.

Story 3: US-003 - Refactor entire authentication system
  ⚠️  WARNING: Title contains broad scope words - may be too large
```

### Step 3: Run Ralph

```bash
# Run with default 10 iterations
./scripts/ralph/ralph.sh

# Or specify max iterations
./scripts/ralph/ralph.sh 20
```

## 📋 Example PRDs Included

### 1. `player-search.prd.json` - Simple Feature (4 stories)
**Best for**: First-time Ralph users, learning how it works

**What it does**: Adds search and filtering to admin players page
- Search by player name
- Filter by team
- Filter by age group
- Persist filters in URL

**Estimated time**: 4 iterations (one per story)

### 2. `coach-dashboard-improvements.prd.json` - UI Enhancement (6 stories)
**Best for**: Frontend work, component creation

**What it does**: Adds quick action buttons to coach dashboard
- Create QuickActions component
- Wire up navigation for 4 common actions
- Add to dashboard layout

**Estimated time**: 6 iterations (one per story)

### 3. `simple-ui-fix.prd.json` - Quick Wins (3 stories)
**Best for**: Testing Ralph, getting quick results

**What it does**: Improves empty state messages
- Admin players empty state
- Coach dashboard empty state
- Parent children empty state

**Estimated time**: 3 iterations (one per story)

## 📊 Monitoring Progress

### Watch Ralph Work

```bash
# In another terminal, watch the progress file
tail -f scripts/ralph/progress.txt

# Or watch git commits
watch -n 2 'git log --oneline -5'
```

### Check PRD Status

```bash
# See which stories are complete
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# Output:
# {
#   "id": "US-001",
#   "title": "Add search input to admin players page",
#   "passes": true    <-- ✅ Complete
# }
# {
#   "id": "US-002",
#   "title": "Add team filter dropdown",
#   "passes": false   <-- ⏳ Pending
# }
```

### Review Learnings

```bash
# See what Ralph learned
cat scripts/ralph/progress.txt

# Look for the Codebase Patterns section at the top
head -n 30 scripts/ralph/progress.txt
```

### Session Tracking & Insights

Ralph automatically tracks each iteration's conversation:

```bash
# View all session IDs
cat scripts/ralph/session-history.txt

# Output:
# Iteration 1: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6 (Sat Jan 11 15:30:45 PST 2026)
# Iteration 2: a46a6193-3441-460d-9464-b20439283e35 (Sat Jan 11 16:00:12 PST 2026)

# View auto-extracted insights from any iteration
cat scripts/ralph/insights/iteration-1-*.md

# Deep dive into a specific iteration
./scripts/ralph/parse-conversation.sh 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6

# This shows:
# - ❌ Errors encountered
# - 📝 Files modified
# - 💻 Bash commands run
# - 🔀 Git commits made
# - 🎯 Key decisions
```

**Why This Matters:**
- See exactly what went wrong in failed iterations
- Find patterns across successful iterations
- Debug errors with full context
- Learn from mistakes automatically

## 🎯 Task Sizing Guidelines

### ✅ Well-Sized Stories (Fit in One Context)

**Good examples:**
- "Add search input to players page"
- "Create QuickActions component with 4 buttons"
- "Add empty state to coach dashboard"
- "Update team filter to persist in URL"

**Characteristics:**
- 1-3 files modified
- 2-4 acceptance criteria
- Clear, specific scope
- One discrete feature

### ❌ Too Large Stories (Won't Fit in One Context)

**Bad examples:**
- "Refactor entire authentication system"
- "Build complete analytics dashboard"
- "Implement full search functionality"
- "Add comprehensive testing suite"

**Characteristics:**
- Many files affected (>10)
- Vague scope ("entire", "complete", "full")
- Multiple related features
- Requires extensive exploration

**Solution**: Split into smaller stories

### 🔄 Splitting Large Stories

**Before:**
```json
{
  "id": "US-001",
  "title": "Build analytics dashboard",
  "acceptanceCriteria": [
    "Create dashboard layout",
    "Add skill distribution chart",
    "Add team comparison chart",
    "Add export functionality",
    "Add date range filter"
  ]
}
```

**After (split into 5 stories):**
```json
[
  {
    "id": "US-001",
    "title": "Create analytics dashboard layout",
    "acceptanceCriteria": [
      "Create dashboard page route",
      "Add page title and description",
      "Create grid layout for charts"
    ]
  },
  {
    "id": "US-002",
    "title": "Add skill distribution chart to dashboard",
    "acceptanceCriteria": [
      "Query skill assessment data",
      "Render bar chart showing skill distribution",
      "Add chart to dashboard grid"
    ]
  },
  // ... etc
]
```

## 🔍 Common Issues & Solutions

### Issue: Ralph keeps failing on same story

**Cause**: Story too large for one context

**Solution**:
```bash
# 1. Check progress.txt for what's blocking
cat scripts/ralph/progress.txt | tail -n 50

# 2. Split the story into smaller tasks
# Edit prd.json and break the story into 2-3 smaller ones

# 3. Reset that story to passes: false
# Edit prd.json and set the story's passes field back to false

# 4. Run Ralph again
./scripts/ralph/ralph.sh
```

### Issue: Quality checks won't pass

**Cause**: Code has type errors or linting issues

**Solution**:
```bash
# 1. Run checks manually to see errors
npm run check-types
npm run check

# 2. Fix manually or add guidance to progress.txt
echo "
## Manual Fix Required
- Type error in file X: Expected Y, got Z
- Solution: Add type annotation to function
---
" >> scripts/ralph/progress.txt

# 3. Commit the fix
git add .
git commit -m "fix: resolve type errors for Ralph"

# 4. Continue with Ralph
./scripts/ralph/ralph.sh
```

### Issue: Ralph finished but feature incomplete

**Cause**: Some stories may have been marked complete prematurely

**Solution**:
```bash
# 1. Test the feature manually
# Navigate to the pages affected

# 2. Find incomplete parts and create new stories
# Edit prd.json and add missing stories with higher priority

# 3. Run Ralph again
./scripts/ralph/ralph.sh
```

## 🎓 Pro Tips

### 1. Start Small
Your first Ralph run should be 1-3 simple stories. Get comfortable with the process before tackling larger features.

### 2. Review Between Iterations
Don't just let Ralph run unsupervised. Check commits and progress after each iteration:
```bash
# After iteration 1
git log -1 --stat
cat scripts/ralph/progress.txt | tail -n 20
```

### 3. Use Validation Early
Always validate before running:
```bash
./scripts/ralph/validate-prd.sh
```

### 4. Keep Progress File Clean
If progress.txt gets too long, archive old learnings:
```bash
mv scripts/ralph/progress.txt scripts/ralph/archive/2026-01-11-progress.txt
```

### 5. Commit Manually If Needed
If Ralph gets stuck, you can help it along:
```bash
# Make a fix
# Then commit with Ralph's format
git commit -m "feat: US-001 - Fix type errors (manual assist)"

# Update PRD if story is complete
# Edit scripts/ralph/prd.json, set passes: true
```

## 📁 File Structure

```
scripts/ralph/
├── Core Scripts
│   ├── ralph.sh                    # Main loop script
│   ├── capture-session-id.sh       # Session ID finder
│   ├── parse-conversation.sh       # Conversation analyzer
│   ├── extract-insights.sh         # Auto-insight extractor
│   ├── create-prd-interactive.sh   # Interactive PRD creator
│   └── validate-prd.sh             # PRD validator
│
├── Configuration
│   ├── prompt.md                   # Instructions for each iteration
│   ├── prd.json                    # YOUR ACTIVE PRD (create this)
│   └── prd.json.example            # Template
│
├── Auto-Generated State Files
│   ├── progress.txt                # Learning log with session IDs
│   ├── session-history.txt         # Session ID timeline
│   ├── insights/                   # Auto-extracted insights
│   │   ├── iteration-1-[session].md
│   │   ├── iteration-2-[session].md
│   │   └── iteration-3-[session].md
│   └── archive/                    # Previous runs
│       └── 2026-01-11-feature-name/
│           ├── prd.json
│           └── progress.txt
│
├── Documentation
│   ├── README.md                   # Full documentation
│   ├── ARCHITECTURE.md             # Technical overview
│   ├── QUICKSTART.md               # This file
│   ├── LEARNING_SYSTEM.md          # Learning architecture
│   └── PRD_CREATION_GUIDE.md       # PRD creation guide
│
└── examples/                       # Example PRDs
    ├── player-search.prd.json
    ├── coach-dashboard-improvements.prd.json
    └── simple-ui-fix.prd.json
```

## 🚦 Your First Ralph Run

Try this now:

```bash
# 1. Use the simple example
cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json

# 2. Validate it
./scripts/ralph/validate-prd.sh

# 3. Run Ralph (just 5 iterations to start)
./scripts/ralph/ralph.sh 5

# 4. Watch what happens!
# Ralph will:
# - Create branch ralph/empty-state-fixes
# - Implement US-001 (admin players empty state)
# - Run type check and linting
# - Commit if passing
# - Move to US-002
# - Continue until done or 5 iterations reached
```

## 📞 Need Help?

Check these resources:
1. **Full documentation**: `scripts/ralph/README.md`
2. **Example PRDs**: `scripts/ralph/examples/`
3. **Progress log**: `scripts/ralph/progress.txt` (after first run)
4. **Validation**: `./scripts/ralph/validate-prd.sh`

Happy autonomous coding! 🤖
