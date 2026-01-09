---
id: FW-035
title: "Create shared evidence board UI"
epic: EVIDENCE
priority: high
estimated_complexity: large
dependencies: [FW-031]
is_epic: true
sub_tickets: [FW-035a, FW-035b, FW-035c, FW-035d]
created: 2026-01-07
updated: 2026-01-08
---

## Description

Build the central shared UI where all collected evidence is displayed. Shows evidence organized by category and trust level, enabling cross-verification and trust assessment during deliberation.

**Note:** This ticket has been split into sub-tickets for manageability:
- **FW-035a**: Evidence Board Core UI (display structure)
- **FW-035b**: Trust Level Visualization (trust indicators, quality display)
- **FW-035c**: Collector Attribution & Verification (who collected, verification states)
- **FW-035d**: Entity Possibility Matrix (deduction grid)

## Acceptance Criteria

### Evidence Display (8 Types)
- [ ] Display all 8 evidence types organized by category:
  - **Equipment-Derived:** EMF Signature, Freezing Temp, Prism Reading, Aura Pattern
  - **Readily-Apparent:** Visual Manifestation, Physical Interaction
  - **Triggered Test:** Ghost Writing
  - **Behavior-Based:** Hunt Behavior
- [ ] Each evidence type shows: icon, name, collection status

### Trust Level Indicators
- [ ] Visual indicator for trust level of each evidence type:
  - UNFALSIFIABLE (gold border) - Hunt Behavior
  - HIGH (green) - EMF, Thermometer, Visual, Physical
  - VARIABLE (yellow) - Aura Pattern
  - LOW (orange) - Prism Reading
  - SABOTAGE_RISK (red outline) - Ghost Writing
- [ ] Tooltip explaining trust implications

### Reading Quality Display
- [ ] Strong readings shown with solid icon
- [ ] Weak readings shown with faded/dashed icon
- [ ] Quality affects how evidence weighs in entity elimination

### Collector Attribution
- [ ] Shows which player(s) collected each evidence
- [ ] Hover for timestamp and location
- [ ] Multiple collectors shown for verified evidence

### Verification States
- [ ] **Unverified** (single checkmark): One player collected
- [ ] **Verified** (double checkmark): Multiple independent confirmations
- [ ] **Contested** (exclamation): Conflicting reports exist
- [ ] Visual distinction for each state

### Entity Possibility Matrix
- [ ] Shows all possible entities as rows
- [ ] Columns for each evidence type
- [ ] Checkmarks for entity's known evidence
- [ ] Entities eliminated as evidence rules them out
- [ ] Remaining possibilities highlighted

### Accessibility
- [ ] Evidence board accessible via hotkey during investigation
- [ ] Always visible during DELIBERATION phase
- [ ] Synced across all players in real-time
- [ ] Keyboard navigation support

## Technical Notes

**Trust Gradient Display:**
The board should visually communicate that not all evidence is equally trustworthy. Color-coding and icons help players quickly assess which evidence to scrutinize.

**Entity Elimination Logic:**
- Collect EMF 5 → eliminate entities without EMF_SIGNATURE
- Observe hunt behavior → eliminate entities with incompatible behavior
- Cross-reference equipment + behavior to catch lies

**Deliberation Focus:**
During deliberation, the board becomes the central focus. Players discuss:
- Which evidence is verified vs single-witness
- Which evidence came from suspected Cultist
- Does equipment evidence match behavioral observations?

## Out of Scope

- Voting UI (separate ticket)
- Entity identification submission
- Chat/notes integration
- Evidence annotation
