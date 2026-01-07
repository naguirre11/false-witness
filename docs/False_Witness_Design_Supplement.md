FALSE WITNESS
Design Supplement
Competitive Analysis & Recommended Improvements
Companion Document to Main GDD
January 2026

---

Executive Summary
This supplement identifies nine improvements to False Witness based on competitive analysis of Phasmophobia, R.E.P.O., and Demonologist. The recommendations address gaps in dead player engagement, entity behavior depth, hunt mechanics, evidence system polish, and post-identification content.
Each improvement is evaluated for impact on player experience, development cost, and implementation priority. The goal is to match or exceed competitor depth in areas that matter while maintaining the Cultist mechanic as our core differentiator.

Priority Matrix
Improvement
| Impact
| Dev Cost
| Priority
|
Echo System (dead players)
| High
| Medium
| 1
|
Entity Behavioral Tells
| High
| Medium
| 2
|
Hunt Mechanic Depth
| High
| Medium
| 3
|
Evidence Decay (contaminated)
| Medium
| Low
| 4
|
Cross-Verification System
| Medium
| Low
| 5
|
Banishment Phase (optional)
| Medium
| High
| 6
|
Tutorial/Onboarding
| Medium
| Medium
| 7
|
Portent Deck Modifiers
| Low
| Low
| 8
|
Basic Physics Interactions
| Low
| Medium
| 9
|

Recommended for MVP: Priorities 1-5 (dead player system, entity behaviors, hunt depth, evidence decay, cross-verification)
Post-Launch Consideration: Priorities 6-9 (banishment, tutorial polish, modifiers, physics)

---

1. Echo System — Dead Player Mechanics
1.1 Competitive Context
Game
| Dead Player Experience
| Engagement Level
|
Phasmophobia
| Spectate until mission ends
| Very Low — players alt-tab or leave
|
R.E.P.O.
| Possess severed head, hop around, proximity voice, can be carried to revival point
| High — active participation continues
|
Demonologist
| Spectate; rare Tarot card can revive
| Low — mostly passive
|

R.E.P.O.'s Death Head system is the current gold standard for dead player engagement. Players remain active participants rather than frustrated spectators.
1.2 Design for False Witness
The "Echo" State
When a player dies, they become an Echo — a spectral observer bound to the investigation site. Echoes retain full agency but lose physical capability.

What Echoes CAN do:
Move freely through the environment (including through walls)
See the entity at all times (even when not manifesting)
Communicate via proximity voice chat with living players
Observe evidence and entity behavior
Call out warnings, directions, and observations

What Echoes CANNOT do:
Use equipment or collect evidence
Interact with physical objects
Use Cultist contamination abilities (if they were the Cultist)
Be targeted by the entity
Why This Works for Social Deduction
Unlike a "clean witness" system where dead players are automatically trustworthy, the Echo system preserves paranoia:
A dead Cultist can still lie about what they're seeing
"The entity went toward the basement" — but did it really?
"I see Ghost Orbs in the attic" — are they telling the truth?
Living players must weigh Echo testimony against the possibility of deception
The Cultist loses their contamination abilities on death (a significant penalty), but retains their most powerful tool: their voice. This creates interesting decisions — a Cultist might intentionally die to become a "trusted" Echo who can mislead without suspicion of planting false evidence.
Revival Mechanic
Echoes can be anchored back to physical form:
A living player must spend 30 seconds at the Echo's death location
The revival process is interruptible by entity hunts
Revived players return with 50% sanity and no equipment
Each player can only be revived once per investigation
This creates meaningful decisions: Is it worth the time and risk to revive a teammate? What if they're the Cultist?
1.3 Implementation Notes
Echo movement should feel floaty/spectral (reduced gravity, glide movement)
Visual indicator shows living players where Echoes are (faint outline)
Echo voice has slight reverb/ethereal effect
Entity should occasionally "react" to Echo presence (head turns, pauses) for atmosphere

---

2. Entity Behavioral Tells
2.1 Competitive Context
Phasmophobia's 27 ghost types each have unique behavioral signatures beyond their evidence combinations. These "tells" enable identification even when evidence is hidden on higher difficulties:
The Revenant moves at 1 m/s when unaware but 3 m/s when chasing
The Wraith never steps in salt
The Banshee targets one player regardless of team position
The Goryo only appears on camera through DOTS, never to direct observation
Demonologist adds voice-reactive behaviors — the Gul hunts if players swear nearby, creating genuine tension around voice chat.
2.2 Current Gap in False Witness
The main GDD defines entities primarily by evidence combinations. Entity behaviors are generic (hunt, manifest, interact). This means:
Skilled players have no way to narrow identification beyond equipment readings
The Cultist's false evidence is harder to detect through behavioral inconsistencies
Less depth for experienced players to master
2.3 Proposed Entity Behavioral Matrix
Each entity should have at least one unique behavioral tell that skilled players can observe:
Entity
| Evidence
| Behavioral Tell
| Counterplay/Note
|
Phantom
| EMF 5, Spirit Box, DOTS
| Disappears instantly when photographed during manifestation
| Camera becomes defensive tool
|
Banshee
| Ghost Orbs, UV, DOTS
| Fixates on one player; will ignore others to reach target
| Identify and protect the target
|
Revenant
| Freezing, Orbs, Writing
| Extremely slow (1 m/s) when unaware; fastest (3 m/s) when chasing
| Never let it spot you
|
Shade
| EMF 5, Writing, Freezing
| Will not hunt if 2+ players in same room; very shy
| Stay grouped for safety
|
Poltergeist
| Spirit Box, UV, Writing
| Throws multiple objects simultaneously; rooms become dangerous
| Clear loose objects from investigation areas
|
Wraith
| EMF 5, Spirit Box, DOTS
| Never touches ground; floats; ignores salt entirely
| Salt traps don't work
|
Mare
| Spirit Box, Orbs, Writing
| Cannot hunt in lit rooms; more aggressive in darkness
| Keep lights on at all costs
|
Demon
| UV, Writing, Freezing
| Hunts at 70% sanity (vs normal 50%); shortest cooldown between hunts
| Crucifix is essential; expect frequent hunts
|

2.4 The Listener — Voice-Reactive Entity
Inspired by Demonologist's Gul, one entity should create tension around voice communication itself:

The Listener
Evidence: Freezing, Spirit Box, Ghost Writing
Behavioral Tell: Hunts immediately if any player speaks above normal volume during its dormant phase
Counterplay: Whisper or use text chat; monitor for dormant phase indicators
Design Intent: Creates genuine tension around the core communication mechanic
This entity fundamentally changes how teams play when suspected — suddenly proximity voice chat becomes a liability, not just a feature.
2.5 How Behavioral Tells Interact with Cultist
Behavioral tells create a second verification layer against false evidence:
"The evidence says Wraith, but I just saw it step in the salt pile. Someone's lying."
This rewards attentive players and creates more opportunities for the Cultist to be caught — but also more opportunities for skilled Cultists to account for behavioral consistency in their deception.

---

3. Hunt Mechanic Depth
3.1 Competitive Context
Phasmophobia's hunt system has significant depth:
Mechanic
| Phasmophobia Implementation
|
Sanity Threshold
| Team average below 50% enables hunts (ghost-specific variations: Demon 70%, Shade 35%)
|
Grace Period
| 3-5 seconds after hunt starts before ghost can kill (difficulty-dependent)
|
Electronic Detection
| Ghost detects electronics in hand within 7.5m during hunts
|
Hunt Duration
| 15-60 seconds based on difficulty and map size
|
Hiding Mechanics
| Closets/lockers block entry; breaking line of sight resets tracking
|
Prevention Items
| Crucifix prevents hunts within 3-5m; Incense blinds ghost for 5-7.5 seconds
|
Hunt Cooldown
| 25 seconds between hunts (20s for Demon)
|

3.2 Current Gap in False Witness
The main GDD describes hunts generically: "Hunt Mode — Entity actively seeks players. Counterplay: Hide, stay silent, break line of sight." This lacks the mechanical depth that creates skill expression and tension.
3.3 Proposed Hunt System
Sanity Thresholds
Entity
| Hunt Threshold
| Note
|
Most Entities
| 50% team average
| Standard threshold
|
Shade
| 35%
| Very reluctant to hunt
|
Demon
| 70%
| Hunts much earlier
|
Banshee
| 50% of target only
| Ignores team sanity; only checks fixation target
|
Listener
| Any (if triggered)
| Voice activation bypasses sanity check
|

Hunt Phases
Warning Phase (3 seconds): Lights flicker, equipment static, entity vocalizes. Players can reach hiding spots.
Active Hunt (20-40 seconds): Entity searches for players. Duration scales with map size.
Cooldown (25 seconds): Entity cannot hunt again. Safe window for evidence collection.
Detection Mechanics
Base detection radius: 7 meters
Electronics in hand: +3 meters (10m total)
Voice activity: +5 meters (12m total) — except for Listener, which triggers hunt
Hiding spots (closets, lockers): Entity cannot enter; will search nearby then move on
Line of sight break: Entity loses tracking, begins searching last known position
Protection Items
Item
| Effect
| Limitations
|
Crucifix
| Prevents hunt if entity attempts to hunt within 3m radius
| 2 charges; must be placed before hunt; doesn't stop active hunts
|
Sage Bundle
| Blinds entity for 5 seconds during hunt; prevents hunts for 60 seconds after use
| 1 charge; Demon reduced to 30 seconds prevention
|
Salt Line
| Reveals entity footsteps when crossed; slows some entities
| Wraith ignores entirely; 3 uses per pile
|

3.4 Cultist Hunt Manipulation
The Cultist should have limited ability to influence hunts:
Provocation (1 use): Force an immediate hunt regardless of sanity. High-risk sabotage — if teammates notice the hunt happened at high sanity, suspicion falls on anyone who was alone.
False Alarm (1 use): Trigger hunt warning signs (flicker, static) without an actual hunt. Wastes team resources (hiding, sage) and creates paranoia.
Both abilities should have observable tells for attentive players — Provocation might cause a brief electrical surge visible on equipment; False Alarm produces slightly different flicker patterns than real hunts.

---

4. Evidence Decay for Contaminated Readings
4.1 Design Rationale
Currently, false evidence planted by the Cultist is permanent and indistinguishable from real evidence. This creates an all-or-nothing dynamic where contamination either succeeds completely or fails completely.
Evidence decay creates a middle ground: contaminated evidence degrades over time, giving attentive players a chance to notice inconsistencies.
4.2 Proposed Mechanic
Contaminated Evidence Lifecycle
Planted (0-60 seconds): False evidence appears identical to real evidence. Full strength.
Unstable (60-120 seconds): Evidence begins showing inconsistencies. EMF readings flicker. Temperature fluctuates. Observant players may notice.
Degraded (120-180 seconds): Evidence is clearly inconsistent. EMF shows impossible patterns. Temperature swings wildly.
Expired (180+ seconds): False evidence disappears entirely.
Visual/Audio Tells by Evidence Type
Evidence Type
| Stable Appearance
| Degraded Appearance
|
EMF Spoof
| Steady Level 5 reading
| Flickers between levels; resets randomly
|
Temperature Manipulation
| Consistent freezing temps
| Temperature swings ±5° every few seconds
|
Spirit Box Interference
| Clear response
| Response becomes garbled; cuts out
|
Fingerprint Planting
| Clear UV prints
| Prints fade; partial visibility
|
Ghost Orb Fake
| Steady floating orb
| Orb flickers; moves erratically
|

4.3 Strategic Implications
For Investigators: Re-check evidence over time. If a reading was solid 5 minutes ago but is now unstable, it may have been contaminated.
For Cultists: Timing matters. Plant evidence when the team is close to making a decision, not at the start of the investigation. Refresh contamination if needed (costs additional ability charges).
This creates a more dynamic cat-and-mouse game rather than static "plant and forget" contamination.

---

5. Cross-Verification System
5.1 Design Rationale
Real paranormal investigation relies on multiple independent confirmations. Currently, a single player's evidence collection is treated the same as corroborated evidence. This undersells the value of teamwork and gives the Cultist too much uncontested space.
5.2 Proposed Mechanic
Verification States
Evidence on the shared board displays one of three states:
State
| Icon
| Meaning
| Trust Level
|
Unverified
| Single checkmark
| One player collected this evidence
| Could be Cultist contamination
|
Verified
| Double checkmark
| Two players independently confirmed
| Very likely real
|
Contested
| Exclamation mark
| Players report conflicting readings
| Suspicious — investigate further
|

Verification Rules
Same evidence type, same location, different players = Verified
Different equipment types confirming same evidence = Stronger verification
Conflicting reports (one player sees evidence, another doesn't) = Contested
Cultists CANNOT contaminate already-Verified evidence
5.3 UI Implementation
The Evidence Board shows:
Evidence type icon
Verification state icon
Collector name(s) — hoverable for timestamp
Location collected
Contested evidence should be visually distinct (yellow highlight, pulsing border) to draw attention during deliberation.
5.4 Strategic Implications
For Investigators: Prioritize verifying evidence before the Cultist can contaminate. Work in pairs when possible.
For Cultists: Race to contaminate before verification. Create conflicting reports to cast doubt on legitimate evidence. Avoid being the only source of critical evidence.

---

6. Banishment Phase (Optional Endgame)
6.1 Competitive Context
Phasmophobia ends at identification — once you name the ghost, the mission is complete. Demonologist extends gameplay with map-specific exorcism rituals that require additional objectives, item gathering, and execution.
Demonologist's exorcisms provide:
Extended gameplay for skilled teams
Higher rewards for completion
Map-specific variety and replayability
A reason to keep playing after identification
6.2 Design for False Witness
Optional Banishment Opportunity
After correct entity identification, the team can choose to:
Extract safely — receive standard rewards, investigation ends
Attempt banishment — risk additional danger for bonus rewards
This is strictly optional — teams that just want to play the social deduction game can extract immediately.
Banishment Requirements
Each entity type has a unique banishment ritual:
Entity
| Banishment Requirement
| Risk Factor
|
Phantom
| Photograph during manifestation 3 times
| Must be close; entity attacks after each photo
|
Demon
| Place holy water in 4 corners of its room simultaneously
| Requires 4 players coordinating; hunts constantly during attempt
|
Wraith
| Complete salt circle around manifestation point
| Salt must be unbroken; entity will try to prevent
|
Mare
| Keep all lights on for 3 minutes straight
| Entity targets fuse box and light sources
|
Revenant
| Trap in room using crucifix barriers
| Must execute without being caught at 3 m/s
|
Listener
| Complete ritual in perfect silence (no voice chat)
| Any sound triggers immediate attack
|

Cultist's Final Chance
Even after identification (and even after being discovered), the Cultist can sabotage the banishment:
Break salt circles
Flip breakers during Mare banishment
Make noise during Listener banishment
Mislead teammates about ritual requirements
This gives the Cultist a second win condition and keeps them engaged through the endgame.
6.3 Rewards Structure
Outcome
| XP Multiplier
| Currency Multiplier
|
Extraction without identification
| 0.5×
| 0.5×
|
Correct identification + extraction
| 1.0×
| 1.0×
|
Correct identification + successful banishment
| 2.0×
| 2.0×
|
Failed banishment (team wipe)
| 0.25×
| 0.25×
|

6.4 Implementation Priority
This is marked as Priority 6 (post-launch consideration) because:
Core social deduction loop must be solid first
Requires significant content creation (unique rituals per entity)
Can be added as a major update to re-engage players
Testing needed to ensure it doesn't overshadow the identification phase

---

7. Tutorial & Onboarding System
7.1 Competitive Context
All three major competitors have poor tutorials:
Phasmophobia: Minimal in-game tutorial; wiki essentially mandatory; hostile community toward new players asking questions
Demonologist: "Massive text blocks with poor writing" — players skip and learn through failure
R.E.P.O.: Better contextual hints but still assumes familiarity with genre conventions
This is a clear opportunity for differentiation. A well-designed onboarding system is low-cost, high-impact.
7.2 Proposed System
Training Mode (Solo)
A single-player mode with AI "teammates" (no Cultist) that teaches core mechanics:
Movement & Interaction: Basic controls, opening doors, picking up items
Equipment Usage: How each evidence tool works; what readings mean
Evidence Collection: Identifying evidence types; using the evidence board
Hunt Survival: Warning signs; hiding; protection items
Entity Identification: Cross-referencing evidence; behavioral tells
Completion unlocks multiplayer. Estimated playtime: 15-20 minutes.
Cultist School (Unlocks at Level 5)
A separate tutorial for playing the Cultist role:
Contamination Abilities: How each ability works; placement timing
Social Engineering: Principles of misdirection; when to lie vs. stay silent
Avoiding Detection: How cross-verification catches Cultists; evidence decay tells
Advanced Tactics: Intentional death for Echo misdirection; hunt manipulation
Players must complete at least one investigation before accessing (prevents first-game Cultists who don't understand base mechanics).
Contextual Hints (First 5 Matches)
During early matches, subtle UI hints appear:
"Your EMF reader is detecting activity. Move closer to pinpoint the source."
"The lights are flickering — a hunt may begin soon. Find a hiding spot."
"This evidence conflicts with Player 2's reading. One of you may have contaminated data."
Hints can be disabled in settings. They automatically disable after 5 completed matches.
Evidence Board Tutorial Overlay
First time opening the evidence board, a transparent overlay explains:
Evidence type icons and what each means
Verification states (single check, double check, exclamation)
Collector attribution
How to cross-reference for identification

---

8. Portent Deck — Match Modifiers
8.1 Design Rationale
Roguelike variance keeps repeated playthroughs fresh. Rather than relying solely on entity/map randomization, a modifier system adds another layer of unpredictability that players can plan around.
Inspired by Demonologist's Tarot cards but applied at match start rather than as consumable items.
8.2 Proposed Mechanic
Pre-Match Portent Draw
Before each investigation, one card is drawn from the Portent Deck and revealed to all players:
Card
| Effect
| Impact
|
The Moon
| Entity hunts 25% less frequently
| Easier investigation; less time pressure
|
The Tower
| One random evidence type will not appear
| Harder identification; more behavioral reliance
|
The Hermit
| Proximity voice chat range reduced by 50%
| Team coordination harder; isolation scarier
|
The Fool
| Cultist receives one extra contamination charge
| Cultist advantage; more false evidence possible
|
The Star
| All players start with 75% sanity (vs 100%)
| Hunts come earlier; faster-paced match
|
The Devil
| Entity has 25% chance to ignore hiding spots
| Hiding less reliable; must keep moving
|
The Lovers
| Two players are "linked" — if one dies, both die
| Protects pair or creates double-kill risk
|
The Wheel
| Evidence and entity type re-randomized halfway through match
| Chaos mode; all progress resets
|
The Sun
| All lights start on; entity cannot turn them off
| Mare is trivial; other entities unchanged
|
Blank Card
| No modifier
| Standard match
|

8.3 Implementation Notes
Portent Deck is optional — can be disabled in lobby settings
Custom lobbies can choose specific cards or exclude cards
Some cards should be rarer than others (The Wheel = 2% chance; Blank = 20%)
Revealed to all players INCLUDING the Cultist — everyone adapts strategy
8.4 Priority Assessment
This is Priority 8 (post-launch) because:
Core mechanics must be balanced before adding variance layers
Requires extensive playtesting to ensure no card breaks the game
Easy to add incrementally — start with 3-4 cards, expand over time
Good content for seasonal updates or events

---

9. Basic Physics Interactions
9.1 Competitive Context
R.E.P.O.'s physics system creates the "friendslop" moments — emergent comedy through objects behaving unexpectedly. While False Witness is investigation-focused (not extraction-focused), selective physics adoption could enhance both horror atmosphere and clip potential.
9.2 Proposed Scope (Minimal)
Full physics simulation is out of scope. Instead, targeted physics interactions:
Grabbable Objects
Small objects (books, bottles, tools) can be picked up and thrown
Throwing creates noise — attracts entity attention
Can be used as distraction (throw bottle to draw entity away from teammate)
Poltergeist throws these objects at players — cleared rooms are safer
Ragdoll Deaths
Player death triggers ragdoll physics
Body position indicates where entity attacked
Creates memorable/clip-worthy death moments
Echo spawns at death location (ragdoll position)
Moveable Furniture (Limited)
Select heavy objects (chairs, small tables) can be pushed
Can block doorways temporarily (entity will break through after delay)
Creates improvised barricades during hunts
Risk: Moving furniture creates noise
9.3 What NOT to Include
Full physics simulation on all objects (scope explosion)
Object value/degradation systems (R.E.P.O. territory)
Physics puzzles (not the core experience)
Climbable physics objects (complexity vs. payoff)
9.4 Priority Assessment
This is Priority 9 because:
Core investigation loop doesn't require physics
Networking physics adds significant complexity
Can be added incrementally (ragdoll first, then throwables)
Nice-to-have for streams/clips, not essential for gameplay

---

Appendix: Competitive Feature Matrix
Complete feature comparison across all three competitors and False Witness (proposed):
Feature
| Phasmophobia
| R.E.P.O.
| Demonologist
| False Witness
|
Entity/Monster Count
| 27
| 29
| 24
| 8-10 (MVP)
|
Evidence Types
| 7
| N/A
| 7
| 8
|
Map Count
| 14
| 4
| 9
| 3-4 (MVP)
|
Player Count
| 1-4
| 1-6
| 1-4
| 4-6
|
Dead Player Agency
| None
| High (Death Head)
| Low
| Medium (Echo)
|
Hunt Depth
| High
| Medium
| Medium
| High (proposed)
|
Endgame Content
| None
| Extraction quota
| Exorcism rituals
| Banishment (optional)
|
Social Deduction
| None
| None
| None
| Core mechanic
|
VR Support
| Yes
| No
| No
| No (MVP)
|
Progression System
| Levels + Prestige
| Permanent upgrades
| Levels + Unlocks
| Journal + Variants
|
Tutorial Quality
| Poor
| Medium
| Poor
| Good (proposed)
|
Price Point
| $13.99
| $9.99
| $11.99
| $9.99 (target)
|

Key Differentiators for False Witness
ONLY game with integrated social deduction / traitor mechanics
Evidence contamination system (unique to genre)
Cross-verification creating trust dynamics
Dead players retain meaningful agency AND uncertainty
Entity behavioral tells reward observation skill
Optional banishment extends gameplay without forcing it

— End of Supplement —
