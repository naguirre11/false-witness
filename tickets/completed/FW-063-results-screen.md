---
id: FW-063
title: "Implement post-match results screen"
epic: FLOW
priority: medium
estimated_complexity: medium
dependencies: [FW-061]
created: 2026-01-07
---

## Description

Create the results screen shown after each match. Critical for learning and social engagement - shows what really happened.

## Acceptance Criteria

- [ ] Correct entity revealed with its evidence types
- [ ] Cultist identity revealed
- [ ] Timeline of Cultist actions (what they contaminated)
- [ ] Which evidence was real vs contaminated
- [ ] Individual contribution breakdown (evidence collected)
- [ ] Win/loss status with reason
- [ ] Humorous superlatives ("Most Screams", "Best Hide", etc.)
- [ ] Return to lobby button

## Technical Notes

Per GDD: "Post-game breakdown shows Cultist's moves, enabling learning."

This screen is important for player retention - understanding what happened makes players want to play again.

## Out of Scope

- XP/progression display
- Statistics tracking
- Replay system

## Implementation Notes (2026-01-21)

**Files Created:**
- `src/ui/results_screen.gd` - Results screen controller
- `src/core/match_result.gd` - MatchResult resource class
- `scenes/ui/results_screen.tscn` - Results screen scene

**Acceptance Criteria Status:**
- [x] Entity revealed with evidence types (correct vs missed)
- [x] Cultist identity revealed with status message
- [x] Timeline of Cultist actions with timestamps and color coding
- [x] Evidence collected/contaminated display
- [x] Individual contribution breakdown (evidence collected, verified, echo status)
- [x] Win/loss status with reason via WinCondition enum
- [x] Humorous superlatives (Evidence Hunter, Speed Demon, Most Screams)
- [x] Return to lobby button with scene transition

**MatchResult Resource:**
- `winning_team`: Team enum (INVESTIGATORS, CULTIST)
- `win_condition`: WinCondition enum (CORRECT_IDENTIFICATION, etc.)
- `entity_type`, `entity_evidence`, `evidence_collected_correctly`
- `cultist_username`, `cultist_actions` (timeline)
- `player_stats`: Dictionary with username, evidence_collected, deaths, etc.
- Helper methods: `did_investigators_win()`, `get_win_condition_text()`

**Superlatives Generated:**
- Evidence Hunter (most evidence)
- Speed Demon (fastest first evidence)
- Most Screams (most deaths)
- Random fallbacks: Lucky Survivor, Team Player, Eagle Eye

**Notes:**
- Returns to lobby_screen.tscn on button press
- Calls LobbyManager.reset_for_rematch() if available
- Tested via commits FW-061-01 and FW-063
