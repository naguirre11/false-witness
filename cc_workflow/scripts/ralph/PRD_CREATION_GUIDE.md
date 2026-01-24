# PRD Creation Guide for Claude Code CLI

The original Ralph (Amp CLI) had built-in "skills" for PRD generation. Claude Code CLI doesn't have this, but here are **better alternatives** that work just as well (or better!).

---

## 🎯 Option 1: Use Example Templates (Fastest) ⭐⭐⭐⭐⭐

**Best for**: Getting started quickly, learning Ralph

```bash
# Copy an example PRD
cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json

# Edit to customize
code scripts/ralph/prd.json

# Validate
./scripts/ralph/validate-prd.sh

# Run
./scripts/ralph/ralph.sh
```

**Time**: 2 minutes

**Available examples:**
- `simple-ui-fix.prd.json` - 3 stories (empty states)
- `player-search.prd.json` - 4 stories (search & filters)
- `coach-dashboard-improvements.prd.json` - 6 stories (UI components)

---

## 🎯 Option 2: Interactive CLI Creator (No Claude) ⭐⭐⭐⭐

**Best for**: Creating custom PRDs without AI assistance

```bash
./scripts/ralph/create-prd-interactive.sh
```

**Prompts you'll see:**
```
Project/Feature Name: Player Export Feature
Git Branch Name: ralph/player-export
Feature Description: Allow admins to export player data to CSV

User Story 1 (US-001)
Story Title: Add export button to players page
Description: Admin can click export button to download CSV
Priority (1-5): 1

Acceptance Criteria (press Enter on empty line to finish):
  1. Button appears in page header
  2. Clicking downloads CSV file
  3. CSV includes all player fields
  4.

Technical Notes: Use existing player query

Add another story? (y/n): y
```

**Output**: Valid `prd.json` ready to use

**Time**: 5-10 minutes

---

## 🎯 Option 3: Ask Claude Directly (AI-Assisted) ⭐⭐⭐⭐⭐

**Best for**: Complex features, getting AI suggestions

### Method A: Using Claude in this conversation

Just ask me:
> "Create a PRD for [your feature]. I need 4 user stories for adding player export functionality to the admin page."

I'll generate a complete `prd.json` for you!

### Method B: Using Claude CLI with prompt

```bash
./scripts/ralph/create-prd.sh
```

This script:
1. Asks you for feature name and story count
2. Pipes a prompt to Claude CLI
3. Extracts the JSON response
4. Saves to `prd.json`

**Time**: 3 minutes (+ Claude response time)

### Method C: Manual prompt to Claude

Create a file with this prompt:
```bash
cat > /tmp/prd-prompt.txt <<'EOF'
Create a PRD in JSON format for this feature:

Feature: Add player statistics dashboard
Number of stories: 5

Requirements:
- Admin can view player statistics
- Show skill ratings over time
- Compare players on same team
- Export statistics to PDF
- Filter by date range

Format as valid prd.json with structure:
{
  "project": "...",
  "branchName": "ralph/...",
  "description": "...",
  "userStories": [
    {
      "id": "US-001",
      "title": "...",
      "description": "...",
      "acceptanceCriteria": [...],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}

Make each story completable in one iteration (1-3 files).
Include specific acceptance criteria.
Add technical notes where helpful.
EOF

# Send to Claude
cat /tmp/prd-prompt.txt | claude > /tmp/prd-response.txt

# Extract JSON (manually or with script)
# Copy to scripts/ralph/prd.json
```

---

## 🎯 Option 4: Start from Blank Template ⭐⭐⭐

**Best for**: Total control, simple features

```bash
# Copy template
cp scripts/ralph/prd.json.example scripts/ralph/prd.json

# Edit manually
code scripts/ralph/prd.json
```

**Template structure:**
```json
{
  "project": "Your Feature Name",
  "branchName": "ralph/your-feature",
  "description": "Brief description",
  "userStories": [
    {
      "id": "US-001",
      "title": "First story title",
      "description": "As a [role], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Type checking passes: npm run check-types"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Technical hints here"
    }
  ]
}
```

**Time**: 10-15 minutes

---

## 🎯 Option 5: Convert from GitHub Issues (Advanced) ⭐⭐⭐⭐

**Best for**: Team collaboration, existing issue tracking

**Coming soon**: `github-sync.sh` script to pull issues → prd.json

See: `scripts/ralph/GITHUB_INTEGRATION_IDEAS.md`

---

## 📋 PRD Best Practices

### Good User Story Structure

```json
{
  "id": "US-001",
  "title": "Add search input to players page",
  "description": "As an admin, I want to search players by name so I can quickly find them",
  "acceptanceCriteria": [
    "Search input appears at top of players table",
    "Filters by firstName and lastName (case-insensitive)",
    "Updates results in real-time as user types",
    "Type checking passes: npm run check-types"
  ],
  "priority": 1,
  "passes": false,
  "notes": "File: apps/web/src/app/orgs/[orgId]/admin/players/page.tsx"
}
```

### Task Sizing Guidelines

✅ **Right-sized (1-3 files):**
- "Add search input to existing page"
- "Create QuickActions component"
- "Update team filter dropdown"

❌ **Too large (>5 files):**
- "Build complete dashboard"
- "Refactor entire authentication"
- "Add comprehensive analytics"

**Solution**: Split large stories into smaller ones

### Acceptance Criteria Tips

**Good criteria** (specific, testable):
- ✅ "Search input appears in page header"
- ✅ "Dropdown shows all team names"
- ✅ "Type checking passes: npm run check-types"

**Bad criteria** (vague, subjective):
- ❌ "Search works well"
- ❌ "UI looks nice"
- ❌ "Performance is good"

### Always Include Quality Checks

Add these to **every story's** acceptance criteria:
```json
"acceptanceCriteria": [
  "... (feature-specific criteria)",
  "Type checking passes: npm run check-types",
  "Linting passes: npm run check"
]
```

---

## 🔄 PRD Workflow Comparison

### Original Ralph (Amp CLI)
```
1. Load PRD skill → Answer questions → Markdown PRD created
2. Load Ralph skill → Convert MD to JSON → prd.json created
3. Run ralph.sh → Implementation
```

### Ralph for Claude Code CLI (Your Options)
```
Option 1: Copy example → Edit → Validate → Run
Option 2: Interactive script → Validate → Run
Option 3: Ask Claude (me!) → Save JSON → Validate → Run
Option 4: Manual editing → Validate → Run
Option 5: GitHub sync → Validate → Run (future)
```

**Key difference**: No "skills" system, but **more flexible** and **faster** for most use cases!

---

## 🚀 Recommended Workflow by Experience Level

### First Time Using Ralph
```bash
# Use example template
cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh 5
```

### Creating Your First Custom PRD
```bash
# Ask Claude (me!) in this conversation
"Create a PRD for [your feature description]"
# Copy the JSON I provide to scripts/ralph/prd.json
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh
```

### Experienced Ralph User
```bash
# Interactive creation
./scripts/ralph/create-prd-interactive.sh
# or manual editing from template
cp scripts/ralph/prd.json.example scripts/ralph/prd.json
code scripts/ralph/prd.json
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh
```

### Team Environment
```bash
# Future: GitHub issues integration
./scripts/ralph/github-sync.sh pull
./scripts/ralph/validate-prd.sh
./scripts/ralph/ralph.sh
./scripts/ralph/github-sync.sh push
```

---

## 🎓 Example: Creating PRD with Claude (This Conversation)

**You**: "Create a PRD for adding bulk player deletion to the admin page. I need 3 user stories."

**Me**: "Here's your PRD:"
```json
{
  "project": "Bulk Player Deletion",
  "branchName": "ralph/bulk-player-deletion",
  "description": "Allow admins to delete multiple players at once",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add checkboxes to player list",
      "description": "As an admin, I want to select multiple players for bulk actions",
      "acceptanceCriteria": [
        "Checkbox appears next to each player row",
        "Select all checkbox in table header",
        "Selection state persists while navigating filters",
        "Type checking passes: npm run check-types"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Add selection state to players page component"
    },
    {
      "id": "US-002",
      "title": "Add bulk delete button",
      "description": "As an admin, I want to delete selected players in one action",
      "acceptanceCriteria": [
        "Delete button appears when players selected",
        "Shows count of selected players",
        "Confirmation dialog before deletion",
        "Button disabled when no selection",
        "Type checking passes: npm run check-types"
      ],
      "priority": 2,
      "passes": false,
      "notes": "Use existing deletePlayer mutation in bulk"
    },
    {
      "id": "US-003",
      "title": "Handle bulk delete operation",
      "description": "As an admin, confirmed bulk delete should remove all selected players",
      "acceptanceCriteria": [
        "Deletes all selected players",
        "Shows success toast with count deleted",
        "Clears selection after deletion",
        "Updates player list automatically",
        "Error handling if some deletions fail",
        "Type checking passes: npm run check-types"
      ],
      "priority": 3,
      "passes": false,
      "notes": "May need to create bulkDeletePlayers mutation in Convex"
    }
  ]
}
```

**You**: Copy that JSON to `scripts/ralph/prd.json` and run!

---

## 💡 Pro Tips

1. **Start with examples** - Modify existing PRDs instead of creating from scratch
2. **Use validation** - Always run `validate-prd.sh` before Ralph
3. **Small stories** - If validation shows warnings, split stories
4. **Ask Claude** - I can generate PRDs faster than manual creation
5. **Iterate** - First PRD doesn't need to be perfect; Ralph can handle changes

---

## 📁 Files Reference

| File | Purpose |
|------|---------|
| `create-prd.sh` | AI-assisted PRD creation (uses Claude CLI) |
| `create-prd-interactive.sh` | Manual guided PRD creation |
| `validate-prd.sh` | Check if PRD is well-structured |
| `prd.json.example` | Blank template |
| `examples/*.prd.json` | Ready-to-use example PRDs |

---

## 🆘 Troubleshooting

**Q: create-prd.sh fails with "claude: command not found"**
A: The Claude CLI isn't in your PATH. Use `create-prd-interactive.sh` instead, or ask me directly in this conversation.

**Q: Interactive script is tedious for many stories**
A: Ask me to generate the PRD! Just describe your feature and I'll create the JSON.

**Q: My PRD has validation warnings**
A: Split large stories into smaller ones. Each should change 1-3 files max.

**Q: Can I use markdown PRDs like Amp?**
A: Not currently, but we could add MD → JSON conversion if you prefer that workflow.

---

Want me to create a PRD for you right now? Just describe your feature!
