FALSE WITNESS
Game Design Document
A Cooperative Horror Investigation Game
with Hidden Traitor Mechanics
Version 1.0
January 2026
Target Platform: PC (Steam)
Engine: Godot 4.4

---

Table of Contents
1. Executive Summary
2. Game Overview
3. Core Gameplay Loop
4. Evidence System & False Evidence Mechanics
5. Traitor Design
6. Entity Design
7. Map & Environment Design
8. Progression & Meta Systems
9. Technical Architecture
10. Networking Strategy
11. Art Direction
12. Audio Design
13. UI/UX Design
14. Development Roadmap
15. Risk Assessment
16. Key Decisions Required
17. Godot Template Recommendations

---

1. Executive Summary
1.1 Vision Statement
False Witness is a 4-6 player cooperative horror investigation game where one player secretly works to mislead the team toward incorrect conclusions. Unlike traditional traitor games that focus on sabotage and elimination, False Witness centers on evidence manipulation and interpretation steering. The traitor wins not by killing teammates, but by causing the group to identify the wrong entity.
1.2 One-Sentence Pitch
"Phasmophobia meets Deception: Murder in Hong Kong — investigate hauntings with your team, but someone is planting false evidence."
1.3 Target Audience
Primary: Friend groups who play Lethal Company, Phasmophobia, R.E.P.O., Content Warning together (the "friendslop" audience)
Secondary: Social deduction fans looking for more mechanical depth than Among Us
Tertiary: Horror game streamers seeking content with high clip potential
1.4 Market Positioning
This game occupies an unexplored niche: investigation horror with unreliable information. Previous horror-traitor hybrids (Dread Hunger, Project Winter, Deceit) failed because they bolted social deduction voting onto survival gameplay. False Witness integrates deception into the core investigation loop itself — the traitor succeeds through plausible misdirection, not obvious sabotage.
1.5 Key Differentiators
False Evidence Mechanics: The traitor plants misleading readings, not just sabotages equipment
Interpretation Over Accusation: Evidence is inherently ambiguous; success comes from steering interpretation
Discovery Doesn't End the Game: Identified traitors retain influence and can still cast doubt
Short Match Length: 15-20 minute investigations prevent horror fatigue and enable replay

---

2. Game Overview
2.1 Core Concept
Players are paranormal investigators contracted by a mysterious organization to document supernatural activity. Each investigation requires the team to identify the specific entity haunting a location by collecting and cross-referencing evidence types. However, one investigator is secretly a Cultist — a plant working to discredit the organization by ensuring investigations reach wrong conclusions.
2.2 Player Count & Roles
Configuration
| Investigators
| Cultists
| Notes
|
4 Players
| 3
| 1
| Minimum viable. Tight, high-tension.
|
5 Players
| 4
| 1
| Sweet spot for balance.
|
6 Players
| 4-5
| 1-2
| Optional 2-Cultist mode for variety.
|

2.3 Win Conditions
Investigators Win If:
Correctly identify the entity type before time expires, OR
Correctly identify AND vote out the Cultist (bonus victory)
Cultist Wins If:
Team submits incorrect entity identification, OR
Time expires without identification, OR
Team votes out an innocent investigator
2.4 Match Structure
Phase
| Duration
| Description
|
Briefing
| 1-2 min
| Team receives location info, selects equipment, Cultist is secretly assigned
|
Investigation
| 12-15 min
| Explore location, collect evidence, entity becomes increasingly aggressive
|
Deliberation
| 3-5 min
| Team discusses findings, can call emergency vote, submits final identification
|
Revelation
| 1 min
| Results shown: correct entity, actual Cultist, individual contributions
|

---

3. Core Gameplay Loop
3.1 Investigation Flow
The core loop follows a collect-verify-deduce pattern that creates natural tension between speed (entity aggression increases over time) and accuracy (rushing leads to mistakes the Cultist can exploit).
Phase 1: Equipment Selection (Pre-Investigation)
Each player selects 3 equipment slots from available tools. Not all evidence types can be detected — teams must coordinate coverage. The Cultist sees what equipment teammates selected, enabling strategic contamination planning.
Phase 2: Evidence Collection
Players spread through the location using equipment to detect paranormal signatures. Each evidence type has distinct collection mechanics requiring different player behaviors (staying still for EMF, speaking for spirit box, etc.).
Phase 3: Cross-Verification
Evidence collected by one player should ideally be verified by another. The UI tracks who collected each piece of evidence, creating an implicit trust/verification layer. Cultists must contaminate evidence before verification or provide plausible reasons for conflicting readings.
Phase 4: Deduction & Submission
The team uses collected evidence to narrow down entity possibilities. A shared evidence board shows all findings. Any player can propose an identification, but submission requires majority agreement (or a called vote).
3.2 Entity Aggression Escalation
Entities become more dangerous over time, creating pressure to conclude investigations quickly:
Time Elapsed
| Aggression Level
| Behavior Changes
|
0-5 min
| Dormant
| Passive manifestations only, evidence is stable
|
5-10 min
| Active
| Occasional hunts, some evidence becomes harder to collect
|
10-15 min
| Aggressive
| Frequent hunts, entity actively interferes with equipment
|
15+ min
| Furious
| Near-constant hunting, escape becomes primary concern
|

This escalation serves multiple design purposes: it prevents games from dragging, creates natural dramatic tension, and gives Cultists a win condition through stalling (though obvious stalling is suspicious).

---

4. Evidence System & False Evidence Mechanics
4.1 Design Philosophy
The evidence system is the heart of what makes False Witness different from other traitor games. Evidence is designed to be inherently ambiguous — multiple entities share evidence types, readings have natural variance, and environmental factors create noise. This ambiguity is a feature, not a bug: it gives Cultists plausible deniability and makes accusation difficult without solid proof.
4.2 Evidence Types
Evidence Type
| Equipment
| Collection Method
| Ambiguity Factor
|
EMF Readings
| EMF Reader
| Proximity to activity
| Levels 1-5; only Level 5 is definitive
|
Spirit Box Response
| Spirit Box
| Asking questions aloud
| Responses can be unclear/partial
|
Ghost Writing
| Journal
| Leave in active area
| Handwriting varies, can be faint
|
Freezing Temps
| Thermometer
| Area temperature reading
| Natural cold spots exist
|
Ultraviolet Traces
| UV Flashlight
| Scan surfaces
| Fingerprints vs. residue distinction
|
DOTS Projection
| DOTS Projector
| Motion in laser field
| Can be triggered by debris
|
Ghost Orbs
| Video Camera
| Review footage
| Dust particles can mimic
|
Spectral Audio
| Parabolic Mic
| Directional listening
| Ambient noise interference
|

4.3 Entity Evidence Matrix
Each entity type produces exactly 3 evidence types. With 8 evidence types and 3 per entity, this allows for 12-15 distinct entities with meaningful differentiation.
Entity
| Evidence 1
| Evidence 2
| Evidence 3
|
Phantom
| EMF 5
| Spirit Box
| DOTS
|
Banshee
| Ghost Orbs
| Fingerprints
| DOTS
|
Revenant
| Freezing
| Ghost Orbs
| Ghost Writing
|
Shade
| EMF 5
| Ghost Writing
| Freezing
|
Poltergeist
| Spirit Box
| Fingerprints
| Ghost Writing
|
Wraith
| EMF 5
| Spirit Box
| DOTS
|
Mare
| Spirit Box
| Ghost Orbs
| Ghost Writing
|
Demon
| Fingerprints
| Ghost Writing
| Freezing
|

Critical Design Note: Several entities share 2 of 3 evidence types (e.g., Phantom and Wraith both have EMF 5 + Spirit Box). This overlap is intentional — it creates situations where the Cultist only needs to contaminate one evidence type to cause misidentification.
4.4 False Evidence Mechanics (Cultist Abilities)
The Cultist has access to special actions that allow evidence contamination. These are designed to be powerful but require skill and timing to use without detection.
Contamination Abilities
EMF Spoof (2 uses): Plant a device that generates false EMF 5 readings in an area. Lasts 60 seconds. Requires 5 seconds of unobserved placement.
Temperature Manipulation (2 uses): Lower temperature in a room to freezing range for 90 seconds. Creates false freezing evidence.
Spirit Box Interference (1 use): Cause the next spirit box session in range to produce a false positive response.
Fingerprint Planting (2 uses): Leave UV-visible traces that mimic ghost fingerprints.
Equipment Sabotage (1 use): Cause a teammate's equipment to malfunction for 30 seconds, preventing evidence collection.
Ability Constraints
Limited uses prevent spam and force strategic timing
Placement/activation has brief animation that can be spotted
Some contaminated evidence has subtle tells for observant players
Using abilities too aggressively creates inconsistencies in the evidence picture
4.5 Evidence Verification Mechanics
To counter Cultist contamination, investigators can verify evidence through multiple methods:
Cross-Verification: Multiple players observing the same evidence with different equipment
Temporal Consistency: Real evidence persists; some fake evidence degrades over time
Pattern Analysis: Real entity behavior follows patterns; contaminated evidence may not fit

---

5. Traitor Design
5.1 Core Philosophy
The Cultist is not a killer or saboteur in the traditional sense. They are a manipulator whose goal is to corrupt the investigation's conclusions. This creates a fundamentally different play experience than games like Among Us or Project Winter.
5.2 Cultist Information Advantage
The Cultist knows:
The true entity type from the start
Which evidence types the real entity produces
Which false evidence would point to incorrect entities
What equipment each teammate brought
5.3 Cultist Win Strategies
Strategy A: Evidence Substitution
Plant false evidence that replaces one of the real entity's types with another. If the real entity is a Phantom (EMF 5, Spirit Box, DOTS) and you plant false Freezing evidence while ensuring EMF 5 isn't collected, you might steer toward a misidentification as a Shade.
Strategy B: Evidence Overload
Plant multiple false evidence types to create an impossible evidence picture that matches no entity, causing confusion and time waste.
Strategy C: Social Engineering
Collect real evidence but misreport it verbally. Claim you saw Ghost Orbs when you didn't. Requires good lying and memory of what you claimed.
Strategy D: Passive Stalling
Don't contaminate at all — instead, slow the investigation through "mistakes," getting lost, requiring help, or leading the team to unproductive areas. Risky because obviously unhelpful behavior is suspicious.
5.4 Discovery & Post-Discovery Play
Unlike many traitor games, being discovered doesn't end the Cultist's game:
Discovered Cultists can still participate in discussion and cast doubt on evidence
Their previously collected evidence becomes suspect, but uncontaminated evidence is still valid
They can't use remaining contamination abilities, but damage already done remains
Voting out a Cultist costs time and requires majority — time the entity uses to escalate
5.5 Anti-Frustration Design
Key design choices to prevent the Cultist role from feeling unfair:
Cultists still experience the horror gameplay (they can be killed by the entity)
Short match length means a bad Cultist game is only 15-20 minutes
Rotating role assignment ensures everyone plays both sides
Post-game breakdown shows Cultist's moves, enabling learning

---

6. Entity Design
6.1 Design Philosophy
Entities serve as environmental pressure and horror atmosphere, not as the primary threat. The real danger is team dysfunction caused by the Cultist. Entities should be scary enough to create tension but not so lethal that investigations end prematurely.
6.2 Entity Behaviors
Behavior
| Description
| Counterplay
|
Hunt Mode
| Entity actively seeks players
| Hide, stay silent, break line of sight
|
Manifestation
| Visual appearance, often preceded by activity
| Observe for evidence, maintain distance
|
Interaction
| Manipulates objects, doors, lights
| Track patterns, use for triangulation
|
Response
| Reacts to player actions (questions, presence)
| Use to confirm evidence types
|

6.3 Death & Respawn
Player death is not permanent within a match:
Dead players become spectators for 60 seconds
Spectators can see the environment but not use equipment or communicate
After 60 seconds, players respawn at the entrance with reduced equipment
Each death increases entity aggression slightly
This system keeps all players engaged while still making death consequential.

---

7. Map & Environment Design
7.1 Location Types
Initial release targets 3-4 maps with distinct layouts and atmospheres:
Location
| Size
| Complexity
| Unique Feature
|
Abandoned House
| Small
| Low
| Tight corridors, limited hiding spots
|
Office Building
| Medium
| Medium
| Multiple floors, elevator system
|
Hospital Wing
| Medium
| High
| Morgue area, procedural room contents
|
Farmstead
| Large
| Medium
| Outdoor areas, multiple buildings
|

7.2 Procedural Elements
While layouts remain static (reducing development scope), the following elements are procedurally placed each match:
Entity spawn room / favorite room
Evidence spawn locations within the entity's active zone
Item and pickup locations
Hiding spot availability
Environmental storytelling elements (notes, photos, clues)
7.3 Art Direction for Environments
Target aesthetic: PS1/PS2 era low-poly with modern lighting. This style achieves multiple goals:
Achievable scope for small team
Nostalgic appeal to target audience
Imagination-filling ambiguity (low detail = player brain fills gaps)
Distinctive visual identity vs. photorealistic horror games

---

8. Progression & Meta Systems
8.1 Design Philosophy
Progression unlocks complexity and variety, not power. Players don't become stronger; they gain access to more options and customization. This preserves horror tension regardless of playtime.
8.2 Progression Tracks
Investigation Journal
A persistent codex documenting entities, evidence types, and lore discovered through play. Entries unlock through gameplay achievements (correctly identify 5 Phantoms, survive 10 hunts, etc.). Provides knowledge advantage for experienced players without mechanical buffs.
Equipment Variants
Alternative equipment with trade-offs rather than upgrades:
Standard Flashlight vs. UV Flashlight (reveals traces but dimmer)
Basic Thermometer vs. Thermal Camera (area scan but slower reading)
Spirit Box vs. Enhanced Spirit Box (clearer audio but shorter range)
Cosmetics
Character customization: investigator outfits, equipment skins, lobby decorations. No gameplay impact.
8.3 Match-End Rewards
Each match awards XP based on:
Evidence collected (regardless of win/loss)
Correct identification (bonus)
Cultist successfully deceived team (Cultist bonus)
Survival (small bonus)

---

9. Technical Architecture
9.1 Engine: Godot 4.4
Godot 4.4 is selected for the following reasons:
Open source with no revenue share or licensing fees
GDScript is accessible for rapid prototyping; C# available for performance-critical systems
Built-in multiplayer high-level API (MultiplayerSpawner, MultiplayerSynchronizer)
Active community and improving 3D capabilities in 4.x series
Developer familiarity (Nathan's existing Godot experience)
9.2 Core Systems Architecture
Game State Machine
Central state machine managing: Lobby → Equipment Select → Investigation → Deliberation → Results. Each state has distinct networking requirements and player permissions.
Evidence System
EvidenceManager (Singleton): Tracks all evidence in the match, handles replication
EvidenceSource (Node): Attached to locations where evidence can appear
EvidenceDetector (Component): Attached to equipment, handles detection logic
ContaminatedEvidence (Subclass): False evidence planted by Cultist, has decay timer
Entity AI
Behavior Tree implementation for entity decision-making
State-based hunting with aggression escalation
Navmesh-based pathfinding with room awareness
Server-authoritative with client-side prediction for responsiveness
Voice Chat Integration
Proximity-based voice using Godot's AudioStreamPlayer3D
Voice activity detection for entity attraction mechanics
Consider: GodotSteam for Steam Voice integration or standalone VOIP solution
9.3 Performance Targets
Metric
| Minimum
| Target
| Notes
|
Frame Rate
| 30 FPS
| 60 FPS
| At 1080p, medium settings
|
Load Time
| < 30s
| < 15s
| Initial map load
|
Network Tick Rate
| 20 Hz
| 30 Hz
| Entity position updates
|
Voice Latency
| < 200ms
| < 100ms
| End-to-end voice delay
|

---

10. Networking Strategy
10.1 Architecture Decision: Peer-to-Peer with Host
After analyzing failed competitors, peer-to-peer (P2P) with player-hosted sessions is strongly recommended over dedicated servers:
Rationale
Eliminates ongoing server costs that killed VHS, Propnight, and others
Matches friendslop usage pattern (friend groups playing together)
Steam's matchmaking and relay services handle NAT traversal
Game can survive indefinitely without studio support
Implementation Approach
Use Godot's ENet-based networking with Steam relay fallback
Host is authoritative for game state (entity behavior, evidence spawns, Cultist assignment)
Critical Cultist data is encrypted/hidden from host inspection where possible
Host migration if original host disconnects
10.2 Steam Integration
GodotSteam plugin provides:
Steam Lobby system for friend invites and matchmaking
Steam Networking Sockets for reliable P2P with relay fallback
Steam Voice (optional alternative to custom VOIP)
Rich Presence for "Join Game" functionality
10.3 Anti-Cheat Considerations
For a social deduction game, cheating is existential — if players can determine who the Cultist is through external tools, the game breaks. Mitigations:
Cultist identity is server-side only; client receives role reveal at match start, not in lobby
Private lobby codes rather than public matchmaking reduces stranger-cheating risk
Post-game replay system allows group to review suspicious behavior
Consider: Steam Family Sharing disabled to prevent ban evasion

---

11. Art Direction
11.1 Visual Style: PS1/PS2 Horror
Target aesthetic references: Silent Hill, Resident Evil (PS1), Fatal Frame. Key characteristics:
Low-poly models with limited texture resolution (256x256 or 512x512)
Vertex lighting with baked shadows
CRT/VHS post-processing effects (scanlines, chromatic aberration, noise)
Limited color palette per environment
Affine texture warping for authentic retro feel
11.2 Character Design
Investigators are deliberately generic — minimal facial features, silhouette-based differentiation. This serves both art scope reduction and horror effectiveness (faceless characters are unsettling).
Entities follow the "glimpse" philosophy: designed to be terrifying in brief encounters, not extended observation. Low-detail models with strong silhouettes and audio design.
11.3 UI Aesthetic
In-world equipment UI (diegetic) where possible: EMF reader has a physical display, thermometer shows temperature on the device. HUD elements styled as investigation paperwork/clipboard.

---

12. Audio Design
12.1 Audio Philosophy
Audio is the primary horror delivery mechanism. Visuals are low-fidelity by design; audio must be high-quality and spatially accurate.
12.2 Key Audio Systems
Proximity Voice Chat
Core mechanic for both atmosphere and gameplay. Voice fades with distance. Entity can "hear" loud voice activity. Technical implementation via GodotSteam or custom WebRTC.
Entity Audio Design
Each entity type has unique audio signatures (footstep patterns, vocalizations, environmental effects)
Hunt audio is distinctive and terrifying — players learn to recognize it instantly
Subtle audio cues differentiate real evidence from contaminated evidence (for attentive players)
Environmental Audio
Dynamic ambient soundscape that responds to entity proximity and aggression level. Silence is as important as sound — sudden quiet is a horror cue.
12.3 Corporate Satire Audio
A calm, corporate narrator provides investigation updates (similar to Lethal Company's announcement system). Juxtaposition of bureaucratic tone with supernatural chaos creates dark comedy.
Examples:
"Investigation efficiency rating: suboptimal. Please increase evidence collection velocity."
"Team member terminated. Productivity impact: minimal. Please continue."

---

13. UI/UX Design
13.1 Evidence Board
Central shared UI element where all collected evidence is displayed. Design priorities:
Shows which player collected each piece of evidence
Visual indicators for verified vs. unverified evidence
Entity possibility matrix that updates as evidence is collected
Accessible via hotkey during investigation, always visible during deliberation
13.2 Equipment Interface
Diegetic UI wherever possible: equipment shows readings on the physical model. Minimal HUD intrusion to maintain immersion.
13.3 Post-Match Summary
Critical for learning and social engagement. Shows:
Correct entity and its evidence types
Cultist reveal with timeline of their actions
Which evidence was real vs. contaminated
Individual contribution breakdown
Humorous superlatives ("Most Screams," "Best Hide," etc.)

---

14. Development Roadmap
14.1 Phase 0: Pre-Production (Weeks 1-4)
Task
| Duration
| Deliverable
|
Technical prototype
| 2 weeks
| Basic networked movement, voice chat proof-of-concept
|
Core loop prototype
| 2 weeks
| Single map, 2 evidence types, no entity, placeholder art
|
Template evaluation
| 1 week
| Decision on FPS template usage (see Section 17)
|
GDD finalization
| Ongoing
| This document, updated with prototype learnings
|

Milestone: Playable prototype demonstrating evidence collection and false evidence planting with 4 networked players.
14.2 Phase 1: Vertical Slice (Weeks 5-16)
Task
| Duration
| Deliverable
|
First map (House)
| 4 weeks
| Complete playable environment
|
Entity AI system
| 3 weeks
| One entity type with full behavior
|
Evidence system complete
| 3 weeks
| All 8 evidence types functional
|
Cultist abilities
| 2 weeks
| All contamination abilities implemented
|
Basic UI/UX
| 2 weeks
| Evidence board, equipment UI, deliberation screen
|
Audio foundation
| 2 weeks
| Entity audio, ambient sound, voice chat integration
|

Milestone: Complete vertical slice: one map, one entity, full evidence system, Cultist role, 4-player networked play.
14.3 Phase 2: Content Expansion (Weeks 17-28)
Task
| Duration
| Deliverable
|
Additional entities (4-6)
| 4 weeks
| Distinct behaviors and evidence combinations
|
Second map (Office)
| 3 weeks
| Medium complexity environment
|
Third map (Hospital)
| 3 weeks
| High complexity environment
|
Progression system
| 2 weeks
| Journal, equipment variants, cosmetics foundation
|
Polish pass
| 3 weeks
| Bug fixes, balance tuning, performance optimization
|
Closed alpha testing
| 3 weeks
| Friend group playtesting, feedback incorporation
|

Milestone: Feature-complete alpha with 3 maps, 5+ entities, full progression system.
14.4 Phase 3: Launch Preparation (Weeks 29-36)
Task
| Duration
| Deliverable
|
Steam page and marketing
| 2 weeks
| Store page, trailer, screenshots
|
Steam Next Fest demo
| 2 weeks
| Polished demo build, fest participation
|
Beta testing
| 3 weeks
| Wider testing, streamer key distribution
|
Launch prep
| 1 week
| Final bug fixes, launch day logistics
|

Target Launch: 9 months from project start, Early Access on Steam.
14.5 Post-Launch Content Plan
Sustaining player interest requires regular content updates. 12-month roadmap:
Month 1-2: Bug fixes, balance patches based on player data
Month 3: New entity pack (2-3 entities)
Month 5: New map
Month 7: New equipment variants, cosmetic drop
Month 9: Second Cultist mode (2 Cultists for 6 players)
Month 12: Major update (new map + entities), 1.0 release consideration

---

15. Risk Assessment
15.1 Technical Risks
Risk
| Likelihood
| Impact
| Mitigation
|
Networking complexity exceeds estimates
| High
| High
| Start networking prototype immediately; use proven templates
|
Voice chat integration issues
| Medium
| High
| Evaluate GodotSteam voice early; have fallback to Discord
|
Entity AI performance problems
| Medium
| Medium
| Profile early; simplify behaviors if needed
|
Godot 4.4 stability issues
| Low
| Medium
| Pin to stable release; avoid bleeding-edge features
|

15.2 Design Risks
Risk
| Likelihood
| Impact
| Mitigation
|
Cultist role feels unfun
| Medium
| Critical
| Extensive playtesting; ensure Cultist has agency even when discovered
|
Evidence system too complex
| Medium
| High
| Tutorial implementation; simplify if playtest feedback indicates confusion
|
Horror loses tension over time
| High
| Medium
| Short match length; escalation system; entity variety
|
Community schism (horror vs deduction fans)
| Medium
| High
| Clear marketing positioning; mode variants for different preferences
|

15.3 Market Risks
Risk
| Likelihood
| Impact
| Mitigation
|
Friendslop market saturation
| Medium
| High
| Differentiate through Cultist mechanic; don't position as "another Lethal Company"
|
Competitor releases similar concept
| Low
| Medium
| Speed to market; build community early
|
Streaming meta shifts away from horror
| Low
| Medium
| Core friend-group audience less dependent on streamers
|
Negative reception to traitor mechanics
| Medium
| High
| Optional "pure co-op" mode with AI Cultist
|

---

16. Key Decisions Required
The following decisions need to be made before or during development. Each has significant implications for scope, timeline, and game feel.
Decision 1: Voice Chat Implementation
Option
| Pros
| Cons
|
GodotSteam Voice
| Integrated with Steam; lower latency; proven reliability
| Requires Steam; less control over audio processing
|
Custom WebRTC
| Platform-agnostic; full control; works without Steam
| Complex implementation; maintenance burden
|
External (Discord)
| Zero implementation; proven quality
| Breaks immersion; no proximity mechanics possible
|

Recommendation: GodotSteam Voice for initial release; custom WebRTC as stretch goal for non-Steam platforms.
Decision 2: Cultist Visibility Post-Discovery
Option
| Pros
| Cons
|
Full exclusion (can't interact)
| Clear consequences; satisfying for investigators
| Boring for discovered Cultist; short gameplay
|
Limited participation (can discuss, can't use equipment)
| Cultist stays engaged; can still influence
| May feel toothless; balance concerns
|
Marked but full participation
| Maximum Cultist agency; psychological gameplay
| May feel unfair to investigators
|

Recommendation: Limited participation — discovered Cultists can observe, discuss, and vote, but cannot collect evidence or use abilities.
Decision 3: Evidence Ambiguity Level
Option
| Pros
| Cons
|
High ambiguity (multiple interpretation)
| More Cultist opportunity; deeper deduction
| Steeper learning curve; potential frustration
|
Medium ambiguity (some overlap)
| Balanced skill floor/ceiling
| May feel arbitrary
|
Low ambiguity (clear evidence)
| Accessible; clear feedback
| Cultist is easily caught; less depth
|

Recommendation: Medium ambiguity with tutorial that teaches cross-verification. Adjust based on playtest data.
Decision 4: Public Matchmaking
Option
| Pros
| Cons
|
Private lobbies only
| Reduces toxicity; matches audience expectations; simpler
| Limits player pool; harder for solo players
|
Public + Private
| Larger audience; more accessible
| Moderation burden; cheating risk; Discord coordination cheating
|
Quick Play with ranked
| Competitive angle; retention driver
| Significant infrastructure; balance nightmare
|

Recommendation: Private lobbies only for 1.0. Evaluate public matchmaking post-launch based on community demand.
Decision 5: Monetization Strategy
Option
| Pros
| Cons
|
Premium ($9.99)
| Matches market; simple; friendslop standard
| Barrier to friend group adoption
|
Premium with cosmetic DLC
| Ongoing revenue; player expression
| Content split concerns; DLC fatigue
|
Free with cosmetic shop
| Maximum reach; viral potential
| Requires constant content; F2P stigma in horror
|

Recommendation: Premium at $9.99 with optional cosmetic DLC packs post-launch. Consider 24-hour free launch window for visibility (Content Warning strategy).

---

17. Godot Template Recommendations
17.1 Template Evaluation Criteria
For a networked first-person horror game, templates should provide:
First-person controller with smooth movement and interaction
Multiplayer foundation (lobby system, player synchronization)
Item/inventory system
Godot 4.4 compatibility
Clean, documented code for modification
17.2 Recommended Templates
Option A: FPS Template by GDQuest
Provides: First-person controller, basic interaction system
Missing: Multiplayer, inventory, horror-specific features
Effort to adapt: Medium — good starting point, networking needs full implementation
Option B: Cogito (Horror FPS Framework)
Provides: First-person controller, interaction system, inventory, save/load, Phasmophobia-like structure
Missing: Multiplayer (designed for single-player)
Effort to adapt: High — excellent feature set but retrofitting multiplayer is complex
Option C: Multiplayer FPS Kit (Various Asset Store)
Provides: Networked FPS foundation, lobby system, player sync
Missing: Horror-specific features, investigation mechanics
Effort to adapt: Medium — networking foundation saves significant time
Option D: Build from Scratch
Provides: Full control, no legacy code constraints
Missing: Everything — requires implementing all systems
Effort to adapt: Very High — but cleanest architecture
17.3 Recommendation
Given the unique requirements (multiplayer + investigation + social deduction), a hybrid approach is recommended:
Start with a Multiplayer FPS template for networking foundation
Reference Cogito's design patterns for inventory and interaction systems
Build evidence and Cultist systems from scratch (no template covers this)
Spend Week 1-2 evaluating specific templates with these criteria. Create a proof-of-concept with the top candidate before committing.

---

Appendix A: Reference Games
Game
| Relevance
| Key Learnings
|
Phasmophobia
| Investigation mechanics
| Evidence system design, entity behaviors, equipment variety
|
Lethal Company
| Friendslop formula
| Proximity chat, corporate horror-comedy, extraction loop
|
Content Warning
| Attribution system
| Post-run breakdown, individual contribution tracking
|
Among Us
| Social deduction
| Traitor role design, voting mechanics, post-death engagement
|
Deception: Murder in Hong Kong
| False evidence
| Ambiguous clues, interpretation steering, no elimination
|
Project Winter
| Hybrid horror-traitor
| What NOT to do: complexity overload, player schism
|

Appendix B: Glossary
Friendslop: Genre term for co-op games prioritizing emergent comedy and friend group experiences over polish
Cultist: The traitor role in False Witness; a player working to sabotage investigation conclusions
Contaminated Evidence: False evidence planted by the Cultist that mimics real paranormal readings
Cross-Verification: Multiple players confirming the same evidence to increase confidence
Hunt: Entity aggressive state where it actively pursues and can kill players
Deliberation: End-of-match phase where team discusses findings and votes on entity identification

— End of Document —
