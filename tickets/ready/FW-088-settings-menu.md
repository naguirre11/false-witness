---
id: FW-088
title: "Implement settings and options menu"
epic: UI
priority: high
estimated_complexity: medium
dependencies: [FW-081, FW-086]
created: 2026-01-24
phase: 2
---

## Description

Create a comprehensive settings menu accessible from main menu and in-game pause menu. Covers audio, video, controls, and accessibility options.

## Acceptance Criteria

### Audio Settings
- [ ] Master volume slider (0-100%)
- [ ] SFX volume slider
- [ ] Music volume slider
- [ ] Voice volume slider
- [ ] Ambient volume slider
- [ ] Mute all toggle
- [ ] Audio device selection (if multiple outputs)

### Video Settings
- [ ] Resolution dropdown
- [ ] Fullscreen / Windowed / Borderless toggle
- [ ] VSync toggle
- [ ] FPS limit (30/60/120/Unlimited)
- [ ] Graphics quality preset (Low/Medium/High/Ultra)
- [ ] Individual quality options:
  - Shadow quality
  - Anti-aliasing
  - Ambient occlusion
  - Bloom toggle

### Controls Settings
- [ ] Mouse sensitivity slider (0.1 - 3.0)
- [ ] Invert Y-axis toggle
- [ ] Key rebinding for all actions:
  - Movement (WASD)
  - Sprint, Crouch
  - Interact, Use Equipment
  - Toggle Flashlight, Evidence Board
  - Push to Talk
- [ ] Controller support toggle
- [ ] Controller sensitivity

### Accessibility
- [ ] Subtitles toggle
- [ ] Subtitle size (Small/Medium/Large)
- [ ] High contrast UI toggle
- [ ] Screen shake intensity (0-100%)
- [ ] Flash intensity reduction
- [ ] Colorblind mode (None/Deuteranopia/Protanopia/Tritanopia)

### Gameplay Settings
- [ ] Tutorial hints toggle (first 5 matches)
- [ ] Push-to-talk vs open mic
- [ ] Voice activation threshold

### UI/UX
- [ ] Settings persist across sessions (save to user config)
- [ ] Apply button for video changes
- [ ] Reset to defaults button per category
- [ ] Uses DesignTokens for consistent styling

## Technical Notes

Settings stored in `user://settings.cfg` using ConfigFile.

Categories as tabs:
- Audio | Video | Controls | Accessibility | Gameplay

Apply video settings with confirmation dialog (10s timeout reverts).

## Out of Scope

- Cloud save sync
- Profile-based settings
- Advanced graphics options (individual shader toggles)
