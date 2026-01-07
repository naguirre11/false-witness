---
id: FW-053
title: "Implement Cultist discovery and post-discovery play"
epic: CULTIST
priority: medium
estimated_complexity: medium
dependencies: [FW-052, FW-061]
created: 2026-01-07
---

## Description

Create the voting system to identify the Cultist and define how discovered Cultists continue to participate. Unlike most traitor games, discovery doesn't end the Cultist's influence.

## Acceptance Criteria

- [ ] Emergency vote can be called during investigation
- [ ] Voting UI with player selection
- [ ] Majority required to vote out
- [ ] Voting out Cultist: Investigators bonus win condition
- [ ] Voting out Innocent: Cultist wins immediately
- [ ] Discovered Cultist restrictions:
  - Can observe and discuss
  - Cannot collect evidence
  - Cannot use remaining abilities
  - Previously collected evidence becomes suspect
- [ ] Discovered status visible to all players

## Technical Notes

Per GDD: "Identified traitors retain influence and can still cast doubt."

Vote timing: Costs investigation time, entity continues escalating.

## Out of Scope

- Voting history tracking
- Evidence tampering after discovery
