# Game State Manager API

## Document Role

This file defines only:

* `GameStateManager.gd` Autoload ownership;
* public gameplay API exposed to UI;
* public selectors exposed to UI;
* setup API;
* phase API;
* economy and market API;
* combat API;
* role, contract, Street Deal, contact, Turf Level, and AI facade API;
* mutation rules;
* result shapes;
* validation behavior;
* signal expectations;
* state snapshot access rules;
* GameStateManager-related GUT tests.

This file must not redefine:

* card prices;
* card effects;
* market generation rules;
* income formulas;
* combat resolution;
* role effects;
* contract conditions;
* contact effects;
* Street Deal effects;
* debt rules;
* Turf Level effects;
* AI scoring;
* deterministic random algorithms;
* UI layout or rendering behavior.

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

`GameStateManager.gd` is the single gameplay facade used by UI and high-level scene scripts.

It owns the active runtime state snapshot and exposes safe API methods for:

* starting a new game;
* reading state views;
* buying cards;
* ending phase participation;
* executing combat actions;
* selecting Street Deals;
* claiming contracts;
* selecting contacts;
* running AI turns;
* advancing phase flow through validated logic.

`GameStateManager.gd` must not become a mega-file with full gameplay logic. It must delegate rule resolution to owner logic modules.

The UI must call `GameStateManager.gd`, not low-level logic modules, for gameplay mutations.

## 2. Ownership Boundaries

This file owns:

* public method names;
* public payload shapes;
* public result shapes;
* mutation safety rules;
* selector safety rules;
* facade-level signal expectations;
* GameStateManager file boundaries.

This file references:

* module PRD files for actual rule ownership;
* `15_GODOT_ARCHITECTURE.md` for dependency direction;
* `17_UI_UX_SPEC.md` for UI usage;
* `18_TEST_PLAN.md` for test expectations.

This file does not own:

* actual gameplay formulas;
* validation internals;
* AI scoring internals;
* Resource loading internals;
* UI rendering;
* save/load behavior.

## 3. Core Terms

| Term              | Meaning                                                                          |
| ----------------- | -------------------------------------------------------------------------------- |
| GameStateManager  | Autoload facade that owns the active `state` Dictionary.                         |
| Public Mutator    | API method that may change `state` after successful validation.                  |
| Selector          | Read-only API method that returns state views or previews without mutation.      |
| Working State     | Deep copy of `state` used by mutators before committing.                         |
| Commit            | Replacing `GameStateManager.state` with a validated updated state.               |
| Failed Validation | Result with `ok == false`; must not mutate active state.                         |
| Result Shape      | Stable Dictionary returned by API methods.                                       |
| Disabled Reason   | Stable validation error code shown by UI.                                        |
| Phase-Safe API    | Method that changes readiness, action completion, or phases through owner logic. |

## 4. Runtime State

### 4.1. Active State

`GameStateManager.gd` owns:

```gdscript
var state: Dictionary = {}
```

Rules:

* `state` is the single active gameplay snapshot.
* UI must not mutate `state` directly.
* Logic modules must receive duplicated working state from mutator methods.
* Failed mutators must leave `state` unchanged.
* Selectors must not mutate `state`.

### 4.2. Required Autoload

`GameStateManager.gd` must be registered as an Autoload:

```text
GameStateManager
```

Path:

```text
res://autoload/GameStateManager.gd
```

### 4.3. State Initialization

Before a game starts:

```gdscript
state = {}
```

After `start_new_game(config)` succeeds, `state` must contain a valid `GameState` from `04_GAME_STATE_SCHEMA.md`.

### 4.4. Signal Expectations

Recommended signals:

```gdscript
signal state_changed(state: Dictionary)
signal action_failed(error: String, result: Dictionary)
signal phase_changed(phase_id: String)
signal game_started(state: Dictionary)
signal game_ended(result: Dictionary)
```

Signal rules:

* emit `state_changed` only after successful state mutation;
* emit `action_failed` after failed public mutator calls if useful for UI;
* selectors must not emit signals;
* failed validation must not emit `state_changed`.

## 5. Rules

### 5.1. Facade Rule

UI must call `GameStateManager.gd` for gameplay operations.

Allowed UI calls:

* mutators listed in this file;
* selectors listed in this file;
* state view helpers.

Forbidden UI behavior:

* direct mutation of `GameStateManager.state`;
* direct calls to owner logic mutators;
* direct card placement;
* direct combat resolution;
* direct phase advancement;
* direct AI execution;
* direct random calls for gameplay.

### 5.2. Thin Facade Rule

`GameStateManager.gd` must stay under:

```text
250 lines
```

It must not contain full implementations of:

* price calculation;
* purchase validation;
* combat resolution;
* contract completion;
* AI scoring;
* random picking.

Canonical dependency and responsibility order:

```text
UI / AI orchestration -> GameStateManager facade -> pure logic modules
```

Logic modules own calculations, validation, deterministic random consumption, gameplay transitions, and candidate-state mutation. The facade owns active-state copying, delegation, final validation, commit, signals, and UI/AI result adaptation.

Logic modules must not call `GameStateManager`, read active singleton state, emit facade signals, or commit state. GameStateManager must not duplicate, override, or bypass gameplay business rules from logic modules.

If `GameStateManager.gd` approaches the limit:

* move helper formatting to selectors;
* move setup orchestration to `GameStateFactory.gd`;
* move phase flow to `GamePhaseController.gd`;
* keep only public facade methods and commit helpers.

### 5.3. Mutation Rule

Public mutators must follow this pattern:

```gdscript
func some_action(payload: Dictionary) -> Dictionary:
	var working_state := state.duplicate(true)
	var result := SomeLogic.resolve(working_state, payload)

	if result.get("ok", false):
		state = result["state"]
		_emit_success_signals(result)

	return result
```

Failed validation must not mutate active state.

### 5.4. Selector Rule

Selectors must:

* not mutate `state`;
* not consume active `state["random"]`;
* not consume temporary modifiers;
* not consume role flags;
* not write logs;
* not advance phases.

Selectors may:

* calculate previews;
* return disabled reasons;
* return UI-ready views;
* expose state snapshots.

`generate_contract_offers(config)` is the only setup-preview exception: it consumes a temporary RandomState created from config and never mutates active state or active random.

### 5.5. Result Shape Rule

Every public mutator must return:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"state": {},
	"log_entries": []
}
```

or:

```gdscript
{
	"ok": false,
	"error": ValidationErrors.INVALID_STATE,
	"state": {}
}
```

`INVALID_STATE` is an example only. Every method returns the exact canonical owner error. Module-specific fields may be added only when this file or the owner PRD documents them.

### 5.6. Error Code Rule

UI-facing errors must be stable constants from:

```text
res://data/ids/ValidationErrors.gd
```

If a module recommends a new error code, add it to `ValidationErrors.gd` instead of returning ad-hoc strings.

### 5.7. Random Rule

`GameStateManager.gd` must not use:

```gdscript
randf()
randi()
randomize()
RandomNumberGenerator
```

It must not generate random directly.

Random-consuming logic must be delegated to owner modules using:

```text
SeededRandom.gd
SeededPicker.gd
```

### 5.8. AI Rule

AI execution must use the same public or phase-safe internal APIs as human actions.

AI must not bypass:

* `MarketLogic.can_buy_card`;
* `MarketLogic.buy_card`;
* `CombatEngine.validate_attack`;
* `CombatEngine.resolve_attack`;
* phase readiness rules.

### 5.9. Phase Safety Rule

Only phase-safe APIs may change:

* `state["current_phase"]`;
* `state["round"]`;
* `player["ready_for_action"]`;
* `player["action_done"]`;
* `state["active_action_player_id"]`;
* game-over state.

Phase ownership is defined in:

```text
02_CORE_LOOP_AND_PHASES.md
```

## 6. Validation Rules

### 6.1. Public Mutator Validation

Every public mutator must validate:

* game state exists;
* required payload fields exist;
* current phase is valid for action;
* player ID is valid where applicable;
* delegated module returns `ok == true` before committing.

### 6.2. Setup Validation

`start_new_game(config)` must validate:

| Field                  | Required | Rule                                                                        |
| ---------------------- | -------: | --------------------------------------------------------------------------- |
| `game_seed`            |      yes | Non-empty String.                                                           |
| `turf_level`           |      yes | Integer `0..10`.                                                            |
| `selected_role_id`     |      yes | Valid role ID.                                                              |
| `selected_contract_id` |      yes | Must be a valid ID and a member of the deterministically regenerated offer list. |

Required error codes:

| Condition           | Error                                          |
| ------------------- | ---------------------------------------------- |
| Invalid seed | `REQUIREMENT_NOT_MET` |
| Invalid Turf Level | `INVALID_TURF_LEVEL` |
| Invalid role ID | `INVALID_ROLE_ID` |
| Invalid contract ID | `INVALID_CONTRACT_ID` |
| Valid contract ID outside regenerated offers | `CONTRACT_OFFER_UNAVAILABLE` |
| Contract already committed in working state | `CONTRACT_ALREADY_SELECTED` |
| Invalid final state | `INVALID_STATE` |

### 6.3. Failed Validation Mutation Rule

Failed validation must not mutate:

* active `state`;
* `state["random"]`;
* logs;
* player resources;
* phase flags;
* temporary modifiers;
* role flags;
* contact flags;
* contract state.

### 6.4. Selector Validation

Selectors must return safe failed results when:

* no active game exists;
* player ID is invalid;
* card ID is invalid;
* requested view is unavailable.

Selectors must not throw errors for normal disabled UI states.

## 7. Resolution / Processing Flow

### 7.1. Public Mutator Flow

All mutators:

1. Check active state if required.
2. Duplicate active state deeply.
3. Call owner logic module.
4. If result fails:

   * keep active state unchanged;
   * optionally emit `action_failed`.
5. If result succeeds:

   * validate returned state;
   * commit returned state;
   * emit signals;
   * return result.

### 7.2. Setup Flow

`start_new_game(config)` flow:

1. Validate config shape.
2. Create local `setup_working` state with `GameStateFactory`.
3. Create deterministic random state.
4. Apply selected role without consuming random.
5. Regenerate exactly three contract offers, validate selected membership, and create one human ContractRuntime.
6. Select strong AI and AI profiles.
7. Apply Turf Level setup modifiers.
8. Set committed phase to Income and `market = {}`.
9. Append `MATCH_STARTED`.
10. Validate the complete committed state.
11. Commit state once.
12. Emit `game_started`.
13. Emit `state_changed`.

### 7.3. Purchase Flow

`buy_card(player_id, card_id)` flow:

1. Duplicate state.
2. Call `MarketLogic.buy_card`.
3. MarketLogic validates and resolves purchase.
4. Contract/contact hooks run inside owner modules where required.
5. Final state is validated.
6. Commit on success.

### 7.4. Combat Flow

`execute_attack(payload)` flow:

1. Duplicate state.
2. Call `CombatEngine.resolve_attack`.
3. CombatEngine validates and resolves.
4. Contract/contact hooks run inside owner modules.
5. Final state is validated.
6. Commit on success.

### 7.5. Phase Flow

Phase APIs delegate to:

```text
GamePhaseController.gd
```

`GameStateManager.gd` must not manually implement full phase transition logic.

Canonical `advance_phase` facade flow:

1. Return `GAME_NOT_STARTED` if active state is empty.
2. Deep-copy active state.
3. Call `GamePhaseController.advance_phase(working_state)`.
4. Let GamePhaseController run all required owner entry hooks on the same candidate, including atomic four-player Income resolution for Income -> Market.
5. If any delegated result fails, return its exact canonical error and discard the candidate.
6. Validate the complete candidate with `GameStateValidator.validate_game_state`.
7. Commit once.
8. Emit `state_changed`, then `phase_changed`; emit `game_ended` only after a committed Game Over result.

The facade does not catch a partial phase result, repair it, or commit owner-module sub-results separately.

### 7.6. AI Flow

AI APIs delegate to:

```text
AIBotController.gd
```

AI result mutation must still be committed only through `GameStateManager.gd` or phase-safe internal commit flow.

## 8. API Expectations

### 8.1. Core State API

```gdscript
func has_active_game() -> bool:
	return not state.is_empty()

func get_state_snapshot() -> Dictionary:
	return state.duplicate(true)

func get_view() -> Dictionary:
	return GameViewBuilder.build_view(state)

func reset_game() -> Dictionary:
	state = {}
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": state
	}
```

`get_state_snapshot()` must return a deep copy.

UI must not receive writable access to active state.

### 8.2. Setup API

```gdscript
func start_new_game(config: Dictionary) -> Dictionary:
	return {}
```

Required config shape:

```gdscript
{
	"game_seed": "run_12345",
	"turf_level": 0,
	"selected_role_id": "merchant",
	"selected_contract_id": "gray_capital"
}
```

Required setup selectors:

```gdscript
func get_available_roles() -> Dictionary:
	return {}

func get_available_turf_levels() -> Dictionary:
	return {}

func generate_contract_offers(config: Dictionary) -> Dictionary:
	return {}
```

Required preview config shape:

```gdscript
{
	"game_seed": "run_12345",
	"turf_level": 0,
	"selected_role_id": "merchant"
}
```

`generate_contract_offers(config)` is a pure setup preview:

* it creates a temporary setup state and random state derived from config;
* it returns exactly 3 deterministic contract IDs;
* it does not mutate active game state;
* it does not mutate active random state or append gameplay events;
* it creates no ContractRuntime and no separate offer object;
* repeated calls with the same config return the same IDs in the same order.

`start_new_game(config)` receives `selected_contract_id`, regenerates the same 3 offers in a fresh working state, validates the selection, creates the human ContractRuntime, and commits `contract_offer_ids`, `selected_contract_id`, and `player["contracts"]` together. There is no setup shortcut that bypasses offer membership. `MATCH_STARTED` records the committed offer IDs and selected ID.

### 8.3. Phase API

```gdscript
func advance_phase() -> Dictionary:
	return {}

func end_market_for_player(player_id: String) -> Dictionary:
	return {}

func end_action_for_player(player_id: String) -> Dictionary:
	return {}

func skip_action_for_player(player_id: String) -> Dictionary:
	return {}

func get_current_phase() -> String:
	return state.get("current_phase", "")

func get_round() -> int:
	return int(state.get("round", 0))
```

Rules:

* UI may call `end_market_for_player` for the human.
* AI may call phase-safe internal equivalent.
* `advance_phase` performs exactly one legal phase transition through GamePhaseController.
* Income -> Market resolves all four players, deterministic random, Cops upkeep, debts, contract hooks, Market entry, events, and final validation in one atomic transaction.
* Market -> Action returns `PHASE_NOT_READY` until every player is ready.
* Action -> next phase returns `PHASE_NOT_READY` until every player is done.
* Street Deal -> Income returns `PHASE_NOT_READY` until the human choice is resolved.
* Game Over returns `GAME_ALREADY_OVER`.
* Invalid state, phase, round, random, or delegated owner errors are returned unchanged.
* Failure changes no active state, random step, event log, or signal-visible state.
* UI must not set `ready_for_action` or `action_done` directly.

### 8.4. Economy and Market API

Mutators:

```gdscript
func buy_card(player_id: String, card_id: String) -> Dictionary:
	return {}

func rebuild_district_control(player_id: String) -> Dictionary:
	return {}
```

Selectors:

```gdscript
func get_market_view(player_id: String) -> Dictionary:
	return {}

func get_card_price_preview(player_id: String, card_id: String) -> Dictionary:
	return {}

func get_purchase_disabled_reason(player_id: String, card_id: String) -> String:
	return ""

func get_income_preview(player_id: String) -> Dictionary:
	return {}

func get_cops_upkeep_preview(player_id: String) -> Dictionary:
	return {}

func get_protected_nal_preview(player_id: String) -> Dictionary:
	return {}
```

`rebuild_district_control` is a dedicated API. It must not be hidden as a fake card ID.

District rebuild rules are owned by:

```text
06_ECONOMY_AND_MARKET.md
```

### 8.5. Combat API

Mutators:

```gdscript
func execute_attack(payload: Dictionary) -> Dictionary:
	return {}

func discard_war_card(player_id: String, card_id: String) -> Dictionary:
	return {}
```

Selectors:

```gdscript
func get_combat_preview(payload: Dictionary) -> Dictionary:
	return {}

func get_valid_targets(action_payload: Dictionary) -> Dictionary:
	return {}

func get_valid_engine_targets(attacker_id: String, target_id: String) -> Dictionary:
	return {}

func get_action_disabled_reason(action_payload: Dictionary) -> String:
	return ""
```

Attack payload shape:

```gdscript
{
	"attacker_id": "player_1",
	"target_id": "ai_1",
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"modifiers": [],
	"engine_target_card_id": ""
}
```

Combat rules are owned by:

```text
07_COMBAT_SYSTEM.md
```

### 8.6. Contract API

Mutators:

```gdscript
func claim_contract(player_id: String, contract_id: String) -> Dictionary:
	return {}
```

Selectors:

```gdscript
func get_contract_state(player_id: String) -> Dictionary:
	return {}

func get_contract_claim_disabled_reason(player_id: String, contract_id: String) -> String:
	return ""
```

Contract selection during active run is not supported in MVP after game setup.

Contract setup is handled by:

```gdscript
start_new_game(config)
```

Contract rules are owned by:

```text
09_CONTRACTS.md
```

### 8.7. Street Deal and Debt API

Mutators:

```gdscript
func select_street_deal(payload: Dictionary) -> Dictionary:
	return {}
```

Payload:

```gdscript
{
	"player_id": "player_1",
	"deal_id": "dirty_tip",
	"option_id": "option_a"
}
```

Selectors:

```gdscript
func get_street_deal_view(player_id: String) -> Dictionary:
	return {}

func get_street_deal_disabled_reason(payload: Dictionary) -> String:
	return ""

func get_debt_status(player_id: String) -> Dictionary:
	return {}
```

Manual debt repayment is not part of MVP.

Debt processing happens through Income flow.

Street Deal rules are owned by:

```text
10_STREET_DEALS_AND_DEBTS.md
```

### 8.8. Contact API

Mutators:

```gdscript
func select_contact(payload: Dictionary) -> Dictionary:
	return {}

func activate_contact(payload: Dictionary) -> Dictionary:
	return {}
```

Payload:

```gdscript
{
	"player_id": "player_1",
	"contact_id": "black_cash"
}
```

Selectors:

```gdscript
func get_contact_offer(player_id: String) -> Dictionary:
	return {}

func get_contact_state(player_id: String) -> Dictionary:
	return {}

func get_contact_disabled_reason(payload: Dictionary) -> String:
	return ""
```

MVP note:

* `select_contact` is used for pending contact offers.
* `activate_contact` exists for active contacts, but `street_medic` normally triggers through DebtLogic hook.

Contact rules are owned by:

```text
11_CONTACTS.md
```

### 8.9. AI API

Mutators:

```gdscript
func run_market_for_ai(player_id: String) -> Dictionary:
	return {}

func run_action_for_ai(player_id: String) -> Dictionary:
	return {}

func run_all_ai_market() -> Dictionary:
	return {}

func run_all_ai_actions() -> Dictionary:
	return {}
```

Selectors:

```gdscript
func get_ai_state(player_id: String) -> Dictionary:
	return {}

func get_ai_profiles_view() -> Dictionary:
	return {}
```

Rules:

* UI may call AI APIs only for debug/dev buttons unless phase flow calls them automatically.
* AI APIs must use the same owner modules as human actions.
* AI APIs must not bypass validation.

AI rules are owned by:

```text
13_AI_SYSTEM.md
```

### 8.10. Turf Level API

Selectors:

```gdscript
func get_turf_level() -> int:
	if state.is_empty():
		return TurfLevelIds.BASE
	return state["turf_level"]

func get_turf_level_view() -> Dictionary:
	return {}
```

Turf Level is selected only during setup in MVP.

No runtime mutator for changing Turf Level is allowed during a run.

### 8.11. Debug API

Optional debug-only methods:

```gdscript
func save_debug_snapshot() -> Dictionary:
	return {}

func get_debug_state_summary() -> Dictionary:
	return {}
```

Rules:

* debug APIs must not be required for gameplay;
* debug snapshot save failure must not break gameplay;
* debug APIs must not mutate gameplay state except writing external debug file.

## 9. Result Shapes

### 9.1. Generic Success

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"state": {},
	"log_entries": []
}
```

### 9.2. Generic Failure

```gdscript
{
	"ok": false,
	"error": ValidationErrors.INVALID_STATE,
	"state": {}
}
```

The shown error is an example; a concrete method must return its exact documented canonical owner error.

### 9.2.1. advance_phase Result

Successful transition:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"from_phase": "income",
	"to_phase": "market",
	"round_before": 1,
	"round_after": 1,
	"state": {},
	"log_entries": []
}
```

Failed transition uses the generic failure shape plus `from_phase`, `round_before`, and optional validation `details`. It returns one canonical code from `GAME_NOT_STARTED`, `GAME_ALREADY_OVER`, `INVALID_STATE`, `INVALID_PHASE`, `INVALID_ROUND`, `INVALID_RANDOM_STATE`, `PHASE_NOT_READY`, or a delegated owner-module error.

### 9.3. Setup Result

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"config": {},
	"state": {},
	"log_entries": []
}
```

### 9.4. Purchase Result

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"card_id": "stash",
	"price": 8,
	"destination": "table",
	"state": {},
	"log_entries": []
}
```

### 9.5. Combat Result

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"attacker_id": "player_1",
	"target_id": "ai_1",
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"blocked": false,
	"success": true,
	"effect_result": {},
	"cards_consumed": [],
	"state": {},
	"log_entries": []
}
```

### 9.6. Selector Result

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"view": {}
}
```

### 9.7. Disabled Reason Result

Disabled reason methods may return a String:

```gdscript
ValidationErrors.OK
```

or:

```gdscript
ValidationErrors.NOT_ENOUGH_NAL
```

Empty string should not be used for valid actions. Prefer:

```gdscript
ValidationErrors.OK
```

## 10. Edge Cases

| Edge Case                  | Condition                                   | Expected Behavior                                        | Error Code                                | Mutation Rule           |
| -------------------------- | ------------------------------------------- | -------------------------------------------------------- | ----------------------------------------- | ----------------------- |
| No active game             | Mutator called before setup.                | Return canonical start-state failure.                    | `GAME_NOT_STARTED`                        | No mutation.            |
| Invalid player ID          | API receives unknown player.                | Return canonical ID failure.                             | `INVALID_PLAYER_ID`                       | No mutation.            |
| Invalid phase              | Action called in wrong phase.               | Fail safely.                                             | `INVALID_PHASE`                           | No mutation.            |
| Failed purchase            | MarketLogic rejects purchase.               | Return failure.                                          | Purchase error                            | Active state unchanged. |
| Failed attack              | CombatEngine rejects attack.                | Return failure.                                          | Combat error                              | Active state unchanged. |
| Failed Street Deal choice  | StreetDealLogic rejects choice.             | Return failure.                                          | Street Deal error                         | Active state unchanged. |
| Failed contact selection   | ContactLogic rejects selection.             | Return failure.                                          | Contact error                             | Active state unchanged. |
| Failed contract claim      | ContractLogic rejects claim.                | Return failure.                                          | Contract error                            | Active state unchanged. |
| Preview before game        | Selector called with empty state.           | Return a failed selector result.                         | `GAME_NOT_STARTED`                        | No mutation.            |
| Preview consumes active random | Selector changes active `state["random"]["step"]`. | Test failure; temporary contract-preview random is allowed. | N/A | Must be fixed. |
| AI called for human        | `run_action_for_ai("player_1")`.            | Fail safely.                                             | `INVALID_TARGET`                          | No mutation.            |
| Rebuild unavailable        | Human has no rebuild flag.                  | Fail safely.                                             | `REQUIREMENT_NOT_MET`                     | No mutation.            |
| Debug snapshot write fails | File write unavailable.                     | Return failure but gameplay remains intact.              | `REQUIREMENT_NOT_MET`                     | No gameplay mutation.   |
| Signal on failed action    | Mutator fails.                              | May emit `action_failed`; must not emit `state_changed`. | Error from result                         | No state mutation.      |

## 11. Required Source Files

Required file:

```text
res://autoload/GameStateManager.gd
```

Required owner modules called by GameStateManager:

```text
res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/game_state/WinnerResolver.gd
res://logic/economy/MarketLogic.gd
res://logic/economy/IncomeLogic.gd
res://logic/economy/PriceLogic.gd
res://logic/combat/CombatEngine.gd
res://logic/contracts/ContractLogic.gd
res://logic/street_deals/StreetDealLogic.gd
res://logic/contacts/ContactLogic.gd
res://logic/ai/AIBotController.gd
```

Recommended optional helper:

```text
res://logic/game_state/GameViewBuilder.gd
```

If `GameStateManager.gd` approaches 250 lines, move view shaping to `GameViewBuilder.gd`.

## 12. Required GUT Tests

Required test file:

```text
res://tests/unit/test_game_state_manager_api.gd
```

### 12.1. Setup Tests

Minimum tests:

* `start_new_game` succeeds with valid config;
* `generate_contract_offers` returns 3 deterministic unique IDs;
* `generate_contract_offers` does not mutate active state;
* `start_new_game` regenerates the previewed offers and rejects a contract outside them;
* `start_new_game` stores valid state;
* invalid Turf Level fails;
* invalid role fails;
* invalid contract fails;
* failed setup does not leave partial active state;
* `game_started` signal emits on success;
* `state_changed` signal emits on success.

### 12.2. Mutation Safety Tests

Minimum tests:

* `advance_phase` returns `GAME_NOT_STARTED` for empty active state;
* `advance_phase` returns `PHASE_NOT_READY` for incomplete Market, Action, and Street Deal;
* Income -> Market resolves all four players and commits once;
* a failure during any Income player or Market entry rolls back the complete transition;
* successful `advance_phase` appends canonical events in order;
* failed `advance_phase` appends no event and emits no success signal;
* failed purchase does not mutate active state;
* failed attack does not mutate active state;
* failed Street Deal choice does not mutate active state;
* failed contact selection does not mutate active state;
* failed contract claim does not mutate active state;
* failed rebuild does not mutate active state.

### 12.3. Selector Tests

Minimum tests:

* `get_state_snapshot` returns deep copy;
* mutating returned snapshot does not mutate active state;
* `get_market_view` does not mutate state;
* `get_card_price_preview` does not mutate state;
* `get_combat_preview` does not mutate state;
* `get_valid_targets` does not mutate state;
* selectors do not consume active random; contract preview uses only temporary setup random.

### 12.4. Economy API Tests

Minimum tests:

* `buy_card` delegates to MarketLogic;
* successful purchase commits state;
* failed purchase does not commit state;
* `rebuild_district_control` works only when valid;
* purchase disabled reason returns stable error code.

### 12.5. Combat API Tests

Minimum tests:

* `execute_attack` delegates to CombatEngine;
* successful attack commits state;
* failed attack does not commit state;
* `discard_war_card` removes card only on success;
* `get_valid_engine_targets` returns valid Saboteur targets.

### 12.6. Contract API Tests

Minimum tests:

* `claim_contract` applies reward once;
* `claim_contract` fails before completion;
* `claim_contract` fails after already claimed;
* failed claim does not mutate state.

### 12.7. Street Deal API Tests

Minimum tests:

* `select_street_deal` resolves valid choice;
* invalid option fails;
* insufficient Nal fails;
* failed choice does not mutate state;
* `get_debt_status` returns player debts.

### 12.8. Contact API Tests

Minimum tests:

* `select_contact` unlocks offered contact;
* selecting contact outside offer fails;
* selecting second contact fails;
* failed contact selection does not mutate state;
* `get_contact_offer` does not mutate state.

### 12.9. AI API Tests

Minimum tests:

* `run_market_for_ai` fails for human player;
* `run_action_for_ai` fails for human player;
* AI Market uses MarketLogic validation;
* AI Action uses CombatEngine validation;
* failed AI candidate does not corrupt state.

### 12.10. Signal Tests

Minimum tests:

* successful mutator emits `state_changed`;
* failed mutator does not emit `state_changed`;
* failed mutator may emit `action_failed`;
* phase change emits `phase_changed`.

### 12.11. Static Tests

Minimum tests:

* `GameStateManager.gd` is under 250 lines;
* `GameStateManager.gd` does not contain forbidden random APIs;
* `GameStateManager.gd` does not contain large rule bodies for price, combat, contracts, or AI scoring;
* UI files call GameStateManager instead of low-level mutators.

## 13. Static Scan Requirements

Static scan must fail if `GameStateManager.gd` contains:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

Static scan should flag if `GameStateManager.gd` contains suspicious gameplay implementation blocks such as:

* hardcoded card price tables;
* combat effect mutation tables;
* AI purchase score tables;
* contract condition implementations;
* Street Deal effect implementations.

Allowed:

* method forwarding;
* result commit logic;
* signal emitting;
* state snapshot access;
* high-level setup orchestration.

Static scan must fail if UI scripts mutate:

```text
GameStateManager.state
```

directly.

UI must use public API methods.

## 14. Implementation Notes For LLM Agents

When implementing `GameStateManager.gd`:

* Keep it as a facade.
* Do not paste full gameplay logic into it.
* Keep file under 250 lines.
* Use deep copies before mutating.
* Commit state only on `ok == true`.
* Never mutate active state on failed validation.
* Emit `state_changed` only after successful commits.
* Do not consume active random in selectors; contract preview may consume only temporary setup random.
* Do not use forbidden random APIs.
* Do not let UI write to `state`.
* Do not let AI bypass the same APIs or owner logic used by the human.
* Use stable error codes from `ValidationErrors.gd`.
* Add API tests before wiring final UI.

If a public API is needed but not listed here, add it to this file first and define:

* method name;
* payload;
* result shape;
* owner module;
* mutation rule;
* tests.

## 15. Acceptance Criteria

This module is complete when:

* `GameStateManager.gd` is registered as Autoload;
* active runtime state is stored in `GameStateManager.state`;
* UI-facing mutators exist for setup, purchase, combat, Street Deals, contacts, contracts, phase flow, and AI;
* UI-facing selectors exist for market, prices, combat previews, contracts, contacts, Street Deals, debts, and state snapshots;
* all mutators duplicate state before mutation;
* active state is committed only on success;
* failed validation does not mutate active state;
* selectors do not mutate state;
* selectors do not consume active random;
* `rebuild_district_control` is a dedicated API;
* `claim_contract` is a dedicated API;
* `select_contact` is a dedicated API;
* `discard_war_card` is a dedicated API;
* valid target selectors exist for combat UI;
* stable result shapes are returned;
* stable error codes are returned;
* signals are emitted only where appropriate;
* `GameStateManager.gd` does not contain gameplay mega-logic;
* `GameStateManager.gd` does not use forbidden random APIs;
* `GameStateManager.gd` stays under 250 lines;
* required GUT tests pass.

## 16. Final Rule

GameStateManager owns the state and the public API, but gameplay rules must stay in their owner logic modules.
