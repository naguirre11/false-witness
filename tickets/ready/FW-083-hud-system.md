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
