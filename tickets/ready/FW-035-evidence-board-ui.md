---
id: FW-035
title: "Create shared evidence board UI"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
created: 2026-01-07
---

## Description

Build the central shared UI where all collected evidence is displayed. Shows what evidence has been found and who collected it, enabling cross-verification and trust assessment.

## Acceptance Criteria

- [ ] Evidence board accessible via hotkey during investigation
- [ ] Always visible during DELIBERATION phase
- [ ] Shows all 8 evidence types as columns
- [ ] Shows which player collected each piece
- [ ] Visual indicator for verified vs unverified evidence
- [ ] Entity possibility matrix that updates as evidence collected
- [ ] Highlight evidence that matches remaining possible entities
- [ ] Synced across all players in real-time

## Technical Notes

Entity matrix: As evidence is collected, eliminate entities that don't match. Shows remaining possibilities.

Trust layer: Players can see WHO collected each piece - relevant when Cultist is suspected.

## Out of Scope

- Voting UI
- Entity identification submission
- Chat/notes on evidence
