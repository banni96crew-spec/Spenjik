# PRD Documentation Index

## 1. Document Purpose

This file is the entry point for the modular PRD documentation of The Turf.

It does not describe game rules in detail and does not replace individual system specifications.
Its purpose is to define the documentation structure, reading order, responsibility boundaries for each file, and rules for using the documents during development with Cursor / Claude Code / LLM agents.

## 2. Source of Truth

The current documentation is based on:

PRD v2.4 Godot Edition: The Turf

Target project version:

Engine: Godot 4.6.2
Language: GDScript
UI: Godot Control nodes + Containers + Theme
State: GameStateManager.gd as Autoload
Configs: .tres Resources
Random: SeededRandom.gd + SeededPicker.gd
Tests: GUT
Target platforms: Windows / Linux first

## 3. Hard Invariants

These rules must not be changed without a separate decision and PRD update.

- A match lasts exactly 15 rounds.
- The game has 4 participants: the main character + 3 local AI players.
- The player with the highest amount of Victory Points wins, then tie-break rules are applied.
- The core loop must not be changed.
- Card balance must not be changed.
- Card prices must not be changed.
- Card effects must not be changed.
- CardId values must not be renamed.
- Roles must not be changed.
- Contracts must not be changed.
- Contacts must not be changed.
- Street Deals must not be changed.
- Turf Levels must not be changed.
- AI profiles must not be changed.
- Gameplay random is allowed only through SeededRandom.gd / SeededPicker.gd.
- randf(), randi(), randomize(), and RandomNumberGenerator are forbidden for gameplay logic.
- UI must not contain gameplay logic.
- UI must communicate only with GameStateManager.gd and read-only selectors.
- Source code files must not exceed 250 lines.
- The web stack is forbidden: React, TypeScript, Zustand, Tailwind, Docker, and Next.js are not used.

## 4. Documentation Structure

docs/
  prd/
    00_INDEX.md
    01_PRODUCT_OVERVIEW.md
    02_CORE_LOOP_AND_PHASES.md
    03_IDS_AND_CONSTANTS.md
    04_GAME_STATE_SCHEMA.md
    05_CARDS_DATABASE.md
    06_ECONOMY_AND_MARKET.md
    07_COMBAT_SYSTEM.md
    08_ROLES.md
    09_CONTRACTS.md
    10_STREET_DEALS_AND_DEBTS.md
    11_CONTACTS.md
    12_TURF_LEVELS.md
    13_AI_SYSTEM.md
    14_DETERMINISTIC_RANDOM.md
    15_GODOT_ARCHITECTURE.md
    16_GAME_STATE_MANAGER_API.md
    17_UI_UX_SPEC.md
    18_TEST_PLAN.md
    19_IMPLEMENTATION_ORDER.md
    20_LLM_AGENT_RULES.md
    21_OPEN_QUESTIONS_AND_FIXES.md

## 5. File Responsibilities

File	Responsibility
00_INDEX.md	Main documentation map, reading order, file boundaries
01_PRODUCT_OVERVIEW.md	Short product description, genre, MVP, and out of scope
02_CORE_LOOP_AND_PHASES.md	Core loop, phases, transitions, round flow, phase state machine
03_IDS_AND_CONSTANTS.md	All IDs, constants, validation errors, phase IDs, attack modes
04_GAME_STATE_SCHEMA.md	GameState, PlayerState, runtime states, validation, ownership rules
05_CARDS_DATABASE.md	Full card database, prices, types, destination, requirements, limits
06_ECONOMY_AND_MARKET.md	Income, prices, scaling, market, purchases, upkeep, price modifiers
07_COMBAT_SYSTEM.md	War cards, attacks, defenses, payload, validation, combat result
08_ROLES.md	Roles, starting effects, limitations, role flags, RoleLogic
09_CONTRACTS.md	Contracts, runtime, progress, completion, failure, rewards
10_STREET_DEALS_AND_DEBTS.md	Street Deals, option effects, debts, debt processing
11_CONTACTS.md	Contacts, unlock, passive/active effects, cooldowns
12_TURF_LEVELS.md	Turf Levels, effects, module ownership
13_AI_SYSTEM.md	AI profiles, purchase logic, target logic, fallback, strong AI
14_DETERMINISTIC_RANDOM.md	SeededRandom, SeededPicker, random state, replay requirements
15_GODOT_ARCHITECTURE.md	Godot project structure, layers, Resources, Autoload, export policy
16_GAME_STATE_MANAGER_API.md	Public GameStateManager.gd API, selectors, return shapes
17_UI_UX_SPEC.md	UI screens, panels, widgets, UX states, disabled reasons
18_TEST_PLAN.md	GUT tests, fixtures, replay tests, static scan, acceptance criteria
19_IMPLEMENTATION_ORDER.md	Step-by-step development order for Cursor / Claude
20_LLM_AGENT_RULES.md	General LLM-agent rules, restrictions, guardrails
21_OPEN_QUESTIONS_AND_FIXES.md	Resolved fixes, accepted decisions, and deferred non-MVP questions

## 6. Recommended Reading Order for Human Review

For manual PRD refinement, read in this order:

1. 01_PRODUCT_OVERVIEW.md
2. 02_CORE_LOOP_AND_PHASES.md
3. 04_GAME_STATE_SCHEMA.md
4. 05_CARDS_DATABASE.md
5. 06_ECONOMY_AND_MARKET.md
6. 07_COMBAT_SYSTEM.md
7. 08_ROLES.md
8. 09_CONTRACTS.md
9. 10_STREET_DEALS_AND_DEBTS.md
10. 11_CONTACTS.md
11. 12_TURF_LEVELS.md
12. 13_AI_SYSTEM.md
13. 14_DETERMINISTIC_RANDOM.md
14. 15_GODOT_ARCHITECTURE.md
15. 16_GAME_STATE_MANAGER_API.md
16. 17_UI_UX_SPEC.md
17. 18_TEST_PLAN.md
18. 19_IMPLEMENTATION_ORDER.md
19. 20_LLM_AGENT_RULES.md
20. 21_OPEN_QUESTIONS_AND_FIXES.md

## 7. Recommended Reading Order for LLM Agents

For Cursor / Claude Code / LLM agents, do not load the entire documentation at once.

Minimum context for any task:

1. 20_LLM_AGENT_RULES.md
2. 03_IDS_AND_CONSTANTS.md
3. The specific system file relevant to the current task
4. 18_TEST_PLAN.md or the relevant test section

Examples:

Task: implement MarketLogic.gd

Provide the agent with:
- 20_LLM_AGENT_RULES.md
- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 05_CARDS_DATABASE.md
- 06_ECONOMY_AND_MARKET.md
- 14_DETERMINISTIC_RANDOM.md
- 18_TEST_PLAN.md
Task: implement CombatEngine.gd

Provide the agent with:
- 20_LLM_AGENT_RULES.md
- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 05_CARDS_DATABASE.md
- 07_COMBAT_SYSTEM.md
- 18_TEST_PLAN.md
Task: implement UI MarketPanel.gd

Provide the agent with:
- 20_LLM_AGENT_RULES.md
- 16_GAME_STATE_MANAGER_API.md
- 17_UI_UX_SPEC.md
- 06_ECONOMY_AND_MARKET.md only as a reference, without permission to implement logic in UI

## 8. Development Context Packs

### 8.1. Foundation Pack

Used for initial project setup.

- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 14_DETERMINISTIC_RANDOM.md
- 15_GODOT_ARCHITECTURE.md
- 20_LLM_AGENT_RULES.md

### 8.2. Economy Pack

Used for IncomeLogic, PriceLogic, MarketLogic.

- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 05_CARDS_DATABASE.md
- 06_ECONOMY_AND_MARKET.md
- 08_ROLES.md
- 12_TURF_LEVELS.md
- 14_DETERMINISTIC_RANDOM.md
- 20_LLM_AGENT_RULES.md

### 8.3. Combat Pack

Used for AttackValidator, DefenseResolver, CombatEngine, CombatLogBuilder.

- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 05_CARDS_DATABASE.md
- 07_COMBAT_SYSTEM.md
- 09_CONTRACTS.md
- 11_CONTACTS.md
- 20_LLM_AGENT_RULES.md

### 8.4. Progression Pack

Used for Contracts, Contacts, Street Deals, Debts, Turf Levels.

- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 09_CONTRACTS.md
- 10_STREET_DEALS_AND_DEBTS.md
- 11_CONTACTS.md
- 12_TURF_LEVELS.md
- 20_LLM_AGENT_RULES.md

### 8.5. AI Pack

Used for AIBotController, AIPurchaseLogic, AITargetLogic, AIFallbackLogic.

- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 05_CARDS_DATABASE.md
- 06_ECONOMY_AND_MARKET.md
- 07_COMBAT_SYSTEM.md
- 13_AI_SYSTEM.md
- 14_DETERMINISTIC_RANDOM.md
- 20_LLM_AGENT_RULES.md

### 8.6. UI Pack

Used for Godot Control UI.

- 16_GAME_STATE_MANAGER_API.md
- 17_UI_UX_SPEC.md
- 20_LLM_AGENT_RULES.md

### 8.7. Testing Pack

Used for GUT tests and replay tests.

- 03_IDS_AND_CONSTANTS.md
- 04_GAME_STATE_SCHEMA.md
- 14_DETERMINISTIC_RANDOM.md
- 18_TEST_PLAN.md
- 20_LLM_AGENT_RULES.md

## 9. Documentation Ownership Rules

Each file has exactly one responsibility area.

- Card prices are defined only in 05_CARDS_DATABASE.md and 06_ECONOMY_AND_MARKET.md.
- War card effects are defined only in 07_COMBAT_SYSTEM.md.
- GameState and PlayerState are defined only in 04_GAME_STATE_SCHEMA.md.
- Phases are defined only in 02_CORE_LOOP_AND_PHASES.md.
- AI behavior is defined only in 13_AI_SYSTEM.md.
- The random contract is defined only in 14_DETERMINISTIC_RANDOM.md.
- UI behavior is defined only in 17_UI_UX_SPEC.md.
- LLM restrictions are defined only in 20_LLM_AGENT_RULES.md.
- Unresolved questions are tracked only in 21_OPEN_QUESTIONS_AND_FIXES.md.

If a rule must be mentioned in another file, link to the source file instead of duplicating the full description.

## 10. Cross-Document Reference Rules

Use this format for references between files:

- See: [War Cards](05_CARDS_DATABASE.md#13-war-cards)
- See: [Defense Resolution Order](07_COMBAT_SYSTEM.md#72-defense-resolution-order)
- See: [Replay Tests](14_DETERMINISTIC_RANDOM.md#165-replay-tests)

If a rule changes, update only the file that owns the rule.

## 11. Implementation Order Summary

The full implementation order is described in:

19_IMPLEMENTATION_ORDER.md

Short order:

1. Create the Godot 4.6.2 project structure.
2. Create IDs and constants.
3. Create Resource schemas.
4. Create .tres configs and catalogs.
5. Implement SeededRandom.gd and SeededPicker.gd.
6. Implement GameStateFactory.gd.
7. Implement GameStateValidator.gd.
8. Implement PriceLogic.gd.
9. Implement MarketLogic.gd.
10. Implement IncomeLogic.gd.
11. Implement CombatEngine.gd and related combat modules.
12. Implement ContractLogic.gd.
13. Implement ContactLogic.gd.
14. Implement StreetDealLogic.gd and DebtLogic.gd.
15. Implement AI modules.
16. Implement GamePhaseController.gd.
17. Implement WinnerResolver.gd.
18. Implement GameStateManager.gd as a thin facade.
19. Write and pass GUT unit tests.
20. Implement UI only after logic tests are green.
21. Run replay tests.
22. Run manual UX tests.

## 12. Resolved Pre-Development Decisions

The pre-development questions tracked in:

21_OPEN_QUESTIONS_AND_FIXES.md

have been resolved for MVP. The resolved P0/P1 areas include:

- Full tie-break rules below Turf Level 10.
- Cops upkeep: cost, timer, non-payment behavior.
- RoleLogic.gd: existence and responsibilities.
- State ownership for contacts / street_deals / player debts.
- Street Deal participants: human-only or all players.
- Strong AI contact unlock: MVP behavior.
- Saboteur target rules.
- Insider modifier rules.
- Unified random_state contract for all gameplay random operations.
- GameStateManager selectors for UI.

## 13. Standard Header for Every PRD File

Each specification file must start with this block:

```markdown
# [Document Title]

## Document Role

This file defines only: [system name].

This file must not redefine:
- card prices unless this is 05_CARDS_DATABASE.md or 06_ECONOMY_AND_MARKET.md;
- combat effects unless this is 07_COMBAT_SYSTEM.md;
- state schema unless this is 04_GAME_STATE_SCHEMA.md;
- UI behavior unless this is 17_UI_UX_SPEC.md;
- AI behavior unless this is 13_AI_SYSTEM.md;
- random rules unless this is 14_DETERMINISTIC_RANDOM.md.

Source of truth dependencies:
- [list relevant docs]

Implementation target:
- Godot 4.6.2
- GDScript
- GUT tests
```

## 14. Standard Prompt Context for LLM Tasks

Every development prompt for Cursor / Claude Code must include:

You are working on the Godot 4.6.2 project The Turf.

Use only the provided PRD files as the source of truth.

Hard rules:
- Do not change PRD rules.
- Do not change balance.
- Do not change card prices.
- Do not change card effects.
- Do not rename IDs.
- Do not add cards.
- Do not use React, TypeScript, Zustand, Tailwind, Docker, or Next.js.
- Do not put gameplay logic into UI scenes.
- Do not use randf(), randi(), randomize(), or RandomNumberGenerator for gameplay logic.
- Use SeededRandom.gd / SeededPicker.gd only for gameplay random.
- Keep every source file under 250 lines.
- Use GDScript static typing wherever possible.
- Add or update GUT tests for the implemented logic.

## 15. MVP Scope Summary

MVP includes:

- 15-round local single-player match.
- Human player + 3 local AI players.
- Manual Turf Level selection before the match.
- Role selection.
- Contract selection.
- Income phase.
- Market phase.
- Action phase.
- Street Deal phase after rounds 4, 8, and 12.
- Cards from PRD v2.4.
- Roles from PRD v2.4.
- Contracts from PRD v2.4.
- Contacts from PRD v2.4.
- Turf Levels from PRD v2.4.
- AI profiles from PRD v2.4.
- Deterministic random.
- GUT tests.
- Basic Godot Control UI.
- Windows / Linux export.

MVP does not include:

- Multiplayer.
- Backend.
- Accounts.
- Campaign persistence.
- Mobile adaptation.
- Web export as a required target.
- Card editor.
- In-game balance simulator.
- C# version.
- React / web shell.
- Docker deployment.

## 16. Current Documentation Status

Status: modular PRD complete; targeted internal consistency pass applied
Base PRD: v2.4 Godot Edition
Target: focused owner documents ready for staged implementation
Main risk: implementation drift from owner documents and canonical state/API contracts
Next required action: begin implementation from 19_IMPLEMENTATION_ORDER.md

## 17. Definition of Ready for Development

Documentation is ready for development when:

- All P0 questions in 21_OPEN_QUESTIONS_AND_FIXES.md are resolved.
- All P1 questions are either resolved or explicitly deferred.
- 03_IDS_AND_CONSTANTS.md contains all IDs.
- 04_GAME_STATE_SCHEMA.md contains final state ownership rules.
- 02_CORE_LOOP_AND_PHASES.md contains the full phase transition table.
- 14_DETERMINISTIC_RANDOM.md contains the unified random_state contract.
- 16_GAME_STATE_MANAGER_API.md contains all mutating methods and selectors.
- 18_TEST_PLAN.md contains acceptance criteria for core logic.
- 20_LLM_AGENT_RULES.md is ready to be included in every development prompt.

## 18. Definition of Done for Implementation Tasks

Each development task is complete only if:

- Only the files listed in the task were implemented.
- PRD rules were not changed.
- Balance was not changed.
- No unauthorized dependencies were added.
- Gameplay logic was not added to UI.
- Forbidden random APIs are not used.
- Every source file is under 250 lines.
- GUT tests were added or updated.
- Tests pass.
- Public API does not diverge from 16_GAME_STATE_MANAGER_API.md.

## 19. Notes for Future Updates

When updating documentation:

- Update only the file that owns the rule.
- Do not duplicate tables across files.
- If a change affects other systems, add a cross-reference.
- If a change affects MVP scope, update 01_PRODUCT_OVERVIEW.md and 19_IMPLEMENTATION_ORDER.md.
- If a change affects LLM development, update 20_LLM_AGENT_RULES.md.
- If a question is not resolved yet, add it to 21_OPEN_QUESTIONS_AND_FIXES.md.

## 20. Final Rule

If an LLM agent needs more than 5–7 PRD files at the same time for one task, the task is too large.

Split it.
