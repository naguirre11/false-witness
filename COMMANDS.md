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

   Read and follow the decision tree in `FLOWCHART.md`. This guides you through:
   1. Checking the latest handoff for emergencies or non-ticketed work
   2. Selecting the correct ticket (active in dev_in_progress, or NEXT from STATUS.md)
   3. Verifying dependencies and blockers before starting
   4. Implementation, testing, completion, and handoff procedures

   Use this command at the start of a session to ensure systematic, foolproof workflow. 