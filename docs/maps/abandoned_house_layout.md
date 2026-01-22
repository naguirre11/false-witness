# Abandoned House - Floor Plan Layout

## Overview

Small two-story house with basement and attic. Designed for 4-6 players with tight corridors and multiple hiding spots. Total of 8 main rooms plus hallways.

**Design Goals:**
- PS1/PS2 aesthetic (low-poly, simple textures)
- Tight corridors for tension
- Multiple hiding spots per floor
- Clear navigation between rooms
- Varied lighting conditions

---

## Floor Plan - Main Floor

```
                    NORTH
                      ^
                      |
    +------------------+------------------+
    |                  |                  |
    |    KITCHEN       |    LIVING        |
    |    (4x4m)        |    ROOM          |
    |    [T][C]        |    (5x5m)        |
    |    [H1]          |                  |
    |    E1 E2         |    [TV]          |
    +-------[D1]-------+    E3 E4         |
    |                  |    [COUCH]       |
    |    HALLWAY       +-------[D2]-------+
    |    (1.5m wide)   |                  |
    |    [L]           |    ENTRYWAY      |
    |    [STAIRS UP]   |    (3x4m)        |
    |                  |    [SPAWNS]      |
    +-------[D3]-------+    S1 S2 S3      |
    |                  |    S4 S5 S6      |
    |    BASEMENT      |    [FRONT DOOR]  |
    |    STAIRS        +------------------+
    |    [DOWN]        |
    +------------------+
          SOUTH

Legend:
[D#] = Door
[L]  = Light Switch
[T]  = Table
[C]  = Cabinets
[TV] = TV Stand
[H#] = Hiding Spot
E#   = Evidence Spawn Point
S#   = Player Spawn Point
```

---

## Floor Plan - Upper Floor

```
                    NORTH
                      ^
                      |
    +------------------+------------------+
    |                  |                  |
    |   BATHROOM       |   MASTER         |
    |   (3x3m)         |   BEDROOM        |
    |   [MIRROR]       |   (4x4m)         |
    |   [L]            |   [L]            |
    |   E5 E6          |   [BED]          |
    |   [TUB]          |   [H2] closet    |
    +-------[D4]-------+   [H3] under-bed |
    |                  |   E7 E8 E9       |
    |   UPPER HALLWAY  +-------[D5]-------+
    |   (1.5m wide)    |                  |
    |   [L]            |   SECOND         |
    |   [STAIRS DOWN]  |   BEDROOM        |
    |                  |   (3x4m)         |
    +------------------+   [L]            |
    |                  |   [BED]          |
    |   ATTIC          |   [DESK]         |
    |   ACCESS         |   [H4] closet    |
    |   [LADDER]       |   E10 E11        |
    +------------------+-------[D6]-------+
          SOUTH

Legend:
[D#] = Door
[L]  = Light Switch
[H#] = Hiding Spot
E#   = Evidence Spawn Point
```

---

## Floor Plan - Basement

```
                    NORTH
                      ^
                      |
    +--------------------------------------+
    |                                      |
    |              BASEMENT                |
    |              (8x6m)                  |
    |                                      |
    |    [SHELVING]         [SHELVING]     |
    |    [H5]               [H6]           |
    |                                      |
    |    E12  E13  E14  E15                |
    |                                      |
    |    [BOXES]           [WORKBENCH]     |
    |                                      |
    |    [L] (dim)                         |
    |                                      |
    +----------------[STAIRS UP]-----------+
          SOUTH
```

---

## Floor Plan - Attic

```
                    NORTH
                      ^
                      |
    +--------------------------------------+
    |  /                                \  |
    | /         ATTIC (6x4m)             \ |
    |/           Sloped ceiling           \|
    |                                      |
    |    [OLD FURNITURE]    [BOXES]        |
    |                                      |
    |    E16  E17  E18                     |
    |                                      |
    |    NO LIGHT (flashlight required)    |
    |                                      |
    +----------------[LADDER DOWN]---------+
          SOUTH
```

---

## Room Details

### Main Floor

| Room | Dimensions | Doors | Hiding Spots | Evidence Points | Notes |
|------|------------|-------|--------------|-----------------|-------|
| Entryway | 3x4m | Front door, D2 | None | None | Spawn area, clear sightlines |
| Living Room | 5x5m | D2, D1 | None | E3, E4 | Main gathering, TV stand, couch |
| Kitchen | 4x4m | D1 | H1 (cabinet) | E1, E2 | Interactable cabinets |
| Hallway | 1.5m wide | D1, D3, stair access | None | None | Tight corridor, light switch |

### Upper Floor

| Room | Dimensions | Doors | Hiding Spots | Evidence Points | Notes |
|------|------------|-------|--------------|-----------------|-------|
| Master Bedroom | 4x4m | D5 | H2 (closet), H3 (under bed) | E7, E8, E9 | Primary hiding location |
| Second Bedroom | 3x4m | D6 | H4 (closet) | E10, E11 | Entity favorite candidate |
| Bathroom | 3x3m | D4 | None | E5, E6 | Mirror for manifestations |
| Upper Hallway | 1.5m wide | D4, D5, D6, attic access | None | None | Tight, connects all rooms |

### Below/Above

| Room | Dimensions | Access | Hiding Spots | Evidence Points | Notes |
|------|------------|--------|--------------|-----------------|-------|
| Basement | 8x6m | Stairs from hallway | H5, H6 (behind shelves) | E12, E13, E14, E15 | Dark, high tension |
| Attic | 6x4m | Ladder from upper hallway | None | E16, E17, E18 | No lights, cramped |

---

## Hiding Spots Summary

| ID | Location | Type | Detection Difficulty |
|----|----------|------|---------------------|
| H1 | Kitchen | Cabinet | Medium |
| H2 | Master Bedroom | Closet | Low |
| H3 | Master Bedroom | Under bed | High |
| H4 | Second Bedroom | Closet | Low |
| H5 | Basement | Behind shelves (east) | Medium |
| H6 | Basement | Behind shelves (west) | Medium |

**Detection Difficulty:**
- Low: Entity checks immediately
- Medium: 50% chance entity checks
- High: Entity only checks if player recently entered room

---

## Evidence Spawn Points Summary

| ID | Room | Compatible Evidence Types |
|----|------|--------------------------|
| E1-E2 | Kitchen | EMF, Temperature, Writing |
| E3-E4 | Living Room | EMF, Temperature, Aura |
| E5-E6 | Bathroom | Writing (mirror), Temperature |
| E7-E9 | Master Bedroom | All types |
| E10-E11 | Second Bedroom | All types |
| E12-E15 | Basement | All types (high probability) |
| E16-E18 | Attic | All types (high probability) |

**Notes:**
- Basement and Attic have higher evidence spawn probability (entity favorite room candidates)
- Bathroom mirror supports Ghost Writing manifestations
- All points support EMF and Temperature readings

---

## Navigation Flow

### Main Floor Connections
```
ENTRYWAY <--> LIVING ROOM <--> KITCHEN
                  |
              HALLWAY (stairs up, stairs down)
```

### Upper Floor Connections
```
MASTER BEDROOM <--> UPPER HALLWAY <--> SECOND BEDROOM
                         |
                    BATHROOM
                         |
                  (attic access)
```

### Vertical Connections
```
ATTIC
  ^
  | (ladder)
UPPER HALLWAY
  ^
  | (stairs)
MAIN HALLWAY
  ^
  | (stairs)
BASEMENT
```

---

## Lighting Configuration

| Room | Default State | Light Type | Switch Location |
|------|---------------|------------|-----------------|
| Entryway | ON | OmniLight | By front door |
| Living Room | ON | OmniLight | By D2 |
| Kitchen | OFF | OmniLight | By D1 |
| Main Hallway | ON | OmniLight | Center |
| Master Bedroom | OFF | OmniLight | By D5 |
| Second Bedroom | OFF | OmniLight | By D6 |
| Bathroom | OFF | OmniLight | By D4 |
| Upper Hallway | ON | OmniLight | Center |
| Basement | OFF | OmniLight (dim) | Top of stairs |
| Attic | N/A | None | Flashlight required |

---

## Build Order Recommendation

1. **FW-071-03**: Entryway (spawn area) - establish scale
2. **FW-071-04**: Living Room - main gathering space
3. **FW-071-05**: Kitchen - interactable cabinets
4. **FW-071-11**: Hallways and stairs - connect rooms
5. **FW-071-06**: Master Bedroom - hiding spots
6. **FW-071-07**: Second Bedroom
7. **FW-071-08**: Bathroom - mirror
8. **FW-071-09**: Basement - dark atmosphere
9. **FW-071-10**: Attic - cramped space
10. **FW-071-12-13**: Doors and light switches
11. **FW-071-14-20**: Systems (hiding spots, navigation, evidence, lighting, collision)
