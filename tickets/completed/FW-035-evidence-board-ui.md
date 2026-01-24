---
id: FW-035
title: "Create shared evidence board UI"
epic: EVIDENCE
priority: high
estimated_complexity: small
dependencies: [FW-031]
created: 2026-01-07
updated: 2026-01-21
---

## Description

Build the central shared UI where all collected evidence is displayed. Shows evidence organized by category and trust level, enabling cross-verification and trust assessment during deliberation.

**Status Update (2026-01-21):** Core implementation is complete. Evidence board, slots, detail popup, and entity matrix all exist and function. Remaining work is polish and design token integration.

## Acceptance Criteria

### Evidence Display (8 Types)
- [x] Display all 8 evidence types organized by category:
  - **Equipment-Derived:** EMF Signature, Freezing Temp, Prism Reading, Aura Pattern
  - **Readily-Apparent:** Visual Manifestation, Physical Interaction
  - **Triggered Test:** Ghost Writing
  - **Behavior-Based:** Hunt Behavior
- [x] Each evidence type shows: icon, name, collection status

### Trust Level Indicators
- [x] Visual indicator for trust level of each evidence type:
  - UNFALSIFIABLE (gold border) - Hunt Behavior
  - HIGH (green) - EMF, Thermometer, Visual, Physical
  - VARIABLE (yellow) - Aura Pattern
  - LOW (orange) - Prism Reading
  - SABOTAGE_RISK (red outline) - Ghost Writing
- [x] Tooltip explaining trust implications

### Reading Quality Display
- [x] Strong readings shown with solid icon
- [x] Weak readings shown with faded/dashed icon
- [ ] Quality affects how evidence weighs in entity elimination (needs EvidenceManager integration)

### Collector Attribution
- [x] Shows which player(s) collected each evidence
- [x] Hover for timestamp and location (via detail popup)
- [x] Multiple collectors shown for verified evidence

### Verification States
- [x] **Unverified** (single checkmark): One player collected
- [x] **Verified** (double checkmark): Multiple independent confirmations
- [x] **Contested** (exclamation): Conflicting reports exist
- [x] Visual distinction for each state

### Entity Possibility Matrix
- [x] Shows all possible entities as rows
- [x] Columns for each evidence type
- [x] Checkmarks for entity's known evidence
- [x] Entities eliminated as evidence rules them out
- [x] Remaining possibilities highlighted

### Accessibility
- [x] Evidence board accessible via hotkey during investigation (Tab)
- [x] Always visible during DELIBERATION phase
- [ ] Synced across all players in real-time (needs network integration)
- [x] Keyboard navigation support (arrow keys, Enter)

### Polish (Remaining Work)
- [ ] Refactor to use DesignTokens (see FW-087)
- [ ] Add fade-in animation on open
- [ ] Add hover animations on slots

## Technical Notes

**Files Implemented:**
- `src/ui/evidence_board.gd` - Main board controller with category grid
- `src/ui/evidence_slot.gd` - Individual slot with trust/verification display
- `src/ui/evidence_detail_popup.gd` - Detail modal with timestamp, location, conflicts
- `src/ui/entity_matrix.gd` - Entity-evidence correlation grid

**Trust Gradient Display:**
The board visually communicates trust levels via color-coded borders (gold/green/yellow/orange/red).

**Deliberation Focus:**
During deliberation, the board is force-visible. Players discuss which evidence is verified vs single-witness.

## Out of Scope

- Voting UI (FW-062)
- Entity identification submission (FW-062)
- Chat/notes integration
- Evidence annotation
