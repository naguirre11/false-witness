---
id: FW-035d
title: "Evidence Board Entity Possibility Matrix"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-035a, FW-041]
parent: FW-035
created: 2026-01-08
---

## Description

Create the entity possibility matrix that shows all possible entities and which evidence types rule them out. This is the core deduction UI where players narrow down the entity type.

## Acceptance Criteria

- [ ] Shows all possible entities as rows
- [ ] Columns for each evidence type
- [ ] Checkmarks for evidence types each entity can produce
- [ ] Entities visually eliminated as evidence rules them out (strikethrough/fade)
- [ ] Remaining possibilities highlighted
- [ ] Clear "possible" vs "eliminated" distinction

## Technical Notes

**Entity Data Source:**
Depends on FW-041 (Entity Core) for entity definitions. May need stub data until entities are implemented.

**Elimination Logic:**
- If EMF 5 collected, eliminate entities without EMF_SIGNATURE
- If Freezing Temps collected, eliminate entities without FREEZING_TEMPERATURE
- Entity must match ALL collected evidence to remain possible

**Grid Layout:**
- Rows: Entity names (Phantom, Banshee, Demon, etc.)
- Columns: Evidence types
- Cells: Check (entity can produce) or X (entity cannot)

**Updates:**
Matrix updates live as evidence is collected. Use signals from EvidenceManager.

## Out of Scope

- Entity definitions (FW-041)
- Voting/identification submission
- Confidence scoring
