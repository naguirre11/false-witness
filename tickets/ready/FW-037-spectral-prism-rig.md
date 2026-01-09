---
id: FW-037
title: "Spectral Prism Rig (Epic)"
epic: EVIDENCE
is_epic: true
priority: high
estimated_complexity: large
dependencies: [FW-031, FW-023]
sub_tickets: [FW-037a, FW-037b, FW-037c]
created: 2026-01-08
---

## Description

Create the Spectral Prism Rig, a two-part cooperative equipment where BOTH operators can lie about their role's output. This is the core "symmetric trust" equipment — neither player is inherently more trustworthy.

**Trust Dynamic:** Cooperative — Symmetric (both Calibrator and Lens Reader can lie)

## Sub-Tickets

| ID | Title | Status |
|----|-------|--------|
| FW-037a | Spectral Prism Equipment Base | for_review |
| FW-037b | Calibrator Unit | ready |
| FW-037c | Lens Reader Unit | draft |

**Execution Order**: FW-037a -> FW-037b -> FW-037c

## Acceptance Criteria

### Equipment Components

#### Calibrator Unit
- [ ] 3D model: brass-and-glass sextant with rotating colored prism filters
- [ ] Viewfinder that player looks through
- [ ] Rotating filter controls (player input)
- [ ] "Lock" action when alignment achieved

#### Lens Reader Unit
- [ ] 3D model: handheld monocle with etched reference guide
- [ ] Eyepiece display showing entity signature
- [ ] Only functional after Calibrator locks alignment

### Operation Procedure
- [ ] Step 1: Calibrator looks through viewfinder at anchor point (entity location)
- [ ] Step 2: Calibrator rotates filters until abstract blobs resolve into shape
- [ ] Step 3: Calibrator announces alignment shape and locks calibration
- [ ] Step 4: Lens Reader looks through eyepiece
- [ ] Step 5: Lens Reader announces entity signature pattern

### Evidence Outcomes
- [ ] Pattern Shape determines entity category:
  - Triangle = Passive entity (Shade, Spirit-type)
  - Circle = Aggressive entity (Demon, Oni-type)
  - Square = Territorial entity (Goryo, Hantu-type)
  - Spiral = Mobile entity (Wraith, Phantom-type)
- [ ] Pattern Color provides secondary confirmation:
  - Blue-violet = Passive
  - Red-orange = Aggressive
  - Green = Territorial
  - Yellow = Mobile
- [ ] Combined shape+color = PRISM_READING evidence type

### Trust Mechanics
- [ ] Calibrator can lie: "I aligned to triangle" (actually circle)
- [ ] Lens Reader can lie: "Lens showed Revenant signature" (actually Banshee)
- [ ] Neither player sees the other's view directly
- [ ] Third player cannot easily verify either claim

### Proximity Requirements
- [ ] Both players must be within 5m of each other
- [ ] Calibrator must have line-of-sight to anchor point
- [ ] Equipment fails if players separate during operation

### Reading Quality
- [ ] **Strong**: Full alignment achieved, stable, both players stationary
- [ ] **Weak**: Partial alignment, rushed, movement during read

### Network Sync
- [ ] Calibration state synced between two equipment holders
- [ ] Lock action triggers Lens Reader availability
- [ ] Evidence submission server-authoritative

## Technical Notes

**Fictional Justification:**
The Prism Rig works by refracting spectral energy through precisely-aligned chromatic filters. The Calibrator tunes the frequency; the Lens Reader interprets the result. Neither component functions alone.

**Cultist Strategies:**
- As Calibrator: Intentionally misalign to wrong shape, announce false alignment
- As Lens Reader: Report different color/shape than actually visible
- Advanced: Collude with innocent player to create plausible false evidence

**Counter-Strategies:**
- Cross-reference Prism Reading with Hunt Behavior (behavioral ground truth)
- Repeat reading with different operators
- Watch for inconsistencies between shape (category) and behavior

**UI Considerations:**
- Calibrator sees: abstract color blobs that resolve when aligned
- Lens Reader sees: entity signature pattern (shape + color overlay)
- Neither sees what the other sees

## Out of Scope

- Entity-specific signature definitions (part of entity design)
- Cultist-specific abilities to corrupt readings (FW-052)
