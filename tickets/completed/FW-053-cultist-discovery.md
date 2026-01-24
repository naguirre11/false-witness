---
id: FW-053
title: "Implement Cultist discovery and post-discovery play"
epic: CULTIST
priority: medium
estimated_complexity: medium
dependencies: [FW-052, FW-061]
created: 2026-01-07
---

## Description

Create the voting system to identify the Cultist and define how discovered Cultists continue to participate. Unlike most traitor games, discovery doesn't end the Cultist's influence.

## Acceptance Criteria

- [ ] Emergency vote can be called during investigation
- [ ] Voting UI with player selection
- [ ] Majority required to vote out
- [ ] Voting out Cultist: Investigators bonus win condition
- [ ] Voting out Innocent: Cultist wins immediately
- [ ] Discovered Cultist restrictions:
  - Can observe and discuss
  - Cannot collect evidence
  - Cannot use remaining abilities
  - Previously collected evidence becomes suspect
- [ ] Discovered status visible to all players

## Technical Notes

Per GDD: "Identified traitors retain influence and can still cast doubt."

Vote timing: Costs investigation time, entity continues escalating.

## Out of Scope

- Voting history tracking
- Evidence tampering after discovery

## Implementation Notes (Ralph - 2026-01-21)

### Files Created

**Core Systems (additions to cultist_manager.gd):**
- Emergency vote system (+150 lines)
- Vote tracking with majority calculation (+100 lines)
- Cultist discovery/innocent voted outcomes (+80 lines)
- Action logging for post-game reveal (+100 lines)

**UI Components:**
- `src/ui/cultist_vote.gd` + scene - Voting panel (~460 lines)
- `src/ui/player_name_label_3d.gd` - 3D "CULTIST" indicator (~170 lines)
- `src/ui/discovered_cultist_label.gd` - Alternative label component (~140 lines)
- `src/ui/player_slot_ui.gd` - 2D "[CULTIST]" indicator (+80 lines)

**Tests:**
- `tests/integration/test_cultist_voting.gd` (27 tests, ~550 lines)

### Key Implementation Details
- Emergency votes limited to 2 per match (`MAX_EMERGENCY_VOTES = 2`)
- Each vote costs 30 seconds of investigation time (`EMERGENCY_VOTE_TIME_COST = 30.0`)
- 30-second voting timer with majority threshold (>50% of alive players)
- Ties result in no ejection
- Cultist discovery: abilities disabled, evidence marked suspect
- Innocent voted: Cultist wins immediately via MatchManager
- Discovered status tracked via `_discovery_state` in CultistData
- Visual indicators: 3D billboard label above player, 2D label in player lists

### Signals Added
- `emergency_vote_called(caller_id: int)`
- `vote_cast(voter_id: int, target_id: int)`
- `vote_timer_updated(time_remaining: float)`
- `vote_complete(target_id: int, is_majority: bool)`
- `cultist_discovered(player_id: int)`
- `innocent_voted_out(player_id: int)`

### Test Verification
```
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_cultist_voting.gd
Result: 27/27 passed
```

### Acceptance Criteria Status
- [x] Emergency vote can be called during investigation
- [x] Voting UI with player selection
- [x] Majority required to vote out
- [x] Voting out Cultist: Investigators bonus win condition
- [x] Voting out Innocent: Cultist wins immediately
- [x] Discovered Cultist restrictions:
  - [x] Can observe and discuss (voice chat still works)
  - [x] Cannot collect evidence (enforced in EvidenceManager)
  - [x] Cannot use remaining abilities (disabled in ability bar)
  - [x] Previously collected evidence becomes suspect
- [x] Discovered status visible to all players (3D + 2D indicators)
