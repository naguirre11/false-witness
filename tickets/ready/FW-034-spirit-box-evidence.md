---
id: FW-034
title: "Implement Spirit Box and voice response evidence"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
created: 2026-01-07
---

## Description

Create the Spirit Box equipment that allows players to ask questions and receive entity responses through radio static.

## Acceptance Criteria

- [ ] Spirit Box equipment with static audio
- [ ] Voice activity detection triggers question mode
- [ ] Entity responds if Spirit Box evidence type
- [ ] Responses are distorted/unclear (ambiguity)
- [ ] Predefined response pool
- [ ] No response if entity doesn't have this evidence
- [ ] Network synced responses (all players hear)

## Technical Notes

Collection method: Player asks questions aloud (requires voice chat). Spirit Box detects voice activity and entity may respond.

Ambiguity: Responses can be unclear or partial, requiring interpretation.

## Out of Scope

- False responses (Cultist contamination)
- Voice recognition for specific questions
