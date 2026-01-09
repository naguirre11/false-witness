---
id: FW-034
title: "Implement Spirit Box equipment (DEFERRED)"
epic: EVIDENCE
priority: low
estimated_complexity: medium
dependencies: [FW-031, FW-014]
created: 2026-01-07
status: deferred
---

## Status: DEFERRED

**Reason:** The Evidence Sources v2 design document removed Spirit Box from the core 8 evidence types. The cooperative equipment (Spectral Prism Rig, Dowsing Rods + Aura Imager) replaced it to create more interesting trust dynamics.

**Potential Future Use:**
- Could be added as 9th evidence type post-launch
- Would require voice chat integration (FW-014)
- Trust dynamic: Single-witness (only holder hears responses)

## Original Description

Create the Spirit Box equipment that allows players to ask questions and receive entity responses through radio static.

## Original Acceptance Criteria

- [ ] Spirit Box equipment with static audio
- [ ] Voice activity detection triggers question mode
- [ ] Entity responds if Spirit Box evidence type
- [ ] Responses are distorted/unclear (ambiguity)
- [ ] Predefined response pool
- [ ] No response if entity doesn't have this evidence
- [ ] Network synced responses (all players hear)

## Technical Notes

**If Revisited:**
The Evidence Depth document suggests Spirit Box could work as a "relay" equipment where only the holder hears responses and must report them to the team. This creates single-witness evidence with high Cultist manipulation potential.

Key design consideration: Should responses be audible to all (high trust) or only to holder (low trust, Cultist opportunity)?

## Out of Scope (Original)

- False responses (Cultist contamination)
- Voice recognition for specific questions
