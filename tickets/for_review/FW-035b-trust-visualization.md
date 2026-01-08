---
id: FW-035b
title: "Evidence Board Trust Level Visualization"
epic: EVIDENCE
priority: high
estimated_complexity: small
dependencies: [FW-035a]
parent: FW-035
created: 2026-01-08
---

## Description

Add trust level indicators and reading quality display to the evidence board. Visual communication of evidence trustworthiness is critical for player decision-making.

## Acceptance Criteria

- [x] Visual indicator for trust level of each evidence type:
  - UNFALSIFIABLE (gold border) - Hunt Behavior
  - HIGH (green border) - EMF, Thermometer, Visual, Physical
  - VARIABLE (yellow border) - Aura Pattern
  - LOW (orange border) - Prism Reading
  - SABOTAGE_RISK (red outline) - Ghost Writing
- [x] Tooltip on hover explaining trust implications
- [x] Strong readings shown with solid icon
- [x] Weak readings shown with faded/semi-transparent icon
- [x] Quality affects visual weight in the UI

## Technical Notes

**Trust Level Mapping:**
Trust levels come from `EvidenceType` enum in the evidence system. Map these to visual styles.

**Tooltip Content:**
- UNFALSIFIABLE: "Cannot be fabricated - behavioral ground truth"
- HIGH: "Equipment-verified, difficult to fake"
- VARIABLE: "Requires cooperation, verify with second reading"
- LOW: "Easy to misreport, cross-reference recommended"
- SABOTAGE_RISK: "Cultist can directly contaminate"

## Out of Scope

- Collector attribution (FW-035c)
- Entity possibility matrix (FW-035d)

## Implementation Notes

**Files Changed:**
- `src/ui/evidence_slot.gd`: Added trust level visualization with colored borders, tooltips, and quality-based icon alpha
- `scenes/ui/evidence_slot.tscn`: Added Border panel node for trust level styling
- `tests/test_evidence_slot.gd`: Added 11 new tests covering trust visualization

**Implementation Details:**
- Trust colors defined as constants: GOLD (unfalsifiable), GREEN (high), YELLOW (variable), ORANGE (low), RED (sabotage risk)
- Border styling uses `StyleBoxFlat` with 2px border width and 4px corner radius
- Tooltips set on the invisible button overlay (captures hover over entire slot)
- Icon alpha: 1.0 for strong readings, 0.6 for weak readings, 0.3 when not collected
- Fixed bug where `set_collected()` wasn't updating icon - now calls `_update_icon()` after state change

**Test Commands:**
```bash
# Run evidence slot tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gprefix=test_evidence_slot -gsuffix=.gd -gexit

# All 691 tests pass
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```
