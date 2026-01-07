---
id: FW-061
title: "Implement win/loss conditions and match resolution"
epic: FLOW
priority: high
estimated_complexity: medium
dependencies: [FW-003, FW-031, FW-051]
created: 2026-01-07
---

## Description

Create the complete win/loss condition system that determines match outcomes. Multiple paths to victory for both teams.

## Acceptance Criteria

- [ ] Entity identification submission during DELIBERATION
- [ ] Majority vote required for submission
- [ ] Win condition checks:

**Investigators Win If:**
- [ ] Correctly identify entity type before time expires
- [ ] Correctly identify AND vote out Cultist (bonus)

**Cultist Wins If:**
- [ ] Team submits incorrect entity identification
- [ ] Time expires without identification
- [ ] Team votes out an innocent investigator

- [ ] Match end triggers RESULTS state
- [ ] Win/loss broadcast to all players

## Technical Notes

Entity identification: Team uses evidence board to narrow possibilities, then submits guess. Submission requires majority agreement.

Time limit: 15-20 minutes total investigation + deliberation.

## Out of Scope

- Results screen UI (separate ticket)
- XP/rewards calculation
