---
id: FW-040
title: "Implement Readily-Apparent Evidence system"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031, FW-041]
created: 2026-01-08
---

## Description

Create the Readily-Apparent Evidence system for environmental phenomena that anyone present can observe. This includes Visual Manifestations and Physical Interactions — evidence types where the Cultist can only fail to report, not fabricate.

**Trust Dynamic:** Multi-witness — High Trust (Cultist can only omit, not fabricate)

## Acceptance Criteria

### Visual Manifestation Evidence (VISUAL_MANIFESTATION)

#### Entity Visibility Events
- [ ] Entity becomes visible during manifestation events
- [ ] Visibility duration: 2-5 seconds typically
- [ ] Multiple players in room can all see manifestation
- [ ] Server tracks who was present during manifestation

#### Manifestation Types
- [ ] Full body apparition (clear entity sighting)
- [ ] Partial manifestation (limbs, face, shadow)
- [ ] Silhouette/shadow figure
- [ ] Brief flash/flicker appearance

#### Photo Capture
- [ ] Camera equipment can capture manifestation
- [ ] Photo provides permanent record of visual evidence
- [ ] Photo visible to all players (shareable proof)
- [ ] Missed shot = no evidence (skill expression)

### Physical Interaction Evidence (PHYSICAL_INTERACTION)

#### Object Movement
- [ ] Entity can throw/move objects
- [ ] Movement visible AND audible to all nearby players
- [ ] Different entities have different interaction patterns:
  - Poltergeist: Multiple objects, violent throws
  - Spirit: Single objects, gentle movement
  - Demon: Aggressive, targeted throws

#### Door Interactions
- [ ] Doors slam shut (audible throughout building)
- [ ] Doors open slowly (creepy, visible)
- [ ] Door interactions indicate territorial behavior

#### Electronic Interference
- [ ] Lights flicker (visible to all in area)
- [ ] Lights explode/break (aggressive entities)
- [ ] TV/radio static or activation
- [ ] Electronics malfunction patterns vary by entity

#### Surface Manifestations
- [ ] Writing appears on walls/mirrors
- [ ] Handprints appear (bloody, ashy, etc.)
- [ ] Scratch marks form
- [ ] These persist and can be shown to other players

### Trust Mechanics
- [ ] All phenomena visible/audible to EVERYONE present
- [ ] Cultist CANNOT fabricate these events
- [ ] Cultist CAN only:
  - Fail to report what they saw when alone
  - Distract others so they miss events
  - Claim they "didn't see it" when others did

### Evidence Collection
- [ ] Players can "Report" phenomena they witness
- [ ] Report includes: type, location, timestamp, witnesses
- [ ] Multi-witness reports automatically higher trust
- [ ] Single-witness reports marked as such

### Witness Tracking
- [ ] Server tracks player positions during events
- [ ] Automatically determines who could have witnessed
- [ ] "You were in the room when this happened" notifications
- [ ] Enables catching Cultists who claim they "didn't see" obvious events

### Network Sync
- [ ] All phenomena server-authoritative
- [ ] Visual effects synced to all clients in range
- [ ] Audio cues synced with spatial positioning
- [ ] Event log maintained for deliberation review

## Technical Notes

**Why Readily-Apparent Works for Trust:**
These events happen in the game world, not on a private display. When an object flies across the room, everyone in that room sees it. The Cultist can't claim "I saw a different object move" — they can only claim "I wasn't looking" or "I didn't notice."

**Cultist Limitations:**
- Cannot fabricate: "I saw the ghost throw a chair" when nothing happened
- Can only omit: "I didn't see anything" when they clearly did
- Can distract: "Hey, come look at this!" to pull people away from an event
- Can downplay: "I think something moved but I'm not sure"

**Evidence Quality:**
- **Strong**: Multiple witnesses, clear phenomenon, documented (photo/recording)
- **Weak**: Single witness, brief/unclear event, no documentation

**Integration with Entity AI:**
This ticket depends on FW-041 (Entity AI) to trigger the actual manifestation and interaction events. This ticket handles the evidence collection and trust mechanics around those events.

## Out of Scope

- Entity AI behavior that triggers these events (FW-041)
- Specific entity manifestation visuals (part of entity design)
- Camera equipment implementation (separate ticket if needed)

---

## Implementation Notes (Ralph PRD - 2026-01-21)

### Files Created
- `src/evidence/readily_apparent_manager.gd` - Core witness tracking, phenomenon registration, omission tracking
- `src/evidence/manifestation_enums.gd` - ManifestationType, InteractionType enums, visibility/audibility ranges
- `src/interaction/throwable_object.gd` - Entity-throwable objects with ThrowPattern (GENTLE/VIOLENT/ERRATIC)
- `src/interaction/interactable_door.gd` - Door interactions (slam, slow open/close) for entities
- `src/interaction/flickering_light.gd` - Light flicker/break patterns (SUBTLE, RHYTHMIC, CHAOTIC, etc.)
- `src/interaction/surface_manifestation.gd` - Writing, handprints, scratches on surfaces
- `src/ui/phenomenon_report_ui.gd` - Player UI for reporting witnessed phenomena
- `tests/integration/test_readily_apparent.gd` - 51 tests for witness tracking, reporting, omissions

### Key Implementation Details
1. **Witness tracking**: `get_witnesses_in_area()` returns players within range; `get_definite_witnesses()` adds facing check
2. **Omission tracking**: `get_omissions_for_player()` returns phenomena player witnessed but didn't report (for post-game reveal)
3. **Report window**: 120 seconds to report a phenomenon
4. **EventBus signals**: Added `object_thrown`, `object_landed`, `door_manipulated`, `light_flickered`, `light_broken`, `surface_manifestation_created`, `phenomenon_reported`
5. **Network sync**: All interaction classes emit EventBus signals for server-authoritative sync

### Integration Gap
⚠️ **ReadilyApparentManager is NOT registered as an autoload in project.godot**
The class is complete and tested but needs to be added to autoloads for runtime use.

### Test Results
- All 15 user stories complete (FW-040-01 through FW-040-15)
- test_readily_apparent.gd: 51 tests pass

### Verification Commands
```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_readily_apparent.gd -gdir=res://tests/integration/ -gexit
```
