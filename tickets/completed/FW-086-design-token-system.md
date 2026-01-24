---
id: FW-086
title: "Implement design token system"
epic: UI
priority: high
estimated_complexity: medium
dependencies: []
created: 2026-01-21
---

## Description

Create a centralized design token system to replace the 90+ hardcoded color, spacing, and timing values scattered across UI files. This provides the foundation for consistent theming and enables future UI polish work.

**Scope Decision**: After evaluating ThemeGen and Maaack's Menus Template, we're implementing a lightweight custom solution. The existing menu architecture works well; retrofitting external addons adds integration risk without proportional benefit.

## Acceptance Criteria

### Design Tokens Autoload
- [ ] Create `themes/design_tokens.gd` as autoload singleton named `DesignTokens`
- [ ] Define color palette constants:
  - Backgrounds: `bg_primary`, `bg_secondary`, `bg_surface`, `bg_overlay`
  - Text: `text_primary`, `text_secondary`, `text_muted`, `text_danger`
  - Accent: `accent_primary`, `accent_secondary`, `accent_warning`, `accent_success`
  - Horror: `horror_blood`, `horror_ethereal`, `horror_corruption`
  - Trust levels: `trust_unfalsifiable`, `trust_high`, `trust_variable`, `trust_low`, `trust_sabotage`
  - Evidence categories: `evidence_equipment`, `evidence_apparent`, `evidence_triggered`, `evidence_behavior`
  - Player attribution: 8-color rotation array
- [ ] Define spacing constants: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48)
- [ ] Define font size constants: `xs` (12), `sm` (14), `md` (16), `lg` (20), `xl` (24), `xxl` (32), `display` (48)
- [ ] Define animation timing constants:
  - Standard: `duration_instant` (0.1), `duration_fast` (0.15), `duration_normal` (0.25), `duration_slow` (0.4)
  - Horror: `duration_tension` (0.6), `duration_reveal` (0.8), `duration_startle` (0.05)
- [ ] Define border constants: radii (`none`, `sm`, `md`, `lg`, `full`), widths (`thin`, `normal`, `thick`)

### Theme Resource
- [ ] Create `themes/horror_theme.tres` with base Control styles using token values
- [ ] Style base types: Panel, Button, Label, LineEdit, OptionButton, HSlider, CheckBox
- [ ] Create type variations: `DangerButton`, `GhostButton`, `CorruptedPanel`

### Verification
- [ ] DesignTokens autoload accessible from any script
- [ ] Theme resource can be applied to root UI nodes
- [ ] No regressions in existing UI appearance (visual comparison)

## Technical Notes

**Color Extraction**: Current codebase uses these patterns that tokens should cover:
- Success/ready states: green variants (0.3, 1.0, 0.3)
- Warning states: yellow/orange (1.0, 0.7-0.8, 0.3-0.4)
- Danger/error states: red (1.0, 0.3, 0.3)
- Disabled/muted: gray (0.4-0.5)
- Trust levels: gold, green, yellow, orange, red (from evidence_slot.gd)
- Evidence categories: cornflower blue, light green, gold, indian red

**File Structure**:
```
themes/
├── design_tokens.gd    # Autoload with const dictionaries
└── horror_theme.tres   # Theme resource using token values
```

**Usage Pattern**:
```gdscript
# Before
label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

# After
label.add_theme_color_override("font_color", DesignTokens.COLORS.accent_success)
```

## Out of Scope

- Refactoring existing UI files (FW-087)
- Animation utilities (deferred to post-MVP)
- Scene transitions (deferred to post-MVP)
- External addon integration (ThemeGen, Maaack's)
