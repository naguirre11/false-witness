---
id: FW-038
title: "Implement Dowsing Rods + Aura Imager (cooperative asymmetric equipment)"
epic: EVIDENCE
priority: high
estimated_complexity: large
dependencies: [FW-031, FW-023]
created: 2026-01-08
---

## Description

Create the Dowsing Rods + Aura Imager, a two-part cooperative equipment where only ONE operator (the Imager) can lie. The Dowser's position is visible to everyone, neutralizing their ability to deceive. This creates strategic role selection dynamics.

**Trust Dynamic:** Cooperative — Asymmetric (only Imager can lie; Dowser is neutralized)

## Acceptance Criteria

### Equipment Components

#### Dowsing Rods
- [ ] 3D model: traditional copper L-rods with wooden handles
- [ ] Held loosely in both hands, extended forward
- [ ] Rods physically react (cross/spread) based on positioning
- [ ] Rod position visible to ALL nearby players

#### Aura Imager
- [ ] 3D model: modified camera with treated crystal lens
- [ ] Screen on back showing aura visualization
- [ ] Screen only clearly visible to operator (viewing angle)
- [ ] Must be aimed at Dowser's back/rods

### Operation Procedure
- [ ] Step 1: Dowser holds rods extended, facing suspected anchor point
- [ ] Step 2: Imager positions behind Dowser, aims at their back/rods
- [ ] Step 3: Imager gives verbal directions: "Step left... raise them slightly..."
- [ ] Step 4: Dowser adjusts position per directions, holds steady when directed
- [ ] Step 5: Imager watches screen for pattern resolution
- [ ] Step 6: Imager announces entity signature when aura pattern resolves

### Spatial Constraints (Critical)
- [ ] Dowser MUST face anchor point (turning breaks alignment)
- [ ] Imager MUST be behind Dowser (screen aimed at rods)
- [ ] This spatial separation is PHYSICAL NECESSITY, not arbitrary rule
- [ ] Dowser cannot see Imager's screen without breaking operation

### Evidence Outcomes
- [ ] Aura Color determines entity temperament:
  - Cold blue = Passive/shy entity
  - Hot red = Aggressive entity
  - Pale green = Territorial entity
  - Deep purple = Roaming entity
- [ ] Aura Form provides secondary info:
  - Tight, contained = Passive
  - Spiking, erratic = Aggressive
  - Diffuse, spreading = Territorial
  - Swirling, mobile = Roaming
- [ ] Combined color+form = AURA_PATTERN evidence type

### Trust Mechanics
- [ ] **Dowser CANNOT lie**: Rod positioning visible to everyone; they face away from screen
- [ ] **Imager CAN lie**: They alone see screen clearly; control direction and interpretation
- [ ] Third player CAN watch over Imager's shoulder (costs coverage elsewhere)

### Strategic Implications
- [ ] Cultist wants Imager role — only position where they can corrupt evidence
- [ ] Paranoid teams can force suspects into Dowser role (neutralizes lying)
- [ ] Innocent players might volunteer for Imager to build trust
- [ ] Cultist might AVOID Imager role to seem less suspicious

### Reading Quality
- [ ] **Strong**: Proper alignment, steady positioning, clear pattern resolution
- [ ] **Weak**: Rushed, Dowser fumbling, incomplete pattern

### Network Sync
- [ ] Dowser rod positions synced (visible to all)
- [ ] Imager screen state server-authoritative
- [ ] Evidence submission requires both players in position

## Technical Notes

**Why Dowser Can't See Screen:**
The Dowser faces the anchor point with their back to the Imager. Turning around breaks rod alignment. The roles are spatially separated by necessity — this isn't an arbitrary rule but emerges from the equipment's physical operation.

**Cultist Strategies:**
- As Imager: Report false color/form; give misleading positioning directions to waste time
- As Dowser: Cannot lie about evidence, but CAN intentionally fumble positioning to delay
- Role Selection: Cultist benefits from Imager role but this may raise suspicion

**Counter-Strategies:**
- Assign suspected player to Dowser role (neutralizes lying ability)
- Third player watches over Imager's shoulder (but costs coverage)
- Cross-reference Aura Pattern with Hunt Behavior (behavioral ground truth catches lies)

**UI Considerations:**
- Dowser sees: Rod position feedback, direction they're facing
- Imager sees: Aura visualization on screen, resolution progress indicator
- Third-party observers see: Dowser's rod positions, back of Imager's screen

## Out of Scope

- Solo operation mode (always requires two players)
- Cultist-specific abilities (FW-052)

---

## Implementation Notes (Ralph PRD - 2026-01-21)

### Files Created
- `src/equipment/aura/aura_enums.gd` - AuraColor, AuraForm, EntityTemperament enums + mappings
- `src/equipment/aura/spatial_constraints.gd` - Position validation (behind check, facing check, distance)
- `src/equipment/aura/dowsing_rods.gd` - Dowser equipment with rod angles, behavior, anchor detection
- `src/equipment/aura/aura_imager.gd` - Imager equipment with resolution system, positioning validation
- `scenes/ui/aura_imager_view.tscn` - Camera screen UI with aura visualization, resolution thresholds
- `scenes/equipment/dowsing_rods.tscn` - 3D L-rod copper rod placeholder (independent left/right animation)
- `scenes/equipment/aura_imager.tscn` - 3D camera with crystal lens placeholder
- `tests/unit/test_aura_enums.gd` - Enum mapping tests
- `tests/unit/test_spatial_constraints.gd` - Position validation tests
- `tests/integration/test_dowsing_rods.gd` - Dowser mechanics tests
- `tests/integration/test_aura_imager.gd` - Imager mechanics tests

### Key Implementation Details
1. **Asymmetric trust**: Dowser state exposed via `get_observable_state()` - visible to all. Imager screen is private.
2. **Spatial validation**: `spatial_constraints.gd` enforces behind-check, distance validation
3. **Resolution thresholds**: 30% for color, 50% for form, 70% for full reading
4. **Direction commands**: DirectionCommand enum with verbal relay mechanic
5. **Third-party verification**: `can_observer_see_screen()` allows shoulder-watching

### Test Results
- All 15 user stories complete (FW-038-01 through FW-038-15)
- Full test suite passes

### Verification Commands
```bash
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_aura_imager.gd -gdir=res://tests/integration/ -gexit
$GODOT --headless -s addons/gut/gut_cmdln.gd -gtest=test_spatial_constraints.gd -gdir=res://tests/unit/ -gexit
```
