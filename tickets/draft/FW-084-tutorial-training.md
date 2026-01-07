---
id: FW-084
title: "Implement solo training mode tutorial"
epic: UI
priority: medium
estimated_complexity: medium
dependencies: [FW-021, FW-031, FW-041]
created: 2026-01-07
phase: post-mvp
---

## Description

Create a single-player training mode with AI teammates (no Cultist) that teaches core mechanics. Addresses competitor weakness in onboarding. Completion unlocks multiplayer.

## Acceptance Criteria

### Training Modules
- [ ] **Movement & Interaction**: Basic controls, doors, items
- [ ] **Equipment Usage**: How each tool works, what readings mean
- [ ] **Evidence Collection**: Identifying types, using evidence board
- [ ] **Hunt Survival**: Warning signs, hiding, protection items
- [ ] **Entity Identification**: Cross-referencing evidence, behavioral tells

### AI Teammates
- [ ] 1-2 AI investigators that follow player
- [ ] AI collects some evidence (demonstrates mechanics)
- [ ] AI provides contextual voice lines
- [ ] No Cultist in training mode

### Progression
- [ ] Must complete training to unlock multiplayer
- [ ] Estimated playtime: 15-20 minutes
- [ ] Skip option for returning players

### Contextual Hints (First 5 Matches)
- [ ] Subtle UI hints during early multiplayer matches
- [ ] "Your EMF reader is detecting activity..."
- [ ] "The lights are flickering — find a hiding spot..."
- [ ] Auto-disable after 5 completed matches
- [ ] Manual disable in settings

## Technical Notes

Tutorial uses same systems as multiplayer but with scripted entity behavior and AI companions.

Good opportunity to introduce lore and world-building.

## Out of Scope

- Cultist tutorial (separate ticket FW-085)
- Full AI behavior for competitive play
