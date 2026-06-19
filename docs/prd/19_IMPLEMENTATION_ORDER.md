# Implementation Order

## Document Role

This file defines only:

* recommended implementation sequence;
* module dependency order;
* milestone gates;
* required outputs per milestone;
* minimum tests per milestone;
* static scan timing;
* LLM coding-agent handoff order;
* integration checkpoints;
* allowed partial implementation states;
* blocker handling during implementation.

This file must not redefine:

* card prices;
* card effects;
* role effects;
* contract conditions;
* contact effects;
* Street Deal effects;
* debt rules;
* Turf Level effects;
* AI profiles;
* combat rules;
* economy formulas;
* market generation rules;
* deterministic random algorithms;
* UI behavior;
* phase transition rules;
* GameStateManager API behavior.

Source of truth dependencies:

* 00_INDEX.md
* 01_PRODUCT_OVERVIEW.md
* 02_CORE_LOOP_AND_PHASES.md
* 03_IDS_AND_CONSTANTS.md
* 04_GAME_STATE_SCHEMA.md
* 05_CARDS_DATABASE.md
* 06_ECONOMY_AND_MARKET.md
* 07_COMBAT_SYSTEM.md
* 08_ROLES.md
* 09_CONTRACTS.md
* 10_STREET_DEALS_AND_DEBTS.md
* 11_CONTACTS.md
* 12_TURF_LEVELS.md
* 13_AI_SYSTEM.md
* 14_DETERMINISTIC_RANDOM.md
* 15_GODOT_ARCHITECTURE.md
* 16_GAME_STATE_MANAGER_API.md
* 17_UI_UX_SPEC.md
* 18_TEST_PLAN.md
* 20_LLM_AGENT_RULES.md
* 21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

* Godot 4.6.2
* GDScript
* .tres Resources
* Dictionary state snapshots
* GameStateManager.gd Autoload
* GUT tests

## 1. Purpose

This file defines the safest order for implementing The Turf in Godot 4.6.2 with LLM coding agents.

The order is designed to:

* reduce circular dependencies;
* keep source files under 250 lines;
* make tests useful early;
* prevent UI from receiving gameplay logic;
* prevent AI from bypassing validation;
* lock deterministic random before random consumers are built;
* make each implementation step independently testable.

Implementation must proceed from stable foundations to gameplay modules, then integration, then UI.

## 2. Ownership Boundaries

This file owns:

* implementation sequence;
* milestone boundaries;
* dependency gates;
* required test timing;
* what may be stubbed temporarily;
* what must not be stubbed;
* when integration can begin.

This file references:

* module files for exact implementation requirements;
* `18_TEST_PLAN.md` for test coverage;
* `15_GODOT_ARCHITECTURE.md` for folder and source file structure;
* `20_LLM_AGENT_RULES.md` for coding-agent constraints;
* `21_OPEN_QUESTIONS_AND_FIXES.md` for unresolved blockers.

This file does not own:

* gameplay rules;
* API result details beyond milestone readiness;
* folder structure beyond implementation order references;
* UI layout details;
* implementation code.

## 3. Core Terms

| Term                   | Meaning                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------- |
| Milestone              | Implementation phase with a clear output and test gate.                                |
| Gate                   | Required passing condition before moving to the next milestone.                        |
| Stub                   | Temporary minimal implementation that returns safe data without gameplay behavior.     |
| Hard Stub Ban          | Rule that a module must not be stubbed because other modules depend on exact behavior. |
| Integration Checkpoint | Test point where multiple modules must work together.                                  |
| Foundation Layer       | Constants, schemas, Resources, catalogs, random, state factory.                        |
| Gameplay Layer         | Economy, combat, roles, contracts, contacts, Street Deals, AI.                         |
| Facade Layer           | `GameStateManager.gd` API.                                                             |
| Presentation Layer     | UI scenes and widgets.                                                                 |
| Static Gate            | Static scan that must pass before continuing.                                          |

## 4. Runtime State

This module does not define runtime gameplay state.

Implementation order affects when these runtime state systems are introduced:

| State Area                    | Introduced In Milestone |
| ----------------------------- | ----------------------- |
| Constants and IDs             | M1                      |
| Resource catalogs             | M2                      |
| Random state                  | M3                      |
| GameState schema              | M4                      |
| Phase state                   | M5                      |
| Market and economy state      | M6                      |
| Combat state                  | M7                      |
| Role flags                    | M8                      |
| Contract runtime              | M9                      |
| Street Deal and debt state    | M10                     |
| Contact state                 | M11                     |
| Turf flags                    | M12                     |
| AI boss state                 | M13                     |
| GameStateManager active state | M14                     |
| UI-local selection state      | M16                     |

Implementation agents must not create state fields before their owner module defines them.

## 5. Rules

### 5.1. Global Implementation Rules

1. Implement foundations before gameplay modules.
2. Implement tests with each module.
3. Do not build final UI before core logic tests pass.
4. Do not implement AI before Market, Combat, deterministic random, and state validation exist.
5. Do not implement random consumers before `SeededRandom.gd` and `SeededPicker.gd`.
6. Do not implement GameStateManager as a gameplay mega-file.
7. Do not implement source files longer than 250 lines.
8. Do not use forbidden random APIs.
9. Do not invent unresolved mechanics.
10. Do not bypass `21_OPEN_QUESTIONS_AND_FIXES.md`.

### 5.2. Allowed Early Stubs

Temporary stubs are allowed only if:

* they return stable result shapes;
* they do not mutate gameplay incorrectly;
* they are replaced before the dependent milestone gate;
* tests mark the stub as incomplete.

Allowed early stubs:

| Stub                              | Allowed Until | Notes                            |
| --------------------------------- | ------------- | -------------------------------- |
| `GameViewBuilder.gd` minimal view | UI milestone  | May return raw safe view.        |
| UI scenes with placeholder labels | UI milestone  | Must not contain gameplay logic. |
| Debug snapshot manager            | Any time      | Optional debug only.             |
| AudioManager                      | Any time      | Non-gameplay only.               |

### 5.3. Hard Stub Bans

These must not be fake-stubbed once a dependent module starts:

| Module                  | Reason                                                   |
| ----------------------- | -------------------------------------------------------- |
| `ValidationErrors.gd`   | All modules require stable errors.                       |
| `GameIds.gd`            | All Resources and logic require stable IDs.              |
| `SeededRandom.gd`       | Random consumers depend on exact step behavior.          |
| `SeededPicker.gd`       | Offers, AI, and market depend on exact step behavior.    |
| `GameStateFactory.gd`   | Tests require complete schemas.                          |
| `GameStateValidator.gd` | Mutation safety depends on validation.                   |
| `PriceLogic.gd`         | Purchases, roles, contacts, Turf Level, AI depend on it. |
| `CombatEngine.gd`       | AI and contracts depend on valid combat hooks.           |

### 5.4. Test Gate Rule

A milestone is complete only when:

* relevant unit tests pass;
* relevant static scans pass;
* source files remain under 250 lines;
* no forbidden random APIs exist;
* failed validation mutation tests pass where applicable.

### 5.5. Open Question Rule

If implementation hits unclear behavior:

1. stop implementing that behavior;
2. add or reference an `OQ-*` item in `21_OPEN_QUESTIONS_AND_FIXES.md`;
3. implement only the clearly defined subset;
4. add tests only for defined behavior.

Do not resolve open questions inside code comments.

### 5.6. PRD Module Update Rule

If implementation reveals a missing API, schema, or constant:

* update the owning PRD module first;
* update constants/schema docs if needed;
* update tests;
* then implement code.

Do not silently add new gameplay behavior.

## 6. Validation Rules

### 6.1. Milestone Validation

Each milestone must validate:

| Validation                       |            Required |
| -------------------------------- | ------------------: |
| Required files exist             |                 yes |
| Required tests exist             |                 yes |
| Unit tests pass                  |                 yes |
| Static scan passes               |                 yes |
| No forbidden random API          |                 yes |
| No `.gd` file over 250 lines     |                 yes |
| No UI-owned gameplay logic       | yes, once UI exists |
| No unresolved blocker dependency |                 yes |

### 6.2. Dependency Validation

Before starting a milestone, all prerequisite milestones must be complete.

If a prerequisite is missing, implementation must not proceed except for:

* pure UI placeholder work;
* documentation-only updates;
* test fixture preparation that does not encode gameplay assumptions.

### 6.3. Failed Gate Behavior

If a milestone gate fails:

* do not continue to later gameplay milestones;
* fix the failing module;
* add regression tests if needed;
* rerun the full related test group.

### 6.4. Static Scan Timing

Static scans must begin early.

Minimum timing:

| Static Scan               | First Required By |
| ------------------------- | ----------------- |
| forbidden random API scan | M3                |
| file length scan          | M1                |
| Resource integrity scan   | M2                |
| architecture scan         | M4                |
| UI boundary scan          | M16               |
| open question scan        | M1                |

## 7. Resolution / Processing Flow

### 7.1. Full Implementation Sequence

Recommended milestone order:

| Milestone | Name                          | Main Output                       |
| --------: | ----------------------------- | --------------------------------- |
|        M0 | Project Bootstrap             | Godot project, GUT, folders       |
|        M1 | Constants and IDs             | Stable IDs and errors             |
|        M2 | Resource Schemas and Catalogs | `.tres` data loaded and validated |
|        M3 | Deterministic Random          | `SeededRandom`, `SeededPicker`    |
|        M4 | Game State Schema             | Factory, validator, fixtures      |
|        M5 | Core Loop and Phases          | Round and phase controller        |
|        M6 | Economy and Market            | prices, income, market, purchases |
|        M7 | Combat System                 | War cards and defenses            |
|        M8 | Roles                         | setup and price modifiers         |
|        M9 | Contracts                     | offers, progress, claim           |
|       M10 | Street Deals and Debts        | deal choices, debt processing     |
|       M11 | Contacts                      | offers and contact effects        |
|       M12 | Turf Levels                   | difficulty modifiers              |
|       M13 | AI System                     | AI setup, market, action          |
|       M14 | GameStateManager API          | facade and mutation safety        |
|       M15 | Integration and Replay        | full game flows                   |
|       M16 | UI / UX                       | screens, panels, widgets          |
|       M17 | Polish and Hardening          | logs, debug, final scans          |

### 7.2. Milestone M0 — Project Bootstrap

Implement:

* Godot 4.6.2 project;
* folder structure from `15_GODOT_ARCHITECTURE.md`;
* GUT addon;
* empty test folders;
* infrastructure-only bootstrap smoke at `res://tests/smoke/test_gut_bootstrap.gd`;
* static scan helper shell.

Required files:

```text
project.godot
res://tests/
res://addons/gut/
```

Gate:

* project opens;
* GUT discovers and passes the M0 bootstrap smoke from `18_TEST_PLAN.md` Section 5.1.1;
* folder structure exists.

The canonical MVP smoke at `res://tests/integration/test_smoke_mvp.gd` is not an M0 deliverable. It requires integrated gameplay dependencies and becomes mandatory no later than M15.

### 7.3. Milestone M1 — Constants and IDs

Implement:

* `GameIds.gd`;
* `PhaseIds.gd`;
* `AttackModes.gd`;
* `ValidationErrors.gd`;
* recommended constants files:

  * `RoleIds.gd`;
  * `ContractIds.gd`;
  * `ContactIds.gd`;
  * `StreetDealIds.gd`;
  * `AIProfileIds.gd`;
  * `TurfLevelIds.gd`;
  * `DefenseStates.gd`.

Gate tests:

* all required constants exist;
* no duplicate IDs;
* all validation error codes referenced by modules exist;
* file length scan passes.

### 7.4. Milestone M2 — Resource Schemas and Catalogs

Implement Resource scripts:

* `CardDefinition.gd`;
* `RoleDefinition.gd`;
* `ContractDefinition.gd`;
* `ContactDefinition.gd`;
* `StreetDealDefinition.gd`;
* `AIProfileDefinition.gd`;
* `TurfLevelDefinition.gd`.

Implement all `.tres` Resources.

Implement catalogs:

* `CardCatalog.gd`;
* `RoleCatalog.gd`;
* `ContractCatalog.gd`;
* `ContactCatalog.gd`;
* `StreetDealCatalog.gd`;
* `AIProfileCatalog.gd`;
* `TurfLevelCatalog.gd`.

Gate tests:

* every required `.tres` exists;
* every Resource ID matches constants;
* no duplicate Resources;
* catalogs load by ID;
* Resources are not mutated.

### 7.5. Milestone M3 — Deterministic Random

Implement:

* `SeededRandom.gd`;
* `SeededPicker.gd`;
* random static scan.

Gate tests:

* same seed and step produce same value;
* `next` consumes 1 step;
* `roll_d6_pair` consumes 2 steps;
* `pick_one`, `pick_unique`, `pick_weighted`, `pick_best_tie` work;
* forbidden random API scan passes.

No random consumer should be implemented before this gate passes.

### 7.6. Milestone M4 — Game State Schema

Implement:

* `GameStateFactory.gd`;
* `GameStateValidator.gd`;
* test fixtures:

  * `TestGameStateFactory.gd`;
  * `TestPlayers.gd`;
  * `TestCards.gd`;
  * `TestStates.gd`.

Factory must include:

* players;
* random state;
* market state;
* Street Deal state;
* contacts global state;
* contracts;
* debts;
* role flags;
* turf flags;
* AI boss state placeholder shape.

Gate tests:

* base state validates;
* player count is 4;
* state has all required top-level fields;
* player schemas contain all required fields;
* invalid states fail validation.

### 7.7. Milestone M5 — Core Loop and Phases

Implement:

* `GamePhaseController.gd`;
* `WinnerResolver.gd`.

Must include:

* 15-round game length;
* Market, Income, Action, Street Deal timing;
* round transitions;
* action order;
* skip action handling;
* game-over trigger;
* winner result shape;
* Turf Level 10 hook placeholder without implementing Turf logic yet.

Gate tests:

* phase order works;
* Street Deal phases occur after rounds 4, 8, 12;
* game ends after round 15;
* winner resolver uses no random;
* failed phase validation does not mutate state.

### 7.8. Milestone M6 — Economy and Market

Implement:

* `PriceLogic.gd`;
* `MarketLogic.gd`;
* `IncomeLogic.gd`;
* `PurchaseValidator.gd`;
* `PurchaseResolver.gd`.

Must include:

* starting resources integration points;
* market generation through `SeededPicker`;
* purchase validation;
* purchase resolution;
* price modifiers integration hooks;
* protected Nal;
* Cops upkeep;
* District Control rebuild.

Gate tests:

* market deterministic;
* purchases work;
* failed purchases do not mutate;
* price preview does not mutate;
* income dice deterministic;
* Cops upkeep works;
* rebuild works.

### 7.9. Milestone M7 — Combat System

Implement:

* `CombatEngine.gd`;
* `AttackValidator.gd`;
* `DefenseResolver.gd`;
* `CombatLogBuilder.gd`.

Must include:

* all War card payloads;
* Cops, Cartel, Judge;
* `insider` as `thug` modifier only;
* attacker-selected `saboteur` engine target;
* combat preview;
* discard War card.

Gate tests:

* every War card validates and resolves;
* blocked attacks consume cards;
* failed attacks do not mutate;
* previews do not mutate;
* combat hooks can be called safely.

### 7.10. Milestone M8 — Roles

Implement:

* `RoleLogic.gd`;
* role setup;
* role price modifiers;
* role flags;
* Accountant requirement and Gray Cardinal bypass.

Gate tests:

* all role setup effects work;
* all role price modifiers work;
* failed purchases do not consume flags;
* per-round role reset works.

### 7.11. Milestone M9 — Contracts

Implement:

* `ContractLogic.gd`;
* deterministic contract offers;
* setup selection;
* progress hooks;
* completion;
* deadline failure;
* manual claim.

Gate tests:

* 3 deterministic offers;
* human selects 1 contract;
* AI receives no contracts;
* all contract conditions work;
* claim twice fails;
* deadlines work.

### 7.12. Milestone M10 — Street Deals and Debts

Implement:

* `StreetDealLogic.gd`;
* `DebtLogic.gd`.

Must include:

* Street Deal generation rounds 4, 8, 12;
* used deal exclusion;
* human-only choices;
* explicit AI side effects;
* player-level debts;
* debt processing during Income;
* Turf Level 8 hook placeholder.

Gate tests:

* every Street Deal option works;
* debts create and process correctly;
* active debt blocks only `loan_shark`;
* failed choices do not mutate;
* deterministic random AI target works.

### 7.13. Milestone M11 — Contacts

Implement:

* `ContactLogic.gd`;
* contact offers;
* contact selection;
* max 1 contact;
* `black_cash`;
* `corrupt_clerk`;
* `street_medic`;
* strong AI victory hook.

Gate tests:

* `inside_contact` offer works;
* strong AI victory offer works;
* all contact effects work;
* failed selection does not mutate.

### 7.14. Milestone M12 — Turf Levels

Implement:

* `TurfLevelLogic.gd`;
* setup modifiers;
* runtime helpers;
* Level 6 AI War discount;
* Level 7 contact offer count;
* Level 8 Street Deal payment delta;
* Level 9 AI War weight multiplier;
* Level 10 tie-break helper.

Gate tests:

* levels 0-10 validate;
* levels are cumulative;
* all level effects work through owner modules;
* Level 10 tie-break works.

### 7.15. Milestone M13 — AI System

Implement:

* `AIBotController.gd`;
* `AIPurchaseLogic.gd`;
* `AITargetLogic.gd`;
* `AIFallbackLogic.gd`;
* `AIActionLogic.gd`.

Prerequisites:

* deterministic random complete;
* market complete;
* combat complete;
* Turf Level helpers complete.

Gate tests:

* strong AI selection deterministic;
* profile assignment deterministic and unique;
* AI buys through MarketLogic;
* AI attacks through CombatEngine;
* AI does not receive roles, contracts, or Street Deal choices;
* AI tie-breaks use SeededPicker.

### 7.16. Milestone M14 — GameStateManager API

Implement:

* `GameStateManager.gd`;
* optional `GameViewBuilder.gd`.

Must expose:

* setup API;
* phase API;
* market API;
* combat API;
* contract API;
* Street Deal API;
* contact API;
* AI API;
* selectors and previews.

Gate tests:

* mutators commit only on success;
* failed mutators do not mutate active state;
* selectors return deep copies or safe views;
* selectors do not consume random;
* GameStateManager stays under 250 lines.

### 7.17. Milestone M15 — Integration and Replay

Implement:

* integration tests;
* replay tests;
* full-round smoke flow;
* full 15-round scripted flow.

Gate tests:

* setup to game over works;
* replay with same seed produces identical snapshot;
* random step matches;
* all static scans pass.

### 7.18. Milestone M16 — UI / UX

Implement:

* SetupScreen;
* GameScreen;
* GameOverScreen;
* PlayerBoard;
* MarketPanel;
* ActionPanel;
* StreetDealPanel;
* ContactPanel;
* ContractPanel;
* GameLogPanel;
* required widgets.

Gate tests:

* UI calls GameStateManager only for gameplay;
* UI does not mutate state directly;
* UI scripts stay under 250 lines;
* UI static boundary tests pass.

### 7.19. Milestone M17 — Polish and Hardening

Implement:

* improved error text mapping;
* log readability;
* debug snapshot;
* final static scans;
* final full test run.

Do not add new gameplay rules during polish.

Gate:

* all tests pass;
* no unresolved blocker from `21_OPEN_QUESTIONS_AND_FIXES.md`;
* game can complete a full run.

## 8. API Expectations

This module has no runtime gameplay API.

Recommended implementation tracking helper shape:

```gdscript
{
	"milestone_id": "M6",
	"name": "Economy and Market",
	"status": "not_started",
	"required_files": [],
	"required_tests": [],
	"dependencies": [],
	"gate_passed": false
}
```

This shape is documentation-only.

Allowed milestone statuses:

| Status        | Meaning                                          |
| ------------- | ------------------------------------------------ |
| `not_started` | No implementation work has begun.                |
| `in_progress` | Work has started.                                |
| `blocked`     | Waiting on open question or failed prerequisite. |
| `implemented` | Code exists, tests not all passing yet.          |
| `complete`    | Code exists and gate tests pass.                 |

Gameplay code must not depend on milestone status.

## 9. Edge Cases

| Edge Case                               | Condition                                    | Expected Behavior                                 | Error Code                     | Mutation Rule                                            |
| --------------------------------------- | -------------------------------------------- | ------------------------------------------------- | ------------------------------ | -------------------------------------------------------- |
| Later module starts before prerequisite | AI starts before Combat or Market.           | Stop and implement prerequisite first.            | N/A                            | No gameplay code workaround.                             |
| Open question blocks module             | Required behavior is unclear.                | Add/reference `OQ-*`; implement only safe subset. | N/A                            | No invented behavior.                                    |
| File exceeds 250 lines                  | Implementation grows too large.              | Split before continuing.                          | N/A                            | No gameplay mutation.                                    |
| UI needs missing selector               | UI cannot display needed data.               | Add selector to `16_GAME_STATE_MANAGER_API.md`.   | N/A                            | UI must not read internals.                              |
| Test fails because PRD unclear          | Expected behavior not specified.             | Add open question.                                | N/A                            | Do not guess.                                            |
| Static scan fails                       | Forbidden pattern found.                     | Fix architecture before continuing.               | N/A                            | No further milestones.                                   |
| Replay mismatch                         | Same seed gives different output.            | Fix random call order before UI polish.           | N/A                            | No gameplay rule change unless owner module requires it. |
| Resource missing late                   | Catalog fails after dependent modules exist. | Fix Resource and catalog tests first.             | `REQUIREMENT_NOT_MET` in tests | No runtime fallback.                                     |
| Debug snapshot not implemented          | Optional manager missing.                    | Allowed until polish.                             | N/A                            | Gameplay unaffected.                                     |

## 10. Required Source Files

This module requires no gameplay source file.

Implementation must eventually create all source files listed by:

* `15_GODOT_ARCHITECTURE.md`;
* module-specific `Required Source Files` sections;
* `18_TEST_PLAN.md`.

Recommended documentation tracking file:

```text
res://docs/implementation_status.md
```

Optional. Must not be used by gameplay code.

## 11. Required GUT Tests

This module does not require a dedicated gameplay test file.

Implementation order should be enforced indirectly by:

* required file existence tests;
* architecture static scans;
* module unit tests;
* integration tests;
* replay tests.

Recommended static test:

```text
res://tests/static/test_implementation_order_readiness.gd
```

Minimum checks:

* foundation files exist before gameplay tests run;
* deterministic random tests pass before random consumer tests;
* Resource catalogs pass before gameplay modules load Resources;
* GameStateManager exists before UI tests;
* UI boundary tests run after UI files exist.

## 12. Static Scan Requirements

Static scans must run from early milestones onward.

Required scans:

* forbidden random API scan;
* file length scan;
* UI boundary scan;
* logic-to-UI dependency scan;
* Resource integrity scan;
* open question marker scan;
* banned non-Godot stack scan.

Static scan must fail if implementation creates:

* React files;
* TypeScript files;
* Tailwind config;
* Zustand store;
* Docker backend files;
* web routing files;
* gameplay code outside Godot project structure.

Static scan must fail if `.gd` files exceed:

```text
250 lines
```

## 13. Implementation Notes For LLM Agents

When following this order:

* Do not skip foundations.
* Do not write final UI before logic and API tests exist.
* Do not implement random consumers before deterministic random.
* Do not implement AI before Market and Combat.
* Do not put missing module logic into GameStateManager.
* Do not put gameplay logic into UI.
* Do not use forbidden random APIs.
* Do not create source files over 250 lines.
* Do not invent missing rules.
* Use owner module PRDs for exact behavior.
* Add tests with each module.
* Run static scans frequently.
* Treat failing replay tests as serious architecture bugs.

For each milestone handoff to an LLM coding agent, include:

* target milestone;
* owner PRD files;
* required source files;
* required tests;
* dependencies already completed;
* explicit rule that failed validation must not mutate state.

## 14. Acceptance Criteria

This module is complete when:

* implementation order is clear from project bootstrap to polish;
* every gameplay module has a defined implementation slot;
* every milestone has a gate;
* deterministic random is implemented before random consumers;
* Resources and catalogs are implemented before gameplay modules;
* GameStateFactory and GameStateValidator are implemented before major logic;
* Economy and Combat are implemented before AI;
* GameStateManager API is implemented before final UI;
* UI implementation comes after logic and facade tests;
* static scans are required throughout;
* replay tests are required before polish;
* optional debug snapshot is correctly treated as non-MVP persistence;
* unresolved blockers must go to `21_OPEN_QUESTIONS_AND_FIXES.md`;
* no milestone requires LLM agents to invent gameplay logic.

## 15. Final Rule

Build foundations first, gameplay second, facade third, UI last; never skip tests to make progress look faster.
