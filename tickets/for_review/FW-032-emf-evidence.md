---
id: FW-032
title: "Implement EMF Reader equipment"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031]
created: 2026-01-07
updated: 2026-01-08
---

## Description

Create the EMF Reader equipment for detecting electromagnetic signatures. This is a solo-operation tool with a shared display (visible to nearby players), making it high-trust evidence.

**Trust Dynamic:** Solo — Low Risk (display visible to all nearby)

## Acceptance Criteria

### Equipment Implementation
- [x] EMF Reader as EquipmentItem extending equipment system
- [ ] 3D model with visible LED display (DEFERRED - requires art assets)
- [x] Display shows current EMF level (1-5)
- [ ] Display visible to all nearby players (shared display) (DEFERRED - visual system)

### EMF Detection
- [x] EMF levels 1-5 based on proximity to entity activity
- [x] Level 5 = definitive evidence (EMF_SIGNATURE type)
- [x] Levels 1-4 = ambient/residual (not evidence)
- [x] Detection range and falloff curves

### Reading Quality System
- [x] **Strong Reading**: During active manifestation, close proximity (<2m), player stationary
- [x] **Weak Reading**: Residual energy, at distance (>5m), player moving
- [x] Quality affects evidence confidence on board

### Triangulation Support
- [x] EMF shows direction indicator (compass needle effect)
- [x] Intensity + direction allows two players to triangulate entity location
- [x] Direction accuracy decreases with distance

### Audio/Visual Feedback
- [x] Escalating beep frequency with EMF level (via EventBus signals)
- [ ] LED color change (green→yellow→red) (DEFERRED - visual system)
- [x] Distinct audio for Level 5 spike (via EventBus signal)

### Network Sync
- [x] EMF readings server-authoritative
- [x] Display state synced to nearby players
- [x] Evidence registration with EvidenceManager

## Technical Notes

**Triangulation Mechanic:**
Two players take readings from different positions. Intersection of reported directions = entity location. This creates cooperative gameplay without requiring two players on one device.

**Reading Quality Factors:**
- Proximity to entity
- Entity activity state (manifesting vs dormant)
- Player movement (stationary = better)
- Time held on target

**Cultist Consideration:**
With shared display, Cultist cannot easily lie about EMF readings when others are present. However, they can:
- Report false direction for triangulation
- Claim readings when alone that didn't happen
- Distract team from checking

## Out of Scope

- False EMF injection (Cultist ability - FW-052)
- EMF zones/sources system (part of entity AI - FW-041)

---

## Implementation Notes (2026-01-08)

### Files Created
- `src/equipment/emf_reader.gd` - EMFReader class extending Equipment
- `src/equipment/emf_source.gd` - EMFSource mock for testing (and entity integration)
- `tests/test_emf_reader.gd` - 35 unit tests for EMFReader
- `tests/test_emf_source.gd` - 29 unit tests for EMFSource

### Implementation Details

**EMF Detection Algorithm:**
- Distance thresholds: Level 5 (<2m), Level 4 (<4m), Level 3 (<6m), Level 2 (<8m), Level 1 (<10m)
- Activity scaling: Higher source activity extends effective range
- Detection range: 12m (configurable)

**Reading Quality:**
- STRONG: Distance <2m AND stationary for 1.5+ seconds
- WEAK: All other conditions

**Direction Indicator:**
- Points toward nearest EMF source
- Accuracy degrades with distance (configurable falloff)
- Range: 15m maximum

**Evidence Collection:**
- Level 5 triggers automatic evidence collection via EvidenceManager
- Includes reading quality (STRONG/WEAK)
- Prevents spam collection (once per activation)

**Mock EMF Sources:**
- EMFSource can be placed in scenes for testing
- Supports manual activity control (`set_activity()`, `trigger_spike()`)
- Auto-pulse mode for periodic activity spikes
- Added to "emf_source" group for detection

### Testing Evidence

```powershell
# Run EMF tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_emf_reader.gd -gexit

# All tests pass: 35/35 EMF Reader, 29/29 EMF Source
```

### Deferred Work
- 3D model with LED display (requires art assets)
- Visual display sync to nearby players (UI/visual system)
- LED color changes (visual system)

These will be addressed when the visual/UI systems are implemented.
