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

## Implementation Notes (2026-01-21)

**Files Created:**
- `src/ui/equipment_select.gd` - Equipment selection controller
- `src/ui/equipment_card.gd` - Individual equipment card component
- `scenes/ui/equipment_select.tscn` - Selection screen scene
- `scenes/ui/equipment_card.tscn` - Card component scene

**Acceptance Criteria Status:**
- [x] Equipment grid showing all 10 equipment types (7 evidence, 3 protection)
- [x] 3 slot selection with click (select/deselect toggles)
- [x] Equipment descriptions and evidence types in tooltip panel
- [x] Visual indication of teammate selections via EventBus
- [x] Ready button enabled when 3 items selected
- [x] Timer countdown with visual warning (red <10s, orange <30s)
- [x] State broadcast via EventBus for network sync
- [x] Selection locked after ready confirmation

**Equipment Data:**
- EMF Reader, Thermometer, Ghost Writing Book
- Spectral Calibrator, Spectral Lens (cooperative pair)
- Dowsing Rods, Aura Imager (cooperative pair)
- Crucifix, Sage Bundle, Salt (protection items)

**Notes:**
- Network sync relies on EventBus.equipment_loadout_changed signal
- force_submit() auto-fills empty slots if timer expires
- Tested via commits FW-082-01 through FW-082-03
