---
id: FW-062
title: "Implement deliberation phase mechanics"
epic: FLOW
priority: high
estimated_complexity: medium
dependencies: [FW-061, FW-035]
created: 2026-01-07
---

## Description

Create the deliberation phase where the team discusses findings and submits their final entity identification. Evidence board is always visible, and players make their final decision.

## Acceptance Criteria

- [ ] Deliberation phase lasts 3-5 minutes
- [ ] All players teleported to safe deliberation area
- [ ] Evidence board always visible
- [ ] Entity not active during deliberation
- [ ] Any player can propose identification
- [ ] Proposal triggers vote UI
- [ ] Majority approval submits identification
- [ ] Timer countdown visible
- [ ] Auto-submission of most recent proposal at timer end (or loss if none)

## Technical Notes

Safe area prevents entity kills during discussion. Voice chat remains active.

Decision: Per GDD, if no submission by timer, Cultist wins.

## Out of Scope

- Chat/note-taking features
- Evidence annotation
