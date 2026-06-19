# UI / UX Spec

## Document Role

This file defines only:

* desktop UI structure;
* screen and panel ownership;
* UI state rendering rules;
* player interaction flows;
* UI payload shapes sent to `GameStateManager.gd`;
* disabled-state display rules;
* preview display rules;
* phase-specific UI behavior;
* setup UX;
* market UX;
* action/combat UX;
* Street Deal UX;
* contact UX;
* contract UX;
* game log UX;
* AI turn visibility;
* UI scene file requirements;
* UI static scan requirements;
* UI-related GUT tests.

This file must not redefine:

* card prices;
* card effects;
* purchase validation;
* purchase resolution;
* income resolution;
* combat resolution;
* role effects;
* contract conditions;
* contact effects;
* Street Deal effects;
* debt rules;
* Turf Level effects;
* AI scoring;
* deterministic random;
* phase transition rules;
* runtime state schemas.

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

The UI / UX layer lets the human player understand the current game state and send valid commands to `GameStateManager.gd`.

The UI exists to:

* display player boards;
* display market cards and prices;
* show disabled reasons;
* collect setup choices;
* collect purchase choices;
* collect combat targets and modes;
* collect Street Deal choices;
* collect contact choices;
* allow contract claiming;
* show AI activity summaries;
* show game logs;
* show final results.

The UI must never own gameplay logic. It must render state, request previews, and call public API methods only.

## 2. Ownership Boundaries

This file owns:

* screen structure;
* panel responsibilities;
* UI interaction flow;
* UI payload construction;
* disabled-state presentation;
* selector usage;
* display refresh rules;
* UI scene/script file list;
* UI-specific tests and static scans.

This file references:

* `16_GAME_STATE_MANAGER_API.md` for all public UI-facing methods;
* `04_GAME_STATE_SCHEMA.md` for state view fields;
* `03_IDS_AND_CONSTANTS.md` for stable IDs and validation errors;
* owner gameplay modules for rule meaning.

This file does not own:

* whether an action is valid;
* how much a card costs;
* what a card does;
* how combat resolves;
* how AI chooses;
* how phases advance;
* how random works;
* how contracts complete;
* how contacts activate;
* how debts process.

## 3. Core Terms

| Term            | Meaning                                                                  |
| --------------- | ------------------------------------------------------------------------ |
| Screen          | Full-screen UI state such as Setup, Game, or Game Over.                  |
| Panel           | Reusable UI area inside a screen.                                        |
| Widget          | Small reusable display component.                                        |
| View Model      | UI-ready Dictionary returned by a selector.                              |
| Disabled Reason | Stable validation error code explaining why an action cannot be used.    |
| Preview         | Read-only result showing what would happen if an action were executed.   |
| Command Payload | Dictionary sent from UI to `GameStateManager.gd`.                        |
| Refresh         | Re-rendering UI from current state after a successful or failed command. |
| Selection State | Temporary UI-only state such as selected card, target, or mode.          |

## 4. Runtime State

### 4.1. UI Runtime State Rule

UI may store temporary presentation state only.

Allowed UI-local state:

* selected card ID;
* selected target player ID;
* selected attack mode;
* selected engine target card ID;
* selected Street Deal option;
* hovered card ID;
* currently expanded log entry;
* selected setup role;
* selected setup Turf Level;
* selected setup contract.

Forbidden UI-local gameplay state:

* player Nal;
* player VP;
* player hand contents;
* market contents;
* contract progress;
* contact ownership;
* debt state;
* random step;
* phase state;
* combat results.

Gameplay state must come from:

```text
GameStateManager.get_state_snapshot()
GameStateManager.get_view()
module-specific selectors
```

### 4.2. UI Selection State Shape

Recommended `ActionPanel.gd` local state:

```gdscript
var selected_card_id: String = ""
var selected_target_id: String = ""
var selected_attack_mode: String = ""
var selected_engine_target_card_id: String = ""
var selected_modifiers: Array[String] = []
```

This state is UI-only and must be cleared after:

* successful attack;
* failed attack that changes phase or hand state;
* manual cancel;
* phase change.

### 4.3. UI Refresh Rule

After every public mutator call:

1. UI must inspect the result.
2. If `ok == true`, UI must refresh from `GameStateManager.get_view()` or relevant selectors.
3. If `ok == false`, UI must show `error` and refresh from current state.
4. UI must not manually patch displayed values from guessed mutation.

### 4.4. Signals

UI should listen to:

```gdscript
GameStateManager.state_changed
GameStateManager.action_failed
GameStateManager.phase_changed
GameStateManager.game_started
GameStateManager.game_ended
```

Selectors may also be called manually after button clicks.

## 5. Rules

### 5.1. UI Must Not Own Gameplay Logic

UI must not:

* calculate final prices;
* validate purchases;
* mutate Nal or VP;
* place cards;
* resolve combat;
* apply defense effects;
* create debts;
* claim contracts directly;
* unlock contacts directly;
* run AI logic directly;
* advance phase by writing state fields;
* consume random;
* parse Resource descriptions as gameplay rules.

UI must call `GameStateManager.gd`.

### 5.2. Desktop Layout Rule

The game targets desktop first.

Required desktop baseline:

* landscape layout;
* mouse input;
* readable text at 1080p;
* no mobile-first assumptions;
* no required drag-and-drop for core actions;
* button-based actions must exist for every core command.

Recommended minimum window:

```text
1280x720
```

Recommended target layout:

```text
1920x1080
```

### 5.3. Stable Disabled Reason Rule

Every disabled gameplay action must expose a stable error code.

UI must display user-readable text mapped from validation error codes.

UI must not infer disabled reasons by duplicating gameplay validation.

Required pattern:

```gdscript
var reason := GameStateManager.get_purchase_disabled_reason(player_id, card_id)
button.disabled = reason != ValidationErrors.OK
disabled_label.text = ErrorTextMap.to_text(reason)
```

### 5.4. Preview Before Commit Rule

For complex actions, UI should show previews before commit.

Required previews:

* card price preview;
* purchase disabled reason;
* combat preview;
* valid combat targets;
* valid Saboteur engine targets;
* contract claim disabled reason;
* Street Deal disabled reason;
* contact disabled reason.

Previews must not mutate state.

### 5.5. Error Text Rule

UI may map error codes to readable text.

Example mapping:

| Error Code                          | Suggested UI Text                      |
| ----------------------------------- | -------------------------------------- |
| `OK`                                | `Available`                            |
| `INVALID_PHASE`                     | `Not available in this phase.`         |
| `NOT_ENOUGH_NAL`                    | `Not enough Nal.`                      |
| `CARD_NOT_AVAILABLE_IN_MARKET`      | `Card is not in the market.`           |
| `CARD_ALREADY_PURCHASED_THIS_ROUND` | `Already bought this card this round.` |
| `REQUIREMENT_NOT_MET`               | `Requirement not met.`                 |
| `CARD_LIMIT_REACHED`                | `Limit reached.`                       |
| `INVALID_TARGET`                    | `Invalid target.`                      |
| `INVALID_ACTION_CARD`               | `Invalid action card.`                 |
| `ATTACK_MODE_REQUIRED`              | `Choose attack mode.`                  |
| `INVALID_ATTACK_MODE`               | `Invalid attack mode.`                 |
| `STREET_DEAL_CHOICE_UNAVAILABLE`    | `This choice is unavailable.`          |
| `ACTIVE_DEBT_EXISTS`                | `Active debt already exists.`          |
| `CONTACT_LOCKED`                    | `Contact is not available.`            |
| `CONTACT_ON_COOLDOWN`               | `Contact is on cooldown.`              |

Text can change later. Error codes must stay stable.

### 5.6. No Hidden Auto-Actions Rule

UI must not automatically execute gameplay actions except explicit phase-safe flows owned by GameStateManager.

Allowed:

* refresh view after signal;
* open/close panels;
* clear selection after phase change;
* request preview on hover or selection.

Forbidden:

* auto-buying a card after hover;
* auto-claiming a contract;
* auto-selecting a contact;
* auto-resolving Street Deal choice;
* auto-playing War cards;
* auto-running AI outside phase controller/debug button flow.

### 5.7. AI Visibility Rule

AI actions may be automated, but the UI should show what happened.

Minimum display:

* AI purchases summary;
* AI attacks summary;
* blocked attacks;
* Street Deal AI side effects;
* debt repayment/penalty logs;
* final winner.

UI does not need to animate every AI decision in MVP.

### 5.8. File Length Rule

Every UI script must stay under:

```text
250 lines
```

If a UI script grows too large:

* split panels;
* split widgets;
* move view formatting to helper classes;
* do not move gameplay logic into UI helpers.

## 6. Validation Rules

### 6.1. UI Command Validation

UI must validate only input completeness before sending payloads.

Allowed UI validation:

* required target selected;
* required mode selected;
* required card selected;
* option A/B selected;
* seed text not empty in setup.

Forbidden UI validation:

* checking if player can afford card;
* checking if card is in market;
* checking if attack is blocked;
* checking if contract is completed;
* checking if contact limit is reached.

Gameplay validation belongs to owner modules.

### 6.2. Payload Completeness Validation

UI must not send incomplete payloads when a selection is obviously missing.

Examples:

* `bruiser` requires selected mode;
* `cleaner` requires selected mode;
* `federal_raid` requires `destroy_district`;
* `saboteur` requires selected `engine_target_card_id`;
* Street Deal requires option `option_a` or `option_b`;
* contact selection requires `contact_id`.

If payload is incomplete, UI should show local helper text and not call mutator.

### 6.3. Failed Mutator Behavior

If a mutator returns `ok == false`:

* show the error code mapped to readable text;
* refresh from state;
* do not manually undo anything;
* do not retry automatically;
* keep selection only if still meaningful.

### 6.4. Selector Failure Behavior

If a selector returns failure:

* show safe empty state;
* disable related buttons;
* show readable error message;
* do not crash.

### 6.5. Static UI Validation

Static scan must fail if UI scripts:

* mutate gameplay state directly;
* call forbidden random APIs for gameplay;
* contain hardcoded card prices;
* contain combat effect resolution;
* contain AI scoring;
* contain contract completion logic;
* exceed 250 lines.

## 7. Resolution / Processing Flow

### 7.1. Setup Flow

Setup UI must collect:

1. game seed;
2. Turf Level;
3. role;
4. contract.

Recommended setup flow:

1. User enters or accepts seed.
2. User selects Turf Level.
3. User selects role.
4. UI calls `generate_contract_offers(config)` with the selected seed, Turf Level, and role.
5. UI displays the 3 returned deterministic contract offers.
6. User selects one offered contract.
7. UI calls:

```gdscript
GameStateManager.start_new_game({
	"game_seed": seed,
	"turf_level": turf_level,
	"selected_role_id": role_id,
	"selected_contract_id": contract_id
})
```

8. On success, show Game Screen.
9. On failure, show setup error.

### 7.2. Main Game Refresh Flow

After `state_changed`:

1. GameScreen gets current view.
2. PlayerBoard panels render all players.
3. MarketPanel renders market if relevant.
4. ActionPanel renders hand and valid action controls if relevant.
5. ContractPanel renders contract state.
6. ContactPanel renders contact state or pending offer.
7. StreetDealPanel renders current deal if relevant.
8. GameLogPanel appends or refreshes logs.
9. Phase header updates current phase and round.

### 7.3. Market Purchase Flow

When user selects a market card:

1. UI calls `get_card_price_preview`.
2. UI calls `get_purchase_disabled_reason`.
3. UI displays final price, modifiers, and disabled reason.
4. If enabled, user clicks Buy.
5. UI calls:

```gdscript
GameStateManager.buy_card(GameIds.PLAYER_HUMAN, card_id)
```

6. UI refreshes from result.

UI must not subtract Nal or place cards.

### 7.3.1. Income Continue Flow

When the committed phase is Income:

1. UI displays the current round and an explicit Resolve Income / Continue control.
2. UI calls `GameStateManager.advance_phase()`.
3. GameStateManager resolves all four Income turns and Market entry atomically through owner logic.
4. On success, UI renders Market from committed state.
5. On failure, UI displays the canonical error and remains on the unchanged Income state.

UI must not call IncomeLogic directly or apply partial Income results.

### 7.4. End Market Flow

When user clicks End Market:

1. UI calls:

```gdscript
GameStateManager.end_market_for_player(GameIds.PLAYER_HUMAN)
```

2. UI refreshes.
3. GameStateManager orchestration runs AI Market through logic and calls `advance_phase` only after all players are ready.

UI must not set `ready_for_action`.

### 7.5. Combat Flow

When user selects a War card:

1. UI displays valid target list from `get_valid_targets`.
2. If card needs mode, UI shows mode selector.
3. If card is `saboteur`, UI shows engine target selector from `get_valid_engine_targets`.
4. UI builds payload.
5. UI calls `get_combat_preview`.
6. UI displays preview:

   * target;
   * mode;
   * expected block;
   * selected engine target;
   * estimated Nal steal/gain;
   * expected cards consumed.
7. User clicks Execute.
8. UI calls:

```gdscript
GameStateManager.execute_attack(payload)
```

9. UI refreshes from result.

### 7.6. War Card Discard Flow

When user chooses to discard a War card:

1. UI confirms discard.
2. UI calls:

```gdscript
GameStateManager.discard_war_card(GameIds.PLAYER_HUMAN, card_id)
```

3. UI refreshes.

UI must not remove the card directly.

### 7.7. End Action Flow

When user clicks End Action:

1. UI calls:

```gdscript
GameStateManager.end_action_for_player(GameIds.PLAYER_HUMAN)
```

2. UI refreshes.
3. GameStateManager orchestration runs AI actions through logic and calls `advance_phase` only after all players are done.

UI must not set `action_done`.

### 7.8. Street Deal Flow

When Street Deal phase is active:

1. UI calls `get_street_deal_view`.
2. UI displays current deal title, description, Option A, and Option B.
3. For each option, UI calls or receives disabled reason.
4. User selects option.
5. UI calls:

```gdscript
GameStateManager.select_street_deal({
	"player_id": GameIds.PLAYER_HUMAN,
	"deal_id": deal_id,
	"option_id": option_id
})
```

6. UI refreshes.

If the result creates a pending contact offer, ContactPanel must show it.

### 7.9. Contact Selection Flow

When pending contact offer exists:

1. UI calls `get_contact_offer`.
2. UI displays offered contact cards.
3. User selects one contact.
4. UI calls:

```gdscript
GameStateManager.select_contact({
	"player_id": GameIds.PLAYER_HUMAN,
	"contact_id": contact_id
})
```

5. UI refreshes.

UI must not unlock contacts directly.

### 7.10. Contract Claim Flow

When contract is completed:

1. UI calls `get_contract_claim_disabled_reason`.
2. If enabled, show Claim Reward button.
3. User clicks Claim.
4. UI calls:

```gdscript
GameStateManager.claim_contract(GameIds.PLAYER_HUMAN, contract_id)
```

5. UI refreshes.

UI must not add rewards directly.

### 7.11. Game Over Flow

When `game_ended` signal fires:

1. UI opens GameOverScreen.
2. UI displays:

   * winner;
   * final VP;
   * final Nal;
   * contract result;
   * Turf Level;
   * strong AI;
   * selected role;
   * selected contract;
   * summary log.
3. UI offers:

   * New Game;
   * Exit to Main Menu.

No rematch persistence is required in MVP.

## 8. API Expectations

### 8.1. Required UI Calls to GameStateManager

Setup:

```gdscript
start_new_game(config: Dictionary) -> Dictionary
get_available_roles() -> Dictionary
get_available_turf_levels() -> Dictionary
generate_contract_offers(config: Dictionary) -> Dictionary
```

State:

```gdscript
get_view() -> Dictionary
get_state_snapshot() -> Dictionary
get_current_phase() -> String
get_round() -> int
advance_phase() -> Dictionary
```

Market:

```gdscript
get_market_view(player_id: String) -> Dictionary
get_card_price_preview(player_id: String, card_id: String) -> Dictionary
get_purchase_disabled_reason(player_id: String, card_id: String) -> String
buy_card(player_id: String, card_id: String) -> Dictionary
end_market_for_player(player_id: String) -> Dictionary
rebuild_district_control(player_id: String) -> Dictionary
```

Combat:

```gdscript
get_valid_targets(action_payload: Dictionary) -> Dictionary
get_valid_engine_targets(attacker_id: String, target_id: String) -> Dictionary
get_combat_preview(payload: Dictionary) -> Dictionary
get_action_disabled_reason(action_payload: Dictionary) -> String
execute_attack(payload: Dictionary) -> Dictionary
discard_war_card(player_id: String, card_id: String) -> Dictionary
end_action_for_player(player_id: String) -> Dictionary
```

Street Deals:

```gdscript
get_street_deal_view(player_id: String) -> Dictionary
get_street_deal_disabled_reason(payload: Dictionary) -> String
select_street_deal(payload: Dictionary) -> Dictionary
get_debt_status(player_id: String) -> Dictionary
```

Contacts:

```gdscript
get_contact_offer(player_id: String) -> Dictionary
get_contact_state(player_id: String) -> Dictionary
get_contact_disabled_reason(payload: Dictionary) -> String
select_contact(payload: Dictionary) -> Dictionary
activate_contact(payload: Dictionary) -> Dictionary
```

Contracts:

```gdscript
get_contract_state(player_id: String) -> Dictionary
get_contract_claim_disabled_reason(player_id: String, contract_id: String) -> String
claim_contract(player_id: String, contract_id: String) -> Dictionary
```

AI debug/dev:

```gdscript
run_market_for_ai(player_id: String) -> Dictionary
run_action_for_ai(player_id: String) -> Dictionary
```

### 8.2. Required View Model Shape

Recommended `get_view()` shape:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"view": {
		"round": 1,
		"current_phase": PhaseIds.MARKET,
		"active_action_player_id": "",
		"human_player_id": GameIds.PLAYER_HUMAN,
		"players": [],
		"market": {},
		"contract": {},
		"contacts": {},
		"street_deals": {},
		"debts": {},
		"logs": [],
		"game_result": {}
	}
}
```

UI may use module-specific selectors for richer views.

### 8.3. Required Combat Payload Shape

```gdscript
{
	"attacker_id": GameIds.PLAYER_HUMAN,
	"target_id": "ai_1",
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"modifiers": [],
	"engine_target_card_id": ""
}
```

UI must include:

* `mode` for `bruiser`, `cleaner`, and `federal_raid`;
* `engine_target_card_id` for `saboteur`;
* `insider` in `modifiers` only when user selected it and card is `thug`.

### 8.4. Required Street Deal Payload Shape

```gdscript
{
	"player_id": GameIds.PLAYER_HUMAN,
	"deal_id": "dirty_tip",
	"option_id": "option_a"
}
```

### 8.5. Required Contact Payload Shape

```gdscript
{
	"player_id": GameIds.PLAYER_HUMAN,
	"contact_id": "black_cash"
}
```

## 9. Edge Cases

| Edge Case                              | Condition                                                                 | Expected Behavior                                 | Error Code                      | Mutation Rule          |
| -------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------- | ------------------------------- | ---------------------- |
| No active game                         | GameScreen opens before setup.                                            | Show setup screen or empty state.                 | `REQUIREMENT_NOT_MET`           | No mutation.           |
| Selector fails                         | View selector returns `ok == false`.                                      | Show safe fallback UI.                            | Selector error                  | No mutation.           |
| Purchase disabled                      | Card cannot be bought.                                                    | Disable Buy button and show reason.               | Owner error code                | No mutation.           |
| Price changes after purchase           | State changed after preview.                                              | Refresh preview before next action.               | `OK`                            | UI state only.         |
| Combat payload incomplete              | Required mode or target missing.                                          | Show local helper text; do not call mutator.      | N/A                             | No mutation.           |
| Combat rejected                        | CombatEngine returns failure.                                             | Show error and refresh state.                     | Combat error                    | No UI manual rollback. |
| Saboteur target missing                | User selected Saboteur but no engine target.                              | Disable Execute button.                           | N/A                             | No mutation.           |
| Insider invalid                        | User tries Insider with non-Thug card.                                    | UI should not offer this modifier.                | `INVALID_ACTION_CARD` if called | No mutation.           |
| Contract already claimed               | Claim button clicked again after refresh delay.                           | Show disabled/error.                              | `CONTRACT_ALREADY_CLAIMED`      | No mutation.           |
| Contact limit reached                  | Pending offer exists but player already owns contact due to state change. | Selection fails and UI refreshes.                 | `CONTACT_LIMIT_REACHED`         | No mutation.           |
| Street Deal insufficient Nal           | Paid option unaffordable.                                                 | Disable option and show reason.                   | `NOT_ENOUGH_NAL`                | No mutation.           |
| AI action running                      | AI is resolving turn.                                                     | Disable human command buttons.                    | N/A                             | UI-only lock.          |
| Phase changed while panel open         | Current panel no longer applies.                                          | Clear local selection and show new phase UI.      | N/A                             | UI-only mutation.      |
| Debug AI button clicked in wrong phase | Debug command fails.                                                      | Show error.                                       | `INVALID_PHASE`                 | No mutation.           |
| Window too small                       | Layout cannot fit all panels.                                             | Panels may scroll; core buttons remain reachable. | N/A                             | UI-only.               |

## 10. Required Source Files

Required main scenes:

```text
res://scenes/main/Main.tscn
res://scenes/main/Main.gd
res://scenes/game/GameRoot.tscn
res://scenes/game/GameRoot.gd
```

Required screens:

```text
res://scenes/ui/screens/SetupScreen.tscn
res://scenes/ui/screens/SetupScreen.gd
res://scenes/ui/screens/GameScreen.tscn
res://scenes/ui/screens/GameScreen.gd
res://scenes/ui/screens/GameOverScreen.tscn
res://scenes/ui/screens/GameOverScreen.gd
```

Required panels:

```text
res://scenes/ui/panels/PlayerBoard.tscn
res://scenes/ui/panels/PlayerBoard.gd
res://scenes/ui/panels/MarketPanel.tscn
res://scenes/ui/panels/MarketPanel.gd
res://scenes/ui/panels/ActionPanel.tscn
res://scenes/ui/panels/ActionPanel.gd
res://scenes/ui/panels/StreetDealPanel.tscn
res://scenes/ui/panels/StreetDealPanel.gd
res://scenes/ui/panels/ContactPanel.tscn
res://scenes/ui/panels/ContactPanel.gd
res://scenes/ui/panels/ContractPanel.tscn
res://scenes/ui/panels/ContractPanel.gd
res://scenes/ui/panels/GameLogPanel.tscn
res://scenes/ui/panels/GameLogPanel.gd
```

Required widgets:

```text
res://scenes/ui/widgets/CardView.tscn
res://scenes/ui/widgets/CardView.gd
res://scenes/ui/widgets/DefenseBadges.tscn
res://scenes/ui/widgets/DefenseBadges.gd
res://scenes/ui/widgets/NalVpDisplay.tscn
res://scenes/ui/widgets/NalVpDisplay.gd
res://scenes/ui/widgets/DisabledReasonLabel.tscn
res://scenes/ui/widgets/DisabledReasonLabel.gd
```

Recommended helpers:

```text
res://scenes/ui/helpers/ErrorTextMap.gd
res://scenes/ui/helpers/UIViewFormatters.gd
```

Helpers must not contain gameplay logic.

## 11. Required GUT Tests

Recommended test file:

```text
res://tests/static/test_ui_static_boundaries.gd
```

Recommended scene test file:

```text
res://tests/unit/test_ui_payloads.gd
```

### 11.1. Static Boundary Tests

Minimum tests:

* UI scripts do not mutate `GameStateManager.state`;
* UI scripts do not contain direct Nal mutation;
* UI scripts do not contain direct VP mutation;
* UI scripts do not append to hand directly;
* UI scripts do not append to combat log directly;
* UI scripts do not call forbidden gameplay random APIs;
* UI scripts do not hardcode card price tables;
* UI scripts do not implement combat effect tables;
* UI scripts stay under 250 lines.

### 11.2. Setup UI Tests

Minimum tests:

* SetupScreen builds valid config shape;
* empty seed disables Start or returns readable error;
* selected role ID is passed unchanged;
* selected Turf Level is passed as int;
* selected contract ID is passed unchanged;
* Start button calls `GameStateManager.start_new_game`.

### 11.3. Market UI Tests

Minimum tests:

* MarketPanel calls `get_market_view`;
* CardView displays price preview;
* disabled Buy button uses `get_purchase_disabled_reason`;
* Buy button calls `buy_card`;
* End Market button calls `end_market_for_player`;
* MarketPanel does not subtract Nal directly.

### 11.4. Action UI Tests

Minimum tests:

* ActionPanel builds valid attack payload;
* `bruiser` shows mode selector;
* `cleaner` shows mode selector;
* `federal_raid` uses `destroy_district`;
* `saboteur` shows engine target selector;
* `insider` appears only as valid `thug` modifier option;
* Execute button calls `execute_attack`;
* Discard button calls `discard_war_card`;
* End Action button calls `end_action_for_player`;
* ActionPanel does not remove cards from hand directly.

### 11.5. Street Deal UI Tests

Minimum tests:

* StreetDealPanel calls `get_street_deal_view`;
* Option buttons call `get_street_deal_disabled_reason`;
* selecting Option A sends payload with `"option_a"`;
* selecting Option B sends payload with `"option_b"`;
* option click calls `select_street_deal`;
* panel does not apply Street Deal effects directly.

### 11.6. Contact UI Tests

Minimum tests:

* ContactPanel calls `get_contact_offer`;
* selecting offered contact calls `select_contact`;
* contact outside offer cannot be selected through UI;
* ContactPanel does not unlock contact directly.

### 11.7. Contract UI Tests

Minimum tests:

* ContractPanel calls `get_contract_state`;
* Claim button uses `get_contract_claim_disabled_reason`;
* Claim button calls `claim_contract`;
* ContractPanel does not apply rewards directly.

### 11.8. Game Log UI Tests

Minimum tests:

* GameLogPanel renders log entries from state/view;
* GameLogPanel does not create gameplay logs;
* GameLogPanel handles empty logs safely.

### 11.9. Signal Tests

Minimum tests:

* UI refreshes on `state_changed`;
* UI shows errors on `action_failed`;
* UI changes visible panel on `phase_changed`;
* GameOverScreen opens on `game_ended`.

## 12. Static Scan Requirements

Static scan must fail if UI scripts contain:

```text
GameStateManager.state[
["nal"] +=
["nal"] -=
["vp"] +=
["vp"] -=
["hand"].append
["hand"].erase
["purchased_this_round"].append
["combat_log"].append
randf(
randi(
randomize(
RandomNumberGenerator
```

Static scan must flag suspicious direct logic calls from UI:

```text
MarketLogic.buy_card
CombatEngine.resolve_attack
StreetDealLogic.select_street_deal
ContactLogic.select_contact
ContractLogic.claim_contract
AIBotController.run_action_for_ai
PriceLogic.calculate
```

Allowed UI calls:

* `GameStateManager.*`;
* pure formatting helpers;
* view rendering;
* selector calls through GameStateManager.

Static scan must fail if UI `.gd` files exceed:

```text
250 lines
```

## 13. Implementation Notes For LLM Agents

When implementing UI:

* Build logic modules and selectors first.
* Keep UI scripts thin.
* Do not implement gameplay rules in UI.
* Do not duplicate validation logic.
* Use disabled reason selectors.
* Use preview selectors.
* Use stable error codes.
* Build payloads exactly as specified.
* Refresh UI from state after every mutator.
* Do not patch UI by guessing result mutations.
* Do not consume random in UI gameplay flows.
* Do not parse Resource descriptions as rules.
* Keep every UI script under 250 lines.
* Split large panels into widgets.
* Use `GameStateManager.gd` for all gameplay mutators.

If UI needs data that no selector exposes, add a selector to:

```text
16_GAME_STATE_MANAGER_API.md
```

Do not read internal logic module state directly.

## 14. Acceptance Criteria

This module is complete when:

* SetupScreen can start a valid game through GameStateManager;
* GameScreen renders current round and phase;
* PlayerBoard renders all 4 players;
* MarketPanel renders available cards, prices, modifiers, and disabled reasons;
* MarketPanel buys cards only through GameStateManager;
* ActionPanel builds valid combat payloads;
* ActionPanel supports target, mode, modifier, and Saboteur engine-target selection;
* ActionPanel executes and discards War cards only through GameStateManager;
* StreetDealPanel displays Option A/B and sends valid payloads;
* ContactPanel displays pending offers and selects contacts through GameStateManager;
* ContractPanel displays progress and claims rewards through GameStateManager;
* GameLogPanel displays logs without creating gameplay events;
* GameOverScreen displays final result;
* UI refreshes after `state_changed`;
* UI displays errors after failed actions;
* UI does not mutate gameplay state directly;
* UI does not contain gameplay random;
* UI scripts stay under 250 lines;
* required UI static tests pass.

## 15. Final Rule

UI may ask, preview, display, and send commands; it must never decide or mutate gameplay rules.
