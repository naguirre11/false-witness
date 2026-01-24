---
id: FW-061
title: "Implement win/loss conditions and match resolution"
epic: FLOW
priority: high
estimated_complexity: medium
dependencies: [FW-003, FW-031, FW-051]
created: 2026-01-07
---

## Description

Create the complete win/loss condition system that determines match outcomes. Multiple paths to victory for both teams.

## Acceptance Criteria

- [ ] Entity identification submission during DELIBERATION
- [ ] Majority vote required for submission
- [ ] Win condition checks:

**Investigators Win If:**
- [ ] Correctly identify entity type before time expires
- [ ] Correctly identify AND vote out Cultist (bonus)

**Cultist Wins If:**
- [ ] Team submits incorrect entity identification
- [ ] Time expires without identification
- [ ] Team votes out an innocent investigator

- [ ] Match end triggers RESULTS state
- [ ] Win/loss broadcast to all players

## Technical Notes

Entity identification: Team uses evidence board to narrow possibilities, then submits guess. Submission requires majority agreement.

Time limit: 15-20 minutes total investigation + deliberation.

## Out of Scope

- Results screen UI (separate ticket)
- XP/rewards calculation

## Implementation Notes (Ralph)

### Files Created
- `src/core/managers/match_manager.gd` - Autoload managing win condition logic
- `src/core/match_result.gd` - MatchResult resource with WinningTeam/WinCondition enums
- `tests/unit/test_match_manager.gd` - 23 unit tests for win conditions

### Files Modified
- `src/evidence/evidence_manager.gd` - Added identification submission and voting
- `src/core/managers/event_bus.gd` - Changed match_ended signal to Dictionary type
- `project.godot` - Added MatchManager autoload

### Key Implementation Details
- **MatchManager** (`src/core/managers/match_manager.gd:151`): `check_win_condition()` compares submitted entity to actual
- **EvidenceManager** (`src/evidence/evidence_manager.gd:236`): `submit_identification()` stores pending identification
- **Voting** (`src/evidence/evidence_manager.gd:301`): `vote_for_identification()` with majority threshold
- Win conditions: CORRECT_IDENTIFICATION, INCORRECT_IDENTIFICATION, TIME_EXPIRED, CULTIST_VOTED_OUT, INNOCENT_VOTED_OUT

### Verification
- ✅ Smoke tests: 17/17 pass
- ✅ Unit tests: 23/23 pass (test_match_manager.gd)
- ✅ Full test suite: 1792+ passing
