# Ralph Reference Guide for Claude Code Instances

> Quick reference for building PRDs and managing Ralph iterations effectively.
> Source: [github.com/ardmhacha24/ralph-claude-code](https://github.com/ardmhacha24/ralph-claude-code)

---

## What is Ralph?

Ralph is an autonomous loop that runs Claude Code CLI repeatedly until all PRD tasks complete. Each iteration is a **fresh Claude instance** with no memory of previous runs - context persists through files.

```
while stories remain:
    claude --prompt prompt.md
    capture_session_id
    extract_insights
```

Named after the Simpsons character, Ralph embodies **persistent iteration**: keep trying until you get it right. The technique treats failures as learning data - each failed attempt tells Claude what doesn't work, and over iterations the solution converges toward success.

### Why Simple Loops Beat Complex Orchestrators

[Research and practice](https://www.chrismdp.com/your-agent-orchestrator-is-too-clever/) show that simple Ralph loops outperform elaborate multi-agent systems. One developer's attempt at four parallel Claude instances produced "duplicated code, impossible coordination overhead, and a completely unusable codebase" - while a bash for-loop succeeded.

This follows [Richard Sutton's "bitter lesson"](https://ghuntley.com/loop/): general methods plus compute beat clever engineering. Current models crossed a capability threshold where they can reliably self-correct without elaborate state machines.

---

## Quick Links

| Doc | Purpose |
|-----|---------|
| `ralph/prd.json` | Current PRD (edit this) |
| `ralph/progress.txt` | Learning log (Ralph appends here) |
| `ralph/prompt.md` | Instructions given to each iteration |
| `ralph/session-history.txt` | Conversation ID timeline |
| `ralph/insights/` | Auto-extracted learnings per iteration |

---

## Progress.txt Management

**IMPORTANT: Do not alter `progress.txt` unless explicitly asked by the user.**

Ralph's `progress.txt` is a cumulative learning log. Ralph's automated pipeline:
- **Appends** new iteration entries (never replaces)
- **Archives** the file when switching PRDs (copies to `archive/`)
- **Preserves** full history for cross-PRD learning

### What NOT to do when reviewing Ralph's work:
- Do not truncate or reset progress.txt
- Do not delete old iteration entries
- Do not "clean up" the file to save space

### Size Warning Threshold

When `progress.txt` exceeds **~1000 lines or ~50KB**, alert the user:

> ⚠️ **progress.txt is getting large** (~X lines). Consider consolidating older entries:
> 1. Extract key learnings from old entries into the "Codebase Patterns" section
> 2. Archive the detailed iteration logs to a dated backup
> 3. Keep the last 10-15 iteration entries for recent context

This preserves learnings while managing file size. Only do this **with user approval**.

---

## Core Principles (Validated)

These principles emerge from [Geoffrey Huntley's original work](https://ghuntley.com/loop/), the [Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook), and practitioner experience:

### 1. One Task Per Loop
Each iteration should complete exactly ONE focused task. This ensures 100% of context stays in the "smart zone" - [research shows](https://github.com/ClaytonFarr/ralph-playbook) that even with 200K+ token windows, only 40-60% operates optimally.

### 2. Fresh Context Solves Context Rot
Standard agent loops suffer from context accumulation - failed attempts stay in history, forcing the model to process noise. Ralph solves this by starting fresh each iteration, with memory persisting through files.

### 3. Backpressure Through Automation
Tests, type-checks, lints, and builds create automated feedback that rejects invalid work. As Huntley notes: *"The more you capture the back pressure, the more autonomy you can grant."*

### 4. Sit On the Loop, Not In It
Your role shifts from implementer to **loop engineer**. Watch for failure patterns, update learnings files, and improve the system - rather than doing the implementation yourself.

### 5. Watch and Learn
*"It's important to watch the loop as that is where your personal development and learning will come from. When you see a failure domain – put on your engineering hat and resolve the problem so it never happens again."* - Geoffrey Huntley

---

## Task Sizing (Research-Backed)

[Continue.dev's research](https://blog.continue.dev/task-decomposition/) identifies three task types:

| Type | Examples | AI Performance |
|------|----------|----------------|
| **Type 1: Narrow** | Remove feature flag, write unit test, generate boilerplate | Excellent - minimal context, one correct answer |
| **Type 2: Context-Specific** | Debug specific error, refactor to match pattern, optimize query | Good - show relevant code and examples |
| **Type 3: Open-Ended** | "Build user authentication", "Add photo upload" | Poor - decompose into Type 1 & 2 first |

### Signs Your Task is Right-Sized
- Completes in one iteration
- Changes 1-3 files
- Review takes seconds, not minutes
- Errors stay contained and easy to fix

### Signs Your Task is Too Large
- Requires extensive exploration/searching
- Generates hundreds of lines needing debugging
- AI loses track of earlier context
- Multiple "and"s in the description (split at each "and")

---

## PRD Structure

```json
{
  "project": "Feature Name",
  "branchName": "ralph/feature-name",
  "description": "Brief description of the work",
  "userStories": [
    {
      "id": "TICKET-001",
      "title": "Short descriptive title",
      "description": "What this story accomplishes",
      "acceptanceCriteria": [
        "Specific, testable criterion 1",
        "Specific, testable criterion 2",
        "npm run build passes",
        "npm run lint passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Technical hints, file paths, gotchas"
    }
  ]
}
```

---

## PRD Best Practices

### Story Sizing

**Right-sized** (1-3 files, completable in one iteration):
- "Add search input to existing page"
- "Create Skeleton component primitives"
- "Replace hardcoded colors with theme tokens"
- "Add hover effect utility classes"

**Too large** (split these):
- "Build complete dashboard" → split by section/feature
- "Refactor authentication" → split by concern
- "Add comprehensive analytics" → split by metric type

### Acceptance Criteria

**Good** (specific, testable):
```json
"acceptanceCriteria": [
  "Create useScrollReveal hook in src/hooks/useScrollReveal.ts",
  "Hook uses Intersection Observer with configurable threshold (default 0.2)",
  "Hook returns { ref, isVisible } and only triggers once per element",
  "npm run build passes",
  "npm run lint passes"
]
```

**Bad** (vague, subjective):
```json
"acceptanceCriteria": [
  "Animation works well",
  "UI looks nice",
  "Performance is good"
]
```

### Always Include Quality Checks

Every story should end with:
```json
"acceptanceCriteria": [
  "... feature criteria ...",
  "npm run build passes",
  "npm run lint passes"
]
```

For backend work, add:
```json
"ruff check . && ruff format . passes",
"pytest -q --tb=line passes (if touching tested code)"
```

### Notes Field

Use notes to provide helpful context:
```json
"notes": "Use CSS grid for layout. Apply hover-scale utility from SNOOT-201d."
```

Good notes include:
- File paths: `"File: src/components/search/ArtistCard.tsx"`
- Dependencies: `"Depends on animation tokens from SNOOT-201a"`
- Technical hints: `"Use Intersection Observer, not scroll events"`
- Constraints: `"Keep implementation CSS-only, no external libraries"`

---

## Optimal PRD Size

Based on observed performance:

| Stories | Iterations | Notes |
|---------|------------|-------|
| 3-4 | 3-4 | Good for testing Ralph |
| 5-8 | 5-8 | Sweet spot for feature work |
| 8-12 | 8-12 | Large features, may need monitoring |
| 12+ | Split | Consider multiple PRDs |

**Observation**: Ralph typically completes 1 story per iteration when stories are well-sized.

---

## Creating PRDs

### Option 1: Ask Claude (Recommended)

In conversation:
> "Create a PRD for [feature]. Break it into [N] user stories."

Claude generates the JSON, you copy to `ralph/prd.json`.

### Option 2: Copy and Modify

```bash
cp ralph/examples/simple-ui-fix.prd.json ralph/prd.json
# Edit to customize
```

### Option 3: Interactive Script

```bash
./ralph/create-prd-interactive.sh
```

### Validation

Always validate before running:
```bash
./ralph/validate-prd.sh
```

---

## Story Dependencies

If stories have dependencies, reflect them in priority order:

```json
{
  "userStories": [
    { "id": "SNOOT-201a", "title": "Add animation tokens", "priority": 1 },
    { "id": "SNOOT-201b", "title": "Add scroll reveal hook", "priority": 2, "notes": "Uses tokens from 201a" },
    { "id": "SNOOT-201c", "title": "Add stagger utilities", "priority": 3, "notes": "Uses tokens from 201a" }
  ]
}
```

Ralph works in priority order, so dependent work comes later.

---

## Reviewing Ralph's Work

### After Each Iteration

1. **Check PRD status**:
   ```bash
   cat ralph/prd.json | jq '.userStories[] | {id, title, passes}'
   ```

2. **Check commits**:
   ```bash
   git log --oneline -10
   ```

3. **Read progress log** (tail for recent):
   ```bash
   tail -100 ralph/progress.txt
   ```

### Verifying Completion

Before creating a new PRD, verify:

1. All stories have `"passes": true`
2. Commits match expected changes
3. Build/lint still pass:
   ```bash
   cd code/site && npm run build && npm run lint
   ```

### If Something Looks Wrong

1. Read the progress entry for that story
2. Check the commit diff: `git show <commit-hash>`
3. If needed, parse the conversation:
   ```bash
   ./ralph/parse-conversation.sh <session-id>
   ```

---

## Common Patterns for Snoot PRDs

### Frontend Component Work

```json
{
  "id": "SNOOT-XXXa",
  "title": "Create [Component] with [feature]",
  "acceptanceCriteria": [
    "Create src/components/[path]/[Component].tsx",
    "Component accepts [props] with TypeScript interface",
    "Uses theme tokens from globals.css",
    "Respects prefers-reduced-motion for animations",
    "npm run build passes",
    "npm run lint passes"
  ],
  "notes": "Reference existing [SimilarComponent] for patterns."
}
```

### CSS/Design System Work

```json
{
  "id": "SNOOT-XXXb",
  "title": "Add [utility/token] to globals.css",
  "acceptanceCriteria": [
    "Add [specific CSS] to src/app/globals.css",
    "Expose in @theme inline block for Tailwind access",
    "Works in both light and dark mode",
    "npm run build passes"
  ],
  "notes": "Follow existing token naming: --color-*, --duration-*, --ease-*"
}
```

### Refactoring/Polish Work

```json
{
  "id": "SNOOT-XXXc",
  "title": "Update [Component] to use [new system]",
  "acceptanceCriteria": [
    "Replace [old pattern] with [new pattern]",
    "Verify visual appearance unchanged (or improved as specified)",
    "No TypeScript errors introduced",
    "npm run build passes",
    "npm run lint passes"
  ],
  "notes": "This is a refactor - behavior should remain identical."
}
```

---

## PRD Lifecycle

```
1. CREATE PRD
   └── Define stories with clear acceptance criteria
   └── Set all passes: false
   └── Validate with validate-prd.sh

2. RUN RALPH
   └── ./ralph.sh [max-iterations]
   └── Ralph works through stories in priority order
   └── Each iteration: implement → test → commit → document

3. MONITOR
   └── Watch progress.txt for learnings
   └── Check git log for commits
   └── Verify quality checks pass

4. REVIEW
   └── All passes: true?
   └── Implementation matches expectations?
   └── Code quality acceptable?

5. NEW PRD
   └── Create next PRD for follow-on work
   └── Reference learnings from progress.txt
```

---

## Common Failures & Anti-Patterns

### Anti-Pattern: "Build the Whole Thing"

**Bad**: `"Add user authentication"`
**Good**: Split into focused stories:
1. "Add login form component"
2. "Add auth API endpoint"
3. "Add session management hook"
4. "Add protected route wrapper"

### Anti-Pattern: Vague Acceptance Criteria

**Bad**: `"Search works well"`, `"UI looks nice"`
**Good**: `"Search input filters results in real-time"`, `"Card uses hover-lift utility class"`

### Anti-Pattern: Missing File Paths

Without guidance, Ralph explores extensively, wasting context. Add paths:
```json
"notes": "File: src/components/search/ArtistCard.tsx. Reference FilterPanel.tsx for patterns."
```

### Anti-Pattern: No Quality Checks in Criteria

Every story needs automated verification. Without it, broken code accumulates:
```json
"acceptanceCriteria": [
  "... feature criteria ...",
  "npm run build passes",
  "npm run lint passes"
]
```

### Failure: Premature Exit

**Symptom**: Ralph marks story complete but work is partial
**Cause**: Criteria too vague, AI thinks "good enough"
**Fix**: More specific, testable criteria

### Failure: Context Exhaustion

**Symptom**: Story requires 20+ file reads, iteration ends abruptly
**Cause**: Story scope too broad OR missing context in notes
**Fix**: Split story or provide file paths upfront

### Failure: Repeated Mistakes

**Symptom**: Same error across multiple iterations
**Cause**: Learnings not captured in progress.txt
**Fix**: Ensure progress.txt "Mistakes made" section is populated; Ralph reads this

---

## Troubleshooting

### Ralph Keeps Failing on Same Story

**Likely cause**: Story too large or unclear criteria

**Fix**: Split into smaller stories with more specific criteria

### Quality Checks Failing

**Likely cause**: Pre-existing issues or introduced bugs

**Fix**:
1. Run checks manually to see errors
2. Fix manually or add hint to notes
3. Re-run Ralph

### Story Marked Complete But Wrong

**Fix**:
1. Set `passes: false` in prd.json
2. Add note explaining what's wrong
3. Re-run Ralph

### Ralph Running Out of Context

**Symptoms**: Partial implementation, iteration exits early

**Fix**:
- Story is too large - split it
- Too much exploration needed - add file paths to notes

---

## Example: Well-Structured PRD

From the design system work:

```json
{
  "project": "Snoot",
  "branchName": "ralph/motion-and-loading",
  "description": "Motion System + Loading States",
  "userStories": [
    {
      "id": "SNOOT-201b",
      "title": "Add scroll reveal hook and component",
      "description": "Implement scroll-triggered animations",
      "acceptanceCriteria": [
        "Create useScrollReveal hook in src/hooks/useScrollReveal.ts",
        "Hook uses Intersection Observer with configurable threshold (default 0.2)",
        "Hook returns { ref, isVisible } and only triggers once per element",
        "Create ScrollReveal wrapper component in src/components/common/ScrollReveal.tsx",
        "Component accepts children and applies animation when visible",
        "npm run build passes",
        "npm run lint passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Keep implementation simple - vanilla Intersection Observer, no external libraries."
    }
  ]
}
```

**Why this works**:
- Clear, specific title
- Concrete file paths in criteria
- Testable requirements (threshold value, return shape)
- Quality checks included
- Helpful constraint in notes

---

## Quick Commands

```bash
# Validate PRD
./ralph/validate-prd.sh

# Run Ralph (10 iterations max)
./ralph/ralph.sh 10

# Check story status
cat ralph/prd.json | jq '.userStories[] | {id, passes}'

# View recent progress
tail -100 ralph/progress.txt

# View recent commits
git log --oneline -10

# Parse specific iteration
./ralph/parse-conversation.sh <session-id>
```

---

## Summary: PRD Checklist

Before giving Ralph a PRD:

- [ ] Each story changes 1-3 files
- [ ] Acceptance criteria are specific and testable
- [ ] Quality checks (build, lint) included in each story
- [ ] Dependencies reflected in priority order
- [ ] Notes provide helpful context (file paths, patterns to use)
- [ ] Validated with `./ralph/validate-prd.sh`

After Ralph completes:

- [ ] All stories show `passes: true`
- [ ] Commits match expected work
- [ ] Build and lint still pass
- [ ] Implementation meets acceptance criteria

---

## Sources & Further Reading

### Primary Sources
- [Geoffrey Huntley - "Everything is a Ralph Loop"](https://ghuntley.com/loop/) - Original concept and philosophy
- [Ralph Playbook by Clayton Farr](https://github.com/ClaytonFarr/ralph-playbook) - Comprehensive implementation guide
- [Ralph for Claude Code](https://github.com/ardmhacha24/ralph-claude-code) - The implementation we use

### Design Patterns & Research
- [Agent Design Patterns (2026)](https://rlancemartin.github.io/2026/01/09/agent_design/) - Context management, sub-agents, caching
- [Task Decomposition for AI Agents](https://blog.continue.dev/task-decomposition/) - Research on task sizing
- [Why Simple Loops Beat Complex Orchestrators](https://www.chrismdp.com/your-agent-orchestrator-is-too-clever/) - The "bitter lesson" applied

### Context & Memory Research
- [METR - AI Task Completion Time Horizons](https://theaidigest.org/time-horizons) - Task length capabilities doubling every 7 months
- [AI Agents' Context Management](https://bytebridge.medium.com/ai-agents-context-management-breakthroughs-and-long-running-task-execution-d5cee32aeaa4) - Memory mechanisms for long-running tasks

### Key Insight
> *"The bitter lesson keeps teaching the same thing. Simpler methods plus more compute beat clever engineering. In 2026, the agents are good enough that a for loop is a legitimate orchestration strategy."*
> — [Chris Parsons](https://www.chrismdp.com/your-agent-orchestrator-is-too-clever/)
