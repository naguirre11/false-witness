---
id: FW-073
title: "Create third map: Hospital Wing"
epic: MAP
priority: medium
estimated_complexity: large
dependencies: [FW-071]
created: 2026-01-24
phase: 2
---

## Description

Design and implement the third investigation location - an abandoned hospital wing. Medium-large map with medical theming, long corridors, and atmospheric horror elements.

## Map Specifications

| Property | Value |
|----------|-------|
| Size | Large (2 floors + basement) |
| Rooms | 20-25 |
| Players | 4-6 |
| Difficulty | Hard |

## Acceptance Criteria

### Layout
- [ ] Ground floor: Reception, waiting area, exam rooms, pharmacy
- [ ] Second floor: Patient rooms (6-8), nurse station, operating theater
- [ ] Basement: Morgue, storage, maintenance tunnels
- [ ] Central elevator shaft (non-functional)
- [ ] Long corridors with many doors

### Key Locations
- [ ] **Morgue**: Cold room, freezing temperature spawn, body drawers
- [ ] **Operating Theater**: Large open space, medical equipment
- [ ] **Patient Rooms**: Identical layout, easy to get disoriented
- [ ] **Pharmacy**: Locked cabinets, pill bottles for interactions
- [ ] **Chapel**: Small prayer room, potential safe zone feeling

### Interactive Elements
- [ ] Hospital beds that can move/shake
- [ ] IV stands that swing
- [ ] Wheelchairs that roll
- [ ] Medicine cabinet doors
- [ ] Heart monitors that beep/flatline
- [ ] Flickering fluorescent lights
- [ ] Automatic doors (some broken)

### Hiding Spots
- [ ] Under hospital beds
- [ ] Inside supply closets (4 locations)
- [ ] Bathroom stalls
- [ ] Behind curtain dividers
- [ ] Inside morgue drawers (risky but effective)

### Audio Design
- [ ] Distant PA system crackle
- [ ] Heart monitor beeps
- [ ] Wheelchair squeaks
- [ ] Ventilation hum
- [ ] Dripping water in basement

### Horror Elements
- [ ] Body bags in morgue
- [ ] Abandoned wheelchairs in corridors
- [ ] Patient charts with disturbing notes
- [ ] Broken medical equipment
- [ ] Old blood stains (subtle)

### Evidence Spawn Points
- [ ] 8-10 spawn points per evidence type
- [ ] Morgue has permanent temperature zone
- [ ] Patient rooms good for ghost writing
- [ ] Long corridors for chase sequences

### Navigation
- [ ] Long sight lines in corridors
- [ ] Multiple stairwell access points
- [ ] Basement accessible via stairs only
- [ ] Room numbers for orientation

## Technical Notes

Hospital approximately 60m x 40m footprint, 10m total height.

Long corridors create tension and make sound propagation important.

Morgue drawer hiding spot should have special interaction (climb in, close door).

## Out of Scope

- Working medical equipment
- Patient NPCs
- Full hospital (just one wing)
