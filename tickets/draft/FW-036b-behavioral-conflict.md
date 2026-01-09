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
