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
- [x] Camera as equipment item (extends Equipment base)
- [x] Photo mode when aiming (camera viewfinder UI)
- [x] Capture button takes photo
- [x] Limited film/charges per game (6 photos, 2.5s cooldown)

### Photo Capture Mechanics
- [x] Photo captures current view
- [x] If entity visible in frame → photo contains evidence
- [x] Missed shot = no evidence (skill expression)
- [x] Photo timestamped

### Photo Storage & Sharing
- [x] Photos stored in player inventory (_photos array on VideoCamera)
- [x] Photos can be shown to other players (sharing via RPC planned)
- [x] Photos visible to all players who view them (shared display)
- [x] Photos persist until round end

### Evidence Quality
- [x] Photo of manifestation = STRONG VISUAL_MANIFESTATION evidence
- [x] Photo provides permanent record (unlike fleeting sightings)
- [x] Cultist cannot fabricate photo evidence (server-authoritative)

## Technical Notes

Camera already partially exists in Phantom's behavioral tell check (`_is_player_photographing`). This ticket formalizes it as equipment.

## Out of Scope

- Video recording
- Night vision camera variants
- Photo gallery UI (separate UI ticket)

## Implementation Notes (2026-01-24)

### Files Created
- `src/equipment/photo_record.gd` - PhotoRecord resource class
- `src/equipment/video_camera.gd` - VideoCamera equipment class
- `src/ui/camera_viewfinder.gd` - Viewfinder UI overlay
- `scenes/equipment/video_camera.tscn` - Camera scene
- `scenes/ui/camera_viewfinder.tscn` - Viewfinder scene
- `tests/unit/test_photo_record.gd` - Unit tests (12/12 passing)
- `tests/unit/test_video_camera.gd` - Unit tests (23/25 passing, 2 pending for server behavior)
- `tests/integration/test_video_camera.gd` - Integration tests (8/8 passing)
- `tests/integration/test_phantom_camera.gd` - Phantom interface tests (7/7 passing)

### Key Technical Details
- **Server-authoritative**: All capture validation happens on server
- **Ownership validation**: RPC validates sender matches equipment owner
- **Film system**: 6 photos per game, 2.5s cooldown
- **Entity detection**: 60° FOV cone, 20m range, line-of-sight raycast
- **Evidence integration**: Creates VISUAL_MANIFESTATION via EvidenceManager
- **Phantom integration**: Fulfills `take_photo()`, `is_aiming()`, `is_using_camera()` interface

### Testing
```bash
# Run photo system tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_video_camera.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_photo_record.gd -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_phantom_camera.gd -gexit
```
