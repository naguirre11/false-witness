---
id: FW-093
title: "Implement environmental audio system"
epic: AUDIO
priority: medium
estimated_complexity: medium
dependencies: [FW-091]
created: 2026-01-24
phase: 2
---

## Description

Create an environmental audio system for ambient sounds, room-specific audio, and atmospheric horror soundscapes. Builds on AudioManager foundation.

## Acceptance Criteria

### Ambient Zones
- [ ] Define audio zones per room/area
- [ ] Crossfade between zones as player moves
- [ ] Layer multiple ambient tracks
- [ ] Volume based on distance to zone center

### Room-Specific Ambience
- [ ] Kitchen: Refrigerator hum, dripping faucet
- [ ] Bathroom: Dripping water, fan hum
- [ ] Basement: Deep rumble, pipe creaks
- [ ] Bedroom: Clock ticking, curtain rustle
- [ ] Office: Computer hum, fluorescent buzz
- [ ] Hospital: Heart monitors, PA crackle

### Weather/Time Effects
- [ ] Rain on windows (exterior rooms)
- [ ] Thunder (random, distant)
- [ ] Wind howling
- [ ] Night ambience (crickets, owl)

### Horror Stingers
- [ ] Random creepy sounds (distant footsteps, whispers)
- [ ] Triggered by sanity level
- [ ] Triggered by proximity to entity
- [ ] Non-diegetic tension builders

### Dynamic Music System
- [ ] Investigation music (calm, tense variants)
- [ ] Hunt music (intense, chase)
- [ ] Deliberation music (discussion theme)
- [ ] Transition smoothly between states

### Spatial Audio
- [ ] 3D positioned ambient sources
- [ ] Occlusion through walls (muffled)
- [ ] Reverb based on room size
- [ ] Distance attenuation

### Audio Occlusion
- [ ] Sounds through closed doors are muffled
- [ ] Walls block high frequencies
- [ ] Open doors allow sound through
- [ ] Entity footsteps affected by occlusion

## Technical Notes

Zone system using Area3D:
```gdscript
class_name AmbientZone extends Area3D

@export var ambient_track: AudioStream
@export var volume_db: float = -10.0
@export var crossfade_time: float = 2.0

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        AudioManager.crossfade_ambient(ambient_track, crossfade_time)
```

## Out of Scope

- Procedural audio generation
- Voice acting
- Lip sync
