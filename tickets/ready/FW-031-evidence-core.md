---
id: FW-031
title: "Create core evidence system architecture"
epic: EVIDENCE
priority: high
estimated_complexity: large
dependencies: [FW-002, FW-023]
created: 2026-01-07
---

## Description

Build the core evidence system that manages evidence spawning, collection, and tracking. This is the heart of the investigation gameplay.

## Acceptance Criteria

- [ ] EvidenceManager autoload for tracking all evidence
- [ ] EvidenceSource node for evidence spawn locations
- [ ] Evidence base class with type, collector, verified status
- [ ] Evidence spawns based on entity type (3 per entity)
- [ ] Evidence collection triggers via equipment
- [ ] Collected evidence registered with EvidenceManager
- [ ] Evidence state synced across network (server-authoritative)
- [ ] Events emitted when evidence collected

## Technical Notes

From GDD - each entity produces exactly 3 evidence types:
```gdscript
enum EvidenceType {
    EMF_5,
    SPIRIT_BOX,
    GHOST_WRITING,
    FREEZING_TEMPS,
    UV_TRACES,
    DOTS_PROJECTION,
    GHOST_ORBS,
    SPECTRAL_AUDIO
}
```

Evidence has inherent ambiguity - multiple entities share evidence types.

## Out of Scope

- Individual evidence type implementations
- False evidence (Cultist epic)
- Evidence board UI
