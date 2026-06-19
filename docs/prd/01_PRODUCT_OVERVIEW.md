Product Overview
Document Role

This file defines only: the high-level product vision, player experience, MVP scope, non-goals, and product boundaries for The Turf.

This file must not redefine:

card prices;
card effects;
combat resolution;
state schema;
AI behavior;
random rules;
UI implementation details.

Source of truth dependencies:

00_INDEX.md
02_CORE_LOOP_AND_PHASES.md
05_CARDS_DATABASE.md
15_GODOT_ARCHITECTURE.md
19_IMPLEMENTATION_ORDER.md
20_LLM_AGENT_RULES.md
21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

Godot 4.6.2
GDScript
GUT tests
1. Product Summary

The Turf is a short, turn-based card mini-game about criminal influence, resource pressure, risky attacks, and tactical survival.

The game is designed as a compact local single-player experience where the human player competes against three local AI opponents across exactly 15 rounds.

The player buys cards, builds an income engine, gains Victory Points, attacks rivals, handles Street Deals, completes contracts, and tries to end the match with the highest score.

The game is intended to work as a standalone mini-game and as a possible embedded mini-game inside a larger visual novel.

2. Product Identity
Field	Value
Title	The Turf
Genre	Turn-based card mini-game
Format	Local single-player mini-game
Players	4 participants: human player + 3 local AI players
Match length	Exactly 15 rounds
Primary goal	End the match with the highest number of Victory Points
Target engine	Godot 4.6.2
Language	GDScript
Main development style	Indie development with Cursor / Claude Code / LLM agents
Target platforms for MVP	Windows / Linux
Web export	Optional later
Persistence	No campaign persistence in MVP
3. Core Player Fantasy

The player is trying to dominate a small criminal turf war by making better tactical decisions than three AI rivals.

The fantasy is not about large-scale simulation.
It is about sharp choices, limited resources, dirty opportunities, and short-term risk.

The player should feel that every round matters because the match is short, opponents are active, and every purchase or attack can affect the final result.

4. Core Experience Goals

The game should feel:

- Fast to start.
- Easy to understand after a few rounds.
- Tactical without becoming a spreadsheet.
- Replayable through roles, contracts, Street Deals, contacts, Turf Levels, and AI profiles.
- Deterministic enough to test and replay.
- Small enough for one indie developer to finish.

The player should always understand:

- What phase the game is in.
- What actions are available.
- Why an action is disabled.
- What a card will do before it is played.
- How much Nal and Victory Points each player has.
- Which defenses are active.
- What happened after each attack or event.
- How the winner was determined.
5. Target Audience

The MVP is designed for players who enjoy:

- short tactical card games;
- roguelite-inspired structure;
- compact board-game-style decisions;
- AI opponents;
- resource management;
- aggressive interaction between players;
- readable systems over complex hidden simulation.

The game is not aimed at players who expect:

- long campaign progression in the MVP;
- online multiplayer;
- deep deckbuilding;
- collectible card game complexity;
- real-time action;
- heavy narrative branching inside the mini-game;
- large-scale economic simulation.
6. Match Overview

A match contains exactly 15 rounds.

Each round follows this general structure:

Round Start
  -> Income
  -> Market
  -> Action
  -> Optional Street Deal after rounds 4, 8, and 12
  -> Next Round or Game Over

The player and AI opponents gain resources, buy cards, attack each other, complete objectives, and accumulate Victory Points.

At the end of round 15, the game resolves the winner.

Detailed phase rules are defined in:

02_CORE_LOOP_AND_PHASES.md
7. Win Condition

The winner is the participant with the highest number of Victory Points at the end of the match.

If multiple participants are tied, tie-break rules are applied.

The complete winner resolution rules must be defined in:

02_CORE_LOOP_AND_PHASES.md
04_GAME_STATE_SCHEMA.md

Open or unresolved tie-break issues must be tracked in:

21_OPEN_QUESTIONS_AND_FIXES.md
8. Main Resources
8.1. Nal

Nal is the main spendable resource.

It is used to buy cards, pay costs, resolve some Street Deal options, and survive economic pressure.

Nal is not the primary win condition, but it can affect momentum and tie-breaks if defined by the final winner resolution rules.

8.2. Victory Points

Victory Points are the main scoring resource.

The player with the most Victory Points at the end of the match wins unless tie-break rules change the outcome.

8.3. Cards

Cards represent engine growth, status buildings, defenses, and attacks.

The full card database is defined only in:

05_CARDS_DATABASE.md
9. Main Game Systems

The MVP contains the following major systems:

- Core loop and phase state machine.
- Income system.
- Market and card purchasing.
- Card database.
- Combat system.
- Roles.
- Contracts.
- Street Deals.
- Debts.
- Contacts.
- Turf Levels.
- Local AI opponents.
- Deterministic random.
- GameStateManager facade.
- Godot Control UI.
- GUT unit tests.

Each system must be documented in its own PRD file and implemented as a separate logic area where possible.

10. MVP Scope

The MVP must include:

- One complete local match lasting exactly 15 rounds.
- Human player.
- Three local AI opponents.
- Manual Turf Level selection before the match.
- Role selection.
- Contract selection.
- Income phase.
- Market phase.
- Action phase.
- Street Deal phase after rounds 4, 8, and 12.
- Full card database from PRD v2.4.
- Full role list from PRD v2.4.
- Full contract list from PRD v2.4.
- Full Street Deal list from PRD v2.4.
- Full contact list from PRD v2.4.
- Full Turf Level list from PRD v2.4.
- AI profiles from PRD v2.4.
- Deterministic random through SeededRandom.gd and SeededPicker.gd.
- Basic Godot Control UI.
- Combat log.
- Disabled action reasons.
- Game over summary.
- GUT unit tests for core logic.
- Windows and Linux export targets.
11. MVP Success Criteria

The MVP is successful when:

- A full 15-round match can be completed from setup to game over.
- The winner is resolved deterministically.
- All core card types work.
- AI players can buy cards and take actions without blocking the game.
- Market generation is deterministic.
- Income resolution is deterministic.
- Combat resolution is deterministic.
- Street Deals can appear and resolve at the correct rounds.
- Contracts can progress, complete, fail, and reward the player.
- Contacts can unlock and apply their effects according to the rules.
- Turf Levels apply their defined effects.
- UI never implements gameplay logic directly.
- Unit tests cover the core logic modules.
- Replay tests can confirm deterministic behavior for the same seed and scripted decisions.
12. Out of Scope for MVP

The following features are explicitly out of scope for the MVP:

- Online multiplayer.
- Local hot-seat multiplayer.
- Backend.
- Accounts.
- User profiles.
- Cloud saves.
- Campaign persistence.
- Meta-progression between matches.
- Required web export.
- Mobile adaptation.
- Card editor.
- In-game balance simulator.
- Mod support.
- C# implementation.
- React frontend.
- TypeScript codebase.
- Zustand store.
- Tailwind UI.
- Docker deployment.
- WebSockets.
- Real-time combat.
- 3D card animations.
- Complex cinematic presentation.

These features must not be implemented unless the PRD is explicitly updated.

13. Product Constraints

The project is designed for one indie developer using LLM-assisted development.

Therefore, the product must remain:

- small in scope;
- modular in documentation;
- modular in implementation;
- deterministic in gameplay logic;
- heavily covered by unit tests;
- strict about file size;
- strict about avoiding UI/gameplay logic mixing;
- strict about avoiding unnecessary systems.

The game must not become a large simulation, campaign framework, multiplayer platform, or full CCG.

14. Technical Product Direction

The product is built as a local Godot game.

Core technical direction:

- Godot 4.6.2.
- GDScript.
- Logic-first architecture.
- GameStateManager.gd as Autoload facade.
- Dictionary snapshots for runtime game state.
- .tres Resources for data configs.
- Godot Control nodes for UI.
- GUT for tests.
- Custom deterministic random.
- No gameplay persistence in MVP.
- Optional debug snapshot only.

Detailed architecture is defined in:

15_GODOT_ARCHITECTURE.md
15. Development Philosophy

The game must be developed through small, controlled implementation tasks.

Each task should have:

- one clear goal;
- a small set of input PRD files;
- a limited file list;
- explicit forbidden changes;
- required tests;
- a clear definition of done.

Development must avoid large prompts such as:

- "Implement the whole game."
- "Create all systems."
- "Build the full UI and logic."
- "Refactor everything."

Large tasks increase the risk of rule drift, balance changes, duplicated logic, and broken architecture.

16. LLM Development Requirements

Every LLM-assisted development task must follow:

20_LLM_AGENT_RULES.md

The most important rules:

- Do not change game rules.
- Do not change card balance.
- Do not rename IDs.
- Do not add new cards.
- Do not use web stack.
- Do not write gameplay logic in UI.
- Do not use forbidden random APIs.
- Keep source files under 250 lines.
- Add or update tests for implemented logic.
17. Product Risks

The main product risks are:

- The PRD becomes too large for safe LLM context.
- LLM agents misinterpret underdefined rules.
- UI starts duplicating gameplay logic.
- Random behavior becomes non-deterministic.
- GameState ownership becomes inconsistent.
- AI behavior becomes too complex for MVP.
- Contracts, contacts, and Street Deals create too many edge cases.
- Scope expands into campaign, persistence, multiplayer, or web features.

These risks are controlled through modular documentation, strict source-of-truth ownership, and small implementation tasks.

18. Required Pre-Development Decisions

Before implementation begins, the following topics must be resolved in:

21_OPEN_QUESTIONS_AND_FIXES.md

Minimum required decisions:

- Full tie-break rules below Turf Level 10.
- Cops upkeep cost, timer, and non-payment behavior.
- RoleLogic.gd responsibilities.
- State ownership for contacts, Street Deals, and active debts.
- Street Deal participants in MVP.
- Strong AI contact unlock behavior in MVP.
- Saboteur target rules.
- Insider modifier rules.
- Unified random_state contract for all gameplay random operations.
- Required GameStateManager selectors for UI.
19. Definition of Product Ready

The product documentation is ready for development when:

- MVP scope is locked.
- All P0 open questions are resolved.
- P1 open questions are either resolved or explicitly deferred.
- Core loop and phase transitions are fully specified.
- GameState ownership is fully specified.
- Deterministic random contract is fully specified.
- Card, role, contract, contact, Street Deal, Turf Level, and AI data are fixed.
- GameStateManager API is specified.
- UI boundaries are specified.
- Test requirements are specified.
- LLM agent rules are ready to be reused in every development prompt.
20. Final Product Boundary

The MVP is a compact, deterministic, local Godot card mini-game.

It is not a web app.
It is not a multiplayer game.
It is not a campaign system.
It is not a large simulation.
It is not a full collectible card game.

The product must stay small, testable, and finishable.