---
id: FW-040b
title: "Physical Interaction Framework"
epic: EVIDENCE
priority: medium
estimated_complexity: large
dependencies: [FW-040a]
created: 2026-01-10
parent: FW-040
---

## Description

Create the framework for physical interaction evidence - objects that entities can manipulate (throw, move), doors they can interact with, and electronics they can affect. These events are witnessed by all nearby players and generate PHYSICAL_INTERACTION evidence.

## Acceptance Criteria

### Interactable Object System
- [ ] InteractableObject base class for throwable/movable objects
- [ ] Entity can trigger object movement
- [ ] Movement visible AND audible to all nearby players
- [ ] Witness tracking for who saw the interaction

### Door Interactions
- [ ] Doors can be slammed/opened by entities
- [ ] Door sounds audible throughout building
- [ ] Witness tracking for door interactions

### Electronic Interference
- [ ] Lights can flicker or explode
- [ ] Electronic devices can malfunction
- [ ] Different patterns per entity type (configurable)

### Evidence Generation
- [ ] PHYSICAL_INTERACTION evidence auto-generated on interaction
- [ ] Evidence includes interaction type (object, door, electronic)
- [ ] Multi-witness = HIGH trust

### Surface Manifestations
- [ ] Writing on walls/mirrors (persistent until round end)
- [ ] Handprints (bloody, ashy variants)
- [ ] Scratch marks
- [ ] These can be shown to other players as proof

## Technical Notes

Requires game world objects to exist. This ticket creates the framework; actual objects are placed in maps.

## Out of Scope

- Specific object/door placements (map tickets)
- Camera/photo capture of interactions
- Entity-specific interaction patterns (entity tickets)
