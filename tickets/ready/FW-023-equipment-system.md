---
id: FW-023
title: "Create equipment slot and inventory system"
epic: FPS
priority: high
estimated_complexity: medium
dependencies: [FW-022]
created: 2026-01-07
---

## Description

Implement the 3-slot equipment system where players select and carry investigation tools. Equipment is selected pre-investigation and determines what evidence types a player can detect.

## Acceptance Criteria

- [ ] 3 equipment slots per player
- [ ] Equipment selection during EQUIPMENT_SELECT phase
- [ ] Scroll wheel / number keys to switch active equipment
- [ ] Equipment visually held in first-person view
- [ ] Equipment base class with common interface
- [ ] Equipment state synced across network
- [ ] Cannot change equipment after investigation starts

## Technical Notes

Equipment types from GDD:
- EMF Reader
- Spirit Box
- Journal (Ghost Writing)
- Thermometer
- UV Flashlight
- DOTS Projector
- Video Camera
- Parabolic Mic

Each player selects 3, so team must coordinate coverage.

## Out of Scope

- Individual equipment implementations
- Evidence detection logic
- Equipment variants/upgrades
