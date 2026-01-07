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

- [ ] Godot 4.4 project created with project.godot configured
- [ ] Folder structure created:
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
- [ ] .gitignore configured for Godot projects
- [ ] GUT testing addon installed and configured
- [ ] Project compiles without errors: `godot --headless --check-only`

## Technical Notes

- Use Godot 4.4 stable
- Configure project for 3D
- Set default resolution to 1920x1080
- Enable required features in project settings (3D physics, etc.)

## Out of Scope

- Actual game systems implementation
- Asset creation
- Networking setup
