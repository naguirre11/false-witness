---
id: FW-087
title: "Refactor UI files to use design tokens"
epic: UI
priority: medium
estimated_complexity: medium
dependencies: [FW-086]
created: 2026-01-21
---

## Description

Replace hardcoded color, spacing, and timing values in existing UI files with `DesignTokens` references. This ticket is scoped to **high-priority files** that have the most hardcoded values and are most visible to players.

**Scope**: 6 files with highest impact. Remaining files can be refactored opportunistically or in a follow-up ticket.

## Acceptance Criteria

### High-Priority Files (Must Complete)

#### results_screen.gd (16 colors, 6 modulates)
- [ ] Replace all `Color()` constructors with `DesignTokens.COLORS.*`
- [ ] Replace timing values with `DesignTokens.ANIMATION.*`
- [ ] Apply horror_theme.tres to scene root

#### evidence_slot.gd (7 colors, 6 modulates)
- [ ] Replace trust level colors with `DesignTokens.COLORS.trust_*`
- [ ] Replace evidence category colors with `DesignTokens.COLORS.evidence_*`
- [ ] Replace player attribution colors with `DesignTokens.PLAYER_COLORS` array

#### evidence_detail_popup.gd (3 colors, 8 modulates)
- [ ] Replace all hardcoded colors with token references
- [ ] Apply consistent styling with evidence_slot.gd

#### hud.gd (4 colors, 6 modulates)
- [ ] Replace timer warning colors (red <60s, orange <2min) with tokens
- [ ] Replace equipment highlight color with token
- [ ] Replace death overlay color with token

#### entity_matrix.gd (3 colors, 5 modulates)
- [ ] Replace eliminated entity styling with tokens
- [ ] Replace remaining count coloring with tokens

#### voting_ui.gd (4 colors, 4 modulates)
- [ ] Replace vote status colors with tokens
- [ ] Replace button state colors with tokens

### Verification
- [ ] All 6 files compile without errors
- [ ] Visual appearance unchanged (side-by-side comparison)
- [ ] No `Color(` constructors with numeric literals remain in refactored files
- [ ] Smoke tests pass

## Technical Notes

**Search Pattern** to find remaining hardcoded values:
```bash
grep -n "Color([0-9]" src/ui/*.gd
grep -n "\.GOLD\|\.RED\|\.GREEN" src/ui/*.gd
```

**Refactor Pattern**:
```gdscript
# Before
label.modulate = Color(0.3, 1.0, 0.3)
var warning_color = Color.YELLOW

# After
label.modulate = DesignTokens.COLORS.accent_success
var warning_color = DesignTokens.COLORS.accent_warning
```

**Files Deferred** (lower priority, can be done opportunistically):
- player_slot_ui.gd (4 colors) - simple ready/not ready states
- entity_selection.gd (4 colors) - selection states
- equipment_select.gd (3 colors) - timer warnings
- equipment_card.gd (2 colors) - hover/selection
- deliberation_ui.gd (2 colors) - timer states
- evidence_board.gd (1 color) - minimal impact

## Out of Scope

- Adding animations (deferred)
- Restructuring UI architecture
- Creating new components
- Low-priority file refactoring (listed above)
