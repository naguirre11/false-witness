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
- [ ] Replace hardcoded `font_size: 14` with `DesignTokens.FONT_SIZES.sm` (line ~144)
- [ ] Replace hardcoded `Color(0.7, 0.7, 0.7)` with `DesignTokens.COLORS.text_secondary` (line ~145)
- [ ] Replace hardcoded `separation: 8` with `DesignTokens.SPACING.sm` (lines ~150, ~163)

### Animations
- [ ] Add fade-in animation when board opens
- [ ] Add hover animations on evidence slots

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
