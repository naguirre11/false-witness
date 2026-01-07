---
id: FW-003
title: "Implement core game state machine"
epic: FOUNDATION
priority: high
estimated_complexity: medium
dependencies: [FW-002]
created: 2026-01-07
---

## Description

Implement the central game state machine in GameManager that controls match flow. The game progresses through distinct phases: Lobby -> Equipment Select -> Investigation -> Deliberation -> Results.

## Acceptance Criteria

- [ ] GameState enum defined with all phases:
  - MENU
  - LOBBY
  - EQUIPMENT_SELECT
  - INVESTIGATION
  - DELIBERATION
  - RESULTS
- [ ] State transition logic with validation (can't skip states)
- [ ] Signals emitted on state changes via EventBus
- [ ] State-specific timers (investigation: 12-15min, deliberation: 3-5min)
- [ ] Public API for querying current state
- [ ] Unit tests for state transitions

## Technical Notes

State machine should be authoritative - in multiplayer, only host transitions states and clients receive updates.

```gdscript
enum GameState {
    MENU,
    LOBBY,
    EQUIPMENT_SELECT,
    INVESTIGATION,
    DELIBERATION,
    RESULTS
}
```

## Out of Scope

- Network synchronization of state (NET epic)
- Actual phase implementations (separate tickets)
