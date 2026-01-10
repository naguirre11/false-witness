---
id: FW-040c
title: "Photo Evidence System"
epic: EVIDENCE
priority: medium
estimated_complexity: medium
dependencies: [FW-040a, FW-023]
created: 2026-01-10
parent: FW-040
---

## Description

Implement camera equipment that can capture visual manifestations as permanent photo evidence. Photos provide documented proof that can be shared with other players.

## Acceptance Criteria

### Camera Equipment
- [ ] Camera as equipment item (extends Equipment base)
- [ ] Photo mode when aiming (camera viewfinder UI)
- [ ] Capture button takes photo
- [ ] Limited film/charges per game

### Photo Capture Mechanics
- [ ] Photo captures current view
- [ ] If entity visible in frame → photo contains evidence
- [ ] Missed shot = no evidence (skill expression)
- [ ] Photo timestamped

### Photo Storage & Sharing
- [ ] Photos stored in player inventory
- [ ] Photos can be shown to other players
- [ ] Photos visible to all players who view them (shared display)
- [ ] Photos persist until round end

### Evidence Quality
- [ ] Photo of manifestation = STRONG VISUAL_MANIFESTATION evidence
- [ ] Photo provides permanent record (unlike fleeting sightings)
- [ ] Cultist cannot fabricate photo evidence

## Technical Notes

Camera already partially exists in Phantom's behavioral tell check (`_is_player_photographing`). This ticket formalizes it as equipment.

## Out of Scope

- Video recording
- Night vision camera variants
- Photo gallery UI (separate UI ticket)
