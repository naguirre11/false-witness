---
id: FW-035c
title: "Evidence Board Collector Attribution & Verification"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-035a]
parent: FW-035
created: 2026-01-08
---

## Description

Add collector attribution and verification state display to evidence entries. Shows who collected each piece of evidence and whether it has been independently verified.

## Acceptance Criteria

- [x] Shows which player(s) collected each evidence
- [x] Hover/tooltip shows timestamp and location of collection
- [x] Multiple collectors shown for verified evidence (stacked avatars or list)
- [x] Verification states with distinct visuals:
  - **Unverified** (single checkmark): One player collected
  - **Verified** (double checkmark): Multiple independent confirmations
  - **Contested** (exclamation mark): Conflicting reports exist
- [x] Visual distinction clear at a glance (icon + color)

## Technical Notes

**Data Source:**
`EvidenceEntry` resource stores `collector_id`, `timestamp`, and `location`. This ticket adds UI to display that data.

**Verification Logic:**
- Unverified: Single collector
- Verified: 2+ collectors with consistent readings
- Contested: 2+ collectors with different readings

**Player Display:**
Use player color or initial for quick identification. Full name on hover.

## Out of Scope

- Entity possibility matrix (FW-035d)
- Network sync of attribution (handled by EvidenceManager)

## Implementation Notes

**Files Modified:**
- `src/ui/evidence_slot.gd` - Added verification icon, collector row, enhanced tooltips
- `src/ui/evidence_board.gd` - Pass Evidence objects to slots, connect to verification_changed signal
- `scenes/ui/evidence_slot.tscn` - Added VerificationIcon label, CollectorRow container, adjusted layout
- `tests/test_evidence_slot.gd` - Added 20 new tests for FW-035c functionality

**New UI Elements:**
- `VerificationIcon` (Label) - Shows checkmark/double-checkmark/warning based on state
- `CollectorRow` (HBoxContainer) - Shows colored circles with player initials

**Verification State Visuals:**
- UNVERIFIED: Gray single checkmark (✓)
- VERIFIED: Green double checkmark (✓✓)
- CONTESTED: Orange warning symbol (⚠)

**Collector Display:**
- Colored circular indicator with player initial (P0-P9)
- Colors cycle through 8 predefined colors based on peer_id
- Primary and secondary collectors shown for cooperative evidence

**Tooltip Contents (when evidence is collected):**
- Trust level explanation
- Verification status
- Collector name(s)
- Timestamp (MM:SS format)
- Location coordinates

**Test Evidence:**
```powershell
# Run tests
& '../tooling/Godot_v4.4.1-stable_win64_console.exe' --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_evidence_slot.gd -gtest=res://tests/test_evidence_board.gd -gexit
```
Result: 45 evidence slot tests passing, 20 evidence board tests passing
