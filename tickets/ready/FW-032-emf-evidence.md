---
id: FW-032
title: "Implement EMF Reader and EMF evidence"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
created: 2026-01-07
---

## Description

Create the EMF Reader equipment and EMF evidence type. EMF readings range 1-5, with Level 5 being definitive paranormal evidence.

## Acceptance Criteria

- [ ] EMF Reader equipment with visual model
- [ ] EMF detection via proximity to activity zones
- [ ] EMF levels 1-5 displayed on device
- [ ] Only EMF 5 counts as evidence
- [ ] Ambient EMF noise (levels 1-3) for ambiguity
- [ ] Audio feedback for different levels
- [ ] Network synced readings

## Technical Notes

EMF Reader has a physical display showing current reading. Updates in real-time as player moves through zones.

Ambiguity factor: Levels 1-4 are common, Level 5 is rare and definitive.

## Out of Scope

- False EMF (Cultist contamination)
- Other evidence types
