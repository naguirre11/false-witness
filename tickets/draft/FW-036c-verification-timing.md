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
