---
id: FW-040a
title: "Manifestation Evidence Capture"
epic: EVIDENCE
priority: high
estimated_complexity: small
dependencies: [FW-031, FW-041, FW-044]
created: 2026-01-10
parent: FW-040
---

## Description

Connect entity manifestation events to the evidence system. When an entity manifests and players witness it, VISUAL_MANIFESTATION evidence should be automatically generated. This enables the Phantom entity (and future entities with this evidence type) to produce collectible evidence.

## Acceptance Criteria

### Witness Detection
- [x] Server tracks which players are in range when entity manifests
- [x] Witness range configurable (default: players within 15m with line of sight)
- [x] Witness list attached to generated evidence

### Evidence Generation
- [x] VISUAL_MANIFESTATION evidence auto-generated when manifestation ends
- [x] Only generated if at least one witness was present
- [x] Evidence location set to entity position at manifestation start
- [x] Quality: STRONG if multiple witnesses, WEAK if single witness

### Trust Mechanics Integration
- [x] Multi-witness evidence gets HIGH trust (harder for Cultist to dispute)
- [x] Single-witness evidence remains disputable
- [x] Witness IDs stored in evidence metadata for verification

### Network Sync
- [x] Server-authoritative evidence generation
- [x] All clients notified of new VISUAL_MANIFESTATION evidence
- [x] Witness list synced to clients for UI display

## Technical Notes

**Integration Points:**
- Entity.gd `entity_visibility_changed` signal → trigger evidence generation
- Entity.gd `_state_changed` signal → detect manifestation end
- EvidenceManager.gd `collect_evidence()` → store with witness metadata

**Witness Tracking Implementation:**
- Use Entity's existing `_get_alive_players()` method
- Filter by range + line of sight (similar to Phantom's `_has_line_of_sight_to`)
- Track witnesses throughout manifestation duration (anyone who saw it)

**Evidence Metadata Extension:**
- Add `witness_ids: Array[int]` to Evidence class
- Update `to_network_dict()` / `from_network_dict()` to include witnesses

## Out of Scope

- Different manifestation visual types (full body, partial, etc.)
- Photo capture / camera equipment
- Physical interaction events
- Manifestation types beyond basic visibility

## Implementation Notes (2026-01-10)

### Changes Made

**Entity.gd:**
- Added `manifestation_witnessed(witness_ids: Array, location: Vector3)` signal
- Added witness tracking state: `_manifestation_witnesses`, `_witness_check_timer`, `_manifestation_start_position`
- Added constants: `WITNESS_RANGE = 15.0`, `WITNESS_CHECK_INTERVAL = 0.5`
- Added `_update_manifestation_witnesses()` to detect witnesses during manifestation
- Added `_has_line_of_sight_to()` for line-of-sight checks
- Modified `start_manifestation()` to reset witnesses and record start position
- Modified `end_manifestation()` to emit `manifestation_witnessed` signal
- Modified `_process_manifesting()` to periodically check for witnesses

**EntityManager.gd:**
- Connected `manifestation_witnessed` signal when spawning entities
- Added `_on_entity_manifestation_witnessed()` handler to generate evidence
- Quality logic: single witness = WEAK, multiple witnesses = STRONG
- Uses first witness as collector, adds all witnesses to evidence

**Evidence.gd:**
- Already had `witness_ids: Array[int]` field (from previous work)
- Already had network serialization support

### Test Commands

```bash
# Run all tests
../tooling/Godot_v4.4.1-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

# Run specific test files
../tooling/Godot_v4.4.1-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=test_entity.gd -gexit
```

### Test Results

All 43 test files pass. New tests added:
- `test_entity.gd`: 10 new manifestation witness tracking tests
- `test_entity_manager.gd`: 4 new manifestation evidence tests
