---
id: FW-036
title: "Cross-Verification System (Epic)"
epic: EVIDENCE
priority: high
estimated_complexity: large
dependencies: [FW-031, FW-035]
created: 2026-01-07
updated: 2026-01-09
is_epic: true
---

## Description

**EPIC TICKET** - This has been broken into sub-tickets.

Create the cross-verification system where evidence can be confirmed by multiple players or contradicted by behavioral observations. This creates the "gotcha" moments that catch Cultist lies.

**Core Mechanic:** Trust is a resource optimization. Trusting saves time but carries risk; verifying takes time but provides certainty.

## Sub-Tickets

| Ticket | Title | Status | Scope |
|--------|-------|--------|-------|
| FW-036a | Verification Rules Engine | for_review | Trust-level verification rules, witness tracking |
| FW-036b | Behavioral Conflict Detection | for_review | "Gotcha" system, equipment vs behavior mismatch |
| FW-036c | Verification Timing | for_review | Evidence staleness, freshness windows |

## Original Acceptance Criteria (Distributed to Sub-Tickets)

### Verification States (Already in FW-031)
- [x] **Unverified** (single checkmark): One player collected evidence
- [x] **Verified** (double checkmark): Two+ players independently confirmed
- [x] **Contested** (exclamation mark): Conflicting reports from different players

### Verification Rules by Trust Level → FW-036a

#### UNFALSIFIABLE (Hunt Behavior)
- [x] Automatically verified when multiple players witness same behavior
- [x] Cannot be contested (entity behavior is ground truth)
- [x] Single-witness behavior still recorded but marked as such

#### HIGH Trust (EMF, Thermometer, Visual, Physical)
- [x] Verified when 2+ players observe same reading/phenomenon
- [x] Shared displays make independent confirmation easy
- [x] Readily-apparent evidence (breath, objects moving) naturally multi-witness

#### VARIABLE Trust (Aura Pattern - Dowsing/Imager)
- [x] Only Imager role can lie; Dowser is neutralized
- [x] Verification requires third player watching Imager's screen
- [x] OR cross-reference with behavioral evidence

#### LOW Trust (Prism Reading)
- [x] Both Calibrator and Lens Reader can lie
- [x] Verification requires repeating with different operators
- [x] OR cross-reference with behavioral evidence

#### SABOTAGE_RISK (Ghost Writing)
- [x] Verification requires witness to setup AND result
- [x] Buddy system: one places, one watches
- [x] Sabotage detection: book moved, wrong room, broken setup

### Behavioral Cross-Reference (The "Gotcha" Moment) → FW-036b
- [x] System detects when equipment evidence conflicts with observed behavior
- [x] Example: Prism shows "aggressive-red" but entity moves slowly during hunts
- [x] Conflict triggers CONTESTED state with explanation
- [x] This is the primary mechanism for catching Cultist lies

### Verification Timing → FW-036c
- [x] Verification must happen within time window (evidence can "go stale")
- [x] Fresh evidence easier to verify than old claims
- [x] Prevents retroactive verification of made-up evidence

### Evidence Board Integration (Already in FW-035c)
- [x] Verification state icon next to each evidence
- [x] Contested evidence: yellow highlight, shows conflicting reports
- [ ] Click to see verification details (who, when, where) → Future enhancement

### Signals (Distributed)
- [x] `evidence_verified` - emitted when evidence confirmed by second player (FW-031)
- [x] `evidence_contested` - emitted when conflicting reports detected (FW-031)
- [x] `behavioral_conflict` - emitted when equipment vs behavior mismatch (FW-036b)

## Technical Notes

**The Verification Dilemma:**
Players CAN verify everything — but it costs time and coverage:
- Trusting teammates = faster completion, risk of Cultist lies
- Verifying everything = slower completion, guaranteed accuracy
- Cultist exploits BOTH strategies

**Behavioral Ground Truth:**
Hunt behavior cannot be faked. When equipment evidence contradicts observed behavior, one of the following is true:
1. Equipment was misread (honest mistake)
2. Equipment operator lied (Cultist)
3. Behavior was misinterpreted (honest mistake)

This creates satisfying deduction moments.

**Example "Gotcha" Scenario:**
"The Prism Rig showed aggressive-red, but we've watched three hunts and it barely moves. Aggressive entities don't behave like that. Someone's reading was wrong — or someone lied."

## Out of Scope

- Cultist contamination abilities (FW-052)
- Voting on evidence validity
- Evidence removal/retraction

## Implementation Notes

All sub-tickets completed. Core implementation:

### Files Created
- `src/evidence/verification_manager.gd` - Trust-level verification rules autoload
- `src/evidence/conflict_detector.gd` - Behavioral conflict detection autoload

### Autoloads Registered (project.godot)
- VerificationManager - Trust-level verification rules
- ConflictDetector - Behavioral conflict detection

### Test Coverage
- `tests/unit/test_verification_rules.gd` - 17 tests
- `tests/unit/test_conflict_detector.gd` - 15 tests

All 372 tests pass including smoke tests.
