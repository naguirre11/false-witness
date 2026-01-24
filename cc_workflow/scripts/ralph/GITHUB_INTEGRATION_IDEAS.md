# GitHub Integration Ideas for Ralph

## 🎯 Problem Statement

**Current workflow:**
- PRD stored locally in `prd.json`
- Progress tracked in local `progress.txt`
- No visibility for team members
- No collaborative PRD creation
- Manual tracking of what Ralph accomplished

**Opportunity:**
Use GitHub as the source of truth and collaboration layer for Ralph workflows.

---

## 💡 Integration Patterns

### Pattern 1: GitHub Issues as User Stories ⭐⭐⭐⭐⭐

**Concept**: Use GitHub Issues as the PRD, Ralph syncs with GitHub API

```
GitHub Issues          Ralph               Code
─────────────         ──────              ─────
Issue #123 (open)  →  US-001 (pending) →  Implement
Issue #124 (open)  →  US-002 (pending) →  Queue
Issue #125 (open)  →  US-003 (pending) →  Queue
     ↓
Ralph completes US-001
     ↓
Issue #123 (closed) ← Ralph updates GitHub
  + Comment with implementation details
  + Labels: "ralph-complete"
  + Linked commit SHA
```

**Implementation:**

1. **Issue Format** (template):
```markdown
## User Story
As a [role], I want [feature] so that [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Ralph Metadata
- Priority: 1
- Story ID: US-001
- Branch: ralph/feature-name
```

2. **Labels**:
- `user-story` - Identifies Ralph-eligible issues
- `priority-1`, `priority-2`, etc. - Story priority
- `ralph-pending` - Not started
- `ralph-in-progress` - Currently working
- `ralph-complete` - Finished and passing
- `ralph-blocked` - Needs manual intervention

3. **Workflow Script**: `scripts/ralph/github-sync.sh`
```bash
#!/bin/bash
# Pulls GitHub issues and creates prd.json
# Updates GitHub when stories complete

# Pull user stories from GitHub
gh issue list \
  --label "user-story" \
  --label "ralph-pending" \
  --json number,title,body,labels \
  | jq 'convert to prd.json format'

# After iteration, update GitHub
# - Add comment with progress
# - Update labels
# - Close if complete
```

**Benefits:**
- ✅ Team collaboration on PRD
- ✅ Visibility into Ralph's progress
- ✅ Issue discussion for requirements
- ✅ Automatic linking commits ↔ issues
- ✅ Project board integration

**Challenges:**
- ⚠️ Requires gh CLI authentication
- ⚠️ API rate limits
- ⚠️ Need to parse issue body format

---

### Pattern 2: GitHub Projects (Kanban Board) ⭐⭐⭐⭐

**Concept**: Use GitHub Projects for visual progress tracking

```
GitHub Project Board
┌──────────────┬──────────────┬──────────────┐
│   To Do      │ In Progress  │     Done     │
├──────────────┼──────────────┼──────────────┤
│ US-002       │ US-001       │              │
│ US-003       │              │              │
│ US-004       │              │              │
└──────────────┴──────────────┴──────────────┘
                     ↓
              Ralph completes US-001
                     ↓
┌──────────────┬──────────────┬──────────────┐
│   To Do      │ In Progress  │     Done     │
├──────────────┼──────────────┼──────────────┤
│ US-003       │ US-002       │ US-001 ✅    │
│ US-004       │              │              │
└──────────────┴──────────────┴──────────────┘
```

**Implementation:**

1. Create project with automation
2. Link issues to project
3. Ralph updates card status via API
4. Team sees real-time progress in Project board

**gh CLI commands:**
```bash
# List project items
gh project item-list PROJECT_ID

# Move card
gh project item-edit --id ITEM_ID --field-id STATUS --value "Done"

# Add comment
gh project item-add --project-id PROJECT_ID --content-id ISSUE_ID
```

**Benefits:**
- ✅ Visual progress tracking
- ✅ Team can see what Ralph is working on
- ✅ Integrates with existing workflows
- ✅ Mobile-friendly (GitHub mobile app)

---

### Pattern 3: Pull Request per Story ⭐⭐⭐⭐⭐

**Concept**: Ralph creates a PR for each user story

```
US-001 → Branch: ralph/US-001-search-input
         Commits: feat: US-001 - Add search input
         PR #125: "US-001: Add search input to players page"
                  - Acceptance criteria as checklist
                  - Links to parent issue
                  - Auto-created by Ralph
         Status: ✅ Checks passing → Auto-merge

US-002 → Branch: ralph/US-002-team-filter
         PR #126: "US-002: Add team filter dropdown"
         Status: ⏳ In progress
```

**Implementation:**

```bash
# Ralph creates PR after completing story
gh pr create \
  --title "US-001: Add search input to players page" \
  --body "$(cat <<EOF
## User Story
As an admin, I want to search players by name

## Acceptance Criteria
- [x] Search input at top of table
- [x] Filters by firstName and lastName
- [x] Updates in real-time
- [x] Type checking passes

## Implementation
- Modified: apps/web/src/app/orgs/[orgId]/admin/players/page.tsx
- Added: search state and filter logic
- Tests: ✅ Type check passing

Closes #123
EOF
)" \
  --base main \
  --head ralph/US-001-search-input \
  --label "ralph-generated"
```

**Benefits:**
- ✅ Code review per story
- ✅ Isolates changes for easy review
- ✅ CI/CD runs per story
- ✅ Easy to revert if needed
- ✅ Clear audit trail

**Challenges:**
- ⚠️ Many PRs to manage
- ⚠️ Merge conflicts between stories
- ⚠️ Requires auto-merge setup

---

### Pattern 4: Markdown PRD in Repo ⭐⭐⭐

**Concept**: PRD as markdown file, Ralph updates checkboxes

**File**: `docs/prd/player-search-feature.md`
```markdown
# PRD: Player Search Feature

**Branch**: ralph/player-search
**Status**: 🟡 In Progress (2/4 complete)

## User Stories

### ✅ US-001: Add search input to admin players page
**Priority**: 1 | **Status**: Complete

As an admin, I want to search players by name

**Acceptance Criteria:**
- [x] Search input at top of table
- [x] Filters by firstName and lastName
- [x] Updates in real-time
- [x] Type checking passes

**Implementation**: [Commit abc123](link)

---

### 🔄 US-002: Add team filter dropdown
**Priority**: 2 | **Status**: In Progress

As an admin, I want to filter by team

**Acceptance Criteria:**
- [ ] Dropdown shows all teams
- [ ] Filters players by team
- [ ] Works with search
- [ ] Type checking passes

---

### ⏳ US-003: Add age group filter
**Priority**: 3 | **Status**: Pending

...
```

**Ralph workflow:**
1. Read markdown PRD
2. Parse into prd.json format
3. Complete stories
4. Update markdown with checkboxes ✅
5. Add commit links
6. Update status emoji

**Benefits:**
- ✅ Human-readable in GitHub UI
- ✅ Easy to collaborate on
- ✅ Version controlled
- ✅ Can render in docs sites

**Implementation**: `scripts/ralph/md-to-json.sh` and `json-to-md.sh`

---

### Pattern 5: Ralph as GitHub Action ⭐⭐⭐⭐

**Concept**: Run Ralph in GitHub Actions, triggered automatically

**Workflow**: `.github/workflows/ralph.yml`
```yaml
name: Ralph Autonomous Development

on:
  # Trigger manually
  workflow_dispatch:
    inputs:
      max_iterations:
        description: 'Max iterations'
        required: false
        default: '10'

  # Or on schedule (nightly)
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily

  # Or when PRD updated
  push:
    paths:
      - 'scripts/ralph/prd.json'

jobs:
  ralph:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install

      - name: Run Ralph
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          ./scripts/ralph/ralph.sh ${{ github.event.inputs.max_iterations || 10 }}

      - name: Create PR with changes
        if: success()
        run: |
          gh pr create \
            --title "Ralph: Automated development $(date +%Y-%m-%d)" \
            --body "Ralph completed stories. Review and merge."
```

**Benefits:**
- ✅ Run on schedule (nightly development!)
- ✅ Trigger via GitHub UI
- ✅ Logs visible in Actions tab
- ✅ Artifacts stored (progress.txt)
- ✅ No local environment needed

**Use cases:**
- 🌙 Overnight development
- ⏰ Scheduled feature work
- 🔄 Continuous autonomous development

---

### Pattern 6: Issue Comments for Progress Updates ⭐⭐⭐⭐

**Concept**: Ralph comments on issues with detailed progress

**Example Issue #123**:
```markdown
Issue: Add search input to players page

Comments:
┌─────────────────────────────────────────────┐
│ Ralph Bot - 2 hours ago                     │
│ 🤖 Starting work on US-001                  │
│ Branch: ralph/player-search                 │
│ Iteration: 1                                │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Ralph Bot - 1 hour ago                      │
│ ✅ US-001 Complete                          │
│                                             │
│ **What was implemented:**                   │
│ - Added search state to players page        │
│ - Implemented filter logic                  │
│ - Connected to existing player list         │
│                                             │
│ **Files changed:**                          │
│ - apps/web/src/app/orgs/[orgId]/admin/     │
│   players/page.tsx (+45 lines)              │
│                                             │
│ **Quality checks:**                         │
│ ✅ Type check passed                        │
│ ✅ Linting passed                           │
│                                             │
│ **Commits:**                                │
│ - abc123: feat: US-001 - Add search input   │
│                                             │
│ **Learnings:**                              │
│ - Players list uses SmartDataView component │
│ - Filter logic works with existing sorting  │
└─────────────────────────────────────────────┘
```

**Implementation**:
```bash
# After completing story
gh issue comment $ISSUE_NUMBER --body "$(cat progress.txt | tail -n 20)"
gh issue edit $ISSUE_NUMBER --add-label "ralph-complete"
gh issue close $ISSUE_NUMBER
```

**Benefits:**
- ✅ Detailed audit trail
- ✅ Team can follow along
- ✅ Learnings captured in issue
- ✅ Easy to find implementation details

---

## 🏆 Recommended Hybrid Approach

Combine the best patterns for maximum value:

### Setup

1. **GitHub Issues as PRD** (Pattern 1)
   - Team creates issues with `user-story` label
   - Includes acceptance criteria
   - Prioritized with labels

2. **Ralph syncs issues → prd.json**
   ```bash
   ./scripts/ralph/github-sync.sh pull
   ```

3. **Ralph runs locally or in Actions**
   ```bash
   ./scripts/ralph/ralph.sh 10
   ```

4. **Ralph updates GitHub after each story** (Pattern 6)
   - Comments on issue with progress
   - Updates labels (pending → complete)
   - Closes issue when passes: true

5. **Optional: Create PR for review** (Pattern 3)
   ```bash
   ./scripts/ralph/github-sync.sh create-pr
   ```

6. **GitHub Project board auto-updates** (Pattern 2)
   - Issue status changes → Card moves
   - Visual progress tracking

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Team creates GitHub Issues                              │
│    - Label: user-story                                      │
│    - Priority labels                                        │
│    - Acceptance criteria                                    │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Ralph syncs Issues → prd.json                           │
│    ./scripts/ralph/github-sync.sh pull                     │
│    Creates local prd.json from GitHub Issues               │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Ralph runs                                              │
│    ./scripts/ralph/ralph.sh 10                             │
│    - Picks highest priority story                          │
│    - Implements it                                         │
│    - Commits code                                          │
│    - Updates prd.json                                      │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Ralph syncs back to GitHub                              │
│    ./scripts/ralph/github-sync.sh push                     │
│    - Comments on issue with details                        │
│    - Updates labels (ralph-complete)                       │
│    - Closes issue if passes: true                          │
└────────────────────┬────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Team reviews                                            │
│    - Check commits                                         │
│    - Review code                                           │
│    - Test functionality                                    │
│    - Merge to main                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Implementation Plan

### Phase 1: Issue Sync (High Value, Low Effort)

**Files to create:**
1. `scripts/ralph/github-sync.sh` - Bidirectional sync
2. `.github/ISSUE_TEMPLATE/user-story.md` - Issue template
3. `scripts/ralph/issue-to-prd.jq` - jq transform

**Commands:**
```bash
# Pull issues to prd.json
./scripts/ralph/github-sync.sh pull

# Run Ralph
./scripts/ralph/ralph.sh 10

# Push results back to GitHub
./scripts/ralph/github-sync.sh push
```

### Phase 2: Auto-comments (Medium Value, Low Effort)

Add to `ralph.sh`:
```bash
# After each iteration
if [ -n "$ISSUE_NUMBER" ]; then
  gh issue comment $ISSUE_NUMBER \
    --body "$(cat progress.txt | tail -n 30)"
fi
```

### Phase 3: GitHub Actions (High Value, Medium Effort)

Create `.github/workflows/ralph.yml` for scheduled runs

### Phase 4: Project Board Integration (Medium Value, Medium Effort)

Auto-update project board status based on issue labels

---

## 🎯 Quick Wins to Implement First

### 1. Issue Template
Create `.github/ISSUE_TEMPLATE/ralph-user-story.md`:
```markdown
---
name: Ralph User Story
about: User story for autonomous development
labels: user-story, ralph-pending
---

## User Story
As a [role], I want [feature] so that [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Ralph Metadata
<!-- DO NOT EDIT BELOW THIS LINE -->
Priority: [1-5]
Story ID: US-XXX
Branch: ralph/[feature-name]
```

### 2. Simple Sync Script
```bash
#!/bin/bash
# scripts/ralph/github-sync.sh

ACTION=${1:-pull}

if [ "$ACTION" = "pull" ]; then
  # Convert GitHub issues to prd.json
  gh issue list \
    --label "user-story" \
    --label "ralph-pending" \
    --json number,title,body,labels \
    --jq 'to-prd-format'
fi

if [ "$ACTION" = "push" ]; then
  # Update GitHub after completion
  COMPLETED_STORY=$(jq -r '.userStories[] | select(.passes == true and .synced != true) | .id' prd.json)

  # Comment and close issue
  gh issue comment $ISSUE_NUMBER --body "✅ Story complete"
  gh issue close $ISSUE_NUMBER
fi
```

---

## 📊 Comparison Matrix

| Pattern | Value | Effort | Team Collab | Visibility | Recommended |
|---------|-------|--------|-------------|------------|-------------|
| GitHub Issues | ⭐⭐⭐⭐⭐ | 🔨🔨 | ✅ High | ✅ High | ✅ YES |
| Project Board | ⭐⭐⭐⭐ | 🔨 | ✅ High | ✅ High | ✅ YES |
| PR per Story | ⭐⭐⭐⭐⭐ | 🔨🔨🔨 | ✅ High | ✅ High | 🤔 Maybe |
| Markdown PRD | ⭐⭐⭐ | 🔨 | ⚠️ Medium | ⚠️ Medium | ⏸️ Later |
| GitHub Actions | ⭐⭐⭐⭐ | 🔨🔨🔨 | ✅ High | ✅ High | ⏸️ Phase 2 |
| Issue Comments | ⭐⭐⭐⭐ | 🔨 | ✅ High | ✅ High | ✅ YES |

---

## 🚀 Next Steps

Want me to implement:
1. **Issue sync script** - Pull GitHub issues to prd.json
2. **Issue template** - Standardized user story format
3. **Auto-commenting** - Ralph updates issues with progress
4. **All of the above** - Complete GitHub integration

Which would be most valuable for your workflow?
