# COMMANDS

These are custom commands to be used whenever a particular function starting with % is passed in the Claude CLI text box.

## %init / %i (-b)

   When this command is used, you should read:
   - All required core documents
   - The latest handoff doc from the previous Dev session

   If the option -b is used:
      Wait for further instructions - this is bug fix mode and the user should supply some particular work for you
   Otherwise:
      Pick up the next ticket in /ready.

## %handoff / %h

   When this command is used, create a comprehensive handoff document for the next Dev including:
   - Current task state
   - Pending decisions that need resolution
   - Context about architectural choices made
   - Next steps in priority order

   The handoff document should be sufficiently detailed to allow the next Claude instance to pick up where you left off.

## %git / %g (-f)

   Commits should be added and pushed to the remote git repo.

   If the option -f is used:
      Force the push using the --no-verify option where needed
   Otherwise:
      Remind the user of your git restrictions, and request further instructions.

## %tickets / %t

   Wrapper for doing a combination of %i, then %h, then %e, then %g -f.

   The most common workflow. Pick up the latest ready ticket, work on it, test it. Make a handoff. If ticket work is deemed ready for review, update the project repo, commit changes to git. 

## %newtickets / %n

   Evaluate the state of the project, including any progress reports, tickets, etc. Determine gaps in progressing to the next stage of the project. Then write out new tickets. Update prioritization.

## %eval / %e

   Update PROJECT_STRUCTURE.md with changes made during this session. PROJECT_STRUCTURE.md is meant to provide at-a-glance information about the files in the repo.

## %describe / %d

   Analyze the current state of the project and update PROJECT_STATE.md. In order to do this, you should look at previous docs to understand the high-level goals. You should look through all the tickets that have been completed or are in review. Analyze what's still missing to get to the next milestone (MVP, playtest, etc.).

## %flowchart / %f

   Read and follow the decision tree in `./FLOWCHART.md` (project root). This guides you through:
   1. Checking the latest handoff for emergencies or non-ticketed work
   2. Selecting the correct ticket (active in dev_in_progress, or NEXT from STATUS.md)
   3. Verifying dependencies and blockers before starting
   4. Implementation, testing, completion, and handoff procedures

   Use this command at the start of a session to ensure systematic, foolproof workflow. 

## %tasks / %tk

   Read and follow the decision tree in `./TASKS_WORKFLOW.md`. This guides you through:
   1. Checking for existing persistent tasks from previous sessions
   2. Breaking tickets into trackable tasks
   3. Working through tasks systematically
   4. Coordinating with subagents via the shared task list

   Use this command when:
   - Starting a session and want to see outstanding work
   - Breaking a ticket into implementation steps
   - Coordinating parallel work across subagents
   - Resuming multi-session work

   Key tools: `TaskList`, `TaskCreate`, `TaskGet`, `TaskUpdate`

## %orchestrate / %o [options]

   Run the autonomous task orchestrator to complete work with minimal human intervention.
   Uses a two-Claude architecture: an Orchestrator Claude directs an Agent Claude through tasks.

   **Options:**
   - `--ticket FW-XXX` or `-t FW-XXX`: Work on a specific ticket
   - `--max-iterations N` or `-n N`: Limit iterations (default: 20)
   - `--dry-run`: Show plan without executing
   - `--verbose` or `-v`: Verbose output

   **Usage:**
   ```bash
   # Run orchestrator (picks next ticket from queue)
   python -m cc_workflow.orchestrator.main

   # Work on specific ticket
   python -m cc_workflow.orchestrator.main --ticket FW-061

   # Dry run to see current state
   python -m cc_workflow.orchestrator.main --dry-run
   ```

   **How it works:**
   1. Orchestrator Claude analyzes current state (tasks, tickets, git)
   2. Orchestrator decides what Agent Claude should do
   3. Agent Claude executes the task (code, tests, commits)
   4. Orchestrator evaluates results and repeats until done/blocked

   **Files:**
   - `cc_workflow/orchestrator/` - Python orchestrator package
   - `cc_workflow/orchestrator/patterns.txt` - Learned codebase patterns
   - `cc_workflow/orchestrator/prompts/` - System prompts for both Claudes

## %autonomous / %a

   Activate autonomous agent orchestration mode. The main session becomes an orchestrator that:
   1. Reads the current/next ticket
   2. Breaks it into atomic tasks
   3. Spawns OMC executor agents to complete each task
   4. Monitors progress, handles errors, retries failures
   5. Continues until all tasks complete or a blocker is hit

   **How it works:**
   - Reads learnings from previous runs (`cc_workflow/autonomous/learnings.md`)
   - Main session creates Tasks via `TaskCreate`
   - Spawns `oh-my-claudecode:executor` agents to work on tasks
   - Agents can read/update the shared task list
   - Main session monitors `TaskList` and handles results
   - Checkpoints every 3 tasks (smoke tests, commit)
   - Final verification before marking ticket complete
   - Captures learnings (what worked, failures, patterns) for future runs

   **Key differences from other commands:**
   - `%tasks` - You do the work, tasks track progress
   - `%orchestrate` - External Python script manages two Claude instances
   - `%autonomous` - You coordinate OMC agents via task list (this command)

   **When to use:**
   - For tickets that can be broken into independent pieces
   - When you want minimal interaction during execution
   - For standard implementation work (not exploratory/research)

   **Workflow document:** See `AUTONOMOUS_WORKFLOW.md` for the full decision tree.

   **Prerequisites:**
   - OMC plugin installed with Task tools patch (see `cc_workflow/OMC_TASK_TOOLS_PATCH.md`)
   - No other active orchestration running

## %ralph / %r (-r)

   This command is used to collaborate with Ralph (./cc_workflow/scripts/ralph/). A reference for working with Ralph exists at ./cc_workflow/scripts/RALPH_REFERNCE.md.

   If the option -r is used:
      Review the most recent work completed by Ralph.
         If Ralph raised any issues, verify the issue exists.
            If you are able to ameliorate that issue on your own, do so.
         If you have any concerns about Ralph's code quality, raise them and ticket them.
      Create a handoff document for the review.
      Move completed tickets.

   Review ready tickets. If already preparded PRDs exist in ./cc_workflow/scripts/ralph/prd_drafts, begin with one of those, editing as needed, replacing Ralph's current PRD. Otherwise, determine an appropriate workload for Ralph based on tickets, and create the PRD. 