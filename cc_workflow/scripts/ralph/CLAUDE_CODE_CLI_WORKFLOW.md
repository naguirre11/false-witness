# Ralph for Claude Code CLI - Complete Workflow Guide

## 🎯 Key Difference from Original Ralph

**Original Ralph (Amp CLI)**: Built-in "skills" system for PRD generation
**Ralph for Claude Code CLI**: Multiple flexible alternatives (actually better!)

---

## 📋 Workflow Comparison

### Original Amp CLI Workflow
```
┌─────────────────────────────────────────────┐
│ 1. Load PRD skill                          │
│    "Load the prd skill and create a PRD..." │
│    → Answers questions                      │
│    → Creates tasks/prd-feature-name.md     │
└────────────────┬────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────┐
│ 2. Load Ralph skill                        │
│    "Load ralph skill and convert..."        │
│    → Converts markdown to JSON              │
│    → Creates prd.json                       │
└────────────────┬────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────┐
│ 3. Run Ralph                               │
│    ./ralph.sh 10                           │
│    → Implements stories                     │
│    → Auto-handoff at 90% context           │
└─────────────────────────────────────────────┘
```

### Claude Code CLI Workflow (Your Options)

```
┌──────────────────────────────────────────────────────────────┐
│ OPTION 1: Use Example Templates (Fastest)                   │
│                                                              │
│ cp scripts/ralph/examples/simple-ui-fix.prd.json \         │
│    scripts/ralph/prd.json                                   │
│                                                              │
│ Time: 2 minutes                                             │
└────────────────┬─────────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────────┐
│ OPTION 2: Interactive Creator (No AI)                       │
│                                                              │
│ ./scripts/ralph/create-prd-interactive.sh                   │
│   → Prompts for: project, branch, stories                   │
│   → Prompts for: title, criteria, priority                  │
│   → Creates prd.json                                        │
│                                                              │
│ Time: 5-10 minutes                                          │
└────────────────┬─────────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────────┐
│ OPTION 3: Ask Claude Directly (AI-Assisted)                 │
│                                                              │
│ Method A: In this conversation                              │
│   You: "Create PRD for [feature]"                           │
│   Me: [Generates complete prd.json]                         │
│   You: Copy to scripts/ralph/prd.json                       │
│                                                              │
│ Method B: Via CLI script                                    │
│   ./scripts/ralph/create-prd.sh                             │
│   → Asks for feature details                                │
│   → Pipes prompt to claude CLI                              │
│   → Saves response to prd.json                              │
│                                                              │
│ Time: 3 minutes                                             │
└────────────────┬─────────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────────┐
│ OPTION 4: Manual Editing (Full Control)                     │
│                                                              │
│ cp scripts/ralph/prd.json.example \                         │
│    scripts/ralph/prd.json                                   │
│ code scripts/ralph/prd.json                                 │
│                                                              │
│ Time: 10-15 minutes                                         │
└────────────────┬─────────────────────────────────────────────┘
                 ↓
                 ↓ (All options converge here)
                 ↓
┌──────────────────────────────────────────────────────────────┐
│ Validate PRD                                                │
│                                                              │
│ ./scripts/ralph/validate-prd.sh                             │
│   → Checks task sizing                                      │
│   → Warns about complexity                                  │
│   → Validates JSON structure                                │
└────────────────┬─────────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────────────────────────┐
│ Run Ralph                                                   │
│                                                              │
│ ./scripts/ralph/ralph.sh 10                                 │
│   → Fresh Claude instance per story                         │
│   → Iteration-level context management                      │
│   → Commits when quality checks pass                        │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔄 Step-by-Step: The "Amp Skills" Replacement

### ❌ Amp CLI (Old Way)
```bash
# Step 1: PRD generation
amp
> Load the prd skill and create a PRD for player search feature
> [Answer questions in chat]
> [Skill saves to tasks/prd-player-search.md]

# Step 2: Convert to JSON
amp
> Load the ralph skill and convert tasks/prd-player-search.md to prd.json
> [Skill converts MD → JSON]

# Step 3: Run Ralph
./ralph.sh 10
```

### ✅ Claude Code CLI (New Way)

#### **Recommended: Ask Me Directly**
```bash
# Step 1: Generate PRD (in this conversation)
You: "Create a PRD for player search feature with 4 stories:
- Add search input
- Add team filter
- Add age group filter
- Persist filters in URL"

Me: [Generates complete prd.json instantly]

You: Copy the JSON to scripts/ralph/prd.json

# Step 2: Validate
./scripts/ralph/validate-prd.sh

# Step 3: Run Ralph
./scripts/ralph/ralph.sh 10
```

#### **Alternative: Interactive Script**
```bash
# Step 1: Run interactive creator
./scripts/ralph/create-prd-interactive.sh

Project/Feature Name: Player Search Feature
Git Branch Name: ralph/player-search
Feature Description: Add search and filtering to admin players
Number of stories: 4

[Answers prompts for each story]

# Step 2: Validate
./scripts/ralph/validate-prd.sh

# Step 3: Run Ralph
./scripts/ralph/ralph.sh 10
```

---

## 💡 Why This Is Better Than Amp Skills

| Feature | Amp CLI "Skills" | Claude Code CLI |
|---------|-----------------|-----------------|
| **Speed** | 2-step process | 1-step (ask me) or 1-step (examples) |
| **Flexibility** | Fixed workflow | 4 different options |
| **No Setup** | Requires skill installation | Works immediately |
| **Customization** | Skills are black boxes | Full control over PRD |
| **Examples** | None included | 3 ready-to-use templates |
| **Validation** | Not included | Built-in validator |
| **AI Quality** | Amp's model | Claude Sonnet 4.5 |
| **Offline** | ❌ Needs Amp service | ✅ Manual/interactive options work |

---

## 🎓 Examples: Creating PRDs with Different Methods

### Example 1: Fastest Way (Example Template)

**Use case**: You want to try Ralph with minimal setup

```bash
# 30 seconds
cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh 5
```

✅ Done! Ralph is implementing empty states.

---

### Example 2: AI-Assisted (Ask Claude)

**Use case**: Custom feature, want AI help

**You ask me:**
> "Create a PRD for adding bulk player operations to the admin page. I need 4 stories: select multiple players, bulk delete, bulk export to CSV, bulk team assignment."

**I respond with:**
```json
{
  "project": "Bulk Player Operations",
  "branchName": "ralph/bulk-player-ops",
  "description": "Allow admins to perform bulk operations on players",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add player selection checkboxes",
      "description": "As an admin, I want to select multiple players for bulk actions",
      "acceptanceCriteria": [
        "Checkbox next to each player row",
        "Select all checkbox in header",
        "Selection count display",
        "Type checking passes: npm run check-types"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Add selection state to admin players page"
    },
    {
      "id": "US-002",
      "title": "Add bulk delete action",
      "description": "As an admin, I want to delete multiple players at once",
      "acceptanceCriteria": [
        "Delete button when players selected",
        "Confirmation dialog with count",
        "Success toast after deletion",
        "Clear selection after delete",
        "Type checking passes: npm run check-types"
      ],
      "priority": 2,
      "passes": false,
      "notes": "Use deletePlayer mutation in loop or create bulkDelete"
    },
    {
      "id": "US-003",
      "title": "Add bulk CSV export action",
      "description": "As an admin, I want to export selected players to CSV",
      "acceptanceCriteria": [
        "Export button when players selected",
        "Downloads CSV with selected players",
        "Includes all player fields",
        "Type checking passes: npm run check-types"
      ],
      "priority": 3,
      "passes": false,
      "notes": "Use existing player data, format as CSV"
    },
    {
      "id": "US-004",
      "title": "Add bulk team assignment action",
      "description": "As an admin, I want to assign multiple players to a team at once",
      "acceptanceCriteria": [
        "Assign to Team button when players selected",
        "Team picker dropdown",
        "Assigns all selected players",
        "Success toast with count",
        "Type checking passes: npm run check-types"
      ],
      "priority": 4,
      "passes": false,
      "notes": "Use addPlayerToTeam mutation in loop"
    }
  ]
}
```

**You copy and run:**
```bash
# Paste JSON to scripts/ralph/prd.json
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh 10
```

✅ Done! Ralph is implementing bulk operations.

**Time**: 3 minutes total

---

### Example 3: Interactive (No AI)

**Use case**: You prefer guided prompts, no AI needed

```bash
./scripts/ralph/create-prd-interactive.sh

# Prompts:
Project/Feature Name: Player Birthday Reminders
Git Branch Name: ralph/player-birthdays
Feature Description: Show upcoming player birthdays to coaches

# Story 1
Story Title: Add birthday field to player model
Description: Store player date of birth
Priority: 1
Acceptance Criteria:
  1. Add birthday field to orgPlayerEnrollments
  2. Add input to player edit form
  3. Type checking passes
  4. [Enter to finish]
Technical Notes: Optional field, use date input

Add another story? (y): y

# Story 2
Story Title: Display upcoming birthdays on coach dashboard
Description: Show players with birthdays in next 7 days
Priority: 2
Acceptance Criteria:
  1. Card on dashboard showing upcoming birthdays
  2. Lists player name and birthday date
  3. Sorts by date (soonest first)
  4. Type checking passes
  5. [Enter to finish]
Technical Notes: Query players where birthday in date range

Add another story? (n): n

✅ PRD created successfully!
```

**Then:**
```bash
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh 10
```

✅ Done! Ralph is implementing birthday reminders.

**Time**: 5-7 minutes

---

## 🔧 Tools & Scripts Reference

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `create-prd.sh` | AI-assisted PRD via Claude CLI | Complex features, want AI suggestions |
| `create-prd-interactive.sh` | Guided prompts (no AI) | Prefer step-by-step, simple features |
| `validate-prd.sh` | Check PRD quality | **Always use before running Ralph** |
| `ralph.sh` | Main Ralph loop | After PRD created & validated |

---

## 📚 Documentation Files

| File | What It Contains |
|------|-----------------|
| `PRD_CREATION_GUIDE.md` | Complete guide to all PRD creation methods |
| `QUICKSTART.md` | Fast getting started (all 3 steps) |
| `README.md` | Full Ralph documentation |
| `CLAUDE_CODE_CLI_WORKFLOW.md` | This file - workflow comparison |
| `GITHUB_INTEGRATION_IDEAS.md` | Future: GitHub Issues integration |

---

## 🎯 Quick Decision Tree

```
Do you want to try Ralph quickly?
  → YES: Copy example template
    cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json

Do you have a custom feature idea?
  → Want AI help? Ask Claude (me!) in this conversation
  → Want to DIY? Run ./scripts/ralph/create-prd-interactive.sh

Do you need team collaboration?
  → Future: Use GitHub Issues integration
  → Now: Share prd.json file or ask me to generate PRD

Ready to run?
  → Always validate first: ./scripts/ralph/validate-prd.sh
  → Then run: ./scripts/ralph/ralph.sh
```

---

## ✅ Bottom Line

**You don't need Amp "skills"** - Claude Code CLI workflow is actually:
- ✅ Faster (ask me directly vs 2-step skill process)
- ✅ More flexible (4 options vs 1)
- ✅ Better validated (built-in validation)
- ✅ More examples (3 ready-to-use PRDs)

**Best approach**: Ask me to generate your PRD, then validate and run!

---

**Want to try it now?** Tell me what feature you want to build and I'll create the PRD for you!
