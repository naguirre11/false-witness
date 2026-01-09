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
- [ ] Ghost Writing Book as placeable EquipmentItem
- [ ] 3D model: worn leather journal, open to blank pages
- [ ] Can be placed on flat surfaces (tables, floors)
- [ ] Remains where placed until picked up

### Placement Mechanics
- [ ] Player places book in suspected entity room
- [ ] Book must be in entity's anchor room for writing to occur
- [ ] Placement position tracked by server

### Writing Trigger
- [ ] Entity writes in book when conditions met:
  - Book in correct room (entity's anchor room)
  - Entity is active (not dormant)
  - Book has been placed for minimum time (30-60 seconds)
- [ ] Writing appears progressively (scribbling animation)
- [ ] Different entities produce different writing styles

### Evidence Collection
- [ ] Player checks book and sees writing → GHOST_WRITING evidence
- [ ] Empty book after sufficient time → negative evidence (entity doesn't have this type)
- [ ] Writing content provides hints about entity type

### Sabotage Vectors (Cultist Opportunities)
- [ ] **Wrong Room**: Cultist moves book to incorrect room
- [ ] **Book Removal**: Cultist picks up book before writing occurs
- [ ] **False Positive Claim**: Cultist claims writing when book is blank
- [ ] **Timing Manipulation**: Cultist retrieves book too early, claims "no writing"

### Verification Protocol
- [ ] Buddy system recommended: one places, one watches
- [ ] Witness to placement AND result creates verification
- [ ] Unwitnessed book placement is single-source evidence

### Writing Outcomes
- [ ] Crude scrawls = basic entity confirmation
- [ ] Specific symbols = entity category hints
- [ ] Recognizable words = strong entity identification
- [ ] No writing after 2+ minutes = entity doesn't have GHOST_WRITING

### Network Sync
- [ ] Book placement position synced
- [ ] Writing state server-authoritative
- [ ] Writing appearance synced to all players who can see book

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
