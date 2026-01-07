---
id: FW-033
title: "Implement Thermometer and freezing temperature evidence"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
created: 2026-01-07
---

## Description

Create the Thermometer equipment and freezing temperature evidence. Certain entities cause rooms to drop to freezing temperatures.

## Acceptance Criteria

- [ ] Thermometer equipment with visual display
- [ ] Area temperature reading system
- [ ] Freezing threshold (below 0C / 32F)
- [ ] Natural room temperature variance
- [ ] Cold breath visual effect in freezing rooms
- [ ] Audio feedback for temperature changes
- [ ] Network synced temperatures

## Technical Notes

Temperature zones attached to rooms. Entity's active room has modified temperature.

Ambiguity factor: Natural cold spots can exist, making false positives possible.

## Out of Scope

- False temperature (Cultist contamination)
- Thermal camera variant
