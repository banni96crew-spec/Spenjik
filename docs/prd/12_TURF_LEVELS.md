# Turf Levels

## Document Role

This file defines only:

* Turf Level IDs and level range;
* Turf Level Resource data;
* Turf Level setup modifiers;
* Turf Level economy modifiers;
* Turf Level market modifiers;
* Turf Level contact-offer modifiers;
* Turf Level Street Deal payment modifiers;
* Turf Level AI purchase-weight modifier;
* Turf Level winner tie-break modifier;
* Turf Level runtime flags;
* Turf Level validation rules;
* TurfLevelLogic API expectations;
* Turf Level edge cases;
* Turf Level GUT tests.

This file must not redefine:

* card prices except Turf Level modifiers applied on top of prices;
* card effects;
* market generation details beyond Turf Level rotating slot count;
* income resolution beyond Turf Level Cops upkeep interval;
* combat resolution;
* role definitions;
* contract rules;
* contact definitions beyond Turf Level offer count;
* Street Deal option effects beyond Turf Level payment increase;
* AI profiles beyond Turf Level 9 purchase-weight modifier;
* winner resolution outside Turf Level 10 tie-break override;
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
* 11_CONTACTS.md
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

The Turf Level system defines run difficulty modifiers from level 0 to level 10.

Turf Levels modify existing systems without replacing them:

* setup;
* market size;
* Cops upkeep;
* AI War purchase pricing;
* contact offer count;
* Street Deal payments;
* AI War purchase weights;
* final winner tie-break.

Turf Level logic must be explicit, deterministic, and implementation-safe. It must not secretly rewrite card effects, role effects, combat rules, or AI profiles.

In MVP, Turf Level is selected manually before the run. Automatic progression between runs is out of scope.

## 2. Ownership Boundaries

This file owns:

* Turf Level range;
* Turf Level definitions;
* Turf Level Resource schema;
* Turf Level setup modifier descriptions;
* Turf Level runtime flag requirements;
* helper APIs for checking and applying Turf Level effects;
* ownership map showing which module applies each level;
* tests for Turf Level behavior.

This file references:

* `06_ECONOMY_AND_MARKET.md` for market slots, price calculation, and Cops upkeep;
* `10_STREET_DEALS_AND_DEBTS.md` for Street Deal payment handling;
* `11_CONTACTS.md` for contact offer counts;
* `13_AI_SYSTEM.md` for AI purchase weighting;
* `16_GAME_STATE_MANAGER_API.md` for setup and state access;
* `18_TEST_PLAN.md` for required tests.

This file does not own:

* actual market card selection;
* actual purchase resolution;
* actual Cops upkeep payment;
* actual Street Deal effect resolution;
* actual contact selection;
* actual AI profile definitions;
* actual combat resolution;
* normal winner resolution outside Turf Level 10 override.

## 3. Core Terms

| Term                    | Meaning                                                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------------------------- |
| Turf Level              | Difficulty modifier level from 0 to 10.                                                                  |
| Base Rules              | Level 0 behavior with no Turf Level modifier.                                                            |
| Setup Modifier          | Turf Level effect applied during game setup.                                                             |
| Runtime Modifier        | Turf Level effect applied during phase logic, purchases, Street Deals, AI scoring, or winner resolution. |
| Human Player            | `GameIds.PLAYER_HUMAN`.                                                                                  |
| AI Player               | `GameIds.PLAYER_AI_1`, `GameIds.PLAYER_AI_2`, or `GameIds.PLAYER_AI_3`.                                  |
| Strong AI               | AI selected by the AI setup system as stronger opponent.                                                 |
| AI War Discount         | Turf Level 6 first War card price discount for each AI each round.                                       |
| Human VP Lead           | Human has strictly more VP than every AI.                                                                |
| AI War Weight Bonus     | Turf Level 9 `+20%` AI purchase score modifier for War cards when human leads in VP.                     |
| Turf Level 10 Tie-break | If VP is tied and an AI is among leaders, AI wins the tie.                                               |

## 4. Runtime State

### 4.1. GameState Fields

| Field                  | Type              | Owner                   | Usage                                            |
| ---------------------- | ----------------- | ----------------------- | ------------------------------------------------ |
| `state["turf_level"]`  | int               | Setup / TurfLevelLogic  | Selected Turf Level from 0 to 10.                |
| `state["players"]`     | Array[Dictionary] | GameStateFactory        | Player setup and runtime modifier targets.       |
| `state["round"]`       | int               | GamePhaseController     | Used for per-round Turf flags.                   |
| `state["market"]`      | Dictionary        | MarketLogic             | Rotating slot count is affected by Turf Level 4. |
| `state["ai_bosses"]`   | Array[Dictionary] | AIBotController / setup | Strong AI setup affected by Turf Level 2.        |
| `state["game_result"]` | Dictionary        | WinnerResolver          | Turf Level 10 tie-break result.                  |

### 4.2. PlayerState Fields

Turf Levels use these player fields:

| Field                           | Type              | Usage                                                             |
| ------------------------------- | ----------------- | ----------------------------------------------------------------- |
| `player["id"]`                  | String            | Identify human and AI players.                                    |
| `player["is_ai"]`               | bool              | Apply AI-only or human-only effects.                              |
| `player["nal"]`                 | int               | Starting Nal modifiers and Street Deal payments.                  |
| `player["vp"]`                  | int               | Strong AI bonus and winner tie-break.                             |
| `player["defense"]`             | Dictionary        | Cops upkeep interval.                                             |
| `player["temporary_modifiers"]` | Array[Dictionary] | May be used by modules but should not store permanent Turf rules. |
| `player["turf_flags"]`          | Dictionary        | Tracks Turf Level runtime flags.                                  |

### 4.3. Required Turf Flags

Add this to `PlayerState` in `04_GAME_STATE_SCHEMA.md`:

```gdscript id="098pwf"
"turf_flags": TurfLevelLogic.create_empty_turf_flags()
```

Required default shape:

```gdscript id="phuj0a"
static func create_empty_turf_flags() -> Dictionary:
	return {
		"ai_first_war_discount_used_this_round": false
	}
```

Field ownership:

| Flag                                    | Owner                     | Reset Timing                                            |
| --------------------------------------- | ------------------------- | ------------------------------------------------------- |
| `ai_first_war_discount_used_this_round` | Turf Level 6 / PriceLogic | Resets to `false` at start of each round before Market. |

Only AI players use this flag.

Human player may have the same field for schema consistency, but it must not apply to human purchases.

### 4.4. TurfLevelDefinition Resource Schema

Required Resource:

```gdscript id="2kzzzu"
class_name TurfLevelDefinition
extends Resource

@export_range(0, 10) var level: int
@export var title: String
@export var effect_summary: String
```

Gameplay logic must not parse `effect_summary`.

### 4.5. Turf Level Constants

Required constants file:

```gdscript id="eitql6"
class_name TurfLevelIds

const MIN := 0
const MAX := 10

const BASE := 0
const AI_STARTS_WITH_EXTRA_NAL := 1
const STRONG_AI_STARTS_WITH_EXTRA_VP := 2
const HUMAN_STARTS_WITH_LESS_NAL := 3
const SMALLER_ROTATING_MARKET := 4
const HUMAN_COPS_UPKEEP_HARDER := 5
const AI_FIRST_WAR_CARD_DISCOUNT := 6
const CONTACT_CHOICE_REDUCED := 7
const HUMAN_STREET_DEAL_PAYMENTS_INCREASED := 8
const AI_WAR_WEIGHT_WHEN_HUMAN_LEADS := 9
const AI_WINS_VP_TIES := 10

const ALL := [
	BASE,
	AI_STARTS_WITH_EXTRA_NAL,
	STRONG_AI_STARTS_WITH_EXTRA_VP,
	HUMAN_STARTS_WITH_LESS_NAL,
	SMALLER_ROTATING_MARKET,
	HUMAN_COPS_UPKEEP_HARDER,
	AI_FIRST_WAR_CARD_DISCOUNT,
	CONTACT_CHOICE_REDUCED,
	HUMAN_STREET_DEAL_PAYMENTS_INCREASED,
	AI_WAR_WEIGHT_WHEN_HUMAN_LEADS,
	AI_WINS_VP_TIES
]
```

These constants must match `03_IDS_AND_CONSTANTS.md` exactly. `LEVEL_0..LEVEL_10`, string Turf IDs, and locally duplicated numeric ID constants are forbidden.

## 5. Rules

### 5.1. Turf Level Range

Valid Turf Level values:

```text id="pmvrg7"
0..10
```

Invalid Turf Level must fail setup validation.

Required canonical error code from `03_IDS_AND_CONSTANTS.md`:

```gdscript id="esbxri"
const INVALID_TURF_LEVEL := "INVALID_TURF_LEVEL"
```

Invalid Turf Level must return `ValidationErrors.INVALID_TURF_LEVEL`. Fallback error codes are forbidden.

### 5.2. Manual Selection Rule

In MVP:

* Turf Level is selected manually before the run;
* Turf Level does not increase automatically after winning or losing;
* campaign progression is out of scope;
* persistence is out of scope.

### 5.3. Cumulative Level Rule

Turf Levels are cumulative.

If selected Turf Level is `N`, all effects from levels `1..N` apply.

Examples:

* Turf Level 4 applies levels 1, 2, 3, and 4.
* Turf Level 8 applies levels 1 through 8.
* Turf Level 10 applies all Turf Level effects.

### 5.4. Setup Application Order

Setup must apply modifiers in this order:

1. Create base GameState.
2. Create base players.
3. Apply selected human role setup from `08_ROLES.md`.
4. Assign AI profiles and select strong AI through `13_AI_SYSTEM.md`.
5. Apply Turf Level setup modifiers:

   * Level 1;
   * Level 2;
   * Level 3.
6. Initialize runtime flags.
7. Validate final GameState.

Reason:

* Level 2 requires knowing which AI is strong.
* Level 3 explicitly applies after role starting Nal.

### 5.5. Turf Level Table

| Level | Effect                                                               | Owner Module                                        |
| ----: | -------------------------------------------------------------------- | --------------------------------------------------- |
|     0 | Base rules.                                                          | All modules                                         |
|     1 | All AI start with +1 Nal.                                            | GameStateFactory / TurfLevelLogic                   |
|     2 | Strong AI starts with +1 VP.                                         | GameStateFactory / AIBotController / TurfLevelLogic |
|     3 | Human gets -1 starting Nal after role, minimum 3.                    | GameStateFactory / TurfLevelLogic                   |
|     4 | Rotating market contains 3 cards instead of 4.                       | MarketLogic                                         |
|     5 | Human Cops upkeep interval is every 2 Income phases instead of 3.    | IncomeLogic                                         |
|     6 | First War card bought by each AI each round costs 1 less.            | PriceLogic                                          |
|     7 | After victory over strong AI, contact offer count is 2 instead of 3. | ContactLogic                                        |
|     8 | All direct upfront human Street Deal payments increase by +1.        | StreetDealLogic                                     |
|     9 | If human leads in VP, AI War purchase weight increases by 20%.       | AIPurchaseLogic                                     |
|    10 | At equal VP, AI wins if an AI is among leaders.                      | WinnerResolver                                      |

## 6. Turf Level Effects

### 6.1. Level 0 — Base Rules

Effect:

```text id="np2aji"
No Turf Level modifier.
```

Rules:

* no setup changes;
* no market changes;
* no upkeep changes;
* no AI discounts;
* no contact offer reduction;
* no Street Deal payment increase;
* no AI War purchase weight bonus;
* no AI-favored VP tie-break.

### 6.2. Level 1 — AI Starting Nal Bonus

Effect:

```text id="9agf1o"
All AI start with +1 Nal.
```

Implementation:

```gdscript id="vbu6ju"
if state["turf_level"] >= 1 and player["is_ai"]:
	player["nal"] += 1
```

Rules:

* applies once during setup;
* applies to all three AI players;
* does not apply to human;
* does not affect later income;
* does not create log entries unless setup logs are implemented.

### 6.3. Level 2 — Strong AI Starting VP Bonus

Effect:

```text id="dxbk7f"
Strong AI starts with +1 VP.
```

Implementation:

```gdscript id="7poqq9"
if state["turf_level"] >= 2 and player["is_strong_ai"]:
	player["vp"] += 1
```

Rules:

* strong AI must already be selected before applying this modifier;
* applies once during setup;
* applies to exactly one AI;
* does not apply to human;
* does not apply to non-strong AI.

Strong AI selection is owned by:

```text id="d736yc"
13_AI_SYSTEM.md
```

### 6.4. Level 3 — Human Starting Nal Penalty

Effect:

```text id="bqqkqb"
Human gets -1 starting Nal after role, minimum 3.
```

Implementation:

```gdscript id="5zghcl"
if state["turf_level"] >= 3 and not player["is_ai"]:
	player["nal"] = max(3, player["nal"] - 1)
```

Rules:

* applies after role starting Nal;
* applies once during setup;
* applies only to human;
* cannot reduce starting Nal below 3.

Examples:

| Role          | Nal Before Level 3 | Nal After Level 3 |
| ------------- | -----------------: | ----------------: |
| Merchant      |                  7 |                 6 |
| Enforcer      |                  5 |                 4 |
| Gray Cardinal |                  4 |                 3 |
| District Boss |                  5 |                 4 |

### 6.5. Level 4 — Reduced Rotating Market

Effect:

```text id="p80iv5"
Rotating market contains 3 cards instead of 4.
```

MarketLogic must use:

```gdscript id="4b7lsf"
static func get_rotating_slot_count(turf_level: int) -> int:
	if turf_level >= 4:
		return 3
	return 4
```

Rules:

* always available cards are unchanged;
* only rotating card count changes;
* market generation remains deterministic;
* no card IDs are added or removed from pools.

Market ownership:

```text id="jnj1ch"
06_ECONOMY_AND_MARKET.md
```

### 6.6. Level 5 — Human Cops Upkeep Interval Penalty

Effect:

```text id="i82i54"
Human Cops upkeep interval is every 2 Income phases instead of 3.
```

IncomeLogic / PriceLogic must use:

```gdscript id="m3242i"
static func get_cops_upkeep_interval(state: Dictionary, player: Dictionary) -> int:
	if state["turf_level"] >= 5 and not player["is_ai"]:
		return 2
	return 3
```

Rules:

* applies only to human;
* AI Cops upkeep interval remains 3;
* applies only while Cops are active;
* Cops upkeep cost remains 1 Nal;
* Cops deactivation rules are unchanged.

Cops upkeep ownership:

```text id="w0jg3h"
06_ECONOMY_AND_MARKET.md
```

### 6.7. Level 6 — AI First War Purchase Discount

Effect:

```text id="khzcxx"
First War card bought by each AI each round costs 1 less.
```

Rules:

* applies only if `state["turf_level"] >= 6`;
* applies only to AI players;
* applies only to War card purchases;
* applies once per AI per round;
* resets at start of each round before Market;
* final price must be clamped to minimum price by `06_ECONOMY_AND_MARKET.md`;
* failed purchase must not consume the flag.

Required flag:

```gdscript id="ukyw8h"
player["turf_flags"]["ai_first_war_discount_used_this_round"]
```

Modifier shape:

```gdscript id="9ka6sv"
{
	"source": "turf_level",
	"turf_level": 6,
	"flag": "ai_first_war_discount_used_this_round",
	"type": "CARD_PRICE_DELTA",
	"delta": -1,
	"applies_to_card_type": "war",
	"consume_on_success": true,
	"description": "Turf Level 6 first AI War card discount"
}
```

Consumption:

* consume only after successful purchase;
* set flag to `true`.

Do not apply to:

* human War purchases;
* Engine cards;
* Status cards;
* Defense cards;
* War cards gained from Street Deals;
* War cards already in hand.

### 6.8. Level 7 — Reduced Strong AI Victory Contact Offer

Effect:

```text id="yh72po"
After victory over strong AI, player chooses contact from 2 options instead of 3.
```

Rules:

* applies only to contact offers created by `strong_ai_victory`;
* does not affect `inside_contact`, which always offers 2 contacts;
* if fewer than 2 contacts are available, offer all available contacts;
* does not allow more than 1 owned contact.

Contact offer count:

```gdscript id="fco4m8"
static func get_strong_ai_victory_contact_offer_count(turf_level: int) -> int:
	if turf_level >= 7:
		return 2
	return 3
```

Contact ownership:

```text id="9ql2rc"
11_CONTACTS.md
```

### 6.9. Level 8 — Human Street Deal Payment Increase

Effect:

```text id="t9nvjc"
All direct upfront human Street Deal payments increase by +1.
```

Rules:

* applies only if `state["turf_level"] >= 8`;
* applies only to human;
* applies only to direct upfront Nal payments paid immediately when selecting a Street Deal option;
* does not apply to debt amount due;
* does not apply to debt penalties;
* does not apply to positive Nal gains;
* does not apply to AI side effects.

Affected payments:

| Deal                 | Option | Base Payment | Level 8+ Payment |
| -------------------- | ------ | -----------: | ---------------: |
| `dirty_tip`          | A      |            3 |                4 |
| `black_market_cache` | B      |            6 |                7 |
| `risky_contract`     | A      |            3 |                4 |

Required helper:

```gdscript id="gnzcp0"
static func get_street_deal_payment_delta(state: Dictionary, player: Dictionary) -> int:
	if state["turf_level"] >= 8 and not player["is_ai"]:
		return 1
	return 0
```

Street Deal ownership:

```text id="9g0stl"
10_STREET_DEALS_AND_DEBTS.md
```

### 6.10. Level 9 — AI War Purchase Weight Bonus

Effect:

```text id="ufte56"
If human leads in VP, AI get +20% to War purchase weight.
```

Rules:

* applies only if `state["turf_level"] >= 9`;
* applies only when human strictly leads all AI by VP;
* applies only to AI purchase scoring;
* applies only to War cards;
* does not change final card price;
* does not modify Resource AI profile data;
* does not apply if human is tied for VP lead;
* does not apply if any AI has VP greater than or equal to human VP.

Human leads in VP if:

```gdscript id="xartij"
human["vp"] > ai_1["vp"]
and human["vp"] > ai_2["vp"]
and human["vp"] > ai_3["vp"]
```

Multiplier:

```text id="s6fifc"
1.2
```

Recommended helper:

```gdscript id="ragy7t"
static func get_ai_war_purchase_weight_multiplier(state: Dictionary) -> float:
	if state["turf_level"] >= 9 and TurfLevelLogic.is_human_vp_leader(state):
		return 1.2
	return 1.0
```

AIPurchaseLogic should apply:

```gdscript id="9xq7t8"
if card_def.type == "war":
	score *= TurfLevelLogic.get_ai_war_purchase_weight_multiplier(state)
```

AI profile definitions must not be changed.

AI ownership:

```text id="u2rwa4"
13_AI_SYSTEM.md
```

### 6.11. Level 10 — AI-Favored VP Tie-break

Effect:

```text id="n8n7vj"
At equal VP, victory goes to AI if an AI is among the leaders.
```

Rules:

* applies only if `state["turf_level"] >= 10`;
* applies only during final winner resolution;
* applies only when there is a VP tie among leaders;
* if human is sole VP leader, human can still win;
* if one or more AI are tied for highest VP, winner must be AI;
* if multiple AI are tied for highest VP, choose AI winner by:

  1. higher Nal;
  2. stable player order: `ai_1`, then `ai_2`, then `ai_3`.

Resolved behavior example:

| Player     | VP | Nal |
| ---------- | -: | --: |
| `player_1` |  8 |  20 |
| `ai_1`     |  8 |   5 |
| `ai_2`     |  8 |  10 |
| `ai_3`     |  5 |  30 |

Winner:

```text id="hsrrvj"
ai_2
```

because AI must win the VP tie, and `ai_2` has more Nal than `ai_1`.

If AI Nal is also tied, stable order decides:

```text id="hxo5m6"
ai_1 → ai_2 → ai_3
```

WinnerResolver must not use random.

Winner ownership:

```text id="r1beb3"
02_CORE_LOOP_AND_PHASES.md
16_GAME_STATE_MANAGER_API.md
```

## 7. Validation Rules

### 7.1. Turf Level Validation

Turf Level is valid only if:

```gdscript id="1trmim"
turf_level is int and turf_level in TurfLevelIds.ALL
```

Invalid value returns:

```gdscript id="atv8op"
ValidationErrors.INVALID_TURF_LEVEL
```

String values such as `"turf_5"`, `"level_5"`, or territory names are invalid.

### 7.2. Setup Validation

GameStateValidator must verify:

| Condition                                     | Error                                         |
| --------------------------------------------- | --------------------------------------------- |
| `state["turf_level"]` is not an int member of `TurfLevelIds.ALL` | `INVALID_TURF_LEVEL` |
| Turf Level 2 active but no strong AI exists   | `INVALID_AI_STATE`                            |
| Turf flags missing                            | `INVALID_STATE`                               |
| Human Nal below 3 after Level 3 setup         | `INVALID_STATE`                               |
| AI starting Nal bonus not applied at Level 1+ | Test failure                                  |
| Strong AI VP bonus not applied at Level 2+    | Test failure                                  |

### 7.3. Runtime Modifier Validation

| Modifier | Validation                                                          |
| -------- | ------------------------------------------------------------------- |
| Level 4  | Market rotating slots must be 3 at level 4+.                        |
| Level 5  | Human Cops upkeep interval must be 2 at level 5+.                   |
| Level 6  | AI first War discount flag must not be consumed on failed purchase. |
| Level 7  | Strong AI victory offer count must be 2 at level 7+.                |
| Level 8  | Only direct upfront human Street Deal payments receive +1.          |
| Level 9  | AI War weight bonus applies only if human strictly leads VP.        |
| Level 10 | WinnerResolver must select AI on VP tie if AI among leaders.        |

### 7.4. Failed Validation Mutation Rule

Failed validation must not mutate:

* `state["turf_level"]`;
* `player["nal"]`;
* `player["vp"]`;
* `player["turf_flags"]`;
* `state["market"]`;
* `state["game_result"]`;
* `state["random"]`.

Preview/helper functions must not mutate state unless their name explicitly says `apply` or `consume`.

## 8. Resolution / Processing Flow

### 8.1. Setup Flow

TurfLevelLogic setup flow:

1. Validate selected Turf Level.
2. Ensure players exist.
3. Ensure human role setup has already been applied.
4. Ensure AI profiles and strong AI have already been assigned.
5. Apply Level 1 if active:

   * all AI gain +1 Nal.
6. Apply Level 2 if active:

   * strong AI gains +1 VP.
7. Apply Level 3 if active:

   * human loses 1 starting Nal, minimum 3.
8. Initialize `turf_flags` for all players.
9. Validate final state.
10. Return structured setup result.

### 8.2. Round Start Reset Flow

At the start of each round before Market:

```gdscript id="dciz9y"
for player in state["players"]:
	player["turf_flags"]["ai_first_war_discount_used_this_round"] = false
```

This reset is safe for human too, but the flag only applies to AI purchases.

No other Turf Level runtime flags reset.

### 8.3. Price Modifier Flow for Level 6

During price calculation:

1. PriceLogic checks card type.
2. If card is War and buyer is AI and Turf Level is 6+:

   * check `ai_first_war_discount_used_this_round`.
3. If flag is false:

   * include `-1` modifier.
4. PriceLogic applies role, Turf, temporary, and contact modifiers in the owner-defined order.
5. Purchase succeeds or fails.
6. If purchase succeeds and modifier was applied:

   * consume Turf flag.
7. If purchase fails:

   * do not consume Turf flag.

### 8.4. Market Flow for Level 4

MarketLogic calls:

```gdscript id="3j93u2"
TurfLevelLogic.get_rotating_market_slot_count(state["turf_level"])
```

before calling deterministic picker.

Market generation itself remains owned by `06_ECONOMY_AND_MARKET.md`.

### 8.5. Income Flow for Level 5

IncomeLogic calls:

```gdscript id="z6zq5p"
TurfLevelLogic.get_cops_upkeep_interval(state, player)
```

or the equivalent helper in `06_ECONOMY_AND_MARKET.md`.

Cops upkeep resolution remains owned by Economy.

### 8.6. Contact Offer Flow for Level 7

ContactLogic calls:

```gdscript id="17b5va"
TurfLevelLogic.get_strong_ai_victory_contact_offer_count(state["turf_level"])
```

only for `strong_ai_victory`.

`inside_contact` always requests 2 contacts and does not use this helper.

### 8.7. Street Deal Flow for Level 8

StreetDealLogic calls:

```gdscript id="m2k2u5"
TurfLevelLogic.get_street_deal_payment_delta(state, human)
```

when calculating direct upfront human payments.

StreetDealLogic must validate affordability using the modified amount.

### 8.8. AI Purchase Flow for Level 9

AIPurchaseLogic flow:

1. Score cards using AI profile base scores.
2. If Turf Level 9+ and human strictly leads by VP:

   * multiply War card scores by `1.2`.
3. Continue normal AI purchase decision logic.
4. Do not mutate AI profile Resource data.

### 8.9. Winner Resolution Flow for Level 10

WinnerResolver flow:

1. Compute highest VP.
2. Find all players with highest VP.
3. If there is exactly one leader:

   * winner is that leader.
4. If multiple leaders and Turf Level is below 10:

   * use normal winner tie-break from WinnerResolver.
5. If multiple leaders and Turf Level is 10+:

   * if any AI is among leaders:

     1. filter leaders to AI only;
     2. choose highest Nal;
     3. if Nal tied, choose by stable order `ai_1`, `ai_2`, `ai_3`;
     4. winner is selected AI.
   * if no AI is among leaders:

     * use normal winner tie-break.

WinnerResolver must not use random.

## 9. API Expectations

### 9.1. TurfLevelLogic.gd

Required file:

```text id="aa2eq7"
res://logic/turf_levels/TurfLevelLogic.gd
```

Recommended API:

```gdscript id="3ufhba"
class_name TurfLevelLogic

static func create_empty_turf_flags() -> Dictionary:
	return {}

static func is_valid_turf_level(turf_level: int) -> bool:
	return false

static func apply_setup_modifiers(state: Dictionary) -> Dictionary:
	return {}

static func reset_round_turf_flags(player: Dictionary) -> Dictionary:
	return player

static func get_rotating_market_slot_count(turf_level: int) -> int:
	return 4

static func get_cops_upkeep_interval(state: Dictionary, player: Dictionary) -> int:
	return 3

static func get_ai_war_purchase_modifiers(state: Dictionary, player: Dictionary, card_def: CardDefinition) -> Array[Dictionary]:
	return []

static func consume_turf_flags_after_purchase(state: Dictionary, player_id: String, applied_modifiers: Array[Dictionary]) -> Dictionary:
	return {}

static func get_strong_ai_victory_contact_offer_count(turf_level: int) -> int:
	return 3

static func get_street_deal_payment_delta(state: Dictionary, player: Dictionary) -> int:
	return 0

static func is_human_vp_leader(state: Dictionary) -> bool:
	return false

static func get_ai_war_purchase_weight_multiplier(state: Dictionary) -> float:
	return 1.0

static func resolve_level_10_ai_tie_break(state: Dictionary, tied_players: Array[Dictionary]) -> Dictionary:
	return {}
```

### 9.2. Setup Result Shape

```gdscript id="u32zil"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"turf_level": 6,
	"effects_applied": [
		"ai_starting_nal_bonus",
		"strong_ai_starting_vp_bonus",
		"human_starting_nal_penalty"
	],
	"state": {},
	"log_entries": []
}
```

Failed setup result:

```gdscript id="thfa1s"
{
	"ok": false,
	"error": ValidationErrors.INVALID_TURF_LEVEL,
	"turf_level": -1,
	"state": {}
}
```

### 9.3. Turf Price Modifier Shape

```gdscript id="c4acwl"
{
	"source": "turf_level",
	"turf_level": 6,
	"flag": "ai_first_war_discount_used_this_round",
	"type": "CARD_PRICE_DELTA",
	"delta": -1,
	"applies_to_card_type": "war",
	"consume_on_success": true,
	"description": "Turf Level 6 first AI War card discount"
}
```

### 9.4. Level 10 Tie-break Result Shape

```gdscript id="vvb53m"
{
	"ok": true,
	"applied": true,
	"winner_id": "ai_2",
	"reason": "TURF_LEVEL_10_AI_VP_TIE_BREAK",
	"tied_player_ids": [
		"player_1",
		"ai_1",
		"ai_2"
	],
	"ai_tie_break": {
		"method": "highest_nal_then_stable_ai_order",
		"selected_ai_id": "ai_2"
	}
}
```

If Level 10 does not apply:

```gdscript id="wcq5i5"
{
	"ok": true,
	"applied": false,
	"winner_id": "",
	"reason": "",
	"tied_player_ids": []
}
```

### 9.5. GameStateManager.gd Integration

`start_new_game(config)` must accept:

```gdscript id="lyhubz"
{
	"game_seed": "run_12345",
	"turf_level": 0,
	"selected_role_id": "merchant",
	"selected_contract_id": "gray_capital"
}
```

GameStateManager must expose read-only access to current Turf Level through state or selector.

Recommended selector:

```gdscript id="mj4o7g"
func get_turf_level() -> int:
	return state["turf_level"]
```

## 10. Edge Cases

| Edge Case                      | Condition                              | Expected Behavior                              | Error Code                                    | Mutation Rule                         |
| ------------------------------ | -------------------------------------- | ---------------------------------------------- | --------------------------------------------- | ------------------------------------- |
| Turf Level below 0             | `turf_level < 0`.                      | Setup fails.                                   | `INVALID_TURF_LEVEL` | No mutation after validation failure. |
| Turf Level above 10            | `turf_level > 10`.                     | Setup fails.                                   | `INVALID_TURF_LEVEL` | No mutation after validation failure. |
| Turf Level 0                   | Selected level is 0.                   | Base rules only.                               | `OK`                                          | Normal setup mutation only.           |
| Level 1 with all AI            | All AI exist.                          | Each AI gets +1 Nal.                           | `OK`                                          | Setup mutation.                       |
| Level 1 human                  | Human exists.                          | Human does not get +1 Nal.                     | `OK`                                          | No human Nal mutation from Level 1.   |
| Level 2 no strong AI           | No `is_strong_ai == true`.             | Setup validation fails.                        | `INVALID_AI_STATE`                            | No safe continuation.                 |
| Level 2 multiple strong AI     | More than one strong AI.               | Setup validation fails.                        | `INVALID_AI_STATE`                            | No safe continuation.                 |
| Level 3 Gray Cardinal          | Gray Cardinal starts with 4 Nal.       | Human becomes 3 Nal.                           | `OK`                                          | Setup mutation.                       |
| Level 3 minimum clamp          | Human would fall below 3.              | Clamp to 3.                                    | `OK`                                          | Setup mutation.                       |
| Level 4 market                 | `turf_level >= 4`.                     | Rotating slots = 3.                            | `OK`                                          | Market mutation by MarketLogic.       |
| Level 5 AI Cops                | AI has Cops.                           | Upkeep interval remains 3.                     | `OK`                                          | No Turf mutation.                     |
| Level 5 human Cops             | Human has Cops.                        | Upkeep interval becomes 2.                     | `OK`                                          | Income mutation by IncomeLogic.       |
| Level 6 human buys War         | Human buys War card.                   | No Turf discount.                              | `OK`                                          | No Turf flag mutation.                |
| Level 6 AI buys first War      | AI buys first War card this round.     | Price -1, flag consumed.                       | `OK`                                          | Mutate AI turf flag after success.    |
| Level 6 AI failed War purchase | Purchase fails.                        | Discount flag not consumed.                    | Purchase error                                | No Turf flag mutation.                |
| Level 6 AI second War          | Flag already true.                     | No Turf discount.                              | `OK`                                          | No additional flag mutation.          |
| Level 7 inside_contact         | Contact source is `inside_contact`.    | Offer count remains 2.                         | `OK`                                          | ContactLogic mutation only.           |
| Level 7 strong AI victory      | Contact source is `strong_ai_victory`. | Offer count becomes 2.                         | `OK`                                          | ContactLogic mutation.                |
| Level 8 Loan Shark debt        | Human chooses `loan_shark`.            | Amount due unchanged.                          | `OK`                                          | Debt mutation only.                   |
| Level 8 paid Street Deal       | Human pays upfront Street Deal cost.   | Cost +1.                                       | `OK`                                          | StreetDealLogic mutation.             |
| Level 9 human tied in VP       | Human shares VP lead.                  | No AI War weight bonus.                        | `OK`                                          | No profile mutation.                  |
| Level 9 human strictly leads   | Human VP is greater than all AI.       | AI War card purchase weights ×1.2.             | `OK`                                          | No Resource mutation.                 |
| Level 10 human sole VP leader  | Human has highest VP alone.            | Human can win.                                 | `OK`                                          | WinnerResolver result mutation.       |
| Level 10 human tied with AI    | Human and AI share highest VP.         | AI wins tie.                                   | `OK`                                          | WinnerResolver result mutation.       |
| Level 10 multiple AI tied      | Multiple AI share highest VP.          | Highest Nal AI wins; if tied, stable AI order. | `OK`                                          | WinnerResolver result mutation.       |

## 11. Required Source Files

Required files:

```text id="94uwb4"
res://logic/turf_levels/TurfLevelLogic.gd
res://data/resources/turf_levels/TurfLevelDefinition.gd
res://data/resources/turf_levels/turf_level_0.tres
res://data/resources/turf_levels/turf_level_1.tres
res://data/resources/turf_levels/turf_level_2.tres
res://data/resources/turf_levels/turf_level_3.tres
res://data/resources/turf_levels/turf_level_4.tres
res://data/resources/turf_levels/turf_level_5.tres
res://data/resources/turf_levels/turf_level_6.tres
res://data/resources/turf_levels/turf_level_7.tres
res://data/resources/turf_levels/turf_level_8.tres
res://data/resources/turf_levels/turf_level_9.tres
res://data/resources/turf_levels/turf_level_10.tres
```

Required constants file:

```text id="lwvq13"
res://data/ids/TurfLevelIds.gd
```

Related files:

```text id="iw0sib"
res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/game_state/WinnerResolver.gd
res://logic/economy/MarketLogic.gd
res://logic/economy/IncomeLogic.gd
res://logic/economy/PriceLogic.gd
res://logic/contacts/ContactLogic.gd
res://logic/street_deals/StreetDealLogic.gd
res://logic/ai/AIPurchaseLogic.gd
res://autoload/GameStateManager.gd
```

Recommended optional helper files:

```text id="dcrn1l"
res://logic/turf_levels/TurfSetupResolver.gd
res://logic/turf_levels/TurfPriceModifiers.gd
res://logic/turf_levels/TurfWinnerRules.gd
```

Each source file must stay under:

```text id="iu6rfl"
250 lines
```

If `TurfLevelLogic.gd` approaches the limit, split setup, price modifiers, and winner rules.

## 12. Required GUT Tests

Recommended test file:

```text id="34k2rq"
res://tests/unit/test_turf_level_logic.gd
```

### 12.1. Definition Tests

Minimum tests:

* Turf Level 0 Resource exists;
* Turf Level 1 Resource exists;
* Turf Level 2 Resource exists;
* Turf Level 3 Resource exists;
* Turf Level 4 Resource exists;
* Turf Level 5 Resource exists;
* Turf Level 6 Resource exists;
* Turf Level 7 Resource exists;
* Turf Level 8 Resource exists;
* Turf Level 9 Resource exists;
* Turf Level 10 Resource exists;
* all Turf Level Resources have level values from 0 to 10;
* no duplicate Turf Level Resource levels exist.

### 12.2. Validation Tests

Minimum tests:

* `turf_level == 0` is valid;
* `turf_level == 10` is valid;
* `turf_level < 0` is invalid;
* `turf_level > 10` is invalid;
* setup fails with invalid Turf Level;
* state validator rejects invalid Turf Level.

### 12.3. Setup Modifier Tests

Minimum tests:

* Level 1 gives all AI +1 Nal;
* Level 1 does not give human +1 Nal;
* Level 2 gives strong AI +1 VP;
* Level 2 does not give non-strong AI +1 VP;
* Level 3 applies after role starting Nal;
* Level 3 clamps human starting Nal to minimum 3;
* Turf flags are initialized for all players.

### 12.4. Level 4 Market Tests

Minimum tests:

* below Level 4 rotating market slots = 4;
* at Level 4 rotating market slots = 3;
* above Level 4 rotating market slots = 3;
* always available cards are unchanged.

### 12.5. Level 5 Cops Tests

Minimum tests:

* below Level 5 human Cops interval = 3;
* at Level 5 human Cops interval = 2;
* above Level 5 human Cops interval = 2;
* AI Cops interval remains 3 at Level 5+.

### 12.6. Level 6 AI War Discount Tests

Minimum tests:

* below Level 6 AI War discount does not apply;
* at Level 6 AI first War purchase gets -1 price;
* AI second War purchase in same round gets no discount;
* AI War discount resets next round;
* human War purchase never receives this discount;
* failed AI purchase does not consume discount flag;
* non-War AI purchases do not consume discount flag.

### 12.7. Level 7 Contact Tests

Minimum tests:

* below Level 7 strong AI victory offer count = 3;
* at Level 7 strong AI victory offer count = 2;
* above Level 7 strong AI victory offer count = 2;
* `inside_contact` offer count remains 2 at Level 7+.

### 12.8. Level 8 Street Deal Tests

Minimum tests:

* below Level 8 `dirty_tip` Option A costs 3;
* at Level 8 `dirty_tip` Option A costs 4;
* below Level 8 `black_market_cache` Option B costs 6;
* at Level 8 `black_market_cache` Option B costs 7;
* below Level 8 `risky_contract` Option A costs 3;
* at Level 8 `risky_contract` Option A costs 4;
* Level 8 does not increase `loan_shark` debt amount due;
* Level 8 does not increase debt penalties.

### 12.9. Level 9 AI Weight Tests

Minimum tests:

* below Level 9 multiplier = 1.0;
* at Level 9 with human not leading multiplier = 1.0;
* at Level 9 with human tied for VP lead multiplier = 1.0;
* at Level 9 with human strictly leading multiplier = 1.2;
* multiplier applies only to War cards;
* AI profile Resource data is not mutated.

### 12.10. Level 10 Winner Tests

Minimum tests:

* below Level 10 normal winner tie-break is used;
* at Level 10 human sole VP leader wins;
* at Level 10 human tied with one AI loses to that AI;
* at Level 10 human tied with multiple AI loses to AI;
* at Level 10 multiple AI tied choose higher Nal;
* at Level 10 multiple AI tied with equal Nal choose stable order `ai_1`, then `ai_2`, then `ai_3`;
* WinnerResolver does not use random.

### 12.11. Integration Tests

Minimum tests:

* full setup at Turf Level 10 applies Levels 1, 2, and 3 setup modifiers;
* MarketLogic uses Level 4 slot count;
* IncomeLogic uses Level 5 upkeep interval;
* PriceLogic uses Level 6 AI War discount;
* ContactLogic uses Level 7 strong AI offer count;
* StreetDealLogic uses Level 8 payment delta;
* AIPurchaseLogic uses Level 9 War weight multiplier;
* WinnerResolver uses Level 10 AI tie-break;
* no Turf Level logic is implemented in UI files;
* no forbidden random APIs exist in Turf Level logic files.

## 13. Static Scan Requirements

Static scan must fail if Turf Level logic contains:

```text id="l5nwf0"
randf(
randi(
randomize(
RandomNumberGenerator
```

TurfLevelLogic itself should not need random.

Turf Level modules may reference deterministic random ownership only through the systems that already use it, such as:

* `SeededPicker.gd` in MarketLogic;
* `SeededPicker.gd` in ContactLogic;
* `SeededPicker.gd` in AIBotController.

Static scan must fail if Turf Level implementation:

* reads or writes UI nodes;
* lives inside UI scene scripts;
* parses `effect_summary` as gameplay logic;
* changes card base prices;
* changes card effects;
* changes role effects;
* changes contract rewards;
* changes Street Deal option effects;
* changes AI profile Resources;
* resolves combat;
* advances phases directly.

Allowed dependencies:

* `GameIds`
* `ValidationErrors`
* `TurfLevelDefinition`
* `CardDefinition`
* `GameStateValidator`
* `WinnerResolver` only through integration
* `PriceLogic` only through modifier integration

## 14. Implementation Notes For LLM Agents

When implementing Turf Levels:

* Do not change the Turf Level table.
* Do not add levels beyond 0-10.
* Do not implement automatic progression in MVP.
* Treat levels as cumulative.
* Apply Level 3 after role starting Nal.
* Apply Level 2 after strong AI selection.
* Do not apply human role effects to AI.
* Do not apply Level 6 discount to human purchases.
* Consume Level 6 discount only after successful AI War purchase.
* Reset Level 6 flag every round before Market.
* Do not let Level 8 affect debt amount due or penalties.
* Do not mutate AI profile Resources for Level 9.
* Use strict human VP lead for Level 9.
* Use AI-favored VP tie-break at Level 10.
* For Level 10 multiple AI leaders, choose highest Nal, then stable AI order.
* Do not use random in WinnerResolver.
* Do not write Turf Level logic in UI.
* Do not parse Resource summary strings as logic.
* Keep every source file under 250 lines.
* Add or update GUT tests with implementation.

If a future Turf Level rule is unclear, do not invent behavior. Add it to:

```text id="9kp241"
21_OPEN_QUESTIONS_AND_FIXES.md
```

## 15. Acceptance Criteria

This module is complete when:

* Turf Level Resources 0 through 10 exist;
* Turf Level range validation works;
* selected Turf Level is stored in `state["turf_level"]`;
* levels are cumulative;
* Level 1 gives all AI +1 starting Nal;
* Level 2 gives strong AI +1 starting VP;
* Level 3 reduces human starting Nal after role, minimum 3;
* Level 4 reduces rotating market slots to 3;
* Level 5 changes only human Cops upkeep interval to 2;
* Level 6 discounts first AI War purchase each round by 1;
* Level 6 discount does not apply to human;
* Level 6 discount does not consume on failed purchase;
* Level 7 changes strong AI victory contact offer count from 3 to 2;
* Level 8 increases only direct upfront human Street Deal payments by +1;
* Level 9 increases AI War purchase weight by 20% only when human strictly leads in VP;
* Level 10 makes AI win VP ties if AI is among leaders;
* Level 10 multiple-AI tie resolves by highest Nal, then stable AI order;
* TurfLevelLogic does not use UI nodes;
* TurfLevelLogic does not use forbidden random APIs;
* all required GUT tests pass.

## 16. Final Rule

Turf Levels modify existing systems only through explicit, tested modifiers; they must never secretly rewrite core rules or card effects.
