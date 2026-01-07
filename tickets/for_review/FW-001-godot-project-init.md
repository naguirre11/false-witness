---
id: FW-001
title: "Initialize Godot 4.4 project with folder structure"
epic: FOUNDATION
priority: high
estimated_complexity: small
dependencies: []
created: 2026-01-07
---

## Description

Set up the base Godot 4.4 project with the standard folder structure for False Witness. This establishes the foundation for all subsequent development.

## Acceptance Criteria

- [x] Godot 4.4 project created with project.godot configured
- [x] Folder structure created:
  ```
  src/
    core/           # Core systems, managers, autoloads
    gameplay/       # Game mechanics (evidence, entity, cultist)
    ui/             # UI scenes and scripts
    player/         # Player controller, equipment
  assets/
    models/
    textures/
    audio/
    fonts/
  scenes/
    maps/
    entities/
    equipment/
  tests/            # GUT test files
  addons/           # Third-party addons (GUT, etc.)
  ```
- [x] .gitignore configured for Godot projects
- [x] GUT testing addon installed and configured
- [x] Project compiles without errors: `godot --headless --check-only`

## Technical Notes

- Use Godot 4.4 stable
- Configure project for 3D
- Set default resolution to 1920x1080
- Enable required features in project settings (3D physics, etc.)

## Out of Scope

- Actual game systems implementation
- Asset creation
- Networking setup

---

## Implementation Notes

**Completed**: 2026-01-07

### What was done:
- Created `project.godot` configured for Godot 4.4, 3D, Forward Plus renderer, 1920x1080
- Created full folder structure with `.gdkeep` files to track empty directories
- Added comprehensive `.gitignore` for Godot projects
- Installed GUT v9.3.0 testing addon and enabled in project
- Created example test file at `tests/test_example.gd`
- Added `.gutconfig.json` for test configuration
- Pre-configured physics layers and common input actions (WASD, sprint, crouch, interact)

### Verification:
```bash
# Project imports and compiles successfully:
godot --headless --path . --import
# Output: All 66 scripts processed, no errors
```

### Files created:
- `project.godot` - Main project configuration
- `icon.svg` - Placeholder project icon
- `.gitignore` - Godot-specific ignores
- `.gutconfig.json` - GUT test configuration
- `tests/test_example.gd` - Example test (can be deleted)
- `addons/gut/` - GUT testing framework v9.3.0
