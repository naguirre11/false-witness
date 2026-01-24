# False Witness: UI & Aesthetic Implementation Specification

This document defines the tools, systems, and standards to be implemented for consistent, polished UI in False Witness. Claude Code should analyze the current codebase against these specifications and create tickets for any missing or incomplete implementations.

---

## 1. Required Addons & Dependencies

### 1.1 Core Tools to Install

| Addon | Purpose | Source | Priority |
|-------|---------|--------|----------|
| ThemeGen | Programmatic design token system | `https://github.com/Inspiaaa/ThemeGen` | **Critical** |
| Maaack's Menus Template | Menu infrastructure (main, options, pause, credits) | `https://github.com/Maaack/Godot-Menus-Template` | **Critical** |
| GameGUI | Responsive layout system for HUD | `https://github.com/brombres/Godot-GameGUI` | High |
| GLoot | Inventory UI system | `https://github.com/peter-kish/gloot` | Medium |
| Anima | Animation presets library | `https://github.com/ceceppa/anima` | Medium |
| Transit | Scene transition system | Godot Asset Library ID 1829 | Medium |

### 1.2 Audit Checklist

- [ ] Each addon listed above is installed in `addons/` directory
- [ ] Each addon is enabled in Project Settings → Plugins
- [ ] No conflicting or redundant UI systems exist in codebase

---

## 2. Design Token System

### 2.1 Required File Structure

```
res://
├── themes/
│   ├── horror_theme_generator.gd    # ThemeGen script (creates .tres)
│   ├── horror_theme.tres            # Generated theme resource
│   └── design_tokens.gd             # Autoload with token constants
```

### 2.2 Design Token Definitions

Create `res://themes/design_tokens.gd` as an autoload singleton:

```gdscript
extends Node

# === COLOR TOKENS ===
const COLORS = {
    # Backgrounds
    "bg_primary": Color("#1a1a2e"),
    "bg_secondary": Color("#16213e"),
    "bg_surface": Color("#0f0f1a"),
    "bg_overlay": Color("#000000", 0.7),
    
    # Text
    "text_primary": Color("#ffffff"),
    "text_secondary": Color("#a0a0a0"),
    "text_muted": Color("#666666"),
    "text_danger": Color("#e94560"),
    
    # Accent & Interactive
    "accent_primary": Color("#e94560"),
    "accent_secondary": Color("#4a90a4"),
    "accent_warning": Color("#c1583e"),
    "accent_success": Color("#2d6a4f"),
    
    # Horror-specific
    "horror_blood": Color("#5c1610"),
    "horror_ethereal": Color("#4a90a4"),
    "horror_corruption": Color("#3d1a4a"),
}

# === SPACING TOKENS ===
const SPACING = {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32,
    "xxl": 48,
}

# === TYPOGRAPHY TOKENS ===
const FONT_SIZES = {
    "xs": 12,
    "sm": 14,
    "md": 16,
    "lg": 20,
    "xl": 24,
    "xxl": 32,
    "display": 48,
}

# === ANIMATION TOKENS ===
const ANIMATION = {
    # Standard UI
    "duration_instant": 0.1,
    "duration_fast": 0.15,
    "duration_normal": 0.25,
    "duration_slow": 0.4,
    
    # Horror-specific
    "duration_tension": 0.6,
    "duration_reveal": 0.8,
    "duration_startle": 0.05,
    
    # Easing presets (use with Tween)
    "ease_snappy": [Tween.TRANS_BACK, Tween.EASE_OUT],
    "ease_smooth": [Tween.TRANS_QUAD, Tween.EASE_OUT],
    "ease_horror_in": [Tween.TRANS_EXPO, Tween.EASE_IN],
    "ease_horror_out": [Tween.TRANS_EXPO, Tween.EASE_OUT],
}

# === BORDER TOKENS ===
const BORDERS = {
    "radius_none": 0,
    "radius_sm": 4,
    "radius_md": 8,
    "radius_lg": 12,
    "radius_full": 9999,
    
    "width_thin": 1,
    "width_normal": 2,
    "width_thick": 4,
}
```

### 2.3 ThemeGen Implementation

Create `res://themes/horror_theme_generator.gd`:

```gdscript
@tool
extends ProgrammaticTheme

func _init_theme() -> void:
    var tokens = preload("res://themes/design_tokens.gd")
    
    # Base Panel styling
    style("Panel", {
        "panel": stylebox_flat({
            "bg_color": tokens.COLORS.bg_secondary,
            "corner_radius": tokens.BORDERS.radius_md,
        })
    })
    
    # Button base
    style("Button", {
        "normal": stylebox_flat({
            "bg_color": tokens.COLORS.bg_surface,
            "border_color": tokens.COLORS.accent_primary,
            "border_width": tokens.BORDERS.width_thin,
            "corner_radius": tokens.BORDERS.radius_sm,
        }),
        "hover": stylebox_flat({
            "bg_color": tokens.COLORS.accent_primary.darkened(0.3),
            "border_color": tokens.COLORS.accent_primary,
            "border_width": tokens.BORDERS.width_normal,
            "corner_radius": tokens.BORDERS.radius_sm,
        }),
        "pressed": stylebox_flat({
            "bg_color": tokens.COLORS.accent_primary.darkened(0.5),
            "corner_radius": tokens.BORDERS.radius_sm,
        }),
        "font_color": tokens.COLORS.text_primary,
        "font_color_hover": tokens.COLORS.text_primary,
    })
    
    # === TYPE VARIATIONS ===
    
    # Danger/Warning button
    variation("DangerButton", "Button", {
        "normal": stylebox_flat({
            "bg_color": tokens.COLORS.horror_blood.darkened(0.3),
            "border_color": tokens.COLORS.accent_primary,
        }),
        "hover": stylebox_flat({
            "bg_color": tokens.COLORS.horror_blood,
        }),
    })
    
    # Ghost/Secondary button
    variation("GhostButton", "Button", {
        "normal": stylebox_flat({
            "bg_color": Color.TRANSPARENT,
            "border_color": tokens.COLORS.text_muted,
            "border_width": tokens.BORDERS.width_thin,
        }),
        "hover": stylebox_flat({
            "bg_color": tokens.COLORS.bg_surface,
        }),
    })
    
    # Horror panel with corruption effect
    variation("CorruptedPanel", "Panel", {
        "panel": stylebox_flat({
            "bg_color": tokens.COLORS.horror_corruption,
            "border_color": tokens.COLORS.accent_primary,
            "border_width": tokens.BORDERS.width_thin,
        })
    })
```

### 2.4 Audit Checklist

- [ ] `design_tokens.gd` exists and is registered as autoload named `DesignTokens`
- [ ] `horror_theme_generator.gd` exists and extends `ProgrammaticTheme`
- [ ] `horror_theme.tres` is generated and assigned to root UI nodes
- [ ] All UI code references `DesignTokens.COLORS`, `DesignTokens.SPACING`, etc. instead of hardcoded values
- [ ] Type variations exist for: `DangerButton`, `GhostButton`, `CorruptedPanel`, `EtherealPanel`
- [ ] No inline `Color()` constructors with hex values exist in UI scripts (should use tokens)

---

## 3. Menu System Architecture

### 3.1 Required Menu Scenes

Using Maaack's Menus Template as base, the following scenes must exist:

```
res://scenes/ui/menus/
├── main_menu/
│   ├── main_menu.tscn          # Extends Maaack's MainMenu
│   └── main_menu.gd
├── options_menu/
│   ├── options_menu.tscn       # Extends Maaack's OptionsMenu
│   ├── audio_options.tscn
│   ├── video_options.tscn
│   └── controls_options.tscn
├── pause_menu/
│   ├── pause_menu.tscn
│   └── pause_menu.gd
├── credits/
│   └── credits.tscn
└── loading/
    └── loading_screen.tscn
```

### 3.2 Menu Requirements

**Main Menu:**
- Background: Animated/atmospheric scene or static horror imagery
- Buttons: Play, Options, Credits, Quit
- All buttons use `theme_type_variation = "GhostButton"` or custom horror variant
- Subtle idle animations (flickering, breathing effects)

**Options Menu:**
- Audio: Master, Music, SFX, Voice sliders with real-time preview
- Video: Resolution, Fullscreen, VSync, Brightness, Gamma
- Controls: Rebindable keys with conflict detection
- Settings persist via Maaack's `AppSettings` system

**Pause Menu:**
- Semi-transparent overlay (`DesignTokens.COLORS.bg_overlay`)
- Resume, Options, Quit to Main Menu
- Game world visible but darkened behind

**Loading Screen:**
- Progress bar or spinner
- Optional horror tips/lore text
- Minimum display time to prevent flicker (0.5s)

### 3.3 Audit Checklist

- [ ] All menu scenes listed above exist
- [ ] Menus extend or use Maaack's template components where applicable
- [ ] All menus apply `horror_theme.tres`
- [ ] Settings persistence works (audio, video, controls save/load)
- [ ] Keyboard and gamepad navigation works on all menus
- [ ] Menu transitions use Transit or equivalent (no hard cuts)

---

## 4. Animation & Polish Standards

### 4.1 Required Animation Utilities

Create `res://scripts/ui/ui_animations.gd`:

```gdscript
class_name UIAnimations
extends RefCounted

## Standard snappy hover effect for buttons
static func apply_hover_scale(node: Control, scale_factor: float = 1.05) -> void:
    node.mouse_entered.connect(func():
        var tween = node.create_tween()
        tween.tween_property(node, "scale", Vector2.ONE * scale_factor, 
            DesignTokens.ANIMATION.duration_fast)\
            .set_trans(DesignTokens.ANIMATION.ease_snappy[0])\
            .set_ease(DesignTokens.ANIMATION.ease_snappy[1])
    )
    node.mouse_exited.connect(func():
        var tween = node.create_tween()
        tween.tween_property(node, "scale", Vector2.ONE, 
            DesignTokens.ANIMATION.duration_fast)\
            .set_trans(DesignTokens.ANIMATION.ease_smooth[0])\
            .set_ease(DesignTokens.ANIMATION.ease_smooth[1])
    )
    # Set pivot to center
    node.pivot_offset = node.size / 2

## Horror text jitter effect
static func horror_jitter(node: Control, intensity: float = 2.0, loops: int = 3) -> Tween:
    var original_pos = node.position
    var tween = node.create_tween().set_loops(loops)
    tween.tween_property(node, "position:x", original_pos.x + intensity, 0.03)
    tween.tween_property(node, "position:x", original_pos.x - intensity, 0.03)
    tween.tween_property(node, "position:x", original_pos.x, 0.02)
    return tween

## Fade in with optional slide
static func fade_in(node: Control, duration: float = -1, slide_from: Vector2 = Vector2.ZERO) -> Tween:
    if duration < 0:
        duration = DesignTokens.ANIMATION.duration_normal
    
    node.modulate.a = 0.0
    var original_pos = node.position
    
    if slide_from != Vector2.ZERO:
        node.position = original_pos + slide_from
    
    var tween = node.create_tween().set_parallel(true)
    tween.tween_property(node, "modulate:a", 1.0, duration)
    if slide_from != Vector2.ZERO:
        tween.tween_property(node, "position", original_pos, duration)\
            .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    return tween

## Fade out with optional slide
static func fade_out(node: Control, duration: float = -1, slide_to: Vector2 = Vector2.ZERO) -> Tween:
    if duration < 0:
        duration = DesignTokens.ANIMATION.duration_normal
    
    var tween = node.create_tween().set_parallel(true)
    tween.tween_property(node, "modulate:a", 0.0, duration)
    if slide_to != Vector2.ZERO:
        tween.tween_property(node, "position", node.position + slide_to, duration)
    return tween

## Horror reveal - slow, ominous appearance
static func horror_reveal(node: Control, duration: float = -1) -> Tween:
    if duration < 0:
        duration = DesignTokens.ANIMATION.duration_reveal
    
    node.modulate.a = 0.0
    node.scale = Vector2.ONE * 1.1
    
    var tween = node.create_tween().set_parallel(true)
    tween.tween_property(node, "modulate:a", 1.0, duration)\
        .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
    tween.tween_property(node, "scale", Vector2.ONE, duration)\
        .set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
    return tween

## Startle snap - instant sharp appearance
static func startle_snap(node: Control) -> Tween:
    node.scale = Vector2.ONE * 1.3
    node.modulate.a = 1.0
    
    var tween = node.create_tween()
    tween.tween_property(node, "scale", Vector2.ONE, 
        DesignTokens.ANIMATION.duration_startle)\
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    return tween

## Button press feedback
static func button_press(node: Control) -> Tween:
    var tween = node.create_tween()
    tween.tween_property(node, "scale", Vector2.ONE * 0.95, 0.05)
    tween.tween_property(node, "scale", Vector2.ONE, 0.1)\
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    return tween
```

### 4.2 Animation Timing Standards

| Context | Duration | Easing | Use Case |
|---------|----------|--------|----------|
| Button hover | 0.15s | TRANS_BACK, EASE_OUT | Scale up on hover |
| Button press | 0.05s + 0.1s | Linear → TRANS_BACK | Press down, bounce back |
| Menu transition | 0.25-0.4s | TRANS_QUAD, EASE_OUT | Fade/slide between screens |
| Popup appear | 0.2s | TRANS_BACK, EASE_OUT | Modal dialogs |
| Horror reveal | 0.6-0.8s | TRANS_EXPO, EASE_IN | Slow, ominous appearances |
| Startle effect | <0.1s | TRANS_BACK, EASE_OUT | Jump scares, alerts |
| HUD element | 0.15s | TRANS_QUAD, EASE_OUT | Health/stamina changes |

### 4.3 Audit Checklist

- [ ] `UIAnimations` class exists and is accessible globally
- [ ] All buttons have hover feedback (scale, color, or both)
- [ ] All buttons have press feedback
- [ ] Menu transitions are animated (no instant scene switches)
- [ ] Popups/modals fade in rather than appearing instantly
- [ ] No hardcoded duration values in UI scripts (use `DesignTokens.ANIMATION`)
- [ ] Horror-specific effects (jitter, corruption, flicker) are available and documented

---

## 5. HUD & In-Game UI

### 5.1 Diegetic UI Philosophy

Following Phasmophobia's approach, prioritize:

1. **Minimal persistent HUD** - Only show what's absolutely necessary
2. **World-integrated information** - Equipment shows state on the model itself
3. **Context-sensitive displays** - UI appears when relevant, hides otherwise
4. **Physical UI elements** - Journal, phone, tablet as in-world objects

### 5.2 Required HUD Components

```
res://scenes/ui/hud/
├── hud_manager.tscn            # Root HUD controller
├── hud_manager.gd
├── components/
│   ├── sanity_indicator.tscn   # Minimal/diegetic sanity display
│   ├── interaction_prompt.tscn # "Press E to interact" prompts
│   ├── objective_display.tscn  # Current objective (hideable)
│   ├── inventory_quick.tscn    # Quick-access inventory (if needed)
│   └── notification_toast.tscn # Temporary notifications
└── overlays/
    ├── damage_overlay.tscn     # Screen effect when hurt
    ├── fear_overlay.tscn       # Visual distortion when scared
    └── death_screen.tscn
```

### 5.3 Interaction Prompt Standards

```gdscript
# Interaction prompts should:
# - Fade in when in range (0.15s)
# - Show input icon + action text
# - Support keyboard and gamepad icons
# - Fade out when out of range (0.1s)
# - Use DesignTokens.COLORS.text_primary
# - Position: Screen center-bottom or near interactable object
```

### 5.4 Audit Checklist

- [ ] HUD follows minimal/diegetic philosophy
- [ ] Interaction prompts exist and show contextual actions
- [ ] HUD elements use GameGUI or responsive containers
- [ ] Damage/fear overlays exist for horror feedback
- [ ] Objective display can be toggled or auto-hides
- [ ] All HUD text uses design token colors
- [ ] HUD scales appropriately across resolutions

---

## 6. Component Library

### 6.1 Required Reusable Components

Create standardized, reusable UI components:

```
res://scenes/ui/components/
├── buttons/
│   ├── primary_button.tscn     # Standard action button
│   ├── ghost_button.tscn       # Transparent/outline button
│   ├── danger_button.tscn      # Destructive action button
│   └── icon_button.tscn        # Button with icon only
├── panels/
│   ├── base_panel.tscn         # Standard panel container
│   ├── modal_panel.tscn        # Popup/dialog container
│   └── corrupted_panel.tscn    # Horror-styled panel
├── inputs/
│   ├── slider_setting.tscn     # Label + Slider + Value
│   ├── toggle_setting.tscn     # Label + Checkbox
│   └── dropdown_setting.tscn   # Label + OptionButton
├── feedback/
│   ├── loading_spinner.tscn
│   ├── progress_bar.tscn
│   └── toast_notification.tscn
└── typography/
    ├── heading.tscn            # H1-style text
    ├── subheading.tscn         # H2-style text
    └── body_text.tscn          # Paragraph text
```

### 6.2 Component Standards

Each component must:
- Have `theme_type_variation` set appropriately
- Use `DesignTokens` for all colors, spacing, sizing
- Include hover/focus states
- Support keyboard navigation
- Have consistent naming: `{purpose}_{type}.tscn`

### 6.3 Audit Checklist

- [ ] Component library directory structure exists
- [ ] At least 3 button variants exist (primary, ghost, danger)
- [ ] Panel components exist for modals and standard containers
- [ ] Setting input components exist (slider, toggle, dropdown)
- [ ] All components use theme type variations
- [ ] Components are documented (purpose, usage, properties)

---

## 7. Scene Transitions

### 7.1 Transition Implementation

Using Transit addon or equivalent:

```gdscript
# Standard scene change with fade
Transit.change_scene_to_file("res://scenes/levels/house.tscn", 0.3, 0.0)

# Or manual implementation if not using Transit:
class_name SceneTransition
extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func change_scene(path: String, fade_duration: float = 0.3) -> void:
    var tween = create_tween()
    tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
    await tween.finished
    get_tree().change_scene_to_file(path)
    tween = create_tween()
    tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
```

### 7.2 Transition Types Needed

| Transition | Use Case | Duration |
|------------|----------|----------|
| Fade to black | Standard scene change | 0.3s each way |
| Fade to white | Death, bright events | 0.5s each way |
| Cross-dissolve | Menu navigation | 0.2s |
| Corruption effect | Entering ghost territory | 0.5-1.0s |

### 7.3 Audit Checklist

- [ ] Scene transition system exists (Transit or custom)
- [ ] No hard cuts between major scenes
- [ ] Menu-to-menu transitions are smooth
- [ ] Game-to-menu transitions include pause handling
- [ ] Horror-specific transitions available (corruption, static)

---

## 8. Audio Integration

### 8.1 UI Sound Requirements

```
res://audio/ui/
├── button_hover.wav      # Subtle hover sound
├── button_click.wav      # Confirmation sound
├── button_back.wav       # Cancel/back sound
├── menu_open.wav         # Menu appearance
├── menu_close.wav        # Menu dismissal
├── error.wav             # Invalid action
├── notification.wav      # Toast/alert sound
└── horror_ui/
    ├── corruption.wav    # When horror UI appears
    ├── static.wav        # Interference effect
    └── heartbeat.wav     # Tension UI sound
```

### 8.2 Audio Implementation Pattern

```gdscript
# UI sounds should use a dedicated AudioStreamPlayer pool
# or Maaack's UISoundController

class_name UISoundManager
extends Node

@export var hover_sound: AudioStream
@export var click_sound: AudioStream
@export var back_sound: AudioStream

var _player_pool: Array[AudioStreamPlayer] = []

func play(sound: AudioStream, volume_db: float = 0.0) -> void:
    var player = _get_available_player()
    player.stream = sound
    player.volume_db = volume_db
    player.play()
```

### 8.3 Audit Checklist

- [ ] UI sound files exist for core interactions
- [ ] Sound manager/controller is implemented
- [ ] Buttons play sounds on hover and click
- [ ] Menu transitions have audio feedback
- [ ] Volume respects audio settings
- [ ] Horror-specific UI sounds exist

---

## 9. Accessibility Considerations

### 9.1 Requirements

- [ ] All interactive elements keyboard-navigable
- [ ] Focus states clearly visible
- [ ] Text meets minimum contrast ratio (4.5:1 for body, 3:1 for large)
- [ ] Font sizes respect user preferences where possible
- [ ] Critical information not conveyed by color alone
- [ ] Screen reader hints on important elements (using `AccessibleButton` patterns)

### 9.2 Colorblind Considerations

For horror-specific colors (blood red, ethereal blue), ensure:
- Icons or patterns accompany color-coded information
- Danger states have additional visual indicators (shape, animation)
- Test with colorblind simulation filters

---

## 10. Implementation Priority

### Phase 1: Foundation (Critical)
1. Install ThemeGen, create design tokens
2. Install Maaack's Menus Template
3. Create `horror_theme_generator.gd`
4. Apply theme to existing UI

### Phase 2: Core Systems (High)
1. Implement `UIAnimations` utility class
2. Build component library (buttons, panels)
3. Set up scene transition system
4. Create HUD manager and interaction prompts

### Phase 3: Polish (Medium)
1. Add UI sounds
2. Implement horror-specific effects (jitter, corruption)
3. Add GameGUI for responsive layouts
4. Build settings persistence

### Phase 4: Refinement (Lower)
1. Accessibility pass
2. Gamepad navigation polish
3. Loading screen with tips
4. Credits screen

---

## Appendix A: Prompt Patterns for Claude Code

When requesting UI work, use these patterns:

**For new components:**
> "Create a [component type] following the component standards in section 6.2. Use the [TypeVariation] theme variation. Apply hover animation using `UIAnimations.apply_hover_scale()`. Store in `res://scenes/ui/components/[category]/`."

**For menu screens:**
> "Create [menu name] extending Maaack's template pattern. Apply horror_theme.tres. All buttons use GhostButton variation with UIAnimations hover effects. Include fade-in animation on _ready()."

**For animation work:**
> "Add [animation type] to [element]. Use DesignTokens.ANIMATION.[timing] for duration. Use [TRANS_TYPE, EASE_TYPE] easing. Reference UIAnimations.[method] pattern."

**For styling fixes:**
> "Audit [file/scene] for hardcoded colors and replace with DesignTokens.COLORS references. Ensure theme_type_variation is set. Apply consistent spacing using DesignTokens.SPACING."

---

## Appendix B: File Checklist Summary

Required files for complete implementation:

```
res://
├── addons/
│   ├── ThemeGen/
│   ├── maaack_menus_template/
│   ├── GameGUI/
│   ├── gloot/
│   ├── anima/
│   └── transit/
├── themes/
│   ├── design_tokens.gd          # Autoload
│   ├── horror_theme_generator.gd
│   └── horror_theme.tres
├── scripts/ui/
│   ├── ui_animations.gd
│   ├── ui_sound_manager.gd
│   └── scene_transition.gd
├── scenes/ui/
│   ├── menus/
│   │   ├── main_menu/
│   │   ├── options_menu/
│   │   ├── pause_menu/
│   │   ├── credits/
│   │   └── loading/
│   ├── hud/
│   │   ├── hud_manager.tscn
│   │   ├── components/
│   │   └── overlays/
│   └── components/
│       ├── buttons/
│       ├── panels/
│       ├── inputs/
│       ├── feedback/
│       └── typography/
└── audio/ui/
    ├── button_hover.wav
    ├── button_click.wav
    └── ...
```
