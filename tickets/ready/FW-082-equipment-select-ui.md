---
id: FW-082
title: "Create equipment selection UI"
epic: UI
priority: high
estimated_complexity: medium
dependencies: [FW-023, FW-003]
created: 2026-01-07
---

## Description

Build the equipment selection screen shown during EQUIPMENT_SELECT phase. Players choose 3 equipment items to bring on the investigation.

## Acceptance Criteria

- [ ] Equipment grid showing all available types
- [ ] 3 slot selection with drag-drop or click
- [ ] Equipment descriptions and evidence types detected
- [ ] Visual indication of what teammates selected
- [ ] Ready button when 3 items selected
- [ ] Timer countdown for phase
- [ ] Synced state across all players
- [ ] Clear feedback for locked/unavailable items

## Technical Notes

Cultist sees all teammate selections - important for strategic contamination planning.

Equipment types (from GDD):
- EMF Reader, Spirit Box, Journal, Thermometer
- UV Flashlight, DOTS Projector, Video Camera, Parabolic Mic

## Out of Scope

- Equipment variants/upgrades
- Loadout presets
