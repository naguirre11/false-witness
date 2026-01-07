---
id: FW-044
title: "Implement first entity type: Phantom"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-041, FW-042]
created: 2026-01-07
---

## Description

Create the first complete entity type - the Phantom. This establishes the pattern for all future entity implementations.

## Acceptance Criteria

- [ ] Phantom entity class extending Entity base
- [ ] Evidence types: EMF 5, Spirit Box, DOTS
- [ ] Unique behavior: Looking at Phantom drops sanity faster
- [ ] Phantom can disappear when looked at during manifestation
- [ ] Hunt behavior follows base with unique audio
- [ ] Placeholder visual model (can be improved later)
- [ ] Audio cues specific to Phantom

## Technical Notes

From GDD entity matrix:
- Phantom: EMF 5, Spirit Box, DOTS

Phantom shares EMF 5 + Spirit Box with Wraith - only DOTS differentiates. This overlap is intentional for Cultist gameplay.

## Out of Scope

- Additional entity types
- Entity visual polish
