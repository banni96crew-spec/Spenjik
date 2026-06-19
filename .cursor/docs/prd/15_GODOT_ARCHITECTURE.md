# Godot Architecture

## Document Role

This file defines only:

* Godot 4.6.2 project architecture;
* folder structure;
* source file ownership;
* Autoload boundaries;
* logic module boundaries;
* Resource catalog architecture;
* Dictionary state snapshot architecture;
* UI-to-logic separation;
* mutation policy;
* module dependency direction;
* file length rules;
* debug snapshot policy;
* static scan requirements;
* architecture-related GUT tests.

This file must not redefine:

* card prices;
* card effects;
* role effects;
* contract rules;
* contact rules;
* Street Deal effects;
* debt rules;
* Turf Level effects;
* AI profiles;
* combat rules;
* income rules;
* market rules;
* deterministic random algorithm details;
* UI layouts beyond architectural ownership;
* phase transition rules.

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
* 16_GAME_STATE_MANAGER_API.md
* 17_UI_UX_SPEC.md
* 18_TEST_PLAN.md
* 19_IMPLEMENTATION_ORDER.md
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

This file defines the Godot architecture for The Turf.

The architecture must keep gameplay logic:

* deterministic;
* testable without UI;
* data-driven through `.tres` Resources;
* accessible through `GameStateManager.gd`;
* split into small files under 250 lines;
* safe for LLM coding agents.

The main architectural rule is:

```text
UI displays state and sends commands.
GameStateManager receives commands.
Logic modules validate and resolve rules.
Resources store data.
Dictionary snapshots store runtime state.
```

No UI scene may own gameplay rules.

## 2. Ownership Boundaries

This file owns:

* folder layout;
* file placement;
* dependency direction;
* code ownership rules;
* Resource loading architecture;
* Autoload architecture;
* mutation policy;
* file splitting strategy;
* static architecture scans.

This file references:

* gameplay modules for specific rules;
* `16_GAME_STATE_MANAGER_API.md` for exact public API;
* `17_UI_UX_SPEC.md` for UI scene behavior;
* `18_TEST_PLAN.md` for test organization;
* `20_LLM_AGENT_RULES.md` for LLM implementation constraints.

This file does not own:

* specific card behavior;
* phase rules;
* combat rules;
* economy rules;
* AI scores;
* UI layout details;
* save system behavior beyond debug snapshot architecture.

## 3. Core Terms

| Term             | Meaning                                                            |
| ---------------- | ------------------------------------------------------------------ |
| Autoload         | Godot singleton registered in Project Settings.                    |
| GameStateManager | Main gameplay facade used by UI.                                   |
| Logic Module     | Non-Node GDScript class that validates or resolves gameplay rules. |
| Resource         | `.tres` data asset using a `Resource` script schema.               |
| Runtime State    | Dictionary snapshot stored in `GameStateManager.state`.            |
| Source of Truth  | The one file/module that owns a rule or state field.               |
| Facade           | Public interface that hides internal logic modules from UI.        |
| Selector         | Read-only function that returns state views or previews.           |
| Mutator          | Function that may change runtime state after validation.           |
| Static Scan      | Test that checks forbidden APIs and architecture violations.       |
| Debug Snapshot   | Optional JSON dump for development, not MVP persistence.           |

## 4. Runtime State

### 4.1. Runtime State Owner

Runtime state is owned by:

```text
res://autoload/GameStateManager.gd
```

Main field:

```gdscript
var state: Dictionary = {}
```

`GameStateManager.state` is the single active runtime snapshot.

UI scripts must not create independent gameplay state.

### 4.2. Runtime State Format

Runtime state must use Dictionary snapshots.

Primary schemas are defined in:

```text
04_GAME_STATE_SCHEMA.md
```

Required top-level state shape is owned by `GameStateFactory.gd`.

Runtime state must not be implemented as:

* Godot Nodes;
* scene tree state;
* UI Control state;
* Resource instances mutated as gameplay state.

Resources define data. Dictionaries define runtime.

### 4.3. Mutation Policy

The project uses a facade-controlled mutation policy.

Rules:

1. UI must call `GameStateManager.gd`.
2. `GameStateManager.gd` must delegate gameplay calculations, validation, and candidate-state transitions to logic modules.
3. Logic modules must return structured results over the explicit working state and must never commit active state.
4. Failed validation must not mutate state.
5. Preview and selector functions must not mutate state.
6. Resource files must not be mutated at runtime.
7. Gameplay random may mutate only `state["random"]` through deterministic helpers.

Required base mutator result shape; domain methods may add only fields documented by their owner PRD:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"state": {},
	"log_entries": []
}
```

Required base failed result shape; `error` must be the exact canonical owner error:

```gdscript
{
	"ok": false,
	"error": ValidationErrors.INVALID_STATE,
	"state": {}
}
```

`INVALID_STATE` is an example only. Each owner method must return its exact documented canonical error and must not substitute a generic fallback.

### 4.4. Copy vs In-Place Rule

For MVP implementation:

* `GameStateManager.gd` owns the live state.
* Public mutator methods must duplicate state before validation-sensitive mutation.
* If validation fails, the original state must remain unchanged.
* If validation succeeds, `GameStateManager.state` is replaced with the returned state.

Recommended pattern:

```gdscript
func buy_card(player_id: String, card_id: String) -> Dictionary:
	var working_state := state.duplicate(true)
	var result := MarketLogic.buy_card(working_state, player_id, card_id)

	if result["ok"]:
		state = result["state"]

	return result
```

Logic modules may mutate the passed working copy after validation passes.

Preview methods must use duplicated state or read-only access and must not write back.

### 4.5. Resource Runtime Rule

`.tres` Resources are static gameplay data.

They must:

* define IDs;
* define titles;
* define base values;
* define summaries;
* be loaded by catalogs/registries;
* not store runtime state.

They must not:

* track player ownership;
* track cooldowns;
* track market state;
* track random state;
* track contract progress;
* mutate during gameplay.

## 5. Rules

### 5.1. Target Stack

The project must use:

| Area          | Decision                                     |
| ------------- | -------------------------------------------- |
| Engine        | Godot 4.6.2 stable                           |
| Language      | GDScript                                     |
| Typing        | Static typing wherever practical             |
| UI            | Godot Control nodes, Containers, Theme       |
| Runtime State | Dictionary snapshots                         |
| Facade        | `GameStateManager.gd` Autoload               |
| Config Data   | `.tres` Resources                            |
| Random        | `SeededRandom.gd` and `SeededPicker.gd` only |
| Tests         | GUT 9.6.0 for Godot 4.6                     |
| Export        | Windows / Linux first                        |
| Persistence   | None for MVP; optional debug snapshot only   |

### 5.2. Corrected Godot Project Structure

Required structure:

```text
res://
  project.godot

  scenes/
    main/
      Main.tscn
      Main.gd

    game/
      GameRoot.tscn
      GameRoot.gd

    ui/
      screens/
        SetupScreen.tscn
        SetupScreen.gd
        GameScreen.tscn
        GameScreen.gd
        GameOverScreen.tscn
        GameOverScreen.gd

      panels/
        PlayerBoard.tscn
        PlayerBoard.gd
        MarketPanel.tscn
        MarketPanel.gd
        ActionPanel.tscn
        ActionPanel.gd
        StreetDealPanel.tscn
        StreetDealPanel.gd
        ContactPanel.tscn
        ContactPanel.gd
        ContractPanel.tscn
        ContractPanel.gd
        GameLogPanel.tscn
        GameLogPanel.gd

      widgets/
        CardView.tscn
        CardView.gd
        DefenseBadges.tscn
        DefenseBadges.gd
        NalVpDisplay.tscn
        NalVpDisplay.gd
        DisabledReasonLabel.tscn
        DisabledReasonLabel.gd

  autoload/
    GameStateManager.gd
    AudioManager.gd
    DebugSnapshotManager.gd

  logic/
    game_state/
      GameStateFactory.gd
      GameStateValidator.gd
      GamePhaseController.gd
      WinnerResolver.gd

    economy/
      IncomeLogic.gd
      MarketLogic.gd
      PriceLogic.gd
      PurchaseValidator.gd
      PurchaseResolver.gd

    combat/
      CombatEngine.gd
      AttackValidator.gd
      DefenseResolver.gd
      CombatLogBuilder.gd

    roles/
      RoleLogic.gd

    contracts/
      ContractLogic.gd

    street_deals/
      StreetDealLogic.gd
      DebtLogic.gd

    contacts/
      ContactLogic.gd

    turf_levels/
      TurfLevelLogic.gd

    ai/
      AIBotController.gd
      AIPurchaseLogic.gd
      AITargetLogic.gd
      AIFallbackLogic.gd
      AIActionLogic.gd  # optional split helper when AIBotController approaches 250 lines

    random/
      SeededRandom.gd
      SeededPicker.gd

    catalog/
      CardCatalog.gd
      RoleCatalog.gd
      ContractCatalog.gd
      ContactCatalog.gd
      StreetDealCatalog.gd
      AIProfileCatalog.gd
      TurfLevelCatalog.gd

  data/
    ids/
      GameIds.gd
      PhaseIds.gd
      AttackModes.gd
      ValidationErrors.gd
      RoleIds.gd
      ContractIds.gd
      ContactIds.gd
      StreetDealIds.gd
      AIProfileIds.gd
      TurfLevelIds.gd
      DefenseStates.gd

    resources/
      cards/
        CardDefinition.gd
        informant.tres
        laundry.tres
        accountant.tres
        brothel.tres
        stash.tres
        workshop.tres
        district_control.tres
        cops.tres
        cartel.tres
        judge.tres
        thug.tres
        bruiser.tres
        cleaner.tres
        insider.tres
        saboteur.tres
        federal_raid.tres

      roles/
        RoleDefinition.gd
        merchant.tres
        enforcer.tres
        gray_cardinal.tres
        district_boss.tres

      contracts/
        ContractDefinition.gd
        silent_expansion.tres
        bloody_turf_war.tres
        gray_capital.tres
        iron_roof.tres
        district_under_control.tres
        proxy_war.tres
        big_cashbox.tres

      contacts/
        ContactDefinition.gd
        black_cash.tres
        corrupt_clerk.tres
        street_medic.tres

      street_deals/
        StreetDealDefinition.gd
        loan_shark.tres
        dirty_tip.tres
        cheap_protection.tres
        black_market_cache.tres
        inside_contact.tres
        risky_contract.tres

      ai_profiles/
        AIProfileDefinition.gd
        builder.tres
        racketeer.tres
        merchant_ai.tres
        paranoid.tres
        schemer.tres
        avenger.tres

      turf_levels/
        TurfLevelDefinition.gd
        turf_level_0.tres
        turf_level_1.tres
        turf_level_2.tres
        turf_level_3.tres
        turf_level_4.tres
        turf_level_5.tres
        turf_level_6.tres
        turf_level_7.tres
        turf_level_8.tres
        turf_level_9.tres
        turf_level_10.tres

  tests/
    unit/
      test_seeded_random.gd
      test_game_state_factory.gd
      test_game_state_validator.gd
      test_phase_controller.gd
      test_winner_resolver.gd
      test_price_logic.gd
      test_market_logic.gd
      test_income_logic.gd
      test_combat_engine.gd
      test_role_logic.gd
      test_contract_logic.gd
      test_street_deal_logic.gd
      test_debt_logic.gd
      test_contact_logic.gd
      test_turf_level_logic.gd
      test_ai_bot_controller.gd

    static/
      test_static_random_scan.gd
      test_architecture_static_scan.gd
      test_ui_static_boundaries.gd
      test_file_length_scan.gd
      test_resource_integrity_scan.gd
      test_open_questions_docs.gd

    fixtures/
      TestGameStateFactory.gd
      TestPlayers.gd
      TestCards.gd
      TestStates.gd

  addons/
    gut/

  themes/
    main_theme.tres

  assets/
    fonts/
    icons/
    audio/
```

### 5.3. SaveManager Correction

The original PRD listed:

```text
res://autoload/SaveManager.gd
```

But MVP explicitly has no persistence.

Corrected architecture:

```text
res://autoload/DebugSnapshotManager.gd
```

Rules:

* no campaign persistence in MVP;
* no save/load gameplay loop in MVP;
* optional debug snapshot may write JSON to `user://`;
* debug snapshot is for tests and development only;
* gameplay must not depend on debug snapshot files.

If a future save system is added, it must be specified in a later PRD version.

### 5.4. Resource Catalog Rule

Logic modules must not scatter-load `.tres` files ad hoc.

Use catalog files:

| Catalog                | Owns                           |
| ---------------------- | ------------------------------ |
| `CardCatalog.gd`       | CardDefinition Resources       |
| `RoleCatalog.gd`       | RoleDefinition Resources       |
| `ContractCatalog.gd`   | ContractDefinition Resources   |
| `ContactCatalog.gd`    | ContactDefinition Resources    |
| `StreetDealCatalog.gd` | StreetDealDefinition Resources |
| `AIProfileCatalog.gd`  | AIProfileDefinition Resources  |
| `TurfLevelCatalog.gd`  | TurfLevelDefinition Resources  |

Catalogs must:

* preload or load Resources;
* validate IDs;
* return definitions by ID;
* return all definitions;
* not mutate Resources;
* not own runtime state.

Recommended API pattern:

```gdscript
class_name CardCatalog

static func get_by_id(card_id: String) -> CardDefinition:
	return null

static func get_all() -> Array[CardDefinition]:
	return []
```

### 5.5. Dependency Direction Rule

Allowed dependency direction:

```text
UI → GameStateManager → logic modules → catalogs/resources/constants
```

Allowed lateral logic calls:

* Economy may call ContractLogic hooks.
* Combat may call ContractLogic and ContactLogic hooks.
* StreetDealLogic may call ContactLogic and ContractLogic hooks.
* DebtLogic may call ContactLogic and ContractLogic hooks.
* AI may call MarketLogic, PriceLogic, CombatEngine, and selectors.
* GamePhaseController may call module phase hooks.

Forbidden dependency direction:

* logic modules importing UI scenes;
* logic modules calling `GameStateManager` or reading its active singleton state;
* Resources importing runtime logic;
* catalogs importing UI;
* UI importing low-level logic for mutation;
* AI bypassing MarketLogic or CombatEngine;
* WinnerResolver using random;
* any module depending on debug snapshots.

`logic -> facade` calls are forbidden. The canonical flow is `facade -> logic`: logic modules are pure deterministic functions over explicit input and working-state data, while GameStateManager alone owns active-state copy, final validation, commit, signals, and UI/AI adaptation.

### 5.6. UI Architecture Rule

UI scripts are view/controller glue only.

UI scripts may:

* render state;
* call GameStateManager methods;
* show disabled reason codes;
* collect player input payloads;
* display combat log;
* display previews from selectors.

UI scripts must not:

* calculate prices;
* validate purchases;
* resolve attacks;
* mutate player state directly;
* apply Street Deal effects;
* unlock contacts directly;
* advance phases directly;
* run AI decisions;
* call random for gameplay;
* parse Resource summaries as gameplay logic.

### 5.7. Autoload Rule

Required gameplay Autoload:

```text
GameStateManager.gd
```

Allowed non-gameplay Autoloads:

* `AudioManager.gd`;
* `DebugSnapshotManager.gd`.

Forbidden:

* multiple gameplay state managers;
* UI state manager owning gameplay;
* separate stores per scene;
* persistence manager changing gameplay rules.

### 5.8. File Length Rule

Every source code file must stay under:

```text
250 lines
```

This applies to:

* `autoload/`;
* `logic/`;
* `data/ids/`;
* Resource schema scripts;
* UI scripts;
* tests where practical.

If a file approaches the limit:

* split validators;
* split resolvers;
* split log builders;
* split catalogs;
* split preview builders;
* split tests by module.

Do not create god-object files.

### 5.9. Static Typing Rule

Use static typing wherever practical.

Recommended:

```gdscript
var state: Dictionary = {}
var player_id: String = ""
var amount: int = 0
var score: float = 0.0
```

Avoid unnecessary `Variant` unless truly required by Godot APIs.

### 5.10. Constants Rule

Stable IDs and error codes must live in `res://data/ids/`.

Do not hardcode repeated gameplay strings inside logic modules if a constants file owns them.

Required constants files:

* `GameIds.gd`;
* `PhaseIds.gd`;
* `AttackModes.gd`;
* `ValidationErrors.gd`.

Recommended constants files:

* `RoleIds.gd`;
* `ContractIds.gd`;
* `ContactIds.gd`;
* `StreetDealIds.gd`;
* `AIProfileIds.gd`;
* `TurfLevelIds.gd`;
* `DefenseStates.gd`.

### 5.11. Random Architecture Rule

Gameplay random is owned only by:

```text
res://logic/random/SeededRandom.gd
res://logic/random/SeededPicker.gd
```

Forbidden in gameplay logic:

* `randf()`;
* `randi()`;
* `randomize()`;
* `RandomNumberGenerator`.

Random rules are defined in:

```text
14_DETERMINISTIC_RANDOM.md
```

### 5.12. Test-First Logic Rule

Logic modules should be implemented before UI.

Required order:

1. constants;
2. Resources and catalogs;
3. random;
4. state factory/validator;
5. owner logic modules with their GUT tests;
6. GameStateManager facade;
7. integration and replay tests;
8. UI.

UI work before logic tests are green is allowed only for placeholder screens with no gameplay rules.

## 6. Validation Rules

### 6.1. Architecture Validation

Static architecture validation must check:

| Condition                                        | Expected Result |
| ------------------------------------------------ | --------------- |
| Required folders exist                           | Pass            |
| Required constants files exist                   | Pass            |
| Required logic folders exist                     | Pass            |
| Required Resource schema files exist             | Pass            |
| Required `.tres` files exist                     | Pass            |
| Required test folders exist                      | Pass            |
| Required Autoload scripts exist                  | Pass            |
| Source files under 250 lines                     | Pass            |
| UI files do not contain gameplay logic markers   | Pass            |
| Logic files do not import UI scenes              | Pass            |
| Forbidden random APIs absent from gameplay logic | Pass            |

### 6.2. Resource Validation

Catalog tests must verify:

| Resource Type | Validation                                       |
| ------------- | ------------------------------------------------ |
| Cards         | All card IDs exist and match `GameIds.CARD_IDS`. |
| Roles         | All role IDs exist and are unique.               |
| Contracts     | All contract IDs exist and are unique.           |
| Contacts      | All contact IDs exist and are unique.            |
| Street Deals  | All Street Deal IDs exist and are unique.        |
| AI Profiles   | All AI profile IDs exist and are unique.         |
| Turf Levels   | Levels 0 through 10 exist exactly once.          |

### 6.3. Autoload Validation

Project configuration must register:

```text
GameStateManager
```

as an Autoload.

Optional:

* `AudioManager`;
* `DebugSnapshotManager`.

`DebugSnapshotManager` must not be required for normal gameplay tests.

### 6.4. Failed Validation Mutation Rule

Architecture validation failures must not trigger gameplay state changes.

Static scans must fail tests, not mutate code or runtime state.

## 7. Resolution / Processing Flow

### 7.1. Startup Flow

Game startup should resolve in this order:

1. `Main.tscn` loads.
2. `GameStateManager.gd` Autoload is available.
3. Setup screen collects:

   * game seed;
   * Turf Level;
   * selected role;
   * selected contract.
4. UI calls `GameStateManager.start_new_game(config)`.
5. GameStateManager creates runtime state through logic modules.
6. UI receives updated state and renders Game screen.

### 7.2. Gameplay Command Flow

All player commands follow this flow:

```text
UI input
  → GameStateManager public method
  → duplicate working state
  → validate through owner module
  → resolve through owner module
  → validate final state
  → replace GameStateManager.state on success
  → return structured result
  → UI refreshes from state/selectors
```

### 7.3. Preview Flow

All preview commands follow this flow:

```text
UI hover/selection
  → GameStateManager selector
  → logic preview function
  → no mutation
  → return preview/result/error code
  → UI displays result
```

Preview functions must not:

* consume active gameplay random;
* mutate flags;
* write logs;
* advance phases;
* consume modifiers.

The contract setup preview may consume only a temporary RandomState created from setup config; it never reads or mutates active GameState.

### 7.4. AI Flow

AI commands follow the same architecture:

```text
GamePhaseController / GameStateManager
  → AIBotController
  → AI logic builds candidates
  → MarketLogic / CombatEngine validates
  → pure owner logic mutates the shared working state
  → GameStateManager validates and commits the final result
```

AI must never bypass validation or call the facade from inside a logic module.

### 7.5. Resource Loading Flow

Catalog flow:

1. Catalog preloads known Resource files.
2. Catalog validates ID consistency.
3. Logic module asks catalog for definition by ID.
4. Logic reads Resource data.
5. Logic writes only to Dictionary state, never to Resource.

### 7.6. Debug Snapshot Flow

Debug snapshot flow:

1. Developer/test calls `DebugSnapshotManager.save_debug_snapshot(state)`.
2. Snapshot writes JSON to `user://debug_run_snapshot.json`.
3. Gameplay does not read from this file in MVP.
4. Tests may compare snapshots if explicitly designed.

Required debug path:

```text
user://debug_run_snapshot.json
```

## 8. API Expectations

### 8.1. GameStateManager.gd

Required public API is owned by:

```text
16_GAME_STATE_MANAGER_API.md
```

Architecture expectations:

* GameStateManager is the only UI-facing gameplay facade.
* GameStateManager owns `state`.
* GameStateManager exposes mutators and selectors.
* GameStateManager does not contain large gameplay rule bodies.
* GameStateManager delegates to logic modules.

### 8.2. Logic Module API Pattern

Logic mutator functions should use:

```gdscript
static func do_action(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": state,
		"log_entries": []
	}
```

Validation functions should use:

```gdscript
static func validate_action(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK
	}
```

Preview functions should use:

```gdscript
static func get_preview(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK
	}
```

### 8.3. Catalog API Pattern

Catalogs should use:

```gdscript
static func get_by_id(id: String) -> Resource:
	return null

static func has_id(id: String) -> bool:
	return false

static func get_all_ids() -> Array[String]:
	return []

static func get_all() -> Array:
	return []
```

Catalogs must not mutate runtime state.

### 8.4. DebugSnapshotManager.gd

Optional debug-only API:

```gdscript
class_name DebugSnapshotManager
extends Node

func save_debug_snapshot(snapshot: Dictionary) -> void:
	var file := FileAccess.open("user://debug_run_snapshot.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot))

func load_debug_snapshot() -> Dictionary:
	return {}
```

`load_debug_snapshot()` is optional and must not be used by MVP gameplay flow.

### 8.5. Scene Script API Pattern

UI scene scripts should expose methods like:

```gdscript
func render(state_view: Dictionary) -> void:
	pass

func _on_buy_pressed(card_id: String) -> void:
	var result := GameStateManager.buy_card(GameIds.PLAYER_HUMAN, card_id)
	render(GameStateManager.get_view())
```

UI scripts must not perform gameplay calculations.

## 9. Edge Cases

| Edge Case                       | Condition                                 | Expected Behavior                    | Error Code            | Mutation Rule                      |
| ------------------------------- | ----------------------------------------- | ------------------------------------ | --------------------- | ---------------------------------- |
| Missing Resource file           | Required `.tres` file is absent.          | Catalog validation fails.            | `REQUIREMENT_NOT_MET` | No gameplay start.                 |
| Duplicate Resource ID           | Two Resources share ID.                   | Catalog validation fails.            | `REQUIREMENT_NOT_MET` | No gameplay start.                 |
| Missing constant                | Logic references missing ID constant.     | Static/test failure.                 | N/A                   | No runtime workaround.             |
| UI calculates price             | UI script contains price logic.           | Static scan fails.                   | N/A                   | Move logic to PriceLogic.          |
| UI resolves combat              | UI script mutates combat state.           | Static scan fails.                   | N/A                   | Move logic to CombatEngine.        |
| Logic imports UI scene          | Logic depends on scene tree UI.           | Static scan fails.                   | N/A                   | Remove dependency.                 |
| Forbidden random API            | Gameplay file contains Godot random API.  | Static scan fails.                   | N/A                   | Replace with deterministic random. |
| Source file too long            | File exceeds 250 lines.                   | Static scan fails.                   | N/A                   | Split file.                        |
| Debug snapshot unavailable      | `user://` write fails in dev environment. | Gameplay continues.                  | N/A                   | Debug only; no gameplay mutation.  |
| Resource mutated at runtime     | Logic writes to Resource field.           | Test/static review fails.            | N/A                   | Store runtime state in Dictionary. |
| Preview mutates state           | Selector changes state or random step.    | Test fails.                          | N/A                   | Fix preview to be read-only.       |
| AI bypasses validation          | AI directly mutates hand/Nal/combat.      | Test/static scan fails.              | N/A                   | Route through owner module.        |
| Catalog missing optional helper | Optional helper not implemented.          | Allowed if required API still works. | N/A                   | No mutation.                       |

## 10. Required Source Files

### 10.1. Required Autoload Files

```text
res://autoload/GameStateManager.gd
```

Optional:

```text
res://autoload/AudioManager.gd
res://autoload/DebugSnapshotManager.gd
```

### 10.2. Required Logic Files

```text
res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/game_state/WinnerResolver.gd

res://logic/random/SeededRandom.gd
res://logic/random/SeededPicker.gd

res://logic/economy/IncomeLogic.gd
res://logic/economy/MarketLogic.gd
res://logic/economy/PriceLogic.gd

res://logic/combat/CombatEngine.gd
res://logic/combat/AttackValidator.gd
res://logic/combat/DefenseResolver.gd
res://logic/combat/CombatLogBuilder.gd

res://logic/roles/RoleLogic.gd
res://logic/contracts/ContractLogic.gd
res://logic/street_deals/StreetDealLogic.gd
res://logic/street_deals/DebtLogic.gd
res://logic/contacts/ContactLogic.gd
res://logic/turf_levels/TurfLevelLogic.gd

res://logic/ai/AIBotController.gd
res://logic/ai/AIPurchaseLogic.gd
res://logic/ai/AITargetLogic.gd
res://logic/ai/AIFallbackLogic.gd
```

Recommended:

```text
res://logic/ai/AIActionLogic.gd
```

### 10.3. Required Catalog Files

```text
res://logic/catalog/CardCatalog.gd
res://logic/catalog/RoleCatalog.gd
res://logic/catalog/ContractCatalog.gd
res://logic/catalog/ContactCatalog.gd
res://logic/catalog/StreetDealCatalog.gd
res://logic/catalog/AIProfileCatalog.gd
res://logic/catalog/TurfLevelCatalog.gd
```

### 10.4. Required Constants Files

```text
res://data/ids/GameIds.gd
res://data/ids/PhaseIds.gd
res://data/ids/AttackModes.gd
res://data/ids/ValidationErrors.gd
```

Recommended:

```text
res://data/ids/RoleIds.gd
res://data/ids/ContractIds.gd
res://data/ids/ContactIds.gd
res://data/ids/StreetDealIds.gd
res://data/ids/AIProfileIds.gd
res://data/ids/TurfLevelIds.gd
res://data/ids/DefenseStates.gd
```

### 10.5. Required UI Files

Required UI files are listed in Section 5.2.

UI files must remain thin. If a UI script approaches 250 lines, split widgets or move formatting helpers out of gameplay path.

## 11. Required GUT Tests

Required test file:

```text
res://tests/static/test_architecture_static_scan.gd
```

### 11.1. Folder Structure Tests

Minimum tests:

* `res://logic/` exists;
* `res://data/` exists;
* `res://autoload/` exists;
* `res://scenes/` exists;
* `res://tests/` exists;
* required module folders exist.

### 11.2. Source File Tests

Minimum tests:

* required Autoload files exist;
* required logic files exist;
* required constants files exist;
* required Resource schema files exist;
* required catalog files exist;
* required `.tres` files exist.

### 11.3. File Length Tests

Minimum tests:

* every `.gd` file under `res://logic/` is under 250 lines;
* every `.gd` file under `res://autoload/` is under 250 lines;
* every Resource schema script is under 250 lines;
* UI scripts are under 250 lines where practical.

### 11.4. UI Boundary Tests

Minimum static tests:

* UI files do not call `PriceLogic` directly for mutation;
* UI files do not call `CombatEngine.resolve_attack` directly;
* UI files do not mutate `GameStateManager.state` fields directly;
* UI files do not contain `player["nal"] -=`;
* UI files do not contain `player["vp"] +=`;
* UI files do not use forbidden gameplay random APIs.

### 11.5. Logic Boundary Tests

Minimum static tests:

* logic files do not import UI scene paths;
* logic files do not call `get_node()` for UI gameplay;
* logic files do not use `Control` nodes;
* logic files do not use forbidden random APIs;
* WinnerResolver does not reference `SeededRandom` or `SeededPicker`.

### 11.6. Catalog Tests

Minimum tests:

* all catalogs load their Resources;
* every Resource ID matches expected constants;
* no duplicate IDs;
* missing Resource returns safe failure or null;
* catalogs do not mutate Resources.

### 11.7. Mutation Policy Tests

Minimum tests:

* failed purchase does not mutate `GameStateManager.state`;
* failed attack does not mutate `GameStateManager.state`;
* failed Street Deal choice does not mutate `GameStateManager.state`;
* failed contact selection does not mutate `GameStateManager.state`;
* preview functions do not mutate state;
* preview functions do not consume random.

## 12. Static Scan Requirements

Static scan must fail on gameplay files containing:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

Static scan must fail on logic files containing UI scene dependencies:

```text
res://scenes/ui/
Control
Button
Label
TextureRect
Panel
get_node(
$"
```

Exception:

* UI scripts may use UI nodes.
* Tests may mention these strings when testing static scans.
* Markdown files may mention them as forbidden patterns.

Static scan must fail on UI files containing direct gameplay mutation patterns:

```text
["nal"] -=
["nal"] +=
["vp"] -=
["vp"] +=
["hand"].append
["hand"].erase
["purchased_this_round"].append
["combat_log"].append
```

UI must call GameStateManager instead.

Static scan must fail if `.gd` files exceed:

```text
250 lines
```

Static scan must fail if gameplay code references banned web stack terms as implementation targets:

* React;
* TypeScript;
* Zustand;
* Tailwind;
* Docker;
* WebSocket backend.

Markdown may mention those only in out-of-scope or ban sections.

## 13. Implementation Notes For LLM Agents

When implementing architecture:

* Build logic before UI.
* Use Godot 4.6.2 and GDScript only.
* Do not create React, TypeScript, Tailwind, Zustand, Docker, or backend files.
* Keep Resources as data only.
* Keep runtime state in Dictionaries.
* Use GameStateManager as the only gameplay facade for UI.
* Do not write gameplay logic in UI.
* Do not mutate Resource definitions at runtime.
* Do not use forbidden random APIs.
* Do not create source files over 250 lines.
* Split validators, resolvers, log builders, catalogs, and previews early.
* Use catalogs for Resource access.
* Use constants for IDs and validation errors.
* Use GUT tests for every logic module.
* Use static scans to enforce architecture.
* Treat debug snapshots as optional development tools, not save/load gameplay.

If an architecture gap appears, add it to:

```text
21_OPEN_QUESTIONS_AND_FIXES.md
```

Do not solve architecture gaps by creating hidden global state or new source-of-truth files.

## 14. Acceptance Criteria

This module is complete when:

* Godot project uses the required folder structure;
* `GameStateManager.gd` is the only gameplay facade used by UI;
* runtime state is stored as Dictionary snapshots;
* gameplay data is stored as `.tres` Resources;
* Resources are loaded through catalogs;
* logic modules are separated by domain;
* UI scripts do not own gameplay logic;
* AI does not bypass validation;
* deterministic random is centralized;
* debug snapshot architecture is optional and does not imply MVP persistence;
* all required constants files exist or are explicitly tracked;
* all required Resource files exist;
* all source files stay under 250 lines;
* static architecture scans pass;
* required GUT tests pass.

## 15. Final Rule

Godot architecture must keep gameplay rules in tested logic modules, never in UI scenes, Resources, or hidden global state.
