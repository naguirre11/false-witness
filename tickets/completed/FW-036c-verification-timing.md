---
id: FW-036c
title: "Evidence Verification Timing (Staleness System)"
epic: EVIDENCE
priority: medium
estimated_complexity: small
dependencies: [FW-036a]
created: 2026-01-09
parent: FW-036
---

## Description

Implement the verification timing system where evidence has a freshness window. Fresh evidence is easier to verify; stale evidence becomes harder to confirm retroactively.

**Core Mechanic:** Prevents Cultists from making up evidence retroactively. "I saw EMF 5 ten minutes ago" is harder to verify than "I'm seeing EMF 5 right now."

## Acceptance Criteria

### Staleness Calculation
- [ ] Evidence tracks `timestamp` (already exists in Evidence class)
- [ ] Staleness calculated as: `current_time - evidence.timestamp`
- [ ] Configurable staleness thresholds: `FRESH_WINDOW`, `STALE_WINDOW`

### Freshness States
- [ ] **Fresh** (0-60s): Full verification capability
- [ ] **Recent** (60-180s): Verification possible but flagged
- [ ] **Stale** (180s+): Cannot verify, only contest

### Verification Modifiers
- [ ] Fresh evidence: Normal verification rules apply
- [ ] Recent evidence: Verification adds "late_verification" flag
- [ ] Stale evidence: `verify_evidence()` returns failure with "evidence_too_old" reason

### Evidence Board Integration
- [ ] Stale evidence shows visual indicator (dimmed, timestamp visible)
- [ ] Tooltip shows "Collected X minutes ago"
- [ ] Fresh evidence has no special indicator

### Configuration
- [ ] Timing thresholds configurable via exported constants
- [ ] Default values: FRESH=60s, RECENT=180s (configurable per game mode)

### Signals
- [ ] `evidence_became_stale(evidence: Evidence)` - Emitted when crossing stale threshold

## Technical Notes

**Time Source:**
Use `Time.get_ticks_msec()` or game-time counter for consistency. Avoid wall-clock time issues.

**Game Time vs Real Time:**
Consider pausing staleness during deliberation phase (evidence shouldn't "expire" while discussing).

**Implementation Location:**
Staleness logic can live in VerificationManager (from FW-036a) as an additional validation check.

## Out of Scope

- Evidence decay/removal (evidence persists, just becomes harder to verify)
- Staleness affecting evidence board display ordering
- Per-evidence-type staleness rules

## Testing Requirements

- Test freshness state transitions
- Test verification blocking for stale evidence
- Test that recent evidence allows verification with flag
- Test staleness calculation edge cases (exactly at boundary)

---

## Implementation Notes (Ralph PRD - 2026-01-21)

**Completed by Ralph in cross-verification PRD (stories FW-036-14, FW-036-15)**

### Files Created/Modified
- `src/evidence/verification_manager.gd` (+90 lines) - Staleness logic
- `src/evidence/evidence.gd` (+55 lines) - Verification timestamp tracking
- `src/ui/evidence_detail_popup.gd` - Staleness display

### What Was Implemented

**Staleness System (VerificationManager):**
- `StalenessLevel` enum: FRESH (<60s), STALE (60-180s), VERY_STALE (>180s)
- `get_evidence_staleness()` - Calculates current staleness level
- `get_staleness_description()` - Human-readable staleness text
- `get_staleness_color()` - Color coding for staleness display
- Very stale evidence cannot be newly verified
- Late verification flagged in metadata

**Verification Timestamp Tracking (Evidence):**
- `verification_timestamp` - When evidence was verified
- `verification_history` - Array of all verification records
- `record_verification(verifier_id, timestamp)` - Records verification event
- `get_verification_history()` - Returns all verifications

**UI Integration:**
- Staleness displayed with color in evidence detail popup
- "Verified by [Player] at [Time]" shown for verified evidence
- Verify button disabled for very stale evidence

### Acceptance Criteria Status
- [x] Evidence tracks `timestamp` (already existed)
- [x] Staleness calculated from current time vs timestamp
- [x] Configurable thresholds (60s, 180s)
- [x] Fresh evidence: Normal verification
- [x] Stale evidence: Late verification flag
- [x] Very stale evidence: Cannot verify
- [x] Visual indicator for staleness in UI
- [x] Timestamp/verifier display

### Testing
- Unit tests in `tests/unit/test_verification_rules.gd` cover staleness validation

### Related Commits
- 8196037: FW-036-14 - Implement evidence staleness (freshness windows)
- d0f430a: FW-036-15 - Add verification timestamp tracking
