---
id: FW-085
title: "Implement Cultist School tutorial"
epic: UI
priority: low
estimated_complexity: medium
dependencies: [FW-084, FW-052]
created: 2026-01-07
phase: post-mvp
---

## Description

Create a separate tutorial for playing the Cultist role. Unlocks at Level 5 after completing at least one investigation. Teaches contamination, misdirection, and advanced tactics.

## Acceptance Criteria

### Unlock Requirements
- [ ] Player must be Level 5+
- [ ] Must have completed at least 1 investigation
- [ ] Prevents first-game Cultists who don't understand base mechanics

### Training Modules
- [ ] **Contamination Abilities**: How each ability works, placement timing
- [ ] **Social Engineering**: Principles of misdirection, when to lie vs stay silent
- [ ] **Avoiding Detection**: Cross-verification detection, evidence decay tells
- [ ] **Advanced Tactics**: Intentional death for Echo misdirection, hunt manipulation

### Scenarios
- [ ] Practice contamination placement
- [ ] Learn to time ability usage
- [ ] Understand verification mechanics from Cultist perspective

## Technical Notes

Uses AI investigators to demonstrate how players might verify evidence.

Should emphasize that skilled Cultist play is about subtlety, not obvious sabotage.

## Out of Scope

- Competitive AI Cultist mode
- Advanced social engineering (player skill)
