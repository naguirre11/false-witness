---
id: FW-062
title: "Implement deliberation phase mechanics"
epic: FLOW
priority: high
estimated_complexity: medium
dependencies: [FW-061, FW-035]
created: 2026-01-07
---

## Description

Create the deliberation phase where the team discusses findings and submits their final entity identification. Evidence board is always visible, and players make their final decision.

## Acceptance Criteria

- [ ] Deliberation phase lasts 3-5 minutes
- [ ] All players teleported to safe deliberation area
- [ ] Evidence board always visible
- [ ] Entity not active during deliberation
- [ ] Any player can propose identification
- [ ] Proposal triggers vote UI
- [ ] Majority approval submits identification
- [ ] Timer countdown visible
- [ ] Auto-submission of most recent proposal at timer end (or loss if none)

## Technical Notes

Safe area prevents entity kills during discussion. Voice chat remains active.

Decision: Per GDD, if no submission by timer, Cultist wins.

## Out of Scope

- Chat/note-taking features
- Evidence annotation

## Implementation Notes (Ralph)

### Files Created
- `src/deliberation/deliberation_area.gd` - Deliberation area with spawn points (136 lines)
- `src/deliberation/deliberation_manager.gd` - Autoload managing teleportation and movement (237 lines)
- `src/ui/deliberation_ui.gd` - Deliberation UI overlay with timer (163 lines)
- `src/ui/entity_selection.gd` - Entity grid popup for proposals (215 lines)
- `src/ui/voting_ui.gd` - Vote UI for approve/reject (190 lines)
- `scenes/deliberation_area.tscn` - 6 spawn points, boundary area
- `scenes/ui/deliberation_ui.tscn` - CanvasLayer at layer 15
- `scenes/ui/entity_selection.tscn` - Full-screen with dimmer
- `scenes/ui/voting_ui.tscn` - Top-center popup
- `tests/integration/test_deliberation.gd` - Integration tests (222 lines)

### Files Modified
- `project.godot` - Added DeliberationManager autoload

### Key Implementation Details
- **DeliberationManager** (`src/deliberation/deliberation_manager.gd:82`): `teleport_all_players()` on DELIBERATION state
- **EntitySelection** (`src/ui/entity_selection.gd:153`): Filters possible entities based on collected evidence
- **VotingUI** (`src/ui/voting_ui.gd`): Real-time vote count updates, auto-closes on majority
- Timer warning at 60s (red text), auto-approval/loss on expiry handled by MatchManager

### Verification
- ✅ Smoke tests: 17/17 pass
- ✅ Integration tests pass (test_deliberation.gd)
- ✅ Full test suite: 1792+ passing
