---
id: FW-039
title: "Implement Ghost Writing Book (triggered test equipment)"
epic: EVIDENCE
priority: high
estimated_complexity: medium
dependencies: [FW-031, FW-023]
created: 2026-01-08
---

## Description

Create the Ghost Writing Book, a triggered test equipment that players place in the entity's room and wait for writing to appear. This is the only "Triggered Test" evidence type, with unique sabotage vulnerability.

**Trust Dynamic:** Triggered Test — Sabotage Risk (setup can be corrupted)

## Acceptance Criteria

### Equipment Implementation
- [x] Ghost Writing Book as placeable EquipmentItem
- [ ] 3D model: worn leather journal, open to blank pages (deferred - needs asset)
- [x] Can be placed on flat surfaces (tables, floors)
- [x] Remains where placed until picked up

### Placement Mechanics
- [x] Player places book in suspected entity room
- [x] Book must be in entity's anchor room for writing to occur
- [x] Placement position tracked by server

### Writing Trigger
- [x] Entity writes in book when conditions met:
  - Book in correct room (entity's anchor room)
  - Entity is active (not dormant)
  - Book has been placed for minimum time (30-60 seconds)
- [x] Writing appears progressively (scribbling animation) - state machine tracks progress
- [x] Different entities produce different writing styles (WritingStyle enum)

### Evidence Collection
- [x] Player checks book and sees writing → GHOST_WRITING evidence
- [x] Empty book after sufficient time → negative evidence (entity doesn't have this type)
- [x] Writing content provides hints about entity type (via WritingStyle)

### Sabotage Vectors (Cultist Opportunities)
- [x] **Wrong Room**: Cultist moves book to incorrect room - tracked via _placed_room_id
- [x] **Book Removal**: Cultist picks up book before writing occurs - tracked in move_history
- [x] **False Positive Claim**: Cultist claims writing when book is blank - check_book returns has_writing
- [x] **Timing Manipulation**: Cultist retrieves book too early, claims "no writing" - tracked

### Verification Protocol
- [x] Buddy system recommended: one places, one watches - setup_witness_id
- [x] Witness to placement AND result creates verification - setup/result witness tracking
- [x] Unwitnessed book placement is single-source evidence - WEAK quality without witnesses

### Writing Outcomes
- [x] Crude scrawls = basic entity confirmation (WritingStyle.CRUDE_SCRAWLS)
- [x] Specific symbols = entity category hints (WritingStyle.SYMBOLS)
- [x] Recognizable words = strong entity identification (WritingStyle.WORDS)
- [x] No writing after 2+ minutes = entity doesn't have GHOST_WRITING (negative evidence)

### Network Sync
- [x] Book placement position synced
- [x] Writing state server-authoritative
- [x] Writing appearance synced to all players who can see book

## Technical Notes

**Sabotage Detection:**
The system should track:
- Who placed the book
- Where it was placed
- If it was moved (and by whom)
- Time between placement and check

This metadata helps during deliberation: "The book was in the basement, but it was moved to the kitchen before anyone checked it."

**Cultist Strategy:**
- Move book to wrong room when unobserved
- Check book too early and report "no writing"
- Wait for writing then remove book, claim it was blank
- Place book in obviously wrong location to waste team time

**Counter-Strategy:**
- Always place with a witness
- Check book with a witness
- Note book location and verify it hasn't moved
- Cross-reference with other evidence

**Reading Quality:**
- **Strong**: Book in correct room, witnessed placement and check, clear writing
- **Weak**: Unwitnessed, book may have been moved, ambiguous marks

## Out of Scope

- Multiple books (one book per team)
- Entity-specific writing content (part of entity design)
- Cultist ability to forge writing (FW-052)

## Implementation Notes (2026-01-09)

### Files Created/Modified

**New Files:**
- `src/equipment/ghost_writing_book.gd` - GhostWritingBook class (680 lines)
- `tests/test_ghost_writing_book.gd` - Comprehensive unit tests (36 tests)

**Modified Files:**
- `src/equipment/equipment.gd` - Added `GHOST_WRITING_BOOK` to EquipmentType enum

### Architecture

The GhostWritingBook extends Equipment and implements:

1. **State Machine** (BookState enum):
   - HELD → PLACED → WRITING → WRITTEN → CHECKED
   - Progressive writing with configurable duration (3s default)
   - Writing check interval (1s) for entity detection

2. **Writing Styles** (WritingStyle enum):
   - NONE, CRUDE_SCRAWLS, SYMBOLS, WORDS
   - Quality increases from scrawls to words
   - Entity determines writing style via `get_ghost_writing_style()` method

3. **Sabotage Tracking**:
   - `_original_placer_id` - Who placed the book
   - `_was_moved` - Flag if non-placer moved the book
   - `_move_history` - Array of move records with mover_id, positions, time
   - `_placed_room_id` / `_entity_room_id` - Room comparison for wrong-room detection
   - Sabotage flags applied to Evidence: "book_moved", "wrong_room"

4. **Witness System**:
   - `_setup_witness_id` - Player who witnessed placement
   - `_result_witness_id` - Player who witnessed result check
   - Evidence quality WEAK without both witnesses
   - Checker automatically becomes result witness (if not placer)

5. **Evidence Quality**:
   - STRONG requires: not moved, both witnesses, writing > CRUDE_SCRAWLS
   - WEAK otherwise

6. **Entity Integration**:
   - Finds entities via `get_tree().get_nodes_in_group("entities")`
   - Checks `has_evidence_type(GHOST_WRITING)` or `evidence_types` property
   - Checks `is_active()` or `is_dormant` property
   - Gets anchor room via `get_anchor_room_id()` or `anchor_room_id` property

### Test Commands

```bash
# Run Ghost Writing Book tests only
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gtest=res://tests/test_ghost_writing_book.gd -gexit

# Run all tests
$GODOT --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gsuffix=.gd -gexit
```

### Test Results

- 36/36 tests passing
- All 1227 project tests passing
- Linting and formatting validated
