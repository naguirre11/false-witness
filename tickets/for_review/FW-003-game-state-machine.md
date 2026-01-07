---
id: FW-003
title: "Implement core game state machine"
epic: FOUNDATION
priority: high
estimated_complexity: medium
dependencies: [FW-002]
created: 2026-01-07
completed: 2026-01-07
---

## Description

Implement the central game state machine in GameManager that controls match flow. The game progresses through distinct phases: Lobby -> Equipment Select -> Investigation -> Deliberation -> Results.

## Acceptance Criteria

- [x] GameState enum defined with all phases (see implementation notes)
- [x] State transition logic with validation (can't skip states)
- [x] Signals emitted on state changes via EventBus
- [x] State-specific timers (investigation: 12-15min, deliberation: 3-5min)
- [x] Public API for querying current state
- [x] Unit tests for state transitions

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

---

## Implementation Notes

### State Enum Mapping

The implementation uses slightly different state names that better reflect the game design:

| Ticket Spec | Implementation | Notes |
|-------------|----------------|-------|
| MENU | NONE | Clearer for "no game active" |
| EQUIPMENT_SELECT | SETUP | Matches role assignment + equipment select |
| - | HUNT | **Added** - Critical for gameplay (entity hunting) |

The HUNT state was added because the game design requires entities to interrupt investigation with hunts. This is not "skipping states" - it's a bidirectional transition (INVESTIGATION <-> HUNT).

### Timer Implementation

| Phase | Default | Min | Max |
|-------|---------|-----|-----|
| Investigation | 720s (12 min) | 720s | 900s (15 min) |
| Deliberation | 180s (3 min) | 180s | 300s (5 min) |

**Timer API:**
- `get_time_remaining()` - Returns seconds remaining
- `is_timer_active()` - True during timed phases
- `is_timer_paused()` - Check pause state
- `pause_timer()` / `resume_timer()` - Pause controls
- `extend_timer(seconds)` - Add time
- `set_timer(seconds)` - Override time
- `configure_phase_durations(investigation, deliberation)` - Pre-match setup

**Timer Signals (via EventBus):**
- `phase_timer_tick(time_remaining)` - Emitted every second
- `phase_timer_expired(state)` - Emitted when timer hits zero
- `phase_timer_extended(additional_seconds)` - Emitted on extension

### Files Modified

| File | Changes |
|------|---------|
| `src/core/managers/game_manager.gd` | Added timer system, duration constants |
| `src/core/managers/event_bus.gd` | Added 3 timer signals |
| `tests/test_game_manager.gd` | 15 state transition tests |
| `tests/test_game_manager_timer.gd` | 14 timer-specific tests (new file) |
| `tests/test_event_bus.gd` | 6 new timer signal tests |

### Testing

```bash
# Run all tests (50 tests, all passing)
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/

# Test results: 50/50 passed, 75 asserts, 0.025s
```

### State Flow Diagram

```
NONE -> LOBBY -> SETUP -> INVESTIGATION <-> HUNT -> RESULTS
                              |                       |
                              v                       |
                        DELIBERATION -----------------+
```

Timers auto-start when entering INVESTIGATION or DELIBERATION states.
