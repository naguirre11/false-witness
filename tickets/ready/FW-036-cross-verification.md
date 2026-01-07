---
id: FW-036
title: "Implement evidence cross-verification system"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031, FW-035]
created: 2026-01-07
---

## Description

Create the cross-verification system where evidence confirmed by multiple players is marked as more trustworthy. This creates a second layer of defense against Cultist contamination and rewards teamwork.

## Acceptance Criteria

### Verification States
- [ ] **Unverified** (single checkmark): One player collected evidence
- [ ] **Verified** (double checkmark): Two+ players independently confirmed
- [ ] **Contested** (exclamation mark): Players report conflicting readings

### Verification Rules
- [ ] Same evidence type + same location + different players = Verified
- [ ] Different equipment confirming same evidence = Stronger verification
- [ ] Conflicting reports (one sees evidence, another doesn't) = Contested
- [ ] Cultists CANNOT contaminate already-Verified evidence

### Evidence Board Integration
- [ ] Evidence type icon displayed
- [ ] Verification state icon displayed
- [ ] Collector name(s) - hoverable for timestamp
- [ ] Location where collected
- [ ] Contested evidence: yellow highlight, pulsing border

### Cross-Verification Events
- [ ] Signal emitted when evidence verified
- [ ] Signal emitted when evidence contested
- [ ] Verification blocks further contamination of that evidence

## Technical Notes

**Strategic implications:**
- For Investigators: Prioritize verifying evidence before Cultist can contaminate. Work in pairs.
- For Cultists: Race to contaminate before verification. Create conflicting reports to cast doubt. Avoid being sole source of critical evidence.

Verification UI should be clear during deliberation phase - helps team assess which evidence is trustworthy.

## Out of Scope

- Evidence annotation/notes
- Chat integration
