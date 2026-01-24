---
id: FW-097
title: "Implement loading screens and transitions"
epic: UI
priority: medium
estimated_complexity: small
dependencies: [FW-081, FW-086]
created: 2026-01-24
phase: 2
---

## Description

Create polished loading screens and scene transitions. Currently scene changes are instant/jarring. Add proper loading feedback and smooth transitions.

## Acceptance Criteria

### Loading Screen
- [ ] Full-screen loading overlay
- [ ] Animated loading indicator (spinner or progress bar)
- [ ] Loading tips/hints (random selection)
- [ ] Map preview image when loading into investigation
- [ ] Minimum display time (1s) to prevent flash

### Loading Tips
- [ ] Pool of 20+ gameplay tips
- [ ] Random selection each load
- [ ] Categories: Evidence, Entity, Cultist, Equipment, Survival
- [ ] Example: "Freezing temperatures are easier to detect in smaller rooms"

### Scene Transitions
- [ ] Fade to black between scenes
- [ ] Configurable fade duration (0.3-0.5s)
- [ ] Optional iris/circle wipe for style
- [ ] Audio fade out during transition

### Progress Indication
- [ ] Actual loading progress when available
- [ ] Fake progress for quick loads
- [ ] Network sync progress for multiplayer joins

### Match Start Sequence
- [ ] Map name and image
- [ ] Player list with roles hidden
- [ ] Countdown timer (3-2-1)
- [ ] Dramatic reveal transition

### Error Handling
- [ ] Loading timeout detection
- [ ] Retry button on failure
- [ ] Return to menu option
- [ ] Error message display

## Technical Notes

Use CanvasLayer for loading overlay:
```gdscript
class_name LoadingScreen extends CanvasLayer

func show_loading(tip: String = "") -> void:
    _tip_label.text = tip if tip else _get_random_tip()
    _animator.play("fade_in")

func hide_loading() -> void:
    await get_tree().create_timer(min_display_time).timeout
    _animator.play("fade_out")
```

## Out of Scope

- Interactive loading screens
- Minigames during load
- Background asset streaming
