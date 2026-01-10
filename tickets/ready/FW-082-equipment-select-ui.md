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

**Evidence Equipment (implemented):**
- EMF Reader → EMF_SIGNATURE
- Thermometer → FREEZING_TEMPERATURE
- Spectral Prism Calibrator → PRISM_READING (player 1 of pair)
- Spectral Prism Lens Reader → PRISM_READING (player 2 of pair)
- Dowsing Rods → AURA_PATTERN (player 1 of pair)
- Aura Imager → AURA_PATTERN (player 2 of pair)
- Ghost Writing Book → GHOST_WRITING

**Protection Items:**
- Crucifix, Salt, Sage Bundle

## Out of Scope

- Equipment variants/upgrades
- Loadout presets
