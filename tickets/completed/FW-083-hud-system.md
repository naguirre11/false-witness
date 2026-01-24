---
id: FW-083
title: "Implement in-game HUD system"
epic: UI
priority: high
estimated_complexity: medium
dependencies: [FW-021, FW-023]
created: 2026-01-07
---

## Description

Create the minimal in-game HUD showing essential information during investigation. Prioritize diegetic UI (on equipment) over screen overlays.

## Acceptance Criteria

- [ ] Equipment hotbar showing 3 slots
- [ ] Active equipment highlight
- [ ] Interaction prompt when looking at interactables
- [ ] Match timer display
- [ ] Sanity/stamina indicators (if applicable)
- [ ] Voice activity indicator
- [ ] Death/spectator UI overlay
- [ ] Evidence board hotkey indicator

## Technical Notes

Per GDD: "In-world equipment UI (diegetic) where possible." EMF reader shows reading on device, not HUD.

Minimal HUD intrusion to maintain immersion.

## Out of Scope

- Evidence board (separate ticket)
- Cultist-specific UI
- Settings/pause menu

## Implementation Notes (2026-01-21)

**Files Created:**
- `src/ui/hud.gd` - HUD controller (CanvasLayer)
- `scenes/ui/hud.tscn` - HUD scene

**Acceptance Criteria Status:**
- [x] Equipment hotbar showing 3 slots with icons and names
- [x] Active equipment highlight (golden modulate)
- [x] Interaction prompt show/hide methods
- [x] Match timer display with phase label and color warnings
- [ ] Sanity/stamina indicators - deferred (may not be needed per GDD)
- [x] Voice activity indicator (V key toggle for testing)
- [x] Death/spectator UI overlay (ColorRect)
- [x] Evidence board hotkey indicator (Tab key, toggle TODO)

**Features:**
- Auto-hides during NONE, LOBBY, SETUP, RESULTS states
- Shows phase name (Investigation/Hunt/Deliberation)
- Timer color: red <60s, orange <2min, white otherwise
- Connects to EventBus for game_state_changed, phase_timer_tick

**Notes:**
- Evidence board toggle is a placeholder (prints to console)
- Equipment icon/name lookup hardcoded - works with Equipment enum
- Tested via commits FW-083-01 and FW-083
