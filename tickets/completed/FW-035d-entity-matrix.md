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

---

## Implementation Notes (Ralph PRD - 2026-01-21)

**Completed by Ralph in cross-verification PRD (stories FW-035-08, FW-035-09)**

### Files Created/Modified
- `src/ui/entity_matrix.gd` (313 lines) - EntityMatrix component
- `scenes/ui/entity_matrix.tscn` - Scene file
- `src/evidence/evidence_manager.gd` - Entity elimination logic added

### What Was Implemented
- EntityMatrix UI component showing entities vs evidence types grid
- Checkmarks for evidence types each entity produces
- Eliminated entities grayed out based on collected evidence
- Remaining possibilities highlighted
- Updates from `EvidenceManager.eliminations_changed` signal
- 8 entities defined: Phantom, Banshee, Revenant, Shade, Poltergeist, Wraith, Mare, Demon
- `ENTITY_EVIDENCE_MAP` with 3 evidence types per entity

### Acceptance Criteria Status
- [x] Shows all possible entities as rows
- [x] Columns for each evidence type
- [x] Checkmarks for evidence types each entity can produce
- [x] Entities visually eliminated as evidence rules them out
- [x] Remaining possibilities highlighted
- [x] Clear "possible" vs "eliminated" distinction

### Testing
- Integration tests in `tests/integration/test_evidence_board_integration.gd` (27 tests)

### Related Commits
- 90b29c3: FW-035-08 - Create entity possibility matrix
- 6c3b885: FW-035-09 - Implement entity elimination logic in EvidenceManager
