---
id: FW-035e
title: "Evidence Board Polish & Cleanup"
epic: EVIDENCE
priority: low
estimated_complexity: small
dependencies: [FW-035, FW-087]
created: 2026-01-23
parent: FW-035
---

## Description

Polish and cleanup items remaining from the Evidence Board UI epic (FW-035). These are non-blocking improvements identified during review.

## Acceptance Criteria

### DesignTokens Cleanup in evidence_board.gd
- [x] Replace hardcoded `font_size: 14` with `DesignTokens.FONT_SIZES.sm` (line ~148)
- [x] Replace hardcoded `Color(0.7, 0.7, 0.7)` with `DesignTokens.COLORS.text_secondary` (line ~149)
- [x] Replace hardcoded `separation: 8` with `DesignTokens.SPACING.sm` (lines ~154, ~167)

### Animations
- [x] Add fade-in animation when board opens
- [x] Add hover animations on evidence slots

### Integration (Optional/Deferred)
- [ ] Verify network sync works correctly in multiplayer (board subscribes to EvidenceManager signals)
- [ ] Quality affecting entity elimination in matrix (if gameplay requires it)

## Technical Notes

The core evidence board components (`evidence_slot.gd`, `evidence_detail_popup.gd`, `entity_matrix.gd`) already use DesignTokens. Only the parent `evidence_board.gd` has 4 remaining hardcoded values.

For animations, use Godot's Tween system:
```gdscript
func show_board() -> void:
    modulate.a = 0.0
    show()
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, DesignTokens.ANIMATION.fade_normal)
```

## Out of Scope

- New features
- Layout changes
- Accessibility improvements beyond current implementation

## Implementation Notes (2026-01-24)

### Changes Made

**evidence_board.gd:**
- Added `DesignTokens` import via preload
- Replaced 4 hardcoded values with design tokens (font size, color, 2x separation)
- Added fade-in animation in `show_board()` using `modulate.a` and Tween

**evidence_slot.gd:**
- Added `_hover_tween` class variable to track active hover animations
- Set `pivot_offset = size / 2` for center-based scaling
- Connected `mouse_entered` and `mouse_exited` signals to `_button`
- Implemented subtle 1.05x scale animation on hover (0.15s duration)
- Properly kills previous tweens before starting new ones

### Verification
- gdlint passes on both files
- Smoke tests pass (17/17)
- Integration items deferred (network sync and quality-based elimination are optional)
