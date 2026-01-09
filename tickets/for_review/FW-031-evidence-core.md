---
id: FW-031
title: "Create core evidence system architecture"
epic: EVIDENCE
priority: high
estimated_complexity: large
dependencies: [FW-002, FW-023]
created: 2026-01-07
updated: 2026-01-08
---

## Description

Build the core evidence system architecture that manages evidence categories, reading quality, collection, and tracking. This is the foundation for all investigation gameplay.

**Design Philosophy** (from Evidence_Depth.pdf):
- Evidence is definitive when collected properly
- Ambiguity comes from trust and conditions, not RNG
- The Cultist hides in the space between "I messed up" and "I lied"

## Acceptance Criteria

### Evidence Categories
- [x] `EvidenceCategory` enum: READILY_APPARENT, EQUIPMENT_DERIVED, TRIGGERED_TEST, BEHAVIOR_BASED
- [x] Each evidence type assigned to exactly one category

### Evidence Types (8 total)
- [x] `EvidenceType` enum with all 8 types:
  - FREEZING_TEMPERATURE (Equipment-Derived)
  - EMF_SIGNATURE (Equipment-Derived)
  - PRISM_READING (Equipment-Derived, Cooperative)
  - AURA_PATTERN (Equipment-Derived, Cooperative)
  - GHOST_WRITING (Triggered Test)
  - VISUAL_MANIFESTATION (Readily-Apparent)
  - PHYSICAL_INTERACTION (Readily-Apparent)
  - HUNT_BEHAVIOR (Behavior-Based)

### Reading Quality System
- [x] `ReadingQuality` enum: STRONG, WEAK
- [x] Strong readings = definitive evidence (proper conditions)
- [x] Weak readings = suggestive only (suboptimal conditions)
- [x] Quality factors: proximity, timing, stability, entity activity state

### Trust Dynamics
- [x] `TrustLevel` enum: UNFALSIFIABLE, HIGH, VARIABLE, LOW, SABOTAGE_RISK
- [x] Each evidence type has associated trust level
- [x] Trust level affects UI presentation on evidence board

### EvidenceManager Autoload
- [x] Singleton for tracking all collected evidence
- [x] `evidence_collected` signal with evidence data
- [x] `evidence_contested` signal when conflicting reports
- [x] Query methods: get_evidence_by_type(), get_evidence_by_collector()
- [x] Server-authoritative evidence state

### Evidence Resource
- [x] `Evidence` Resource class with:
  - type: EvidenceType
  - category: EvidenceCategory
  - quality: ReadingQuality
  - collector_id: int (player peer ID)
  - location: Vector3
  - timestamp: float
  - trust_level: TrustLevel
  - verification_state: VerificationState (UNVERIFIED, VERIFIED, CONTESTED)

### Network Sync
- [x] Evidence collection RPCs (server-authoritative)
- [x] Evidence state replication to all clients
- [x] Late-join sync for evidence board state

## Technical Notes

**Category Distribution Target:**
- Readily-Apparent: 25% (2/8)
- Equipment-Derived: 50% (4/8) - with varied trust dynamics
- Triggered Tests: 12.5% (1/8)
- Behavior-Based: 12.5% (1/8)

**Reading Quality Conditions:**
- Strong: During active manifestation, close proximity, stable positioning
- Weak: Residual energy, at distance, while moving

**Trust Level Mapping:**
| Evidence Type | Trust Level | Cultist Risk |
|---------------|-------------|--------------|
| Hunt Behavior | UNFALSIFIABLE | None |
| EMF, Thermometer | HIGH | Low (shared display) |
| Visual, Physical | HIGH | Omission only |
| Aura Pattern | VARIABLE | Imager can lie |
| Prism Reading | LOW | Both can lie |
| Ghost Writing | SABOTAGE_RISK | Setup corruption |

## Out of Scope

- Individual equipment implementations (FW-032 through FW-040)
- Evidence board UI (FW-035)
- Cross-verification system (FW-036)
- Cultist contamination abilities (FW-052)

## Implementation Notes

### Files Created

| File | Purpose |
|------|---------|
| `src/evidence/evidence_enums.gd` | EvidenceEnums class with all enums and static helper methods |
| `src/evidence/evidence.gd` | Evidence Resource class for collected evidence |
| `src/evidence/evidence_manager.gd` | EvidenceManager autoload for collection/tracking |
| `tests/test_evidence.gd` | 42 unit tests for Evidence resource |
| `tests/test_evidence_enums.gd` | 51 unit tests for EvidenceEnums helpers |
| `tests/test_evidence_manager.gd` | 47 unit tests for EvidenceManager |

### EventBus Updates

Added 3 new signals:
- `evidence_collected(evidence_uid: String, evidence_data: Dictionary)`
- `evidence_verification_changed(evidence_uid: String, new_state: int)`
- `evidence_contested(evidence_uid: String, contester_id: int)`

### Testing Commands

```bash
# Run all evidence tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_evidence.gd -gtest=test_evidence_enums.gd -gtest=test_evidence_manager.gd -gexit

# Lint evidence source files
gdlint src/evidence/
```

### Test Results

All 531 project tests pass (140 new tests for evidence system):
- test_evidence.gd: 42/42 passed
- test_evidence_enums.gd: 51/51 passed
- test_evidence_manager.gd: 47/47 passed

### Key Design Decisions

1. **EvidenceEnums uses class_name** - Centralized enums with static helpers for type-safe access
2. **Evidence extends Resource** - Serializable for network sync and persistence
3. **EvidenceManager extends Node** (no class_name) - Autoload pattern for singleton access
4. **Server-authoritative** - Clients request collection, server validates and broadcasts
5. **Verification system** - Supports UNVERIFIED → VERIFIED/CONTESTED states for cross-verification
6. **Cooperative evidence support** - Tracks both primary and secondary collectors
