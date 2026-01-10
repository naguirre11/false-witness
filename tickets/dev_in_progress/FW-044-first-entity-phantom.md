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
- [ ] Evidence types: EMF_SIGNATURE, PRISM_READING, VISUAL_MANIFESTATION
- [ ] Unique behavior: Looking at Phantom drops sanity faster
- [ ] Phantom can disappear when looked at during manifestation
- [ ] Hunt behavior follows base with unique audio
- [ ] Placeholder visual model (can be improved later)
- [ ] Audio cues specific to Phantom

## Technical Notes

**Evidence Types (using implemented system):**
- EMF_SIGNATURE - Detected by EMF Reader (level 5)
- PRISM_READING - Detected by Spectral Prism Rig (cooperative symmetric)
- VISUAL_MANIFESTATION - Full/partial entity appearances (readily apparent)

**Cultist Overlap:**
Phantom shares EMF_SIGNATURE + PRISM_READING with Wraith. Only VISUAL_MANIFESTATION vs AURA_PATTERN differentiates them. This overlap is intentional - Cultist needs only contaminate one evidence type to cause misidentification.

**Behavioral Tell:**
Disappears instantly when photographed during manifestation. Camera becomes a defensive tool.

## Out of Scope

- Additional entity types
- Entity visual polish
