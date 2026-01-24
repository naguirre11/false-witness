# Persistent Task Workflow

A decision tree for using the persistent task system. Follow this when `%tasks` / `%tk` is invoked.

Tasks persist across sessions in `~/.claude/tasks/false-witness/` and are shared between sessions and subagents.

---

## When to Use Tasks vs Tickets

| Tasks | Tickets |
|-------|---------|
| Implementation steps within a ticket | Feature-level planning |
| Multi-session work tracking | Human review workflow |
| Subagent coordination | Cross-branch work items |
| Breaking down complex work | Documented requirements |

**Typical flow**: Ticket defines WHAT to build. Tasks define HOW to build it.

---

## Phase 1: Task Discovery

### Step 1: Check existing tasks
Run `TaskList` to see all persistent tasks.

IF there are **pending tasks with your ticket ID**:
  → These are leftover from a previous session
  → Review them - they represent work already planned
  → Continue to Phase 3 (Resume Work)

IF there are **in_progress tasks**:
  → A previous session was mid-work
  → Read the task details with `TaskGet`
  → Decide: resume or reset to pending

IF there are **no relevant tasks**:
  → Continue to Phase 2

### Step 2: Clean up stale tasks
IF tasks exist for completed/abandoned work:
  → Mark them completed with `TaskUpdate`
  → Keeps the task list clean

---

## Phase 2: Task Planning

### Step 3: Identify current ticket
From `cc_workflow/session_start.md` or `tickets/STATUS.md`, identify:
- Active ticket in `dev_in_progress/`, OR
- NEXT ticket to pick up

IF no ticket to work on:
  → Don't create tasks yet
  → Follow `%flowchart` to select a ticket first

### Step 4: Read ticket requirements
Read the full ticket file and understand:
- All acceptance criteria
- Technical notes
- Dependencies
- Out of scope items

### Step 5: Break into tasks
Create tasks for each logical unit of work:

```
TaskCreate:
  subject: "Implement X for FW-061"
  description: "Detailed description of what this task accomplishes..."
  activeForm: "Implementing X"
```

**Task naming convention**: Include ticket ID in subject for filtering.

**Good task breakdown**:
- Each task = 1-2 hours of focused work
- Tasks should be independently testable when possible
- Include setup/teardown tasks if needed

**Example for FW-061 (Win Conditions)**:
1. "Create WinCondition enum and data structures for FW-061"
2. "Implement investigator win logic for FW-061"
3. "Implement cultist win logic for FW-061"
4. "Add win condition signals to GameManager for FW-061"
5. "Write unit tests for win conditions FW-061"
6. "Integration test win/loss flow FW-061"

### Step 6: Set up dependencies
IF tasks have dependencies on each other:

```
TaskUpdate:
  taskId: "2"
  addBlockedBy: ["1"]
```

This prevents starting task 2 until task 1 is complete.

---

## Phase 3: Working with Tasks

### Step 7: Claim a task
Before starting work on a task:

```
TaskUpdate:
  taskId: "1"
  status: "in_progress"
```

This signals to other sessions/agents that you're working on it.

### Step 8: Do the work
Implement the task. As you work:
- Reference the task subject in commit messages if helpful
- If task scope changes, update the description

### Step 9: Complete the task
When task work is done:

```
TaskUpdate:
  taskId: "1"
  status: "completed"
```

### Step 10: Check for unblocked tasks
After completing a task, run `TaskList` to see:
- What tasks are now unblocked
- Overall progress on the ticket

IF all tasks for a ticket are complete:
  → Ticket is ready for final verification
  → Follow Phase 5 of `%flowchart` (Completion)

---

## Phase 4: Multi-Session Handoff

### Step 11: Session ending with tasks remaining
IF you need to stop but tasks remain:

1. Update any in_progress tasks back to pending (or leave as in_progress with notes)
2. In your handoff document, reference the task list:
   ```
   ## Task Progress
   See `TaskList` for current state. Key items:
   - Task #3 (Cultist win logic) is next
   - Task #5 blocked on #3 and #4
   ```

### Step 12: Resuming in new session
The next session will:
1. Run `%tasks` or `TaskList`
2. See exactly where you left off
3. Pick up the next pending task

---

## Phase 5: Subagent Collaboration

### Step 13: Parallel work with subagents
When spawning subagents via the `Task` tool:

1. Create tasks for each piece of parallel work
2. Include task IDs in the subagent prompt:
   ```
   "Work on task #3 (Cultist win logic). Mark it in_progress when you start,
   completed when done. Check TaskList for dependencies."
   ```

3. Subagents share the same task list automatically
4. Monitor progress via `TaskList` from the main session

### Step 14: Coordinating results
After subagents complete:
1. Run `TaskList` to see what's done
2. Review subagent output
3. Update any remaining tasks as needed

---

## Quick Reference: Task Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `TaskList` | See all tasks | Start of session, after completing work |
| `TaskCreate` | Add new task | Breaking down ticket into work items |
| `TaskGet` | Get task details | Before starting work on a task |
| `TaskUpdate` | Change task state | Start work, complete work, add dependencies |

---

## Task Status Flow

```
pending → in_progress → completed
   ↑           |
   └───────────┘ (if paused/abandoned)
```

---

## Anti-Patterns to Avoid

1. **Creating tasks without a ticket** - Tasks implement tickets, not replace them
2. **Overly granular tasks** - "Add import statement" is too small
3. **Overly large tasks** - "Implement entire win system" defeats the purpose
4. **Forgetting to mark in_progress** - Other agents might duplicate your work
5. **Leaving tasks in_progress across sessions** - Reset to pending or complete
6. **Not including ticket ID** - Makes filtering and cleanup harder
7. **Ignoring blocked tasks** - Check `blockedBy` before starting

---

## Completion Signals (For Orchestrator Integration)

When running under the autonomous orchestrator (`%orchestrate`), emit these signals to communicate task status:

### Task Completed
```
<task_complete>TASK_ID</task_complete>
```
Example: `<task_complete>3</task_complete>`

Emit this AFTER:
1. Work is done
2. Tests pass
3. Changes are committed
4. TaskUpdate marks task as completed

### Task Blocked
```
<task_blocked>TASK_ID: reason</task_blocked>
```
Example: `<task_blocked>3: Tests failing with assertion error in test_win_conditions.gd:45</task_blocked>`

Emit this when:
- You cannot proceed without human input
- Errors persist after multiple fix attempts
- Missing dependencies or unclear requirements

### All Tasks Complete
```
<tasks>ALL_COMPLETE</tasks>
```

Emit when all tasks for a ticket are completed and verified.

---

## Example Session

```
# Start of session
> TaskList
#1 [completed] Create WinCondition enum for FW-061
#2 [pending] Implement investigator win logic for FW-061
#3 [pending] Implement cultist win logic for FW-061 (blockedBy: #2)

# Pick up task #2
> TaskUpdate taskId="2" status="in_progress"

# ... do the work ...

# Complete task #2
> TaskUpdate taskId="2" status="completed"
<task_complete>2</task_complete>

# Task #3 is now unblocked
> TaskList
#1 [completed] Create WinCondition enum for FW-061
#2 [completed] Implement investigator win logic for FW-061
#3 [pending] Implement cultist win logic for FW-061

# Continue with #3...
```
