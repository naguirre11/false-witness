---
id: FW-036a
title: "Verification Rules Engine"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031, FW-035a]
created: 2026-01-09
parent: FW-036
---

## Description

Implement the core verification rules engine that determines how evidence gets verified based on trust levels. This is the foundational logic for the cross-verification system.

**Core Mechanic:** Different trust levels have different verification requirements. Higher trust evidence is easier to verify; lower trust requires more rigorous cross-checking.

## Acceptance Criteria

### Verification State Management
- [x] `VerificationManager` autoload created to handle verification logic
- [x] Verification attempts trigger validation against trust-level rules
- [x] Verification state changes emit appropriate signals

### UNFALSIFIABLE Verification (Hunt Behavior)
- [x] Auto-verified when 2+ players witness the same hunt event
- [x] Cannot be manually contested (behavioral ground truth)
- [x] Single-witness events remain UNVERIFIED with "single_witness" metadata

### HIGH Trust Verification (EMF, Thermometer, Visual, Physical)
- [x] Verified when 2+ players report same evidence type in same location (within tolerance)
- [x] Location tolerance: configurable, default 5 meters
- [x] Time tolerance: configurable, default 30 seconds between reports

### VARIABLE Trust Verification (Aura Pattern)
- [x] Requires third player to verify (watched the Imager's screen)
- [x] OR cross-referenced with behavioral evidence (links to FW-036b)
- [x] Verification records the verifier's peer_id

### LOW Trust Verification (Prism Reading)
- [x] Requires repeat reading with different operators
- [x] OR cross-referenced with behavioral evidence (links to FW-036b)
- [x] Tracks which operators have contributed readings

### SABOTAGE_RISK Verification (Ghost Writing)
- [x] Requires witness to both setup AND result collection
- [x] Buddy system tracking: `setup_witness_id` and `result_witness_id`
- [x] Sabotage detection flags: `book_moved`, `wrong_room`, `setup_broken`

### Signals
- [x] `verification_attempted(evidence: Evidence, verifier_id: int, success: bool)`
- [x] `auto_verified(evidence: Evidence, witness_ids: Array[int])`
- [x] `verification_rule_failed(evidence: Evidence, reason: String)`

## Technical Notes

**Data Structure Additions:**
Evidence class may need additional metadata fields:
- `witness_ids: Array[int]` - Players who witnessed this evidence
- `setup_witness_id: int` - For Ghost Writing setup witness
- `result_witness_id: int` - For Ghost Writing result witness
- `sabotage_flags: Dictionary` - Sabotage detection metadata

**Integration Points:**
- EvidenceManager calls VerificationManager when `verify_evidence()` is invoked
- VerificationManager validates against trust-level rules before allowing state change
- EvidenceBoard UI reflects verification state (already implemented in FW-035c)

**Location Matching:**
For HIGH trust evidence, use `Vector3.distance_to()` with configurable tolerance.

## Out of Scope

- Behavioral conflict detection (FW-036b)
- Evidence staleness/timing (FW-036c)
- Evidence board UI integration (already done in FW-035c)
- Cultist contamination abilities (FW-052)

## Testing Requirements

- Unit tests for each trust level's verification rules
- Integration tests with EvidenceManager
- Edge cases: self-verification prevention, location edge cases, timing edge cases

## Implementation Notes

### Files Created/Modified
- `src/evidence/verification_manager.gd` - New VerificationManager autoload
- `src/evidence/evidence.gd` - Added witness tracking fields
- `src/evidence/evidence_manager.gd` - Integrated VerificationManager
- `project.godot` - Added VerificationManager autoload
- `tests/test_verification_manager.gd` - 38 unit tests

### Evidence Class Additions
```gdscript
# Witness Tracking
@export var witness_ids: Array[int] = []
@export var verifier_id: int = 0

# Ghost Writing Witnesses
@export var setup_witness_id: int = 0
@export var result_witness_id: int = 0

# Sabotage Detection
@export var sabotage_flags: Dictionary = {}

# Verification Metadata
@export var verification_metadata: Dictionary = {}
```

### VerificationManager API
```gdscript
# Core verification
func try_verify(evidence: Evidence, verifier_id: int) -> Dictionary
func try_contest(evidence: Evidence, contester_id: int) -> Dictionary

# Witness management
func register_witness(evidence: Evidence, witness_id: int) -> void
func register_operator(evidence: Evidence, operator_id: int) -> void
func set_ghost_writing_witnesses(evidence, setup, result) -> void
func report_sabotage(evidence: Evidence, flag: String) -> void
```

### Test Evidence
```bash
# Run all tests (749 tests)
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit

# Run verification manager tests only (38 tests)
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_verification_manager.gd -gexit
```

### Architectural Decision
Separate VerificationManager autoload pattern chosen over extending EvidenceManager:
- Clean separation of concerns
- EvidenceManager handles collection/storage
- VerificationManager handles trust-level rules
- EvidenceManager delegates to VerificationManager for validation
