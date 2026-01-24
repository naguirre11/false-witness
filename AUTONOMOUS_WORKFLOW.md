# Autonomous Agent Orchestration Workflow

A decision tree for running autonomous agent coordination. Follow this when `%autonomous` / `%a` is invoked.

The main Claude session acts as **Orchestrator**, spawning OMC subagents to execute atomic tasks while monitoring progress and handling errors.

---

## CRITICAL: Continuous Loop

**Autonomous mode is a CONTINUOUS LOOP across MULTIPLE TICKETS.**

```
┌─────────────────────────────────────────────────────────┐
│  DO NOT STOP after completing one ticket!               │
│  After each ticket → Check for next ready ticket        │
│  Only stop when: queue empty OR unrecoverable blocker   │
└─────────────────────────────────────────────────────────┘
```

**Stop conditions (the ONLY reasons to stop):**
- No more tickets in `tickets/ready/`
- Unrecoverable blocker (3+ failed attempts, needs human input)
- User explicitly requests stop

**NOT a stop condition:**
- Completing a ticket (immediately pick up the next one)
- Optional/deferred acceptance criteria (move on)

---

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAIN SESSION (Orchestrator)                  │
│  - Reads tickets, creates fine-grained tasks                    │
│  - Spawns agents, monitors progress                             │
│  - Catches errors, adjusts course                               │
│  - LOOPS through ALL tickets until queue empty or blocker       │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
   ┌─────────────────────────────────────────────────────────────┐
   │  FOR EACH TICKET in ready queue:                            │
   │    1. Move to dev_in_progress                               │
   │    2. Break into tasks                                      │
   │    3. Execute tasks with agents                             │
   │    4. Verify, commit, move to for_review                    │
   │    5. LOOP BACK for next ticket                             │
   └─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   ┌───────────┐        ┌───────────┐        ┌───────────┐
   │ executor  │        │ executor  │        │ executor  │
   │  (task 1) │        │  (task 2) │        │  (task 3) │
   └───────────┘        └───────────┘        └───────────┘
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Shared Task    │
                    │  List + AC      │
                    │  Metadata       │
                    └─────────────────┘
```

---

## Core Principle: Fine-Grained Tasks

**Tasks are the single source of truth** for autonomous execution. Each task should be:

1. **Atomic** - 15-60 minutes of focused work
2. **Self-contained** - All acceptance criteria embedded in the task
3. **Verifiable** - Each AC can be independently checked
4. **Traceable** - Metadata links back to source ticket

The granularity comes from breaking tickets into **story-level tasks**, each with explicit acceptance criteria tracked in task metadata.

---

## Phase 1: Initialization

### Step 0: Read learnings from previous runs
Read `cc_workflow/autonomous/learnings.md`:
1. **Patterns section** - Apply these during task planning and agent selection
2. **Recent run entries** - Note any relevant mistakes to avoid

This takes 30 seconds but prevents repeating past failures.

### Step 1: Check current state
Run `TaskList` to see existing tasks.

**IF** there are pending/in_progress tasks:
  → These are from a previous session
  → Skip to Phase 3 (Orchestration Loop)

**IF** no tasks exist:
  → Continue to Step 2

### Step 2: Identify the ticket
Check for:
1. Active ticket in `tickets/dev_in_progress/`
2. If none, pick NEXT ticket from `tickets/STATUS.md`

**IF** no ticket available:
  → Report: "No ticket to work on. Use %newtickets or select manually."
  → STOP

### Step 3: Move ticket to dev_in_progress
```powershell
cc_workflow/scripts/ticket-move.ps1 FW-XXX dev_in_progress
```

### Step 4: Read and analyze ticket
Read the full ticket file. Extract:
- All acceptance criteria (these become task-level ACs)
- Technical notes (context for agents)
- Dependencies (blockers to check)
- Out of scope (to prevent over-engineering)

---

## Phase 2: Task Planning (Critical for Granularity)

This phase transforms a ticket into fine-grained, verifiable tasks. **This is where granularity is achieved.**

### Step 5: Decompose ticket into story-level tasks

**Goal**: Create tasks that match the granularity of PRD user stories - each task is a coherent unit of work with 3-7 specific acceptance criteria.

#### Task Decomposition Strategy

1. **Group related acceptance criteria** - 3-7 ACs per task
2. **Each task = one logical change** - A single commit's worth of work
3. **Include verification criteria** - Tests, lint, build checks
4. **Preserve context** - Technical notes in description

#### Task Structure Template

```
TaskCreate:
  subject: "[FW-XXX-NN] <imperative action phrase>"
  description: |
    <2-3 sentence description of what this task accomplishes>

    ## Acceptance Criteria
    - [ ] AC1: <specific, testable criterion>
    - [ ] AC2: <specific, testable criterion>
    - [ ] AC3: <specific, testable criterion>
    - [ ] AC4: <specific, testable criterion>
    - [ ] AC5: <specific, testable criterion>

    ## Technical Context
    <relevant files, patterns, constraints>

    ## Verification
    - [ ] Smoke tests pass
    - [ ] gdlint passes
  activeForm: "<present participle phrase>"
  metadata: {
    "ticketId": "FW-XXX",
    "storyNumber": 1,
    "priority": 1,
    "ac": {
      "ac1_short_key": false,
      "ac2_short_key": false,
      "ac3_short_key": false,
      "ac4_short_key": false,
      "ac5_short_key": false,
      "smoke_tests": false,
      "gdlint": false
    }
  }
```

### Step 6: Example - Full Ticket Decomposition

**Ticket**: FW-061 - Win/loss conditions

**Original Acceptance Criteria**:
- [ ] WinCondition enum defines all victory/defeat states
- [ ] MatchManager tracks win condition checks each phase
- [ ] Investigators win if entity correctly identified before time expires
- [ ] Investigators win if all cultists discovered
- [ ] Cultists win if timer expires without correct identification
- [ ] Cultists win if majority vote fails 3 times
- [ ] Win condition triggers phase transition to Results
- [ ] All players notified of outcome simultaneously
- [ ] Unit tests cover all win/loss scenarios
- [ ] Integration test validates full win flow

**Decomposed into 4 Fine-Grained Tasks**:

---

**Task 1: Define win condition enums and data structures**
```
TaskCreate:
  subject: "[FW-061-01] Define win condition enums and data structures"
  description: |
    Create the foundational enums and data structures for tracking
    win/loss conditions in False Witness.

    ## Acceptance Criteria
    - [ ] WinCondition enum in match_result.gd with all states
    - [ ] States: INVESTIGATORS_CORRECT_ID, INVESTIGATORS_ALL_CULTISTS,
          CULTISTS_TIMEOUT, CULTISTS_VOTE_FAIL, NONE
    - [ ] MatchResult resource class to hold outcome data
    - [ ] MatchResult includes: condition, winning_team, timestamp
    - [ ] Follows existing enum patterns (see EvidenceEnums)

    ## Technical Context
    - File: src/core/match_result.gd
    - Pattern: Use class_name, extend Resource
    - Reference: src/evidence/evidence_enums.gd for style

    ## Verification
    - [ ] gdlint src/core/match_result.gd passes
    - [ ] File imports without errors
  activeForm: "Defining win condition enums"
  metadata: {
    "ticketId": "FW-061",
    "storyNumber": 1,
    "priority": 1,
    "ac": {
      "enum_exists": false,
      "all_states_defined": false,
      "result_class": false,
      "result_fields": false,
      "follows_patterns": false,
      "gdlint": false,
      "imports_clean": false
    }
  }
```

---

**Task 2: Implement investigator win detection**
```
TaskCreate:
  subject: "[FW-061-02] Implement investigator win detection"
  description: |
    Add logic to MatchManager to detect when investigators have won.

    ## Acceptance Criteria
    - [ ] check_investigator_victory() method in MatchManager
    - [ ] Returns true if entity correctly identified before timer
    - [ ] Returns true if all cultists have been discovered
    - [ ] Method called at end of each deliberation phase
    - [ ] Emits match_ended signal with MatchResult on victory
    - [ ] Does not trigger if game already ended

    ## Technical Context
    - File: src/core/managers/match_manager.gd
    - Uses: CultistManager.get_discovered_cultists()
    - Uses: EntityManager.is_entity_identified()
    - Signal: match_ended(result: MatchResult)

    ## Verification
    - [ ] Smoke tests pass
    - [ ] gdlint passes
  activeForm: "Implementing investigator win detection"
  metadata: {
    "ticketId": "FW-061",
    "storyNumber": 2,
    "priority": 2,
    "ac": {
      "method_exists": false,
      "correct_id_check": false,
      "all_cultists_check": false,
      "called_each_phase": false,
      "emits_signal": false,
      "no_double_trigger": false,
      "smoke_tests": false,
      "gdlint": false
    }
  }
```

---

**Task 3: Implement cultist win detection**
```
TaskCreate:
  subject: "[FW-061-03] Implement cultist win detection"
  description: |
    Add logic to MatchManager to detect when cultists have won.

    ## Acceptance Criteria
    - [ ] check_cultist_victory() method in MatchManager
    - [ ] Returns true if timer expires without correct identification
    - [ ] Returns true if majority vote has failed 3 times
    - [ ] Tracks vote failure count in MatchManager state
    - [ ] Method called at timer expiry and after each vote
    - [ ] Emits match_ended signal with MatchResult on victory

    ## Technical Context
    - File: src/core/managers/match_manager.gd
    - State: _vote_failure_count: int
    - Timer: GameManager.phase_timer_expired signal

    ## Verification
    - [ ] Smoke tests pass
    - [ ] gdlint passes
  activeForm: "Implementing cultist win detection"
  metadata: {
    "ticketId": "FW-061",
    "storyNumber": 3,
    "priority": 3,
    "ac": {
      "method_exists": false,
      "timeout_check": false,
      "vote_fail_check": false,
      "tracks_vote_count": false,
      "called_correctly": false,
      "emits_signal": false,
      "smoke_tests": false,
      "gdlint": false
    }
  }
```

---

**Task 4: Write unit and integration tests for win conditions**
```
TaskCreate:
  subject: "[FW-061-04] Write unit and integration tests for win conditions"
  description: |
    Comprehensive test coverage for all win/loss scenarios.

    ## Acceptance Criteria
    - [ ] test_match_manager.gd with win condition tests
    - [ ] Test: investigator wins on correct entity ID
    - [ ] Test: investigator wins when all cultists found
    - [ ] Test: cultist wins on timeout
    - [ ] Test: cultist wins after 3 vote failures
    - [ ] Test: no double-trigger of win conditions
    - [ ] Test: all players receive match_ended signal
    - [ ] Integration test: full game flow to win screen

    ## Technical Context
    - Unit tests: tests/unit/test_match_manager.gd
    - Integration: tests/integration/test_win_flow.gd
    - Use GUT framework patterns from existing tests

    ## Verification
    - [ ] All new tests pass
    - [ ] Full test suite passes
    - [ ] gdlint passes
  activeForm: "Writing win condition tests"
  metadata: {
    "ticketId": "FW-061",
    "storyNumber": 4,
    "priority": 4,
    "ac": {
      "test_file_exists": false,
      "test_correct_id": false,
      "test_all_cultists": false,
      "test_timeout": false,
      "test_vote_fail": false,
      "test_no_double": false,
      "test_signal_all": false,
      "integration_test": false,
      "all_tests_pass": false,
      "gdlint": false
    }
  }
```

### Step 7: Set task dependencies

```
TaskUpdate: taskId="2" addBlockedBy=["1"]
TaskUpdate: taskId="3" addBlockedBy=["1"]
TaskUpdate: taskId="4" addBlockedBy=["2", "3"]
```

### Step 8: Announce the plan

Output the task breakdown to the user:

```
## Task Plan for FW-061 - Win/loss conditions

| # | Task | ACs | Blocked By |
|---|------|-----|------------|
| 1 | Define win condition enums | 7 | - |
| 2 | Implement investigator win | 8 | 1 |
| 3 | Implement cultist win | 8 | 1 |
| 4 | Write tests | 10 | 2, 3 |

**Total**: 4 tasks, 33 acceptance criteria

Beginning autonomous execution...
```

---

## Phase 3: Orchestration Loop

This is the main loop. Repeat until all tasks complete or a blocker is hit.

### Step 9: Get next available task
Run `TaskList` and find a task that is:
- Status: `pending`
- `blockedBy` is empty (no unfinished dependencies)

**IF** no available tasks but incomplete tasks exist:
  → All remaining tasks are blocked
  → Check if blocker tasks failed
  → Report blocker and STOP

**IF** all tasks are `completed`:
  → Go to Phase 4 (Completion)

### Step 10: Spawn executor agent

Spawn an OMC executor with **explicit AC verification instructions**:

```
Task:
  subagent_type: "oh-my-claudecode:executor"
  model: "sonnet"
  prompt: |
    ## Your Task
    Work on task #X from the shared task list.

    ## Workflow
    1. Run `TaskGet` to read full task details and acceptance criteria
    2. Run `TaskUpdate` to mark status: in_progress
    3. Implement the work described
    4. **Verify EACH acceptance criterion** - check them one by one
    5. Update AC metadata as you verify:
       `TaskUpdate: taskId="X" metadata={"ac": {"ac1_key": true, ...}}`
    6. Run final verification (tests, lint)
    7. Mark task completed: `TaskUpdate: taskId="X" status="completed"`
    8. Report what you did and which ACs passed

    ## AC Verification Rules
    - Do NOT mark an AC as true until you have EVIDENCE it passes
    - For code changes: file exists with correct content
    - For tests: test actually runs and passes
    - For lint: gdlint command exits 0
    - If an AC fails, note WHY and leave it false

    ## Context
    Ticket: FW-XXX - [title]
    Working directory: C:\Users\vinco\Projects\false_witness

    ## Constraints
    - Stay focused on this ONE task
    - Do NOT modify unrelated code
    - If blocked, report why and stop
```

**Agent selection guide**:
| Task Type | Agent | Model |
|-----------|-------|-------|
| Simple edit, single file | executor-low | haiku |
| Standard implementation | executor | sonnet |
| Complex logic, multi-file | executor-high | opus |
| Build/type errors | build-fixer | sonnet |
| Test writing | tdd-guide | sonnet |

### Step 11: Monitor agent result

When agent returns, check:

**SUCCESS indicators**:
- Agent reports task completed
- AC metadata shows all criteria true
- No errors mentioned

**PARTIAL SUCCESS indicators**:
- Some ACs marked true, others false
- Agent explains what's left

**FAILURE indicators**:
- Agent reports being blocked
- Errors in output (test failures, type errors)
- Work doesn't match task description

### Step 12: Handle agent result

**IF SUCCESS (all ACs true)**:
  1. Verify task is marked completed in TaskList
  2. Quick sanity check (file exists, no obvious errors)
  3. Continue to Step 9 (next task)

**IF PARTIAL SUCCESS**:
  1. Check which ACs are false
  2. Create follow-up task for remaining ACs OR
  3. Respawn agent with focus on failing ACs
  4. Track as partial completion

**IF FAILURE - Recoverable**:
  1. Analyze the error
  2. If simple fix: spawn build-fixer or retry with more context
  3. If agent went off-track: reset task to pending, respawn with clearer prompt
  4. Track retry count (max 3 retries per task)

**IF FAILURE - Blocker**:
  1. Mark task as pending with blocker note
  2. Document the blocker in `handoffs/blockers/`
  3. Check if other tasks can proceed
  4. If no tasks can proceed: STOP and report

### Step 13: Progress checkpoint

After every 3 tasks completed:
1. Run smoke tests: `./cc_workflow/scripts/run-tests.ps1 -Mode smoke`
2. If tests fail: spawn build-fixer to resolve
3. Commit progress: stage changed files, create checkpoint commit

---

## Phase 4: Completion

### Step 14: Final verification

When all tasks are completed:

1. **Verify all AC metadata**:
   Run `TaskList` and for each task, confirm all `ac` values are true.

2. **Run full test suite**:
   ```powershell
   ./cc_workflow/scripts/run-tests.ps1 -Mode full
   ```

3. **Check for lint errors**:
   ```bash
   gdlint src/ tests/
   ```

4. **Review changes**:
   ```bash
   git diff HEAD~N  # where N = number of task commits
   ```

### Step 15: Handle verification results

**IF all checks pass**:
  → Continue to Step 16

**IF tests/lint fail**:
  1. Create fix task: `TaskCreate "[FW-XXX] Fix test/lint failures"`
  2. Spawn build-fixer agent
  3. Re-run verification
  4. Max 3 fix cycles before escalating to blocker

**IF some ACs still false**:
  1. Identify which tasks have incomplete ACs
  2. Create targeted fix tasks
  3. Re-enter orchestration loop

### Step 16: Finalize ticket

1. Move ticket to for_review:
   ```powershell
   cc_workflow/scripts/ticket-move.ps1 FW-XXX for_review
   ```

2. Update ticket with implementation notes (including AC completion summary)

3. Create final commit with all changes

4. Output ticket completion summary (NOT a stopping point):
   ```
   ## Ticket Complete: FW-XXX - [title]

   **Tasks completed**: 4/4
   **Acceptance criteria**: 33/33 verified
   **Test status**: All passing

   Ticket moved to for_review. Checking for next ticket...
   ```

### Step 17: Capture learnings

Append an entry to `cc_workflow/autonomous/learnings.md`:

```markdown
---

## YYYY-MM-DD HH:MM - FW-XXX - [ticket title]

**Tasks**: X completed, Y failed
**Acceptance Criteria**: N verified, M failed
**Agents spawned**: N

### What Worked
- [approaches that succeeded]
- [task breakdown patterns that helped]

### Mistakes/Failures
- [what failed and why]
- [ACs that were hard to verify]

### Patterns Discovered
- [new reusable patterns]

### Agent Notes
- [which agents performed well/poorly for which task types]
```

### Step 18: Loop to next ticket (MANDATORY)

**DO NOT STOP HERE.** Immediately continue to the next ticket:

1. Check `tickets/ready/` for available tickets
2. **IF tickets exist**:
   - Pick the next prioritized ticket (check STATUS.md for NEXT, or use PRIORITIZATION_ROADMAP.md)
   - **Go back to Phase 1, Step 3** (move ticket to dev_in_progress)
   - Continue the loop
3. **IF no tickets remain**:
   - Output: "Autonomous run complete - no more tickets in ready queue"
   - **This is the ONLY normal stopping point**

```
┌────────────────────────────────────────────────────────┐
│  LOOP: Step 18 → Step 3 → ... → Step 17 → Step 18     │
│  Until: ready/ is empty OR unrecoverable blocker      │
└────────────────────────────────────────────────────────┘
```

---

## Phase 5: Error Recovery

### Retry Logic

Each task gets max 3 attempts:
- Attempt 1: Standard execution
- Attempt 2: More context, focus on failing ACs
- Attempt 3: Different agent tier (escalate to opus)

After 3 failures: mark as blocker, move on if possible.

### AC-Level Recovery

If specific ACs fail repeatedly:
1. Check if AC is actually testable (may need rewording)
2. Check if AC has hidden dependencies
3. Consider splitting task at AC boundary

### Common Recovery Patterns

| Error Type | Recovery Action |
|------------|-----------------|
| Test failure | Spawn build-fixer with test output |
| Type error | Spawn build-fixer-low |
| File not found | Check path, update task description |
| Scope creep | Reset task, add explicit boundaries |
| AC ambiguous | Clarify AC wording, respawn agent |
| Circular dependency | Re-plan task order |

### Blocker Documentation

When a blocker is hit, create `handoffs/blockers/FW-XXX-blocker.md`:
```markdown
# Blocker: FW-XXX

## Task
#N - [task subject]

## Failed Acceptance Criteria
- [ ] AC that couldn't be verified
- [ ] Another failing AC

## Error
[Exact error message or issue]

## Attempts
1. [what was tried]
2. [what was tried]
3. [what was tried]

## Possible Solutions
- [idea 1]
- [idea 2]

## Human Input Needed
[Specific question or decision needed]
```

---

## Task Granularity Guidelines

### How Many Tasks Per Ticket?

| Ticket Size | Expected Tasks | ACs per Task |
|-------------|----------------|--------------|
| Small (1-2 AC) | 1-2 tasks | 3-5 |
| Medium (3-5 AC) | 2-4 tasks | 4-6 |
| Large (6-10 AC) | 4-8 tasks | 5-7 |
| Epic (10+ AC) | 8-15 tasks | 5-8 |

### What Makes a Good Task?

**DO**:
- One logical unit of change (could be one commit)
- Clear, testable acceptance criteria
- Include verification steps (tests, lint)
- Provide technical context (files, patterns)
- Use consistent naming: `[FW-XXX-NN] <action>`

**DON'T**:
- Mix unrelated changes in one task
- Leave ACs vague ("works correctly")
- Skip verification criteria
- Create tasks with 10+ ACs (split them)
- Forget metadata for tracking

### AC Writing Guidelines

**Good ACs are SMART**:
- **Specific**: "WinCondition enum has 5 values" not "enum is complete"
- **Measurable**: "gdlint exits 0" not "code is clean"
- **Achievable**: Within scope of this task
- **Relevant**: Directly addresses ticket requirement
- **Testable**: Can verify with command or inspection

**Examples**:
```
❌ "Win detection works"
✓ "check_investigator_victory() returns true when EntityManager.is_entity_identified() is true"

❌ "Tests pass"
✓ "test_investigator_correct_id() in test_match_manager.gd passes"

❌ "Code follows patterns"
✓ "MatchResult extends Resource and uses class_name declaration"
```

### Metadata Schema

Every task should have this metadata structure:

```json
{
  "ticketId": "FW-XXX",       // Source ticket
  "storyNumber": 1,           // Order within ticket
  "priority": 1,              // Execution priority (lower = first)
  "ac": {                     // Acceptance criteria states
    "ac_short_key": false,    // Use snake_case keys
    "another_ac": false,      // All start false
    "verification_step": false
  }
}
```

---

## Quick Reference

### Orchestrator Commands

| Action | Tool/Command |
|--------|--------------|
| See all tasks | `TaskList` |
| Create task | `TaskCreate` |
| Get task details | `TaskGet` |
| Update task/AC metadata | `TaskUpdate` |
| Spawn executor | `Task` with `subagent_type: "oh-my-claudecode:executor"` |
| Run tests | `./cc_workflow/scripts/run-tests.ps1` |
| Move ticket | `cc_workflow/scripts/ticket-move.ps1` |

### Status Codes

| Status | Meaning |
|--------|---------|
| `pending` | Ready to work on (if not blocked) |
| `in_progress` | Agent currently working |
| `completed` | All ACs verified true |

### Agent Types for Tasks

| Agent | Use For |
|-------|---------|
| `oh-my-claudecode:executor-low` | Simple, single-file tasks |
| `oh-my-claudecode:executor` | Standard implementation |
| `oh-my-claudecode:executor-high` | Complex, multi-file tasks |
| `oh-my-claudecode:build-fixer` | Fix test/build failures |
| `oh-my-claudecode:tdd-guide` | Write tests |

---

## Anti-Patterns

1. **Vague tasks** - Every task needs specific, testable ACs
2. **Giant tasks** - If >8 ACs, split into multiple tasks
3. **Missing metadata** - Always include ticketId and ac tracking
4. **Skipping AC verification** - Agents must check each AC individually
5. **Spawning without tasks** - Always create task first
6. **Too many parallel agents** - Max 2-3 at a time
7. **Ignoring partial success** - Track which ACs passed/failed
8. **No checkpoints** - Commit progress every 3 tasks
9. **Unbounded retries** - Max 3 attempts, then blocker

---

## Example Run

```
> %autonomous

## Initializing Autonomous Orchestration

TaskList: No existing tasks

Ticket: FW-061 - Win/loss conditions
Moving to dev_in_progress...

## Task Plan for FW-061 - Win/loss conditions

| # | Task | ACs | Blocked By |
|---|------|-----|------------|
| 1 | Define win condition enums | 7 | - |
| 2 | Implement investigator win | 8 | 1 |
| 3 | Implement cultist win | 8 | 1 |
| 4 | Write tests | 10 | 2, 3 |

**Total**: 4 tasks, 33 acceptance criteria

Beginning autonomous execution...

---

### Task #1: Define win condition enums
Spawning executor-low (haiku)...

Agent Report:
- ✓ ac.enum_exists: Created WinCondition enum
- ✓ ac.all_states_defined: 5 states defined
- ✓ ac.result_class: MatchResult resource created
- ✓ ac.result_fields: condition, winning_team, timestamp
- ✓ ac.follows_patterns: Matches EvidenceEnums style
- ✓ ac.gdlint: Passes
- ✓ ac.imports_clean: No import errors

Task #1 COMPLETE (7/7 ACs verified)

---

### Task #2: Implement investigator win
Spawning executor (sonnet)...

Agent Report:
- ✓ ac.method_exists: check_investigator_victory() added
- ✓ ac.correct_id_check: Uses EntityManager.is_entity_identified()
- ✓ ac.all_cultists_check: Uses CultistManager.get_discovered_cultists()
- ✓ ac.called_each_phase: Connected to phase_ended signal
- ✓ ac.emits_signal: match_ended(result) emitted
- ✓ ac.no_double_trigger: Guard with _match_ended flag
- ✓ ac.smoke_tests: All pass
- ✓ ac.gdlint: Passes

Task #2 COMPLETE (8/8 ACs verified)

---

### Task #3: Implement cultist win
Spawning executor (sonnet)...

Agent Report:
- ✓ ac.method_exists: check_cultist_victory() added
- ✓ ac.timeout_check: Connected to phase_timer_expired
- ✓ ac.vote_fail_check: Checks _vote_failure_count >= 3
- ✓ ac.tracks_vote_count: _vote_failure_count incremented on fail
- ✓ ac.called_correctly: Called on timer and vote events
- ✓ ac.emits_signal: match_ended(result) emitted
- ✓ ac.smoke_tests: All pass
- ✓ ac.gdlint: Passes

Task #3 COMPLETE (8/8 ACs verified)

---

### Checkpoint: Running smoke tests
✓ All smoke tests passing
✓ Committed: feat: [FW-061] implement win condition detection

---

### Task #4: Write tests
Spawning tdd-guide (sonnet)...

Agent Report:
- ✓ ac.test_file_exists: tests/unit/test_match_manager.gd created
- ✓ ac.test_correct_id: test_investigator_wins_on_correct_id()
- ✓ ac.test_all_cultists: test_investigator_wins_all_cultists_found()
- ✓ ac.test_timeout: test_cultist_wins_on_timeout()
- ✓ ac.test_vote_fail: test_cultist_wins_after_three_vote_failures()
- ✓ ac.test_no_double: test_win_condition_only_triggers_once()
- ✓ ac.test_signal_all: test_all_players_receive_match_ended()
- ✓ ac.integration_test: test_full_win_flow.gd created
- ✓ ac.all_tests_pass: 8/8 tests pass
- ✓ ac.gdlint: Passes

Task #4 COMPLETE (10/10 ACs verified)

---

## Final Verification
Running full test suite...
✓ 135/135 tests passing

Running gdlint...
✓ No lint errors

## Autonomous Run Complete

**Ticket**: FW-061 - Win/loss conditions
**Tasks completed**: 4/4
**Acceptance criteria**: 33/33 verified
**Commits**: 2
**Test status**: All passing

Ticket moved to for_review.
```
