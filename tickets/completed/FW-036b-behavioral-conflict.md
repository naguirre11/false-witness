---
id: FW-036b
title: "Behavioral Conflict Detection (Gotcha System)"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-036a, FW-041]
created: 2026-01-09
parent: FW-036
---

## Description

Implement the behavioral conflict detection system - the "gotcha" moments where equipment evidence contradicts observed entity behavior. This is the primary mechanism for catching Cultist lies.

**Core Mechanic:** Hunt behavior is UNFALSIFIABLE ground truth. When equipment readings contradict observed behavior, someone made a mistake - or someone lied.

## Acceptance Criteria

### Conflict Detection Engine
- [ ] `BehavioralConflictDetector` class created (Resource or Node TBD)
- [ ] System compares equipment evidence against behavioral observations
- [ ] Conflicts trigger CONTESTED state with detailed explanation

### Behavioral Evidence Tracking
- [ ] Hunt behavior evidence records specific behavioral traits observed
- [ ] Traits include: `speed` (fast/normal/slow), `aggression` (high/medium/low), `visibility` (visible/flickering/invisible)
- [ ] Multiple witnesses' observations are aggregated

### Conflict Rules
- [ ] Prism "aggressive-red" conflicts with slow/passive hunt behavior
- [ ] Prism "passive-blue" conflicts with fast/aggressive hunt behavior
- [ ] Temperature evidence conflicts with entity type that doesn't affect temperature
- [ ] EMF level conflicts with entity type that has different EMF signature

### Conflict Resolution
- [ ] When conflict detected, evidence marked as CONTESTED
- [ ] Conflict explanation stored: `conflict_reason: String`
- [ ] Conflict identifies which evidence pieces are in conflict
- [ ] UI can display "This evidence conflicts with observed hunt behavior"

### Signals
- [ ] `behavioral_conflict_detected(equipment_evidence: Evidence, behavior_evidence: Evidence, reason: String)`
- [ ] `conflict_resolved(evidence: Evidence)` - If later evidence resolves conflict

### Integration with Verification
- [ ] Behavioral evidence can verify or contest other evidence
- [ ] VARIABLE and LOW trust evidence can be cross-referenced against behavior
- [ ] Conflict detection runs automatically when new evidence is collected

## Technical Notes

**Example Gotcha Scenario:**
```
Player A reports: Prism shows "aggressive-red"
Hunt happens: Entity moves slowly, doesn't pursue actively
System detects: Aggressive entity should move fast and pursue
Result: Prism reading marked CONTESTED
UI shows: "Conflicts with observed hunt behavior - entity showed slow, passive movement"
```

**Entity Type Dependencies:**
This system needs entity behavior data from FW-041. If entity system isn't ready, use mock behavior data for testing.

**Conflict Explanation Format:**
```gdscript
{
    "conflict_type": "prism_vs_behavior",
    "equipment_claim": "aggressive-red",
    "observed_behavior": "slow movement, passive pursuit",
    "conclusion": "Aggressive entities don't behave this way"
}
```

## Out of Scope

- Entity AI implementation (FW-041)
- Full entity type database
- Cultist deception tracking (FW-052)
- Vote-based conflict resolution

## Testing Requirements

- Mock entity behavior for testing without FW-041
- Test each conflict rule type
- Test that conflicts properly trigger CONTESTED state
- Test conflict explanation generation

---

## Implementation Notes (Ralph PRD - 2026-01-21)

**Completed by Ralph in cross-verification PRD (stories FW-036-08 through FW-036-13)**

### Files Created/Modified
- `src/evidence/conflict_detector.gd` (658 lines) - ConflictDetector class
- `src/ui/evidence_slot.gd` - Contested evidence styling
- `src/ui/evidence_detail_popup.gd` - Conflict display

### What Was Implemented

**ConflictDetector Class:**
- `BehaviorCategory` enum: PASSIVE, AGGRESSIVE, TERRITORIAL, MOBILE
- `ENTITY_BEHAVIOR_MAP`, `PRISM_SHAPE_BEHAVIOR_MAP`, `AURA_COLOR_BEHAVIOR_MAP`
- Hunt observation tracking with `start_hunt_tracking()`, `record_observation()`, `end_hunt_tracking()`
- Behavior categorization based on speed, aggression, targeting
- Automatic conflict detection when evidence collected
- `behavioral_conflict` signal when conflict detected
- Marks evidence as CONTESTED via `EvidenceManager.contest_evidence()`

**UI Updates:**
- Contested evidence shows orange highlight/border
- Exclamation mark icon on contested slots
- Conflict description displayed in evidence detail popup

### Acceptance Criteria Status
- [x] `ConflictDetector` class created (extends Node)
- [x] System compares equipment evidence against behavioral observations
- [x] Conflicts trigger CONTESTED state with detailed explanation
- [x] Hunt behavior evidence records behavioral traits
- [x] Multiple witnesses' observations are aggregated
- [x] Prism conflict rules implemented
- [x] Aura conflict rules implemented
- [x] Conflict explanation stored in evidence metadata
- [x] `behavioral_conflict` signal implemented
- [x] EventBus signals for conflict events

### Known Integration Gap
**IMPORTANT:** ConflictDetector is NOT registered as an autoload. The class is complete
but needs to be either added as an autoload or instantiated by a level/scene to function
at runtime. Consider adding to project.godot autoloads.

### Testing
- Unit tests in `tests/unit/test_conflict_detector.gd` (15 tests)

### Related Commits
- 539f07a: FW-036-08/09 - Create behavioral conflict detection system with behavior categories
- 7d351ae: FW-036-10 - Implement hunt behavior observation tracking
- c9b53dc: FW-036-11 - Implement conflict detection for Prism readings
- b863a22: FW-036-13 - Display contested evidence in board
