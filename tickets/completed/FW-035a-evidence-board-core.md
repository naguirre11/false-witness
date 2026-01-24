---
id: FW-035a
title: "Evidence Board Core UI"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
parent: FW-035
created: 2026-01-08
---

## Description

Build the core evidence board UI panel that displays all 8 evidence types organized by category. This provides the foundational data display for the evidence system.

## Acceptance Criteria

- [x] Create EvidenceBoard scene extending Control
- [x] Display all 8 evidence types organized by category:
  - **Equipment-Derived:** EMF Signature, Freezing Temp, Prism Reading, Aura Pattern
  - **Readily-Apparent:** Visual Manifestation, Physical Interaction
  - **Triggered Test:** Ghost Writing
  - **Behavior-Based:** Hunt Behavior
- [x] Each evidence type shows: icon (placeholder), name, collection status (none/collected)
- [x] Evidence board accessible via hotkey (Tab) during investigation phase
- [x] Evidence board always visible during DELIBERATION phase
- [x] Basic styling consistent with game aesthetic (dark theme)

## Technical Notes

**Architecture:**
- `EvidenceBoard` (Control) - Main panel
- `EvidenceCategoryRow` (HBoxContainer) - Groups evidence by category
- `EvidenceSlot` (Control) - Individual evidence display

**Integration with EvidenceManager:**
- Connect to `EvidenceManager.evidence_collected` signal
- Query `EvidenceManager.get_collected_evidence()` for current state

**Placeholder Assets:**
- Use simple geometric shapes for evidence icons initially
- Color-code by category for quick visual distinction

## Out of Scope

- Trust level visualization (FW-035b)
- Collector attribution (FW-035c)
- Entity possibility matrix (FW-035d)
- Network synchronization (handled by EvidenceManager)

## Implementation Notes

**Files Created:**
- `src/ui/evidence_board.gd` - Main evidence board panel
- `src/ui/evidence_slot.gd` - Individual evidence slot component
- `scenes/ui/evidence_board.tscn` - Evidence board scene
- `scenes/ui/evidence_slot.tscn` - Evidence slot scene
- `tests/test_evidence_board.gd` - 20 tests for EvidenceBoard
- `tests/test_evidence_slot.gd` - 14 tests for EvidenceSlot
- `gdlintrc` - Lint configuration (generated from defaults, max-public-methods raised to 50)

**Input Action Added:**
- `toggle_evidence_board` (Tab key) in project.godot

**Architecture:**
- `EvidenceBoard` extends Control, instantiates `EvidenceSlot` for each evidence type
- Categories are built dynamically from `EVIDENCE_BY_CATEGORY` constant
- Connects to `EvidenceManager.evidence_collected` and `evidence_cleared` signals
- Listens to `EventBus.game_state_changed` for DELIBERATION phase handling
- Uses `%UniqueNodeName` pattern for scene references

**Test Evidence:**
```powershell
# Run tests
& 'C:\Users\vinco\Projects\tooling\Godot_v4.4.1-stable_win64_console.exe' --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_evidence_board.gd -gtest=res://tests/test_evidence_slot.gd -gexit
```
Result: 34 tests passing
