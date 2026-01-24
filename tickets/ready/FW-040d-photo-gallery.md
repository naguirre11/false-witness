---
id: FW-040d
title: "Photo Gallery UI"
epic: EVIDENCE
priority: medium
estimated_complexity: small
dependencies: [FW-040c, FW-035]
created: 2026-01-24
parent: FW-040
---

## Description

Add a photo gallery interface to view captured photos during investigation. Players can review their camera evidence and share findings with teammates.

## Acceptance Criteria

### Gallery Access
- [ ] Open gallery via Tab (alongside Evidence Board) or dedicated key
- [ ] Gallery shows all photos taken by local player
- [ ] Photos displayed as thumbnails in grid layout

### Photo Display
- [ ] Thumbnail grid (3x2 layout for 6 photos max)
- [ ] Click thumbnail to view full-size
- [ ] Full-size view shows:
  - Photo image (viewport capture)
  - Timestamp
  - Location name
  - Entity detected indicator (if captured entity)

### Photo Metadata Display
- [ ] Film counter: "X/6 photos remaining"
- [ ] Entity detection badge on photos that captured entity
- [ ] Quality indicator (STRONG if entity visible)

### Multiplayer Integration
- [ ] Photos stored in PhotoRecord resources (already implemented)
- [ ] Server validates entity detection claims
- [ ] Other players can request to view your photos (future ticket?)

### UI Design
- [ ] Uses DesignTokens for styling
- [ ] Horror-appropriate aesthetic (dark background, polaroid-style frames)
- [ ] Smooth transitions between thumbnail and full view

## Technical Notes

PhotoRecord already contains:
- `photo_uid`: Unique identifier
- `timestamp`: When taken
- `location`: World position
- `captured_entity`: Reference to entity if detected
- `quality`: STRONG/WEAK reading

Gallery reads from local player's EquipmentManager → VideoCamera → photo_records array.

## Out of Scope

- Photo sharing between players (separate ticket)
- Photo annotation/marking
- Exporting photos outside game
