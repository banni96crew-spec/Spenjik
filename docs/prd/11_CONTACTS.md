# Contacts

## Document Role

This file defines only:

* Contact IDs and Contact Resource data;
* contact runtime state;
* contact ownership boundaries;
* contact unlock sources;
* contact offer generation;
* contact selection;
* maximum contact limit;
* passive contact effects;
* active contact effects;
* contact cooldown and usage tracking;
* contact hooks for Income, Economy, Street Deals, DebtLogic, and Combat;
* `black_cash`, `corrupt_clerk`, and `street_medic` implementation rules;
* contact validation rules;
* ContactLogic API expectations;
* contact-related edge cases;
* contact-related GUT tests.

This file must not redefine:

* card prices except contact-specific price modifiers;
* card effects outside contact-specific modifiers;
* market generation;
* purchase resolution;
* income resolution order;
* combat resolution;
* role definitions;
* contract completion rules;
* Street Deal option effects beyond contact offer handoff;
* debt rules beyond `street_medic` prevention hook;
* Turf Level definitions beyond contact offer count impact;
* AI profiles;
* UI behavior;
* deterministic random algorithm implementation;
* phase transition logic.

Source of truth dependencies:

* 00_INDEX.md
* 02_CORE_LOOP_AND_PHASES.md
* 03_IDS_AND_CONSTANTS.md
* 04_GAME_STATE_SCHEMA.md
* 05_CARDS_DATABASE.md
* 06_ECONOMY_AND_MARKET.md
* 07_COMBAT_SYSTEM.md
* 08_ROLES.md
* 09_CONTRACTS.md
* 10_STREET_DEALS_AND_DEBTS.md
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

The contact system gives the human player a rare helper bonus unlocked during a run.

Contacts may provide:

* passive economy modifiers;
* one-time price modifiers;
* active protection from a debt penalty.

In MVP:

* only the human player can unlock and own a contact;
* the human player may own at most 1 contact;
* contacts can be unlocked through `inside_contact` or by victory over strong AI;
* contact offers are deterministic and replay-safe;
* contact effects are explicit and must not be parsed from display text.

This module exists to make contact ownership, offer generation, and contact effects implementation-ready without forcing coding agents to invent missing logic.

## 2. Ownership Boundaries

This file owns:

* contact IDs;
* contact Resource schema;
* contact runtime schema;
* contact offer state shape;
* contact unlock source rules;
* contact offer generation;
* contact selection;
* maximum contact limit;
* contact activation validation;
* passive contact effect hooks;
* `street_medic` active effect behavior;
* contact-related price modifier consumption;
* contact-related tests.

This file references:

* `06_ECONOMY_AND_MARKET.md` for Income, Brothel bonus, price calculation, and purchase success flow;
* `07_COMBAT_SYSTEM.md` for strong AI victory trigger events;
* `10_STREET_DEALS_AND_DEBTS.md` for `inside_contact` handoff and debt penalty hook;
* `12_TURF_LEVELS.md` for Turf Level 7 contact offer count;
* `14_DETERMINISTIC_RANDOM.md` for deterministic contact offer selection;
* `16_GAME_STATE_MANAGER_API.md` for public facade methods;
* `17_UI_UX_SPEC.md` for contact selection UI state.

This file does not own:

* Street Deal option resolution;
* debt creation or repayment;
* debt penalty base rules;
* combat attack resolution;
* purchase validation outside contact modifiers;
* phase transitions;
* AI decisions;
* UI rendering.

## 3. Core Terms

| Term                  | Meaning                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| Contact               | A special helper unlocked during the run.                                                               |
| Passive Contact       | Contact whose effect works automatically after unlock.                                                  |
| Active Contact        | Contact that requires activation or a hook-triggered payload.                                           |
| Contact Offer         | Deterministic set of available contact IDs shown to the human player.                                   |
| Unlock Source         | Event that creates a contact offer.                                                                     |
| Owned Contact         | Contact selected and stored in the human player’s contact state.                                        |
| Pending Contact Offer | Global state waiting for human contact selection.                                                       |
| Contact Limit         | Maximum number of contacts a player may own. MVP limit is 1.                                            |
| Cooldown              | Optional delay before an active contact can be used again. MVP contacts do not use recurring cooldowns. |
| Used This Round       | Round-level usage tracking for active effects if needed.                                                |
| Emergency Protection  | One-time `street_medic` protection from VP loss caused by debt penalty.                                 |

## 4. Runtime State

### 4.1. Contact State Ownership

Contacts use split ownership:

* `player["contacts"]` stores owned contacts, cooldowns, and per-round usage;
* `state["contacts"]` stores only global pending contact offer state.

This fixes the duplicated ownership ambiguity.

### 4.2. GameState Contact Fields

Required shape:

```gdscript id="viu8ow"
state["contacts"] = {
	"pending_offer": {}
}
```

Recommended empty state:

```gdscript id="9uc8tg"
static func create_empty_global_state() -> Dictionary:
	return {
		"pending_offer": {}
	}
```

`state["contacts"]` must not store owned contacts.

### 4.3. Player Contact Fields

Required shape:

```gdscript id="r39apv"
player["contacts"] = {
	"unlocked": [],
	"cooldowns": {},
	"used_this_round": []
}
```

Recommended function:

```gdscript id="dau1ah"
static func create_empty_state() -> Dictionary:
	return {
		"unlocked": [],
		"cooldowns": {},
		"used_this_round": []
	}
```

Field meaning:

| Field             | Type          | Meaning                                              |
| ----------------- | ------------- | ---------------------------------------------------- |
| `unlocked`        | Array[String] | Contact IDs owned by this player. MVP max size is 1. |
| `cooldowns`       | Dictionary    | Contact cooldowns by contact ID.                     |
| `used_this_round` | Array[String] | Contacts used during current round.                  |

### 4.4. Pending Contact Offer State

Required shape:

```gdscript id="jcb3vo"
state["contacts"]["pending_offer"] = {
	"player_id": "player_1",
	"source": "inside_contact",
	"contact_offer_ids": [],
	"resolved": false,
	"created_round": 8
}
```

Allowed `source` values:

| Source              | Meaning                                                                     |
| ------------------- | --------------------------------------------------------------------------- |
| `inside_contact`    | Offer created by Street Deal `inside_contact` Option A.                     |
| `strong_ai_victory` | Offer created when human defeats strong AI by destroying a Status building. |

### 4.5. Player Role Flag Used By Contacts

`street_medic` uses:

```gdscript id="bnrmz0"
player["role_flags"]["used_emergency_protection"]
```

Meaning:

* `false`: `street_medic` protection has not been consumed;
* `true`: `street_medic` protection was already used and cannot be used again.

This flag is stored in `role_flags` for compatibility with PRD v2.4, but its gameplay owner is this contact module.

### 4.6. ContactDefinition Resource Schema

Required Resource:

```gdscript id="lgde2l"
class_name ContactDefinition
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export_enum("passive", "active") var effect_kind: String
@export var cooldown_rounds: int = 0
@export var effect_type: String
```

Gameplay logic must not parse `description`.

### 4.7. Contact IDs

Canonical constants are owned by `03_IDS_AND_CONSTANTS.md`:

```gdscript id="5w78lq"
class_name ContactIds

const BLACK_CASH := "black_cash"
const CORRUPT_CLERK := "corrupt_clerk"
const STREET_MEDIC := "street_medic"

const ALL := [
	BLACK_CASH,
	CORRUPT_CLERK,
	STREET_MEDIC
]
```

`ContactIds.gd` is required. Raw alternative contact IDs and locally duplicated contact ID lists are forbidden.

### 4.8. Required Validation Errors

Canonical contact errors are owned by `ValidationErrors.gd`:

```gdscript id="xa6z7v"
const CONTACT_LOCKED := "CONTACT_LOCKED"
const CONTACT_ON_COOLDOWN := "CONTACT_ON_COOLDOWN"
```

```gdscript id="hvcovz"
const INVALID_CONTACT_ID := "INVALID_CONTACT_ID"
const CONTACT_LIMIT_REACHED := "CONTACT_LIMIT_REACHED"
const CONTACT_OFFER_UNAVAILABLE := "CONTACT_OFFER_UNAVAILABLE"
const CONTACT_ALREADY_UNLOCKED := "CONTACT_ALREADY_UNLOCKED"
const CONTACT_ALREADY_USED := "CONTACT_ALREADY_USED"
```

Fallback and ad-hoc contact error strings are forbidden.

## 5. Rules

### 5.1. Contact List

Contacts must not be changed.

| ID              | Type    | Unlock                                     | Effect                                                     |
| --------------- | ------- | ------------------------------------------ | ---------------------------------------------------------- |
| `black_cash`    | Passive | Victory over strong AI or `inside_contact` | Brothel double bonus gives +6 Nal instead of +5.           |
| `corrupt_clerk` | Passive | Victory over strong AI or `inside_contact` | First Status card after receiving contact is cheaper by 1. |
| `street_medic`  | Active  | Victory over strong AI or `inside_contact` | Once per game prevents loss of 1 VP from debt penalty.     |

### 5.2. MVP Ownership Rule

In MVP:

* only the human player can unlock contacts;
* AI players cannot unlock contacts;
* AI players cannot receive contact offers;
* AI players cannot activate contacts.

### 5.3. Maximum Contact Rule

A player may own at most:

```text id="pebp2u"
1 contact
```

If the human already has one contact:

* no new contact offer should be generated;
* existing contact cannot be replaced;
* contact selection must fail if attempted.

Replacing contacts is out of scope.

### 5.4. Unlock Sources

Contacts may be unlocked through:

| Source              |                    Offer Count | Notes                                               |
| ------------------- | -----------------------------: | --------------------------------------------------- |
| `inside_contact`    |                              2 | Created by Street Deal `inside_contact` Option A.   |
| `strong_ai_victory` | 3 normally, 2 at Turf Level 7+ | Created when human defeats strong AI during combat. |

### 5.5. Strong AI Victory Rule

In MVP, victory over strong AI occurs when the human player successfully and without block destroys any Status building owned by the strong AI.

Valid destroyed Status buildings:

* `stash`;
* `workshop`;
* `district_control`.

Valid combat sources:

* successful `bruiser destroy_stash`;
* successful `cleaner destroy_workshop`;
* successful `federal_raid destroy_district`.

Requirements:

* attacker is `GameIds.PLAYER_HUMAN`;
* target is AI;
* target has `is_strong_ai == true`;
* attack is successful;
* attack is not blocked;
* destroyed card is a Status building.

A blocked attack does not count.

A failed validation does not count.

A Nal steal does not count.

Destroying an Engine card with `saboteur` does not count.

### 5.6. Contact Offer Count Rule

Offer count by source:

| Source              | Turf Level | Offer Count |
| ------------------- | ---------: | ----------: |
| `inside_contact`    |        any |           2 |
| `strong_ai_victory` |        0-6 |           3 |
| `strong_ai_victory` |       7-10 |           2 |

If fewer contacts are available than the canonical source count, return `CONTACT_OFFER_UNAVAILABLE`; partial offers are forbidden.

If zero contacts are available, no pending offer is created.

### 5.7. Available Contact Rule

A contact is available for offer only if:

* contact ID is valid;
* player does not already own it;
* player has fewer than 1 unlocked contact;
* contact is not already in the pending offer.

Because MVP max contact count is 1, if the player already owns any contact, available contacts list is empty.

### 5.8. Contact Offer Generation Rule

Contact offers must be deterministic.

Generation must:

1. Validate player is human.
2. Validate source.
3. Validate contact limit.
4. Build available contact list.
5. Pick exactly the requested count through `SeededPicker.gd`.
6. Update `state["random"]` according to `14_DETERMINISTIC_RANDOM.md`.
7. Store pending offer in `state["contacts"]["pending_offer"]`.
8. Return structured result.

Forbidden random APIs must not be used.

### 5.9. Contact Selection Rule

The human may choose exactly 1 contact from the pending offer.

Selection must:

* validate pending offer exists;
* validate `player_id` matches pending offer;
* validate contact ID is in `contact_offer_ids`;
* validate player does not already own a contact;
* add selected contact to `player["contacts"]["unlocked"]`;
* initialize cooldown if required;
* apply immediate setup for passive contact if needed;
* mark pending offer as resolved;
* clear pending offer after resolution.

### 5.10. Passive Contact Rule

Passive contacts work automatically after unlock.

Passive contacts:

* `black_cash`;
* `corrupt_clerk`.

Passive contacts must not require `activate_contact()`.

### 5.11. Active Contact Rule

Active contacts require activation or an explicit hook.

Active contacts:

* `street_medic`.

`street_medic` is used through the debt penalty hook:

```gdscript id="jik4rc"
ContactLogic.before_debt_penalty_applied(state, player_id, debt)
```

It does not need manual pre-activation through UI in MVP because the only defined use case is debt penalty prevention.

If future active contacts are added, they must use `GameStateManager.activate_contact(payload)`.

### 5.12. Round Reset Rule

At the start of each round:

```gdscript id="sp0jjh"
player["contacts"]["used_this_round"] = []
```

`street_medic` one-time use does not reset because it is tracked by:

```gdscript id="arfir6"
player["role_flags"]["used_emergency_protection"]
```

Pending offers persist across round and phase changes until `select_contact` resolves them or `start_new_game` replaces the complete match state.

## 6. Contact Effects

### 6.1. `black_cash`

ID:

```text id="eus8b5"
black_cash
```

Type:

```text id="frj6au"
passive
```

Effect:

```text id="2xu1lx"
Brothel double bonus gives +6 Nal instead of +5.
```

Implementation rule:

* IncomeLogic must check whether human has `black_cash`.
* If player has `black_cash` and Brothel roll is a double, Brothel bonus is `+6`.
* Otherwise Brothel bonus is `+5`.

Required helper:

```gdscript id="2bm4hm"
static func has_contact(player: Dictionary, contact_id: String) -> bool:
	return player["contacts"]["unlocked"].has(contact_id)
```

Income ownership:

```text id="p4p1gj"
06_ECONOMY_AND_MARKET.md
```

### 6.2. `corrupt_clerk`

ID:

```text id="ga98a5"
corrupt_clerk
```

Type:

```text id="0b6tok"
passive
```

Effect:

```text id="yzzq3x"
First Status card after receiving contact is cheaper by 1.
```

Status cards:

* `stash`;
* `workshop`;
* `district_control`.

Implementation rule:

* effect applies to the first successful Status card purchase after unlock;
* failed purchase does not consume the effect;
* effect is once per run;
* final price must be clamped by `06_ECONOMY_AND_MARKET.md`.

Required tracking flag:

```gdscript id="jyfub9"
player["role_flags"]["used_one_time_contact_bonus"]
```

Modifier shape:

```gdscript id="nkehwg"
{
	"source": "contact",
	"contact_id": "corrupt_clerk",
	"flag": "used_one_time_contact_bonus",
	"type": "NEXT_STATUS_CARD_PRICE_DELTA",
	"delta": -1,
	"applies_to_card_type": "status",
	"consume_on_success": true,
	"description": "Corrupt Clerk first Status card discount"
}
```

If `used_one_time_contact_bonus == true`, the discount no longer applies.

### 6.3. `street_medic`

ID:

```text id="mgdjwc"
street_medic
```

Type:

```text id="czzy7x"
active
```

Effect:

```text id="7em61s"
Once per game prevents loss of 1 VP from debt penalty.
```

Implementation rule:

* applies only to VP loss caused by debt penalty;
* does not prevent Nal loss;
* does not prevent debt repayment state changes;
* does not prevent penalty log entry;
* can be used once per run;
* tracked by `player["role_flags"]["used_emergency_protection"]`.

When debt penalty would apply:

```gdscript id="cavg86"
if player has street_medic
and player["role_flags"]["used_emergency_protection"] == false
and penalty would reduce VP:
	prevent up to 1 VP loss
	player["role_flags"]["used_emergency_protection"] = true
```

If penalty includes `lose_all_nal`, Nal loss still applies.

If player has 0 VP and penalty would reduce VP by 1:

* no VP is actually lost due to clamp;
* `street_medic` should not be consumed because there was no effective VP loss to prevent.

## 7. Validation Rules

### 7.1. Contact ID Validation

Valid contact IDs:

```text id="uzfgnc"
black_cash
corrupt_clerk
street_medic
```

Unknown contact ID returns:

```gdscript id="kf71vy"
ValidationErrors.INVALID_CONTACT_ID
```

### 7.2. Contact Offer Validation

A contact offer can be generated only if:

| Condition                     | Error                       |
| ----------------------------- | --------------------------- |
| Player is not human           | `INVALID_TARGET`            |
| Unknown source                | `CONTACT_OFFER_UNAVAILABLE` |
| Player already owns a contact | `CONTACT_LIMIT_REACHED`     |
| No available contacts         | `CONTACT_OFFER_UNAVAILABLE` |
| Requested offer count <= 0    | `CONTACT_OFFER_UNAVAILABLE` |

Failed offer generation must not mutate state.

### 7.3. Contact Selection Validation

A contact can be selected only if:

| Condition                              | Error                       |
| -------------------------------------- | --------------------------- |
| No pending offer exists                | `CONTACT_OFFER_UNAVAILABLE` |
| Pending offer has `resolved == true`   | `INVALID_STATE`             |
| Player ID does not match pending offer | `INVALID_TARGET`            |
| Contact ID not in pending offer        | `CONTACT_LOCKED`            |
| Contact ID invalid                     | `INVALID_CONTACT_ID`        |
| Player already owns a contact          | `CONTACT_LIMIT_REACHED`     |
| Contact already unlocked               | `CONTACT_ALREADY_UNLOCKED`  |

Failed selection must not mutate state.

### 7.4. Contact Activation Validation

For `street_medic` debt hook:

| Condition                           | Error / Behavior                  |
| ----------------------------------- | --------------------------------- |
| Player does not have `street_medic` | No prevention.                    |
| `used_emergency_protection == true` | No prevention.                    |
| Penalty has no VP loss              | No prevention.                    |
| Effective VP loss after clamp is 0  | No prevention and do not consume. |
| Effective VP loss is at least 1     | Prevent 1 VP loss and consume.    |

For explicit `activate_contact(payload)`:

| Condition                 | Error                                           |
| ------------------------- | ----------------------------------------------- |
| Contact not unlocked      | `CONTACT_LOCKED`                                |
| Contact on cooldown       | `CONTACT_ON_COOLDOWN`                           |
| Contact already used once | `CONTACT_ALREADY_USED`                       |
| Contact is passive        | `REQUIREMENT_NOT_MET`                           |

### 7.5. Mutation Rule

Failed validation must not mutate:

* `player["contacts"]`;
* `state["contacts"]`;
* `player["role_flags"]`;
* `player["temporary_modifiers"]`;
* `state["random"]`;
* `state["combat_log"]`.

Preview and selector functions must not mutate state.

## 8. Resolution / Processing Flow

### 8.1. `inside_contact` Offer Flow

When `10_STREET_DEALS_AND_DEBTS.md` resolves `inside_contact` Option A:

1. StreetDealLogic validates the option.
2. StreetDealLogic calls:

```gdscript id="hmpv7x"
ContactLogic.generate_contact_offer(state, GameIds.PLAYER_HUMAN, 2, "inside_contact")
```

3. ContactLogic validates contact limit and availability.
4. ContactLogic deterministically picks exactly 2 contacts.
5. ContactLogic writes `state["contacts"]["pending_offer"]`.
6. ContactLogic appends `LogEventTypes.CONTACT_OFFERED`.
7. StreetDealLogic stores no duplicate pending-contact state.
8. UI later calls `GameStateManager.select_contact(payload)`.

### 8.2. Strong AI Victory Offer Flow

After CombatEngine resolves a successful attack:

1. CombatEngine builds attack event.
2. CombatEngine calls:

```gdscript id="8mta0d"
ContactLogic.on_attack_resolved(state, event)
```

3. ContactLogic checks strong AI victory conditions.
4. If conditions are met and human has no contact:

   * offer count is 3 at Turf Level 0-6;
   * offer count is 2 at Turf Level 7-10.
5. ContactLogic generates pending offer.
6. ContactLogic appends `LogEventTypes.CONTACT_OFFERED`.
7. ContactLogic returns structured result.

Strong AI victory event shape:

```gdscript id="m8y7ql"
{
	"attacker_id": "player_1",
	"target_id": "ai_1",
	"target_is_ai": true,
	"target_is_strong_ai": true,
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"blocked": false,
	"success": true,
	"destroyed_status_card_id": "stash"
}
```

### 8.3. Contact Selection Flow

When the human selects a contact:

1. Normalize payload.
2. Validate pending offer exists.
3. Validate player ID.
4. Validate contact ID.
5. Validate contact ID is in offer.
6. Validate contact limit.
7. If validation fails, return failed result and do not mutate state.
8. Add selected contact to `player["contacts"]["unlocked"]`.
9. Initialize cooldown if needed.
10. Apply immediate passive setup if needed.
11. Add the selected contact and clear pending offer in the same transaction; committed state never retains `resolved == true`.
12. Append `LogEventTypes.CONTACT_UNLOCKED`.
13. Validate state.
14. Return structured result.

### 8.4. Price Modifier Flow for `corrupt_clerk`

During price preview and purchase validation:

1. PriceLogic asks ContactLogic for contact price modifiers.
2. ContactLogic checks:

   * player has `corrupt_clerk`;
   * card type is `status`;
   * `used_one_time_contact_bonus == false`.
3. ContactLogic returns `-1` modifier.
4. PriceLogic applies modifier in normal modifier order.
5. If purchase succeeds, MarketLogic calls:

```gdscript id="pbbh7m"
ContactLogic.consume_contact_flags_after_purchase(state, player_id, card_id, applied_modifiers)
```

6. ContactLogic sets:

```gdscript id="9yw69s"
player["role_flags"]["used_one_time_contact_bonus"] = true
```

Failed purchase must not consume the flag.

### 8.5. Debt Penalty Hook Flow for `street_medic`

Before DebtLogic applies VP loss:

1. DebtLogic builds penalty event.
2. DebtLogic calls:

```gdscript id="ad9yvy"
ContactLogic.before_debt_penalty_applied(state, player_id, debt)
```

3. ContactLogic checks `street_medic`.
4. If prevention applies:

   * reduce VP loss by 1;
   * set `used_emergency_protection = true`;
   * return prevention result.
5. DebtLogic applies remaining penalty parts.
6. DebtLogic logs debt penalty and medic prevention.

### 8.6. Round Reset Flow

At round start:

```gdscript id="wfqi04"
ContactLogic.reset_round_contact_usage(player)
```

This clears:

```gdscript id="ny8kd9"
player["contacts"]["used_this_round"]
```

It must not clear:

* `unlocked`;
* `cooldowns`;
* `used_emergency_protection`;
* `used_one_time_contact_bonus`;
* pending offers.

### 8.7. Contact Logging

ContactLogic uses only:

* `CONTACT_OFFERED` when a pending offer is committed;
* `CONTACT_UNLOCKED` when selection commits and clears the pending offer;
* `CONTACT_ACTIVATED` when a contact use or one-time contact effect is consumed, including `corrupt_clerk` or `street_medic`.

Passive checks that do not consume or mutate contact state append no contact event.

## 9. API Expectations

### 9.1. ContactLogic.gd

Required file:

```text id="ifkzi2"
res://logic/contacts/ContactLogic.gd
```

Required API:

```gdscript id="3lhiyd"
class_name ContactLogic

static func create_empty_state() -> Dictionary:
	return {}

static func create_empty_global_state() -> Dictionary:
	return {}

static func has_contact(player: Dictionary, contact_id: String) -> bool:
	return false

static func is_valid_contact_id(contact_id: String) -> bool:
	return false

static func get_available_contact_ids(state: Dictionary, player_id: String) -> Array[String]:
	return []

static func generate_contact_offer(state: Dictionary, player_id: String, count: int, source: String) -> Dictionary:
	return {}

static func validate_contact_selection(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func select_contact(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func get_contact_price_modifiers(state: Dictionary, player: Dictionary, card_def: CardDefinition) -> Array[Dictionary]:
	return []

static func consume_contact_flags_after_purchase(state: Dictionary, player_id: String, card_id: String, applied_modifiers: Array[Dictionary]) -> Dictionary:
	return {}

static func before_debt_penalty_applied(state: Dictionary, player_id: String, debt: Dictionary) -> Dictionary:
	return {}

static func on_attack_resolved(state: Dictionary, event: Dictionary) -> Dictionary:
	return {}

static func reset_round_contact_usage(player: Dictionary) -> Dictionary:
	return player
```

### 9.2. GameStateManager.gd API

Required existing API:

```gdscript id="h26urb"
func activate_contact(payload: Dictionary) -> Dictionary:
	return {}
```

Recommended additions to `16_GAME_STATE_MANAGER_API.md`:

```gdscript id="to2yyr"
func select_contact(payload: Dictionary) -> Dictionary:
	return {}

func get_contact_offer(player_id: String) -> Dictionary:
	return {}

func get_contact_state(player_id: String) -> Dictionary:
	return {}
```

### 9.3. Contact Offer Result Shape

```gdscript id="668otm"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"source": "inside_contact",
	"contact_offer_ids": [
		"black_cash",
		"street_medic"
	],
	"random": {},
	"state": {}
}
```

Failed result:

```gdscript id="2s1ekb"
{
	"ok": false,
	"error": ValidationErrors.CONTACT_LIMIT_REACHED,
	"player_id": "player_1",
	"source": "inside_contact",
	"contact_offer_ids": [],
	"state": {}
}
```

### 9.4. Contact Selection Payload

```gdscript id="8yc8mz"
{
	"player_id": "player_1",
	"contact_id": "black_cash"
}
```

### 9.5. Contact Selection Result Shape

```gdscript id="v0kjla"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"contact_id": "black_cash",
	"source": "inside_contact",
	"state": {},
	"log_entries": []
}
```

Failed selection:

```gdscript id="3mj5q0"
{
	"ok": false,
	"error": ValidationErrors.CONTACT_LOCKED,
	"player_id": "player_1",
	"contact_id": "black_cash",
	"state": {}
}
```

### 9.6. Debt Penalty Prevention Result Shape

```gdscript id="5cwmsb"
{
	"ok": true,
	"prevented": true,
	"contact_id": "street_medic",
	"vp_loss_prevented": 1,
	"consume_contact": true,
	"state": {}
}
```

No prevention result:

```gdscript id="kkijc1"
{
	"ok": true,
	"prevented": false,
	"contact_id": "",
	"vp_loss_prevented": 0,
	"consume_contact": false,
	"state": {}
}
```

### 9.7. Contact Price Modifier Shape

```gdscript id="4evup9"
{
	"source": "contact",
	"contact_id": "corrupt_clerk",
	"flag": "used_one_time_contact_bonus",
	"type": "NEXT_STATUS_CARD_PRICE_DELTA",
	"delta": -1,
	"applies_to_card_type": "status",
	"consume_on_success": true,
	"description": "Corrupt Clerk first Status card discount"
}
```

## 10. Edge Cases

| Edge Case                                          | Condition                                          | Expected Behavior                                         | Error Code                               | Mutation Rule                             |
| -------------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------- | ----------------------------------------- |
| Invalid contact ID                                 | Contact ID not in valid list.                      | Reject selection or activation.                           | `INVALID_CONTACT_ID`                     | No mutation.                              |
| AI receives offer                                  | Player is AI.                                      | Reject offer generation.                                  | `INVALID_TARGET`                         | No mutation.                              |
| Human already has contact                          | `unlocked.size() >= 1`.                            | No new offer; selection fails.                            | `CONTACT_LIMIT_REACHED`                  | No mutation.                              |
| No available contacts                              | All contacts unavailable or contact limit reached. | No pending offer.                                         | `CONTACT_OFFER_UNAVAILABLE`              | No mutation.                              |
| Fewer contacts than requested                      | Available count is less than the canonical source count. | Reject offer generation; partial offers are forbidden. | `CONTACT_OFFER_UNAVAILABLE`              | No mutation.                              |
| Pending offer already exists                       | `state["contacts"]["pending_offer"]` unresolved.   | Reject new offer generation; do not overwrite it.         | `CONTACT_OFFER_UNAVAILABLE`              | No mutation.                              |
| Contact not in offer                               | Player selects valid contact not offered.          | Selection fails.                                          | `CONTACT_LOCKED`                         | No mutation.                              |
| Offer already resolved                             | Pending offer has `resolved == true`.              | State validation fails.                                   | `INVALID_STATE`                          | No mutation.                              |
| `black_cash` without Brothel                       | Player has contact but no Brothel.                 | No income effect until Brothel double occurs.             | `OK`                                     | No mutation by ContactLogic.              |
| `black_cash` with non-double roll                  | Income roll is not double.                         | No Brothel bonus.                                         | `OK`                                     | No contact mutation.                      |
| `black_cash` with double                           | Brothel double triggers.                           | Bonus is +6 instead of +5.                                | `OK`                                     | Income mutates Nal.                       |
| `corrupt_clerk` failed Status purchase             | Purchase validation fails.                         | Discount is not consumed.                                 | Purchase error                           | No contact flag mutation.                 |
| `corrupt_clerk` successful Status purchase         | First Status purchase after unlock succeeds.       | Apply -1 and consume bonus.                               | `OK`                                     | Set `used_one_time_contact_bonus = true`. |
| `corrupt_clerk` second Status purchase             | Bonus already used.                                | No discount.                                              | `OK`                                     | No flag mutation.                         |
| `street_medic` no debt penalty                     | No VP loss from debt penalty.                      | No prevention.                                            | `OK`                                     | Do not consume.                           |
| `street_medic` already used                        | `used_emergency_protection == true`.               | Debt hook returns success with no prevention.             | `OK`                                     | No mutation.                              |
| `street_medic` penalty at 0 VP                     | VP loss would clamp to 0 anyway.                   | Do not consume.                                           | `OK`                                     | No contact flag mutation.                 |
| `street_medic` with lose-all-Nal penalty           | Debt penalty has Nal loss and VP loss.             | Prevent 1 VP loss only; Nal loss still applies.           | `OK`                                     | Consume medic if VP loss prevented.       |
| Strong AI attack blocked                           | Human attack against strong AI is blocked.         | No contact offer.                                         | `OK`                                     | No contact mutation.                      |
| Strong AI Engine destruction                       | Human destroys strong AI Engine card.              | No contact offer.                                         | `OK`                                     | No contact mutation.                      |
| Strong AI Status destruction with existing contact | Human already owns contact.                        | Combat contact hook returns success with no new offer.    | `OK`                                     | No mutation.                              |
| Turf Level 7 strong AI victory                     | Human defeats strong AI at Turf Level 7+.          | Offer 2 contacts.                                         | `OK`                                     | Pending offer mutation.                   |
| Inside Contact offer                               | Street Deal requests 2 contacts.                   | Offer 2 contacts if available.                            | `OK`                                     | Pending offer mutation.                   |

## 11. Required Source Files

Required files:

```text id="tes6rk"
res://logic/contacts/ContactLogic.gd
res://data/resources/contacts/ContactDefinition.gd
res://data/resources/contacts/black_cash.tres
res://data/resources/contacts/corrupt_clerk.tres
res://data/resources/contacts/street_medic.tres
```

Recommended constants file:

```text id="yc8jy8"
res://data/ids/ContactIds.gd
```

Related files:

```text id="wayefl"
res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/economy/IncomeLogic.gd
res://logic/economy/PriceLogic.gd
res://logic/economy/MarketLogic.gd
res://logic/combat/CombatEngine.gd
res://logic/street_deals/StreetDealLogic.gd
res://logic/street_deals/DebtLogic.gd
res://logic/random/SeededPicker.gd
res://autoload/GameStateManager.gd
```

Recommended optional helper files:

```text id="5eyjvz"
res://logic/contacts/ContactOfferLogic.gd
res://logic/contacts/ContactEffectResolver.gd
res://logic/contacts/ContactValidator.gd
res://logic/contacts/ContactLogBuilder.gd
```

Each source file must stay under:

```text id="ossrp5"
250 lines
```

If `ContactLogic.gd` approaches the limit, split offer generation, validation, and effect hooks.

## 12. Required GUT Tests

Recommended test file:

```text id="9875ck"
res://tests/unit/test_contact_logic.gd
```

### 12.1. Contact Definition Tests

Minimum tests:

* all 3 contact IDs exist;
* every Contact Resource has valid ID;
* `black_cash` is passive;
* `corrupt_clerk` is passive;
* `street_medic` is active;
* no duplicate contact IDs exist.

### 12.2. Contact State Tests

Minimum tests:

* `create_empty_state()` returns `unlocked`, `cooldowns`, and `used_this_round`;
* `create_empty_global_state()` returns `pending_offer`;
* owned contacts are stored in `player["contacts"]`;
* pending offers are stored in `state["contacts"]`;
* `state["contacts"]` does not own unlocked contacts.

### 12.3. Contact Offer Tests

Minimum tests:

* `inside_contact` requests 2 contacts;
* strong AI victory requests 3 contacts below Turf Level 7;
* strong AI victory requests 2 contacts at Turf Level 7+;
* offer contains only valid contact IDs;
* offer contains no duplicates;
* offer excludes already unlocked contacts;
* offer fails if human already owns a contact;
* offer generation fails if fewer contacts than the canonical source count are available;
* same seed and random state produce same offer;
* offer generation updates random state according to `14_DETERMINISTIC_RANDOM.md`;
* no forbidden random APIs are used.

### 12.4. Contact Selection Tests

Minimum tests:

* human can select contact from pending offer;
* selected contact is added to `player["contacts"]["unlocked"]`;
* pending offer is cleared or marked resolved after selection;
* selecting contact outside offer fails;
* selecting invalid contact fails;
* selecting second contact fails;
* AI cannot select contact;
* failed selection does not mutate state.

### 12.5. `black_cash` Tests

Minimum tests:

* without `black_cash`, Brothel double gives +5;
* with `black_cash`, Brothel double gives +6;
* `black_cash` gives no bonus without Brothel;
* `black_cash` gives no bonus without double;
* effect is passive and does not require activation.

### 12.6. `corrupt_clerk` Tests

Minimum tests:

* first Status purchase after unlock gets -1 price;
* failed Status purchase does not consume discount;
* successful Status purchase consumes discount;
* second Status purchase does not get discount;
* non-Status purchase does not consume discount;
* final price is clamped by PriceLogic;
* modifier appears in price preview.

### 12.7. `street_medic` Tests

Minimum tests:

* locked `street_medic` does not prevent debt penalty;
* unlocked `street_medic` prevents 1 VP loss from debt penalty;
* `street_medic` does not prevent Nal loss;
* `street_medic` is consumed after preventing VP loss;
* `street_medic` cannot prevent VP loss twice;
* `street_medic` is not consumed if effective VP loss is 0;
* `street_medic` works through DebtLogic hook.

### 12.8. Strong AI Victory Tests

Minimum tests:

* successful human `destroy_stash` against strong AI creates contact offer;
* successful human `destroy_workshop` against strong AI creates contact offer;
* successful human `destroy_district` against strong AI creates contact offer;
* blocked attack against strong AI does not create offer;
* Nal steal against strong AI does not create offer;
* Engine destruction against strong AI does not create offer;
* destroying Status building of non-strong AI does not create offer;
* AI attacking strong AI does not create offer;
* no offer is created if human already owns a contact.

### 12.9. Integration Tests

Minimum tests:

* `inside_contact` Street Deal Option A creates pending contact offer through ContactLogic;
* Contact selection after `inside_contact` unlocks exactly one contact;
* IncomeLogic uses `black_cash` for Brothel bonus;
* PriceLogic uses `corrupt_clerk` for Status discount;
* MarketLogic consumes `corrupt_clerk` only after successful purchase;
* DebtLogic calls `street_medic` prevention hook before VP penalty;
* CombatEngine calls ContactLogic after successful Status destruction against strong AI;
* no contact logic exists in UI files;
* no forbidden random APIs exist in contact logic files.

## 13. Static Scan Requirements

Static scan must fail if contact logic contains:

```text id="u3ho4i"
randf(
randi(
randomize(
RandomNumberGenerator
```

Allowed deterministic random owners:

* `SeededRandom.gd`
* `SeededPicker.gd`

Static scan must fail if contact implementation:

* reads or writes UI nodes;
* lives inside UI scene scripts;
* parses `description` for gameplay behavior;
* hardcodes card prices;
* resolves purchases directly;
* resolves combat directly;
* creates debts directly;
* completes contracts directly;
* advances phases directly;
* gives contacts to AI players in MVP;
* allows more than 1 owned contact in MVP;
* replaces an existing contact.

Allowed dependencies:

* `GameIds`
* `ContactIds`
* `ValidationErrors`
* `SeededPicker`
* `ContactDefinition`
* `PriceLogic` only through modifier integration
* `DebtLogic` only through hook integration
* `GameStateValidator`

## 14. Implementation Notes For LLM Agents

When implementing contacts:

* Do not change contact IDs.
* Do not change contact effects.
* Do not add new contacts.
* Do not remove contacts.
* Store owned contacts in `player["contacts"]`.
* Store pending offers in `state["contacts"]`.
* Do not use `state["contacts"]` as owned contact source of truth.
* Maximum 1 contact per player in MVP.
* Do not allow contact replacement.
* Do not give contacts to AI in MVP.
* `inside_contact` creates a 2-contact offer.
* strong AI victory creates a 3-contact offer below Turf Level 7.
* strong AI victory creates a 2-contact offer at Turf Level 7+.
* Strong AI victory means successful unblocked destruction of a strong AI Status building by the human.
* `black_cash` is passive.
* `corrupt_clerk` is passive and consumed only after successful Status purchase.
* `street_medic` prevents only 1 VP loss from debt penalty once per run.
* `street_medic` does not prevent Nal loss.
* Failed validation must not mutate state.
* Preview/selectors must not mutate state.
* Do not parse Resource descriptions as logic.
* Do not write contact logic in UI.
* Keep every source file under 250 lines.
* Add or update GUT tests with implementation.

If a future contact rule is unclear, do not invent behavior. Add it to:

```text id="50yf66"
21_OPEN_QUESTIONS_AND_FIXES.md
```

## 15. Acceptance Criteria

This module is complete when:

* all 3 Contact Resources exist;
* contact IDs are centralized or consistently validated;
* owned contacts are stored in `player["contacts"]`;
* pending offers are stored in `state["contacts"]`;
* human can own at most 1 contact;
* contacts cannot be replaced in MVP;
* AI players cannot unlock contacts in MVP;
* `inside_contact` creates a deterministic 2-contact offer;
* strong AI victory creates deterministic contact offers;
* Turf Level 7 changes strong AI victory offer count from 3 to 2;
* contact selection unlocks exactly one offered contact;
* failed contact selection does not mutate state;
* `black_cash` changes Brothel double bonus from +5 to +6;
* `corrupt_clerk` discounts the first successful Status purchase after unlock by 1;
* failed Status purchases do not consume `corrupt_clerk`;
* `street_medic` prevents 1 VP loss from debt penalty once;
* `street_medic` does not prevent Nal loss;
* contact offer generation uses deterministic random only;
* contact logic does not use UI nodes;
* contact logic does not use forbidden random APIs;
* all required GUT tests pass.

## 16. Final Rule

Contacts are rare human-owned helpers; they must never become hidden AI bonuses, extra contracts, or UI-owned gameplay logic.
