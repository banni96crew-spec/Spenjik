# Street Deals and Debts

## Document Role

This file defines only:

* Street Deal timing;
* Street Deal IDs and Resource data;
* Street Deal generation;
* Street Deal offer state;
* human Street Deal selection;
* Street Deal option validation;
* Street Deal option effects;
* debt creation;
* debt storage;
* debt repayment;
* debt penalties;
* debt-related contact hooks;
* Turf Level 8 Street Deal payment modifier;
* Street Deal and debt API expectations;
* Street Deal and debt edge cases;
* Street Deal and debt GUT tests.

This file must not redefine:

* core phase transition logic outside Street Deal entry and exit conditions;
* card prices outside Street Deal temporary price modifiers;
* card purchase validation;
* combat resolution;
* role definitions;
* contract completion rules;
* contact definitions beyond contact-selection hooks;
* Turf Level definitions beyond applying Turf Level 8 to Street Deal payments;
* AI profiles;
* UI behavior;
* deterministic random algorithm implementation.

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

Street Deals are deterministic special events offered after the Action phase in rounds 4, 8, and 12.

They give the human player a meaningful A/B choice that can:

* grant or cost Nal;
* grant VP;
* create debt;
* add War cards to hand;
* create temporary price modifiers;
* trigger contact selection;
* affect AI players through explicitly defined effects.

Debts are delayed obligations created by `loan_shark`. They are processed during Income after income gain and Cops upkeep.

This module exists so Street Deals and debts can be implemented without guessing:

* who chooses;
* where state is stored;
* how effects resolve;
* when debt is repaid;
* how penalties work;
* how random AI targeting remains deterministic.

## 2. Ownership Boundaries

This file owns:

* Street Deal event generation;
* Street Deal availability validation;
* Street Deal A/B option validation;
* Street Deal option effect resolution;
* `loan_shark` debt creation;
* player-level debt processing;
* Street Deal state ownership;
* debt state ownership;
* temporary modifiers created by Street Deals;
* deterministic AI target selection for Street Deal effects;
* logging for Street Deals and debt processing.

This file references:

* `02_CORE_LOOP_AND_PHASES.md` for entering and exiting Street Deal phase;
* `06_ECONOMY_AND_MARKET.md` for Nal, VP, card hand placement, price modifiers, and Income hook order;
* `09_CONTRACTS.md` for contract update hooks after Street Deal effects;
* `11_CONTACTS.md` for contact offer and unlock handling from `inside_contact`;
* `12_TURF_LEVELS.md` for Turf Level 8 payment increase;
* `14_DETERMINISTIC_RANDOM.md` for deterministic Street Deal and AI target selection;
* `16_GAME_STATE_MANAGER_API.md` for public facade methods.

This file does not own:

* phase advancement after Street Deal resolution;
* visual presentation of A/B options;
* actual contact choice implementation;
* card purchase logic;
* AI purchase logic;
* combat logic;
* contract condition definitions;
* random algorithm internals.

## 3. Core Terms

| Term                | Meaning                                                                            |
| ------------------- | ---------------------------------------------------------------------------------- |
| Street Deal         | A special event offered after Action in rounds 4, 8, and 12.                       |
| Current Deal        | The Street Deal generated for the current Street Deal phase.                       |
| Option A / Option B | The two choices available on the current Street Deal.                              |
| Human Choice        | In MVP, only the human chooses an option.                                          |
| AI Side Effect      | A defined Street Deal effect that mutates an AI player without giving AI a choice. |
| Used Deal           | A Street Deal ID already resolved during this run.                                 |
| Debt                | A delayed Nal payment obligation created by `loan_shark`.                          |
| Active Debt         | A debt with `repaid == false`.                                                     |
| Amount Due          | Nal amount required for automatic debt repayment.                                  |
| Deadline Round      | Last round before overdue penalty starts.                                          |
| Penalty             | Effect applied when an active debt remains unpaid after its deadline.              |
| Payment             | Direct upfront Nal cost paid by the human when selecting a Street Deal option.     |
| Temporary Modifier  | One-shot price modifier created by a Street Deal.                                  |

## 4. Runtime State

### 4.1. GameState Fields

Street Deals use these `GameState` fields:

| Field                    | Type              | Owner               | Usage                                                           |
| ------------------------ | ----------------- | ------------------- | --------------------------------------------------------------- |
| `state["round"]`         | int               | GamePhaseController | Determines Street Deal timing and min-round rules.              |
| `state["current_phase"]` | String            | GamePhaseController | Must be `PhaseIds.STREET_DEAL` for selection.                   |
| `state["players"]`       | Array[Dictionary] | GameStateFactory    | Human receives choices; AI may receive explicit side effects.   |
| `state["street_deals"]`  | Dictionary        | StreetDealLogic     | Global Street Deal offer/event state.                           |
| `state["random"]`        | Dictionary        | SeededRandom        | Used for deterministic deal generation and random AI targeting. |
| `state["combat_log"]`    | Array[Dictionary] | Multiple systems    | Receives Street Deal and debt logs.                             |

### 4.2. Global StreetDealState

Street Deal event state is globally owned by:

```gdscript id="2r0v6w"
state["street_deals"]
```

Required shape:

```gdscript id="yzury4"
static func create_empty_state() -> Dictionary:
	return {
		"offered_this_round": false,
		"current_deal_id": "",
		"used_deal_ids": [],
		"choices_by_player": {},
		"option_availability": {}
	}
```

Field meaning:

| Field                   | Type          | Meaning                                                         |
| ----------------------- | ------------- | --------------------------------------------------------------- |
| `offered_this_round`    | bool          | Whether a Street Deal was generated this Street Deal phase.     |
| `current_deal_id`       | String        | Current offered Street Deal ID, or empty string.                |
| `used_deal_ids`         | Array[String] | Street Deals already resolved this run.                         |
| `choices_by_player`     | Dictionary    | Stores resolved option by player ID. MVP uses only `player_1`.  |
| `option_availability`   | Dictionary[String, String] | Canonical option ID -> `ValidationErrors` code; `OK` means available. |

The earlier PRD shape included `active_debts` inside global `StreetDealState`. This module fixes ownership:

* global `state["street_deals"]` owns offers, used deals, current deal, and choices;
* player debt state owns debts.

### 4.3. Player Debt State

Debts are player-level state because debt belongs to a specific player.

Required field in `PlayerState`:

```gdscript id="gk61fx"
player["debts"] = []
```

The canonical player field from `04_GAME_STATE_SCHEMA.md` is:

```gdscript id="0j7z8q"
"debts": [],
```

### 4.4. DebtState

Required shape:

```gdscript id="6ej4oc"
static func create_debt(
	id: String,
	amount_due: int,
	deadline_round: int,
	penalty: Dictionary,
	created_round: int
) -> Dictionary:
	return {
		"id": id,
		"source": "loan_shark",
		"amount_due": amount_due,
		"deadline_round": deadline_round,
		"penalty": penalty,
		"repaid": false,
		"created_round": created_round,
		"repaid_round": 0,
		"penalty_applied_round": 0
	}
```

Required additional runtime fields:

* `created_round`;
* `repaid_round`;
* `penalty_applied_round`.

These fields make debt logs and tests deterministic.

### 4.5. Temporary Modifier State

Street Deals may add temporary modifiers to:

```gdscript id="ug20vb"
player["temporary_modifiers"]
```

Required modifier shape:

```gdscript id="vgobvh"
{
	"id": "cheap_protection_player_1_round_4",
	"type": ModifierTypes.NEXT_DEFENSE_CARD_PRICE_DELTA,
	"source": StreetDealIds.CHEAP_PROTECTION,
	"owner_player_id": GameIds.PLAYER_HUMAN,
	"affected_card_id": "",
	"affected_card_type": CardTypes.DEFENSE,
	"delta": -2,
	"multiplier": 1.0,
	"min_value": 1,
	"expires_at": "next_purchase",
	"consumed": false
}
```

Supported Street Deal modifier types:

| Type                            | Meaning                                |
| ------------------------------- | -------------------------------------- |
| `ModifierTypes.NEXT_DEFENSE_CARD_PRICE_DELTA` | Applies to next Defense card purchase. |
| `ModifierTypes.NEXT_WAR_CARD_PRICE_DELTA`     | Applies to next War card purchase.     |

Price application is owned by `06_ECONOMY_AND_MARKET.md`.

### 4.6. Pending Contact Offer State

`inside_contact` Option A delegates contact offer creation to `ContactLogic`.

Canonical state location:

```gdscript id="ad8cnt"
state["contacts"]["pending_offer"] = {
	"player_id": "player_1",
	"source": "inside_contact",
	"contact_offer_ids": [],
	"resolved": false,
	"created_round": 8
}
```

Contact offer generation and contact selection rules are owned by `11_CONTACTS.md`.

StreetDealLogic must not store a duplicate contact offer under `state["street_deals"]`.

## 5. Rules

### 5.1. Street Deal Timing

Street Deals occur only after Action phase in these rounds:

```text id="dy51ki"
4
8
12
```

Street Deal phase is entered only if Action phase for that round is complete.

Phase transition ownership:

```text id="t5bwdi"
02_CORE_LOOP_AND_PHASES.md
```

### 5.2. Participation Rule

In MVP:

* the human player chooses the Street Deal option;
* AI players do not choose Street Deal options;
* some Street Deal effects may explicitly affect AI players.

This means:

* `choices_by_player` normally contains only `GameIds.PLAYER_HUMAN`;
* AI Street Deal choice logic is out of scope;
* AI side effects must still be deterministic and tested.

### 5.3. Street Deal Generation Rule

When entering Street Deal phase:

1. Generate one current Street Deal.
2. Deal must satisfy `min_round`.
3. Deal must not be in `used_deal_ids`.
4. `loan_shark` must not be generated if the human has an active debt.
5. Selection must use deterministic random through `SeededPicker.gd`.
6. Forbidden random APIs must not be used.
7. Store selected ID in `state["street_deals"]["current_deal_id"]`.
8. Set `offered_this_round = true`.

If no eligible Street Deal exists:

* `current_deal_id` must be `""`;
* generation returns `STREET_DEAL_CHOICE_UNAVAILABLE`;
* the enclosing `advance_phase` transaction is discarded;
* do not append an event when no state change occurs.

### 5.4. Used Deal Rule

After the human resolves a Street Deal option:

```gdscript id="n2lpjx"
state["street_deals"]["used_deal_ids"].append(current_deal_id)
```

A used Street Deal must not be generated again in the same run.

### 5.5. Selection Rule

The human may choose exactly one option for the current Street Deal:

```text id="vltwm4"
option_a
option_b
```

After a successful choice:

* `choices_by_player["player_1"]` stores selected option;
* option effects resolve immediately unless the effect creates a pending contact selection;
* current deal is marked used;
* failed validation must not mutate state.

### 5.6. Active Debt Rule

If the human has any active debt:

```gdscript id="iypo4u"
debt["repaid"] == false
```

then:

* `loan_shark` is not eligible for generation;
* other Street Deals remain available.

Active debt does not block all Street Deals.

### 5.7. Turf Level 8 Payment Rule

At Turf Level 8 or higher:

```text id="y7f0dm"
All human Street Deal payments increase by +1.
```

This module defines “payment” as a direct upfront Nal cost paid immediately by the human when selecting an option.

Affected payments:

| Deal                 | Option | Base Payment | Turf Level 8+ Payment |
| -------------------- | ------ | -----------: | --------------------: |
| `dirty_tip`          | `option_a` |            3 |                     4 |
| `black_market_cache` | `option_b` |            6 |                     7 |
| `risky_contract`     | `option_a` |            3 |                     4 |

Not affected:

* `loan_shark` `amount_due`;
* debt penalties;
* future debt repayment;
* AI rewards;
* positive Nal gains;
* temporary price modifiers.

### 5.8. Nal and VP Clamp Rules

Nal must never go below:

```text id="drah3y"
0
```

VP must never go below:

```text id="wrgmak"
0
```

If a penalty or cost would reduce VP below 0, clamp to 0.

Street Deal upfront costs must be validated before resolution. A player cannot choose an option that requires more Nal than they currently have.

### 5.9. Contract Hook Rule

After a successful Street Deal option or debt processing changes Nal, VP, hand, contacts, or state conditions, the system must call ContractLogic hooks.

Contract ownership:

```text id="qokry5"
09_CONTRACTS.md
```

This file does not define contract completion rules.

### 5.10. Contact Hook Rule

`inside_contact` Option A creates a pending contact selection request.

Actual contact offer generation, contact choice, max-contact validation, unlock, and cooldown behavior are owned by:

```text id="qumy70"
11_CONTACTS.md
```

### 5.11. Debt Processing Timing

Debts are processed during Income after:

1. income is added;
2. Cops upkeep is processed.

Debt processing order within Income:

```text id="orxjzm"
income gain → Cops upkeep → debt processing → contract hooks
```

Income ownership:

```text id="pk7p3w"
06_ECONOMY_AND_MARKET.md
```

## 6. Street Deal Definitions

Street Deal definitions must not be changed.

### 6.1. Street Deal IDs

Canonical constants are owned by `03_IDS_AND_CONSTANTS.md`:

```gdscript id="wtcdpr"
class_name StreetDealIds

const LOAN_SHARK := "loan_shark"
const DIRTY_TIP := "dirty_tip"
const CHEAP_PROTECTION := "cheap_protection"
const BLACK_MARKET_CACHE := "black_market_cache"
const INSIDE_CONTACT := "inside_contact"
const RISKY_CONTRACT := "risky_contract"

const ALL := [
	LOAN_SHARK,
	DIRTY_TIP,
	CHEAP_PROTECTION,
	BLACK_MARKET_CACHE,
	INSIDE_CONTACT,
	RISKY_CONTRACT
]
```

`StreetDealIds.gd` and `StreetDealOptionIds.gd` are required. Locally duplicated ID lists and uppercase option IDs are forbidden.

### 6.2. StreetDealDefinition Resource Schema

Required Resource:

```gdscript id="e9b94d"
class_name StreetDealDefinition
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export var min_round: int = 4
@export var weight: int = 100
@export var max_uses_per_run: int = 1

@export var option_a_label: String
@export var option_a_description: String
@export var option_a_effects: Array[Dictionary]

@export var option_b_label: String
@export var option_b_description: String
@export var option_b_effects: Array[Dictionary]
```

Gameplay logic must not parse descriptions as behavior.

### 6.3. Street Deal Table

| ID                   | Eligibility                        | Option A                                                                       | Option B                                                    |
| -------------------- | ---------------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| `loan_shark`         | `round >= 8`, no active human debt | +10 Nal, create debt 12, deadline `round + 2`, penalty: lose all Nal and -1 VP | +5 Nal, create debt 6, deadline `round + 2`, penalty: -1 VP |
| `dirty_tip`          | `round >= 4`                       | Pay 3 Nal, receive `bruiser` in hand                                           | Gain +3 Nal, deterministic random AI receives `thug`        |
| `cheap_protection`   | `round >= 4`                       | Next Defense card is cheaper by 2, minimum 1                                   | Gain +2 Nal, next War card is more expensive by 1           |
| `black_market_cache` | `round >= 4`                       | Gain +6 Nal                                                                    | Pay 6 Nal, gain +1 VP                                       |
| `inside_contact`     | `round >= 8`                       | Choose 1 contact from 2 available contacts                                     | Gain +4 Nal                                                 |
| `risky_contract`     | `round >= 12`                      | Gain +1 VP, pay 3 Nal                                                          | Gain +5 Nal, richest AI receives +1 Nal                     |

## 7. Validation Rules

### 7.1. Street Deal Generation Validation

A Street Deal is eligible if:

| Condition                                         | Required |
| ------------------------------------------------- | -------: |
| `state["round"]` is 4, 8, or 12                   |      yes |
| `state["current_phase"] == PhaseIds.STREET_DEAL`  |      yes |
| `deal.min_round <= state["round"]`                |      yes |
| deal ID not in `used_deal_ids`                    |      yes |
| deal has not exceeded `max_uses_per_run`          |      yes |
| if deal is `loan_shark`, human has no active debt |      yes |

Generation validation errors:

| Condition                 | Error                            |
| ------------------------- | -------------------------------- |
| Wrong phase               | `INVALID_PHASE`                  |
| No eligible deal          | `STREET_DEAL_CHOICE_UNAVAILABLE` |
| Forbidden random API used | Static test failure              |

### 7.2. Street Deal Option Validation

A Street Deal option can be selected only if:

| Condition                                                  | Error                            |
| ---------------------------------------------------------- | -------------------------------- |
| Current phase is not Street Deal                           | `INVALID_PHASE`                  |
| No current deal exists                                     | `STREET_DEAL_CHOICE_UNAVAILABLE` |
| Player is not human                                        | `INVALID_TARGET`                 |
| Option is not `option_a` or `option_b`                     | `INVALID_STREET_DEAL_OPTION`     |
| Human already chose this round                             | `STREET_DEAL_CHOICE_UNAVAILABLE` |
| Option requires upfront Nal and human has insufficient Nal | `NOT_ENOUGH_NAL`                 |
| `loan_shark` selected while active debt exists             | `ACTIVE_DEBT_EXISTS`             |
| `inside_contact` Option A but no contact can be offered    | `STREET_DEAL_CHOICE_UNAVAILABLE` |

Failed option validation must not mutate state.

### 7.3. Debt Validation

Debt processing validates:

| Condition                                              | Expected Behavior              |
| ------------------------------------------------------ | ------------------------------ |
| No active debts                                        | No-op success.                 |
| `player["nal"] >= debt["amount_due"]`                  | Auto-repay debt.               |
| `round <= debt["deadline_round"]` and insufficient Nal | Debt remains active.           |
| `round > debt["deadline_round"]` and insufficient Nal  | Apply penalty and mark repaid. |
| Debt already repaid                                    | Skip.                          |
| Debt amount is negative                                | State validation fails.        |

### 7.4. Required Validation Error Codes

Existing PRD constants include:

```gdscript id="c9rx2z"
const STREET_DEAL_CHOICE_UNAVAILABLE := "STREET_DEAL_CHOICE_UNAVAILABLE"
const ACTIVE_DEBT_EXISTS := "ACTIVE_DEBT_EXISTS"
const NOT_ENOUGH_NAL := "NOT_ENOUGH_NAL"
const INVALID_PHASE := "INVALID_PHASE"
const INVALID_TARGET := "INVALID_TARGET"
```

Required canonical constants:

```gdscript id="vrnniw"
const INVALID_STREET_DEAL_ID := "INVALID_STREET_DEAL_ID"
const INVALID_STREET_DEAL_OPTION := "INVALID_STREET_DEAL_OPTION"
const INVALID_DEBT_STATE := "INVALID_DEBT_STATE"
```

All listed constants are required. Fallback and ad-hoc error codes are forbidden.

## 8. Resolution / Processing Flow

### 8.1. Enter Street Deal Phase Flow

When phase controller enters `PhaseIds.STREET_DEAL`:

1. Confirm `state["round"]` is 4, 8, or 12.
2. Reset `offered_this_round = false`.
3. Reset `current_deal_id = ""`.
4. Clear `choices_by_player` for the new Street Deal phase.
5. Clear `option_availability`.
6. Call `StreetDealLogic.generate_street_deal(state)`.
7. Store generated current deal and canonical option availability.
8. Set `offered_this_round = true`.
9. Return structured result.

### 8.2. Generate Street Deal Flow

Generation must:

1. Build eligible deal list.
2. Exclude used deals.
3. Exclude deals below `min_round`.
4. Exclude `loan_shark` if active human debt exists.
5. Use weighted deterministic selection through `SeededPicker.gd`.
6. Update `state["random"]` according to `14_DETERMINISTIC_RANDOM.md`.
7. Store selected deal ID.
8. Store `option_availability` using only `option_a` and `option_b`.
9. Append `LogEventTypes.STREET_DEAL_OFFERED`.
10. Return result.

If no eligible deals exist, return:

```gdscript id="vpl94f"
{
	"ok": false,
	"error": ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE,
	"current_deal_id": "",
	"state": state
}
```

### 8.3. Select Street Deal Flow

When the human chooses an option:

1. Normalize payload.
2. Validate phase.
3. Validate player is human.
4. Validate current deal exists.
5. Validate option is available.
6. Validate costs.
7. If validation fails, return failed result and do not mutate state.
8. Apply selected option effects in listed order.
9. Store choice in `choices_by_player`.
10. Add deal ID to `used_deal_ids`.
11. Clear `current_deal_id` and `option_availability`; pending contact state remains exclusively under `state["contacts"]["pending_offer"]`.
12. Call ContractLogic state-change hook.
13. Append `STREET_DEAL_RESOLVED` with exact `details` fields `player_id`, `deal_id`, and `option_id`; append `DEBT_CREATED` or `CONTACT_OFFERED` in the same transaction when the selected effect creates that state.
14. Validate state.
15. Return structured result.

### 8.4. Debt Processing Flow

For each player during Income:

1. Get player active debts.
2. For each debt in stable array order:

   1. skip if `repaid == true`;
   2. if `player["nal"] >= debt["amount_due"]`, auto-repay;
   3. else if `state["round"] <= debt["deadline_round"]`, leave active;
   4. else apply penalty and mark repaid.
3. Append `DEBT_REPAID` or `DEBT_PENALTY_APPLIED` only when the corresponding state mutation occurs.
4. Call ContractLogic state-change hook if Nal or VP changed.
5. Validate state.
6. Return structured debt result.

## 9. Street Deal Option Effects

### 9.1. `loan_shark`

Eligibility:

```gdscript id="9zdtes"
state["round"] >= 8
and not DebtLogic.has_active_debt(human)
```

#### Option A

Effect:

* human gains +10 Nal;
* create debt:

  * `amount_due = 12`;
  * `deadline_round = state["round"] + 2`;
  * penalty:

    * lose all Nal;
    * lose 1 VP.

Debt penalty shape:

```gdscript id="ww4jx6"
{
	"lose_all_nal": true,
	"vp_delta": -1
}
```

#### Option B

Effect:

* human gains +5 Nal;
* create debt:

  * `amount_due = 6`;
  * `deadline_round = state["round"] + 2`;
  * penalty:

    * lose 1 VP.

Debt penalty shape:

```gdscript id="mg8s2o"
{
	"vp_delta": -1
}
```

Turf Level 8 does not increase `amount_due`.

### 9.2. `dirty_tip`

Eligibility:

```gdscript id="zx864p"
state["round"] >= 4
```

#### Option A

Base payment:

```text id="gy1n85"
3 Nal
```

At Turf Level 8+:

```text id="9j9pqg"
4 Nal
```

Effect:

* subtract payment from human Nal;
* add `bruiser` to human hand.

Mutation:

```gdscript id="y1fl1y"
human["nal"] -= payment
human["hand"].append(GameIds.CARD_BRUISER)
```

#### Option B

Effect:

* human gains +3 Nal;
* one deterministic random AI receives `thug`.

AI selection:

* choose from `ai_1`, `ai_2`, `ai_3`;
* use `SeededPicker.gd`;
* update `state["random"]`;
* append `thug` to selected AI hand.

Mutation:

```gdscript id="5hgqe1"
human["nal"] += 3
selected_ai["hand"].append(GameIds.CARD_THUG)
```

### 9.3. `cheap_protection`

Eligibility:

```gdscript id="x9dj8y"
state["round"] >= 4
```

#### Option A

Effect:

* add temporary modifier:

  * next Defense card cheaper by 2;
  * minimum price 1.

Modifier:

```gdscript id="fi013h"
{
	"id": "cheap_protection_player_1_round_4",
	"type": ModifierTypes.NEXT_DEFENSE_CARD_PRICE_DELTA,
	"source": StreetDealIds.CHEAP_PROTECTION,
	"owner_player_id": GameIds.PLAYER_HUMAN,
	"affected_card_id": "",
	"affected_card_type": CardTypes.DEFENSE,
	"delta": -2,
	"multiplier": 1.0,
	"min_value": 1,
	"expires_at": "next_purchase",
	"consumed": false
}
```

#### Option B

Effect:

* human gains +2 Nal;
* add temporary modifier:

  * next War card more expensive by 1.

Modifier:

```gdscript id="2akqhy"
{
	"id": "cheap_protection_player_1_round_4",
	"type": ModifierTypes.NEXT_WAR_CARD_PRICE_DELTA,
	"source": StreetDealIds.CHEAP_PROTECTION,
	"owner_player_id": GameIds.PLAYER_HUMAN,
	"affected_card_id": "",
	"affected_card_type": CardTypes.WAR,
	"delta": 1,
	"multiplier": 1.0,
	"min_value": 1,
	"expires_at": "next_purchase",
	"consumed": false
}
```

### 9.4. `black_market_cache`

Eligibility:

```gdscript id="l1z6es"
state["round"] >= 4
```

#### Option A

Effect:

* human gains +6 Nal.

Mutation:

```gdscript id="km4la2"
human["nal"] += 6
```

#### Option B

Base payment:

```text id="x0ptmu"
6 Nal
```

At Turf Level 8+:

```text id="759axq"
7 Nal
```

Effect:

* subtract payment from human Nal;
* human gains +1 VP.

Mutation:

```gdscript id="f50kqi"
human["nal"] -= payment
human["vp"] += 1
```

### 9.5. `inside_contact`

Eligibility:

```gdscript id="k37fj8"
state["round"] >= 8
```

#### Option A

Effect:

* request 2 available contact offers from `ContactLogic`;
* human later chooses 1 contact through ContactLogic;
* no contact is directly unlocked by StreetDealLogic.

Required call:

```gdscript id="y6t4ge"
ContactLogic.generate_contact_offer(state, GameIds.PLAYER_HUMAN, 2, "inside_contact")
```

Canonical pending state after the call:

```gdscript id="kbqfqd"
state["contacts"]["pending_offer"] = {
	"player_id": GameIds.PLAYER_HUMAN,
	"source": "inside_contact",
	"contact_offer_ids": [],
	"resolved": false,
	"created_round": state["round"]
}
```

If ContactLogic cannot offer any valid contact, Option A is unavailable.

#### Option B

Effect:

* human gains +4 Nal.

Mutation:

```gdscript id="o9yfa4"
human["nal"] += 4
```

### 9.6. `risky_contract`

Eligibility:

```gdscript id="ydr4a8"
state["round"] >= 12
```

#### Option A

Base payment:

```text id="f0xjau"
3 Nal
```

At Turf Level 8+:

```text id="8spbzl"
4 Nal
```

Effect:

* subtract payment from human Nal;
* human gains +1 VP.

Mutation:

```gdscript id="nddfej"
human["nal"] -= payment
human["vp"] += 1
```

#### Option B

Effect:

* human gains +5 Nal;
* richest AI gains +1 Nal.

Richest AI tie-break:

1. highest `nal`;
2. stable player order:

   * `ai_1`;
   * `ai_2`;
   * `ai_3`.

No random is used for this tie-break.

Mutation:

```gdscript id="hp4osp"
human["nal"] += 5
richest_ai["nal"] += 1
```

## 10. Debt Rules

### 10.1. Active Debt Check

Required helper:

```gdscript id="j9oa1w"
static func has_active_debt(player: Dictionary) -> bool:
	for debt in player["debts"]:
		if debt["repaid"] == false:
			return true
	return false
```

### 10.2. Debt Creation

Debt creation happens only from `loan_shark`.

Required behavior:

* create debt with stable ID;
* set source to `loan_shark`;
* set `created_round = state["round"]`;
* append to `human["debts"]`;
* debt starts with `repaid = false`.

Required debt ID format:

```text id="gdfq21"
loan_shark_round_8_option_a
loan_shark_round_8_option_b
```

### 10.3. Auto-Repayment

During Income debt processing, if:

```gdscript id="l2uxdj"
player["nal"] >= debt["amount_due"]
```

then:

* subtract `amount_due`;
* set `debt["repaid"] = true`;
* set `debt["repaid_round"] = state["round"]`;
* append log entry.

### 10.4. Not Yet Due

If:

```gdscript id="uz3ua9"
state["round"] <= debt["deadline_round"]
and player["nal"] < debt["amount_due"]
```

then:

* debt remains active;
* no Nal is subtracted;
* no penalty is applied.

### 10.5. Overdue Penalty

If:

```gdscript id="22byu9"
state["round"] > debt["deadline_round"]
and player["nal"] < debt["amount_due"]
```

then:

* apply penalty;
* set `debt["repaid"] = true`;
* set `debt["penalty_applied_round"] = state["round"]`;
* append log entry.

Penalty application:

* if `penalty["lose_all_nal"] == true`, set `player["nal"] = 0`;
* if `penalty["vp_delta"]` exists, apply it and clamp VP to 0.

### 10.6. Street Medic Hook

`street_medic` can prevent one VP loss from debt penalty.

Ownership:

```text id="bml1js"
11_CONTACTS.md
```

DebtLogic must expose a safe hook point before applying VP loss:

```gdscript id="zsi4ei"
ContactLogic.before_debt_penalty_applied(state, player_id, debt)
```

If ContactLogic reports that VP loss is prevented:

* do not apply the VP loss;
* still apply other penalty parts, such as `lose_all_nal`;
* still mark debt as repaid;
* log prevention result.

## 11. API Expectations

### 11.1. StreetDealLogic.gd

Required file:

```text id="v7hzok"
res://logic/street_deals/StreetDealLogic.gd
```

Required API:

```gdscript id="n10uma"
class_name StreetDealLogic

static func create_empty_state() -> Dictionary:
	return {}

static func generate_street_deal(state: Dictionary) -> Dictionary:
	return {}

static func get_eligible_deal_ids(state: Dictionary, player_id: String) -> Array[String]:
	return []

static func validate_street_deal_choice(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func select_street_deal(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func get_payment_amount(state: Dictionary, deal_id: String, option_id: String, player_id: String) -> int:
	return 0

static func apply_option_effects(state: Dictionary, player_id: String, deal_id: String, option_id: String) -> Dictionary:
	return {}

static func reset_for_new_street_deal_phase(state: Dictionary) -> Dictionary:
	return state
```

### 11.2. DebtLogic.gd

Required file:

```text id="jup4ls"
res://logic/street_deals/DebtLogic.gd
```

Required API:

```gdscript id="zo2xwx"
class_name DebtLogic

static func create_debt(id: String, amount_due: int, deadline_round: int, penalty: Dictionary, created_round: int) -> Dictionary:
	return {}

static func has_active_debt(player: Dictionary) -> bool:
	return false

static func get_active_debts(player: Dictionary) -> Array:
	return []

static func process_debts_for_player(state: Dictionary, player_id: String) -> Dictionary:
	return {}

static func repay_debt(state: Dictionary, player_id: String, debt_id: String) -> Dictionary:
	return {}

static func apply_debt_penalty(state: Dictionary, player_id: String, debt_id: String) -> Dictionary:
	return {}
```

Manual debt repayment is not part of MVP unless explicitly added later. `repay_debt` may exist as an internal helper for automatic repayment.

### 11.3. GameStateManager.gd API

Required existing API:

```gdscript id="ryzyb3"
func select_street_deal(payload: Dictionary) -> Dictionary:
	return {}
```

Recommended selectors:

```gdscript id="gjszd1"
func get_street_deal_view(player_id: String) -> Dictionary:
	return {}

func get_street_deal_disabled_reason(payload: Dictionary) -> String:
	return ""

func get_debt_status(player_id: String) -> Dictionary:
	return {}
```

### 11.4. Street Deal Choice Payload

Required payload shape:

```gdscript id="sfzaxb"
{
	"player_id": "player_1",
	"deal_id": "dirty_tip",
	"option_id": "option_a"
}
```

Allowed `option_id` values:

```text id="4ud0qo"
option_a
option_b
```

### 11.5. Street Deal Result Shape

Successful result:

```gdscript id="rwm68x"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"deal_id": "dirty_tip",
	"option_id": "option_a",
	"effects_applied": [],
	"contact_offer": {},
	"state": {},
	"log_entries": []
}
```

Failed result:

```gdscript id="u9pvp2"
{
	"ok": false,
	"error": ValidationErrors.NOT_ENOUGH_NAL,
	"player_id": "player_1",
	"deal_id": "dirty_tip",
	"option_id": "option_a",
	"effects_applied": [],
	"state": {}
}
```

Failed validation must not mutate state.

### 11.6. Debt Processing Result Shape

```gdscript id="k6bgbz"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"results": [
		{
			"debt_id": "loan_shark_round_8_option_a",
			"was_active": true,
			"repaid": false,
			"auto_repaid": false,
			"penalty_applied": true,
			"amount_paid": 0,
			"nal_lost": 0,
			"vp_lost": 1
		}
	],
	"state": {},
	"log_entries": []
}
```

## 12. Edge Cases

| Edge Case                                | Condition                                    | Expected Behavior                                                                                               | Error Code                       | Mutation Rule                                          |
| ---------------------------------------- | -------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------ |
| Wrong phase                              | Current phase is not `STREET_DEAL`.          | Choice fails.                                                                                                   | `INVALID_PHASE`                  | No mutation.                                           |
| Non-Street-Deal round                    | Round not 4, 8, or 12.                       | No deal generated.                                                                                              | `STREET_DEAL_CHOICE_UNAVAILABLE` | No mutation.                                           |
| No eligible deal                         | All deals used or blocked by rules.          | No current deal.                                                                                                | `STREET_DEAL_CHOICE_UNAVAILABLE` | No effect mutation.                                    |
| Duplicate generated deal                 | Deal already in `used_deal_ids`.             | Must not be selected.                                                                                           | Static/unit test failure         | No mutation.                                           |
| Human already chose                      | `choices_by_player` has `player_1`.          | Reject second choice.                                                                                           | `STREET_DEAL_CHOICE_UNAVAILABLE` | No mutation.                                           |
| AI tries to choose                       | `player_id` is AI.                           | Reject choice.                                                                                                  | `INVALID_TARGET`                 | No mutation.                                           |
| Invalid option                           | Option is not `option_a` or `option_b`.      | Reject choice.                                                                                                  | `INVALID_STREET_DEAL_OPTION`     | No mutation.                                           |
| Insufficient Nal for paid option         | Human Nal below payment amount.              | Reject choice.                                                                                                  | `NOT_ENOUGH_NAL`                 | No mutation.                                           |
| Turf Level 8 dirty_tip A                 | Human at Turf Level 8+ chooses paid option.  | Cost is 4 instead of 3.                                                                                         | `OK`                             | Mutates only on success.                               |
| Turf Level 8 black_market_cache B        | Human at Turf Level 8+ chooses paid option.  | Cost is 7 instead of 6.                                                                                         | `OK`                             | Mutates only on success.                               |
| Turf Level 8 risky_contract A            | Human at Turf Level 8+ chooses paid option.  | Cost is 4 instead of 3.                                                                                         | `OK`                             | Mutates only on success.                               |
| Loan Shark with active debt              | Human has unpaid debt.                       | `loan_shark` is not generated; direct selection fails.                                                          | `ACTIVE_DEBT_EXISTS`             | No mutation.                                           |
| Loan Shark debt due with enough Nal      | Income debt processing sees enough Nal.      | Auto-repay.                                                                                                     | `OK`                             | Subtract amount, mark repaid.                          |
| Loan Shark debt not yet due              | Round <= deadline, insufficient Nal.         | Debt remains active.                                                                                            | `OK`                             | No mutation and no event.                              |
| Loan Shark debt overdue                  | Round > deadline, insufficient Nal.          | Apply penalty and mark repaid.                                                                                  | `OK`                             | Mutate Nal/VP/debt/log.                                |
| Loan Shark Option A penalty at 0 VP      | VP loss would go below 0.                    | Clamp VP to 0.                                                                                                  | `OK`                             | Mutate safely.                                         |
| Street Medic available                   | Debt penalty would reduce VP.                | ContactLogic may prevent VP loss once.                                                                          | `OK`                             | Apply non-VP penalty parts.                            |
| Dirty Tip B random AI                    | AI target needed.                            | Use deterministic SeededPicker.                                                                                 | `OK`                             | Mutate selected AI hand and random state.              |
| Risky Contract B richest AI tie          | Multiple AI have same highest Nal.           | Pick by order `ai_1`, `ai_2`, `ai_3`.                                                                           | `OK`                             | No random used.                                        |
| Inside Contact A no available contacts   | ContactLogic cannot offer contacts.          | Option unavailable.                                                                                             | `STREET_DEAL_CHOICE_UNAVAILABLE` | No mutation.                                           |
| Cheap Protection modifier already exists | Human has an unconsumed modifier from the same source, owner, and round. | Reject duplicate creation. | `INVALID_MODIFIER_STATE` | No mutation. |
| Failed Street Deal validation            | Any validation failure.                      | Return error.                                                                                                   | Relevant error                   | No mutation.                                           |

## 13. Required Source Files

Required files:

```text id="y20v9a"
res://logic/street_deals/StreetDealLogic.gd
res://logic/street_deals/DebtLogic.gd
res://data/resources/street_deals/StreetDealDefinition.gd
res://data/resources/street_deals/loan_shark.tres
res://data/resources/street_deals/dirty_tip.tres
res://data/resources/street_deals/cheap_protection.tres
res://data/resources/street_deals/black_market_cache.tres
res://data/resources/street_deals/inside_contact.tres
res://data/resources/street_deals/risky_contract.tres
```

Recommended constants file:

```text id="aq5c2i"
res://data/ids/StreetDealIds.gd
```

Related files:

```text id="cmc9x7"
res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/economy/IncomeLogic.gd
res://logic/economy/PriceLogic.gd
res://logic/contracts/ContractLogic.gd
res://logic/contacts/ContactLogic.gd
res://logic/random/SeededPicker.gd
res://autoload/GameStateManager.gd
```

Recommended optional helper files:

```text id="r4t7k2"
res://logic/street_deals/StreetDealValidator.gd
res://logic/street_deals/StreetDealEffectResolver.gd
res://logic/street_deals/StreetDealLogBuilder.gd
res://logic/street_deals/DebtPenaltyResolver.gd
```

Each source file must stay under:

```text id="mmtc9y"
250 lines
```

If `StreetDealLogic.gd` approaches the limit, split validation, effect resolution, logging, and debt logic.

## 14. Required GUT Tests

Recommended test files:

```text id="eolc0q"
res://tests/unit/test_street_deal_logic.gd
res://tests/unit/test_debt_logic.gd
```

### 14.1. Street Deal Generation Tests

Minimum tests:

* generation only happens in rounds 4, 8, and 12;
* generated deal respects `min_round`;
* generated deal is not in `used_deal_ids`;
* generated deal has no duplicates across run;
* `loan_shark` is not generated before round 8;
* `loan_shark` is not generated while human has active debt;
* same seed and random state generates same deal;
* generation updates random state according to `14_DETERMINISTIC_RANDOM.md`;
* no forbidden random APIs are used.

### 14.2. Street Deal Selection Tests

Minimum tests:

* human can select Option A;
* human can select Option B;
* AI cannot select Street Deal option;
* invalid option is rejected;
* second choice in same Street Deal phase is rejected;
* failed validation does not mutate state;
* selected deal is added to `used_deal_ids`;
* selected option is stored in `choices_by_player`.

### 14.3. Loan Shark Tests

Minimum tests:

* Option A gives +10 Nal;
* Option A creates debt amount 12;
* Option A debt deadline is `round + 2`;
* Option A overdue penalty loses all Nal and 1 VP;
* Option B gives +5 Nal;
* Option B creates debt amount 6;
* Option B debt deadline is `round + 2`;
* Option B overdue penalty loses 1 VP;
* active debt blocks new `loan_shark`;
* Turf Level 8 does not increase debt amount due.

### 14.4. Dirty Tip Tests

Minimum tests:

* Option A costs 3 Nal below Turf Level 8;
* Option A costs 4 Nal at Turf Level 8+;
* Option A adds `bruiser` to human hand;
* Option A fails with `NOT_ENOUGH_NAL` if human cannot pay;
* Option B gives human +3 Nal;
* Option B gives `thug` to deterministic random AI;
* same seed selects same AI for Option B.

### 14.5. Cheap Protection Tests

Minimum tests:

* Option A adds next Defense discount modifier;
* Option A modifier has delta -2;
* Option A modifier has minimum price 1;
* Option B gives +2 Nal;
* Option B adds next War tax modifier;
* Option B modifier has delta +1;
* modifiers are consumed by PriceLogic after matching purchase.

### 14.6. Black Market Cache Tests

Minimum tests:

* Option A gives +6 Nal;
* Option B costs 6 Nal below Turf Level 8;
* Option B costs 7 Nal at Turf Level 8+;
* Option B gives +1 VP;
* Option B fails with `NOT_ENOUGH_NAL` if human cannot pay.

### 14.7. Inside Contact Tests

Minimum tests:

* `inside_contact` does not appear before round 8;
* Option A requests 2 contact offers from ContactLogic;
* Option A creates pending contact offer state;
* Option A fails if no contacts are available;
* Option B gives +4 Nal;
* StreetDealLogic does not directly unlock a contact.

### 14.8. Risky Contract Tests

Minimum tests:

* `risky_contract` does not appear before round 12;
* Option A costs 3 Nal below Turf Level 8;
* Option A costs 4 Nal at Turf Level 8+;
* Option A gives +1 VP;
* Option B gives human +5 Nal;
* Option B gives richest AI +1 Nal;
* richest AI tie-break uses order `ai_1`, `ai_2`, `ai_3`;
* Option B does not use random.

### 14.9. DebtLogic Tests

Minimum tests:

* `has_active_debt` returns false with no debts;
* `has_active_debt` returns true with unpaid debt;
* auto-repay subtracts amount due when player has enough Nal;
* auto-repay marks debt repaid;
* debt remains active if deadline has not passed and Nal is insufficient;
* overdue debt applies penalty;
* overdue debt marks debt repaid after penalty;
* Option A overdue penalty sets Nal to 0;
* VP penalty clamps VP to 0;
* Street Medic hook can prevent VP loss once;
* repaid debts are skipped.

### 14.10. Integration Tests

Minimum tests:

* Street Deal phase after round 4 can generate and resolve deal;
* Street Deal phase after round 8 can include round-8 deals;
* Street Deal phase after round 12 can include `risky_contract`;
* used deals are excluded across all Street Deal phases;
* debt processing runs during Income after Cops upkeep;
* Street Deal effects call ContractLogic state-change hook;
* debt processing calls ContractLogic state-change hook when Nal or VP changes;
* no Street Deal or debt logic exists in UI files;
* no forbidden random APIs exist in Street Deal and debt logic files.

## 15. Static Scan Requirements

Static scan must fail if Street Deal or debt logic contains:

```text id="vvbdc8"
randf(
randi(
randomize(
RandomNumberGenerator
```

Allowed deterministic random owners:

* `SeededRandom.gd`
* `SeededPicker.gd`

Static scan must fail if Street Deal or debt implementation:

* reads or writes UI nodes;
* lives inside UI scene scripts;
* parses `description`, `option_a_description`, or `option_b_description` for gameplay behavior;
* hardcodes card prices unrelated to Street Deal effects;
* resolves combat;
* performs AI scoring;
* advances phases directly;
* applies contact unlock directly instead of calling ContactLogic;
* completes contracts directly instead of calling ContractLogic hooks.

Allowed dependencies:

* `GameIds`
* `StreetDealIds`
* `ValidationErrors`
* `PhaseIds`
* `SeededPicker`
* `StreetDealDefinition`
* `DebtLogic`
* `ContactLogic`
* `ContractLogic`
* `GameStateValidator`

## 16. Implementation Notes For LLM Agents

When implementing Street Deals and debts:

* Do not change Street Deal IDs.
* Do not change option effects.
* Do not change debt amounts.
* Do not change debt deadlines.
* Do not change penalties.
* Do not make AI choose Street Deal options in MVP.
* Allow Street Deal options to explicitly affect AI only where defined.
* Store global offer/event state in `state["street_deals"]`.
* Store debts in `player["debts"]`.
* Do not use global `active_debts` as the source of truth.
* Exclude `loan_shark` while human has active debt.
* Do not block other Street Deals while debt exists.
* Treat Turf Level 8 as +1 only to direct upfront human Nal payments.
* Do not increase debt amount due from Turf Level 8.
* Use deterministic random for `dirty_tip` Option B AI selection.
* Use stable player-order tie-break for `risky_contract` Option B.
* Use ContactLogic for `inside_contact` Option A.
* Use ContractLogic hooks after successful state-changing effects.
* Process debts during Income after Cops upkeep.
* Failed validation must not mutate state.
* Preview/selectors must not mutate state.
* Keep every source file under 250 lines.
* Add or update GUT tests with implementation.

If a future rule is unclear, do not invent behavior. Add it to:

```text id="l8k0ao"
21_OPEN_QUESTIONS_AND_FIXES.md
```

## 17. Acceptance Criteria

This module is complete when:

* all 6 Street Deal Resources exist;
* Street Deal IDs are centralized or consistently validated;
* global Street Deal state owns offers, current deal, used deals, and choices;
* player-level debt state owns debts;
* Street Deals generate only after rounds 4, 8, and 12;
* Street Deal generation is deterministic;
* used deals are not repeated;
* only the human chooses options in MVP;
* AI side effects resolve only where explicitly defined;
* `loan_shark` is blocked only while active human debt exists;
* `loan_shark` Option A creates debt 12 with correct penalty;
* `loan_shark` Option B creates debt 6 with correct penalty;
* `dirty_tip` Option A cost and card gain work;
* `dirty_tip` Option B deterministic AI target gets `thug`;
* `cheap_protection` temporary modifiers work;
* `black_market_cache` options work;
* `inside_contact` Option A creates ContactLogic handoff;
* `inside_contact` Option B gives +4 Nal;
* `risky_contract` Option A works;
* `risky_contract` Option B richest AI tie-break works;
* Turf Level 8 increases only direct upfront human payments by +1;
* debts auto-repay during Income when possible;
* debts remain active before deadline if unpaid;
* overdue debts apply penalties and become repaid;
* Street Medic hook can prevent VP loss from debt penalty;
* failed validation does not mutate state;
* Street Deal and debt logic do not use UI nodes;
* Street Deal and debt logic do not use forbidden random APIs;
* all required GUT tests pass.

## 18. Final Rule

Street Deals are human choices with explicit effects; debts are player obligations processed only through Income.
