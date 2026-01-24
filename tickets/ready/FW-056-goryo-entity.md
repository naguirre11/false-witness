---
id: FW-056
title: "Implement Goryo entity"
epic: ENTITY
priority: high
estimated_complexity: medium
dependencies: [FW-044, FW-040c]
created: 2026-01-24
phase: 2
---

## Description

Implement the Goryo entity - a ghost that only shows itself through cameras and rarely leaves its favorite room. The Goryo is the "camera ghost" that rewards video camera usage.

## Evidence Profile

| Evidence Type | Category |
|---------------|----------|
| AURA_PATTERN | Equipment-Derived (Cooperative) |
| VISUAL_MANIFESTATION | Readily-Apparent |
| EMF_SIGNATURE | Equipment-Derived |

**Overlap with:** Banshee (AURA + VISUAL) - differentiate by EMF vs HUNT_BEHAVIOR

## Acceptance Criteria

### Core Behavior
- [ ] Extends Entity base class
- [ ] Rarely leaves favorite room (90% of time in favorite room)
- [ ] Only manifests visually when viewed through camera
- [ ] Low roaming tendency

### Unique Behavioral Tells
- [ ] **Camera-only manifestation**: Visual form only appears on camera feed
- [ ] **Room bound**: Almost never leaves favorite room
- [ ] **Photo evidence**: Primary source of VISUAL_MANIFESTATION evidence

### Camera Interaction
- [ ] Manifests when camera is pointed at it (not direct view)
- [ ] Manifestation visible in camera viewport/viewfinder
- [ ] Photos capture manifestation as evidence
- [ ] Direct player view sees nothing (or faint shimmer)

### Hunt Behavior
- [ ] Hunt speed: 1.7 m/s
- [ ] Rarely hunts outside favorite room
- [ ] Hunt range limited (won't chase far from room)
- [ ] Returns to favorite room quickly after failed hunt

### Evidence Generation
- [ ] Produces aura anchor for AURA_PATTERN
- [ ] VISUAL_MANIFESTATION only through camera
- [ ] Generates EMF in favorite room

### Favorite Room Behavior
- [ ] Strongly prefers one room
- [ ] 90% activity in favorite room
- [ ] Will return to favorite room if lured out
- [ ] Favorite room has higher EMF readings

### Visual Design
- [ ] Traditional Japanese ghost aesthetic
- [ ] Long dark hair, white clothing
- [ ] More solid appearance on camera than direct view
- [ ] Subtle shimmer when viewed directly

## Technical Notes

Camera manifestation check:
```gdscript
func should_manifest() -> bool:
    var cameras := get_tree().get_nodes_in_group("cameras")
    for camera in cameras:
        if camera.is_looking_at(global_position):
            return true
    return false
```

## Out of Scope

- Multiple camera requirements
- Destroying cameras
- Video recording playback
