---
id: FW-094
title: "Implement player customization system"
epic: UI
priority: low
estimated_complexity: medium
dependencies: [FW-081]
created: 2026-01-24
phase: 2
---

## Description

Allow players to customize their investigator appearance with different outfits, colors, and accessories. Cosmetic only, no gameplay impact.

## Acceptance Criteria

### Customization Options
- [ ] Character model selection (4-6 base models)
- [ ] Outfit color (primary, secondary)
- [ ] Headwear (none, cap, beanie, headphones)
- [ ] Gloves (none, work gloves, latex)
- [ ] Patches/badges on outfit

### Customization UI
- [ ] Accessible from main menu
- [ ] 3D preview of character
- [ ] Rotate preview with mouse drag
- [ ] Color picker for outfit colors
- [ ] Dropdown/grid for item selection

### Persistence
- [ ] Save customization to user profile
- [ ] Sync across sessions
- [ ] Default outfit for new players

### Multiplayer Sync
- [ ] Customization visible to other players
- [ ] Sync on lobby join
- [ ] Minimal network overhead (send once on join)

### Unlockables (Future)
- [ ] Framework for unlockable items
- [ ] Level-gated unlocks
- [ ] Achievement-based unlocks
- [ ] Placeholder for store items

## Technical Notes

Use Resource for customization data:
```gdscript
class_name PlayerCustomization extends Resource

@export var model_id: int = 0
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY
@export var headwear_id: int = 0
@export var gloves_id: int = 0
```

## Out of Scope

- Monetization/store
- Trading between players
- Animated accessories
- Voice customization
