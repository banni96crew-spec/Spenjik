# Deterministic Random

## Document Role

This file defines only:

* deterministic gameplay random contract;
* forbidden random APIs;
* random runtime state;
* `SeededRandom.gd` API;
* `SeededPicker.gd` API;
* random state mutation rules;
* random tag rules;
* deterministic dice rolling;
* deterministic unique picking;
* deterministic weighted picking;
* deterministic tie-break picking;
* replay requirements;
* static scan requirements;
* random-related GUT tests.

This file must not redefine:

* market composition;
* income formulas;
* combat effects;
* card prices;
* role effects;
* contract rules;
* contact rules;
* Street Deal effects;
* Turf Level effects;
* AI profiles;
* winner resolution;
* UI behavior;
* phase transition logic.

Source of truth dependencies:

* 00_INDEX.md
* 02_CORE_LOOP_AND_PHASES.md
* 03_IDS_AND_CONSTANTS.md
* 04_GAME_STATE_SCHEMA.md
* 06_ECONOMY_AND_MARKET.md
* 09_CONTRACTS.md
* 10_STREET_DEALS_AND_DEBTS.md
* 11_CONTACTS.md
* 12_TURF_LEVELS.md
* 13_AI_SYSTEM.md
* 15_GODOT_ARCHITECTURE.md
* 16_GAME_STATE_MANAGER_API.md
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

The deterministic random system makes every gameplay-random result replay-safe.

The same:

* game seed;
* player decisions;
* phase order;
* random call order;

must always produce the same:

* market history;
* income dice;
* contract offers;
* Street Deals;
* contact offers;
* AI profiles;
* strong AI;
* AI tie-breaks;
* final snapshot.

Gameplay logic must never use Godot’s built-in random APIs. All gameplay random must go through `SeededRandom.gd` and `SeededPicker.gd`.

## 2. Ownership Boundaries

This file owns:

* gameplay random rules;
* random state schema;
* random step mutation;
* random tag behavior;
* random helper APIs;
* picker helper APIs;
* static scan rules;
* replay-test rules.

This file references:

* `06_ECONOMY_AND_MARKET.md` for Income dice and market picking;
* `09_CONTRACTS.md` for contract offer picking;
* `10_STREET_DEALS_AND_DEBTS.md` for Street Deal generation and random AI targeting;
* `11_CONTACTS.md` for contact offer generation;
* `13_AI_SYSTEM.md` for strong AI selection, profile assignment, attack probability, and tie-breaks.

This file does not own:

* which cards are in the market pool;
* which contracts exist;
* which Street Deals exist;
* which contacts exist;
* which AI profiles exist;
* AI scoring formulas;
* phase ordering;
* UI animations.

## 3. Core Terms

| Term            | Meaning                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------ |
| Gameplay Random | Any random result that can affect game state, choices, scoring, cards, Nal, VP, AI actions, or winner. |
| Visual Random   | Randomness used only for animation, particles, sound variation, or non-gameplay visuals.               |
| Random State    | Dictionary stored in `state["random"]`.                                                                |
| Seed            | String run seed used to initialize deterministic random.                                               |
| Step            | Integer counter consumed by every gameplay random draw.                                                |
| Tag             | Debug label for the latest random call. It does not change the random result.                          |
| Random Draw     | One call that consumes one step and returns one float in `[0.0, 1.0)`.                                 |
| Picker          | Helper that uses deterministic draws to select from arrays.                                            |
| Replay          | Re-running the same scripted game with the same seed and getting identical results.                    |

## 4. Runtime State

### 4.1. Random State Schema

Required shape:

```gdscript
{
	"seed": "run_12345",
	"step": 0,
	"last_random_tag": "",
	"random_history_enabled": false,
	"history": []
}
```

`history` is always present to keep the runtime schema stable. It remains empty when `random_history_enabled == false`.

### 4.2. Field Rules

| Field                    | Type              | Rule                                                       |
| ------------------------ | ----------------- | ---------------------------------------------------------- |
| `seed`                   | String            | Must be stable for the full run.                           |
| `step`                   | int               | Must start at 0 and increase by exactly 1 per random draw. |
| `last_random_tag`        | String            | Must store the latest tag passed to `SeededRandom.next`.   |
| `random_history_enabled` | bool              | If true, random calls may append debug history.            |
| `history`                | Array[Dictionary] | Debug-only list; empty while history is disabled.          |

### 4.3. Step Ownership Rule

`state["random"]["step"]` is the single source of truth for gameplay random progression.

Gameplay systems must not:

* keep local random counters;
* derive separate random streams from `game_seed + round`;
* skip step updates;
* reset random step during a run;
* use tags as hidden seeds.

### 4.4. Tag Rule

Tags are debug labels only.

A tag:

* must not affect the random value;
* must not be mixed into the seed;
* must be stored in `last_random_tag`;
* should describe the random call purpose.

Good tags:

```text
income_player_1_round_4_die_1
market_round_2_rotating_pick
ai_1_action_attack_roll_round_6
contract_offer_setup
street_deal_round_8
```

Bad tags:

```text
random
test
foo
```

## 5. Rules

### 5.1. Forbidden Gameplay APIs

Gameplay logic must not use:

```gdscript
randf()
randi()
randomize()
RandomNumberGenerator
```

This ban applies to:

* `res://logic/`;
* `res://autoload/GameStateManager.gd`;
* gameplay-related helpers in `res://data/`;
* tests that simulate gameplay results, unless explicitly testing the static scan.

### 5.2. Allowed Visual Random Exception

Godot visual-only random may be used only in UI or visual scripts when it cannot affect gameplay state.

Allowed examples:

* card hover jitter;
* particle variation;
* screen shake variation;
* sound pitch variation;
* animation offset.

Visual random must not:

* change state Dictionaries;
* affect card availability;
* affect AI decisions;
* affect dice results;
* affect combat;
* affect prices;
* affect logs used in replay tests.

### 5.3. Single Random Contract Rule

All gameplay random must consume the unified random state:

```gdscript
state["random"]
```

This fixes the previous contradiction where some examples derived results from `game_seed + round`.

Correct:

* pass `state["random"]` into random helper;
* helper returns updated random state;
* owner writes updated random state back into `state["random"]`.

Incorrect:

* `"%s_%s_market" % [game_seed, round]` as a standalone seed;
* local `RandomNumberGenerator`;
* local `step` variables not stored back into state.

### 5.4. Mutation Rule

Any function that consumes random must return the updated random state.

Functions that preview active-game choices must not consume active random.

The contract setup preview is the only exception: it consumes a temporary setup RandomState and does not mutate active GameState.

Examples:

* `generate_market(state)` consumes random.
* `get_market_view(state)` must not consume random.
* `choose_ai_target(state)` consumes random only if there is a tie that requires random tie-break.
* `score_ai_targets(state)` must not consume random.

### 5.5. Random History Rule

If:

```gdscript
random_state["random_history_enabled"] == true
```

then each `SeededRandom.next()` call must append one debug entry:

```gdscript
{
	"step_before": 0,
	"step_after": 1,
	"tag": "market_round_1_pick_0",
	"value": 0.123456
}
```

History collection is optional and debug-only, but the `history` field is always present.

The history entry must contain exactly `step_before`, `step_after`, `tag`, and `value`.
The legacy shape using only `step` is forbidden.

If history is disabled, `history` remains an empty array.
If history is enabled, every `SeededRandom.next()` call appends exactly one entry.

Gameplay logic must not depend on `history`.

### 5.6. Float Range Rule

`SeededRandom.seeded_random(seed, step)` must return:

```text
0.0 <= value < 1.0
```

It must never return `1.0`.

### 5.7. Integer Range Rule

Integer selection must use:

```gdscript
int(floor(value * count))
```

Then clamp defensively:

```gdscript
index = clamp(index, 0, count - 1)
```

This prevents edge issues if float precision ever produces a boundary value.

### 5.8. No Random in WinnerResolver

Winner resolution must not use random.

Tie-breaks must be deterministic through explicit rules.

Turf Level 10 AI tie-break is defined in:

```text
12_TURF_LEVELS.md
```

## 6. Required Algorithms

### 6.1. Required Seed Hash

`SeededRandom.gd` must use:

```text
cyrb53
```

as the seed hashing algorithm.

### 6.2. Required PRNG

`SeededRandom.gd` must use:

```text
mulberry32
```

as the deterministic pseudo-random number generator.

### 6.3. Algorithm Stability Rule

The algorithm must be treated as gameplay contract.

Do not replace:

* `cyrb53`;
* `mulberry32`;
* float normalization behavior;
* step progression behavior;

without creating a save/replay compatibility break.

### 6.4. Exact Numerical Contract

`SeededRandom.seeded_random(seed, step)` must perform these exact operations:

1. Build:

```text
hash_input = seed + "::step::" + str(step)
```

2. Calculate:

```text
hash53 = cyrb53(hash_input, 0)
```

3. Fold the 53-bit hash into a 32-bit state:

```text
low32 = hash53 & 0xffffffff
high32 = (hash53 >> 21) & 0xffffffff
state32 = (low32 ^ high32) & 0xffffffff
```

4. Advance the required PRNG once:

```text
output32 = mulberry32_next(state32)
```

5. Normalize using:

```text
value = output32 / 4294967296.0
```

The tag must not participate in `hash_input`, hashing, PRNG state, or normalization.

`seeded_random()` is pure and consumes 0 random steps.
`next()` consumes exactly 1 random step.
`roll_d6_pair()` consumes exactly 2 random steps.

### 6.5. Locked Sample Vectors

The following values are replay compatibility contracts:

| Seed | Step | Value |
| --- | ---: | ---: |
| `run_12345` | 0 | `0.708633181872` |
| `run_12345` | 1 | `0.749210928567` |
| `run_12345` | 2 | `0.925818509422` |

Starting from `create_random_state("run_12345")`, `roll_d6_pair()` must return:

```gdscript
{
	"dice": [5, 5],
	"sum": 10,
	"is_double": true
}
```

The returned random state must have `step == 2`.

### 6.6. Implementation Note

Exact GDScript implementation may differ internally, but output must be stable for:

* same seed;
* same step;
* same code version.

GUT tests must lock the sample outputs from Section 6.5.

## 7. SeededRandom.gd API

Required file:

```text
res://logic/random/SeededRandom.gd
```

Required API:

```gdscript
class_name SeededRandom

static func seeded_random(seed: String, step: int) -> float:
	# cyrb53 + mulberry32
	return 0.0

static func next(random_state: Dictionary, tag: String = "") -> Dictionary:
	var value := seeded_random(random_state["seed"], random_state["step"])
	random_state["step"] += 1
	random_state["last_random_tag"] = tag

	return {
		"value": value,
		"random": random_state
	}

static func roll_d6_pair(random_state: Dictionary, tag: String = "") -> Dictionary:
	return {}
```

### 7.1. `seeded_random`

Rules:

* pure function;
* does not mutate state;
* same `seed + step` always returns same value;
* different step should usually return different value;
* returns float in `[0.0, 1.0)`.
* follows the exact hash input, 53-bit folding, PRNG advance, and normalization contract from Section 6.4.

Result:

```gdscript
var value: float = SeededRandom.seeded_random("run_12345", 0)
```

### 7.2. `next`

Rules:

* consumes exactly 1 step;
* mutates only the passed random state copy/reference depending on architecture;
* returns value and updated random state;
* updates `last_random_tag`;
* appends history only if enabled.

Result shape:

```gdscript
{
	"value": 0.42,
	"random": {
		"seed": "run_12345",
		"step": 1,
		"last_random_tag": "ai_attack_roll",
		"random_history_enabled": false,
		"history": []
	}
}
```

### 7.3. `roll_d6_pair`

Required behavior:

* consumes exactly 2 random steps;
* returns two dice from 1 to 6;
* updates random state;
* does not use Godot random APIs.

Recommended implementation behavior:

```gdscript
static func roll_d6_pair(random_state: Dictionary, tag: String = "") -> Dictionary:
	var first_result := SeededRandom.next(random_state, "%s_die_1" % tag)
	var first_value: float = first_result["value"]
	random_state = first_result["random"]

	var second_result := SeededRandom.next(random_state, "%s_die_2" % tag)
	var second_value: float = second_result["value"]
	random_state = second_result["random"]

	var first := int(floor(first_value * 6.0)) + 1
	var second := int(floor(second_value * 6.0)) + 1

	first = clamp(first, 1, 6)
	second = clamp(second, 1, 6)

	return {
		"dice": [first, second],
		"sum": first + second,
		"is_double": first == second,
		"steps_used": 2,
		"random": random_state
	}
```

This replaces the older `roll_d6_pair(seed, step)` shape for gameplay use.

The old shape may exist only as a pure low-level test helper, not as gameplay API.

## 8. SeededPicker.gd API

Required file:

```text
res://logic/random/SeededPicker.gd
```

Required API:

```gdscript
class_name SeededPicker

static func pick_one(random_state: Dictionary, items: Array, tag: String = "") -> Dictionary:
	return {}

static func pick_unique(random_state: Dictionary, items: Array, count: int, tag: String = "") -> Dictionary:
	return {}

static func pick_weighted(random_state: Dictionary, weighted_items: Array[Dictionary], tag: String = "") -> Dictionary:
	return {}

static func pick_best_tie(random_state: Dictionary, tied_items: Array, tag: String = "") -> Dictionary:
	return {}
```

All picker functions that select randomly must:

* consume random only through `SeededRandom.next`;
* return updated random state;
* never mutate input item arrays unless explicitly documented;
* fail safely on empty input.

### 8.1. Picker Result Shape

Successful result:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"selected": "ai_2",
	"selected_items": [],
	"random": {}
}
```

Failed result:

```gdscript
{
	"ok": false,
	"error": ValidationErrors.REQUIREMENT_NOT_MET,
	"selected": null,
	"selected_items": [],
	"random": {}
}
```

### 8.2. `pick_one`

Rules:

* input `items` must not be empty;
* consumes exactly 1 random step;
* selects one item by random index;
* returns selected item and updated random state.

Index:

```gdscript
index = int(floor(value * items.size()))
index = clamp(index, 0, items.size() - 1)
```

### 8.3. `pick_unique`

Rules:

* selects up to `count` unique items;
* if `count > items.size()`, return all items in picked order;
* consumes exactly 1 random step per selected item;
* must not return duplicates;
* must preserve deterministic order of selected results.

Recommended algorithm:

1. Copy input items into local pool.
2. For each pick:

   * call `pick_one` on pool;
   * append selected to result;
   * remove selected from pool.
3. Return selected array and updated random state.

Step usage:

| Requested Count | Available Items | Steps Used |
| --------------: | --------------: | ---------: |
|               3 |               7 |          3 |
|               4 |              12 |          4 |
|              10 |               3 |          3 |
|               0 |             any |          0 |

### 8.4. `pick_weighted`

Input shape:

```gdscript
[
	{
		"id": "loan_shark",
		"weight": 100
	},
	{
		"id": "dirty_tip",
		"weight": 50
	}
]
```

Rules:

* ignore items with `weight <= 0`;
* fail if no positive-weight item exists;
* consumes exactly 1 random step;
* total weight is sum of positive weights;
* random threshold is `value * total_weight`;
* select first item where cumulative weight exceeds threshold;
* return selected item.

Tie/boundary behavior:

* stable array order decides boundaries;
* do not sort unless caller explicitly sorted before passing.

### 8.5. `pick_best_tie`

Rules:

* used only when caller has already built a list of equally scoring items;
* if `tied_items.size() == 0`, fail;
* if `tied_items.size() == 1`, return the only item and consume 0 steps;
* if `tied_items.size() > 1`, call `pick_one` and consume 1 step.

Used by:

* AI purchase score ties;
* AI target score ties;
* AI attack option score ties;
* any deterministic random tie-break required by module specs.

## 9. Gameplay Random Consumers

Gameplay random may be consumed only by these systems:

| System                          | Random Use                            | Owner                          |
| ------------------------------- | ------------------------------------- | ------------------------------ |
| IncomeLogic                     | 2d6 Income roll                       | `06_ECONOMY_AND_MARKET.md`     |
| MarketLogic                     | Rotating market card selection        | `06_ECONOMY_AND_MARKET.md`     |
| ContractLogic                   | Setup contract offer selection        | `09_CONTRACTS.md`              |
| StreetDealLogic                 | Street Deal generation                | `10_STREET_DEALS_AND_DEBTS.md` |
| StreetDealLogic                 | `dirty_tip` Option B random AI target | `10_STREET_DEALS_AND_DEBTS.md` |
| ContactLogic                    | Contact offer generation              | `11_CONTACTS.md`               |
| AIBotController                 | Strong AI selection                   | `13_AI_SYSTEM.md`              |
| AIBotController                 | AI profile assignment                 | `13_AI_SYSTEM.md`              |
| AIPurchaseLogic                 | Purchase score tie-break              | `13_AI_SYSTEM.md`              |
| AIBotController / AIActionLogic | Attack probability roll               | `13_AI_SYSTEM.md`              |
| AITargetLogic                   | Target score tie-break                | `13_AI_SYSTEM.md`              |
| AIActionLogic                   | Attack option tie-break               | `13_AI_SYSTEM.md`              |

These systems must use the unified random state.

## 10. Non-Random Deterministic Tie-breaks

Some tie-breaks must not consume random.

| System                      | Tie-break                                       | Owner                          |
| --------------------------- | ----------------------------------------------- | ------------------------------ |
| Risky Contract Option B     | Richest AI; if tied, `ai_1`, `ai_2`, `ai_3`     | `10_STREET_DEALS_AND_DEBTS.md` |
| AI Saboteur Engine Target   | `brothel`, `laundry`, `accountant`, `informant` | `13_AI_SYSTEM.md`              |
| Turf Level 10 AI Winner Tie | Highest Nal, then `ai_1`, `ai_2`, `ai_3`        | `12_TURF_LEVELS.md`            |
| WinnerResolver base rules   | No random                                       | `02_CORE_LOOP_AND_PHASES.md`   |

Do not use `SeededPicker` for these unless the owner module explicitly changes the rule.

## 11. Validation Rules

### 11.1. Random State Validation

GameStateValidator must verify:

| Condition                                  | Error                 |
| ------------------------------------------ | --------------------- |
| `state["random"]` missing                  | `REQUIREMENT_NOT_MET` |
| `random["seed"]` missing or not String     | `REQUIREMENT_NOT_MET` |
| `random["step"] < 0`                       | `REQUIREMENT_NOT_MET` |
| `random["last_random_tag"]` missing        | `REQUIREMENT_NOT_MET` |
| `random["random_history_enabled"]` missing | `REQUIREMENT_NOT_MET` |

### 11.2. Picker Validation

Picker functions must validate:

| Condition                     | Behavior                                              |
| ----------------------------- | ----------------------------------------------------- |
| Empty `items` in `pick_one`   | Return failed result.                                 |
| `count <= 0` in `pick_unique` | Return success with empty selection and 0 steps used. |
| Empty weighted list           | Return failed result.                                 |
| All weights <= 0              | Return failed result.                                 |
| Single tied item              | Return it with 0 random steps consumed.               |

### 11.3. Failed Validation Mutation Rule

If random validation fails:

* do not mutate game state;
* do not consume random step;
* return structured failure where possible.

If picker validation fails:

* return original random state unchanged;
* do not consume random step.

## 12. Resolution / Processing Flow

### 12.1. Generic Random Draw Flow

1. Caller prepares tag.
2. Caller passes `state["random"]` to `SeededRandom.next`.
3. `SeededRandom.next` reads `seed` and `step`.
4. `SeededRandom.seeded_random(seed, step)` produces float.
5. Step increments by 1.
6. `last_random_tag` updates.
7. A history entry is appended only when history is enabled.
8. Caller writes returned random state back into `state["random"]`.
9. Caller uses value to make deterministic choice.

### 12.2. Generic Picker Flow

1. Caller builds validated item list.
2. Caller passes `state["random"]` to `SeededPicker`.
3. Picker consumes required steps through `SeededRandom.next`.
4. Picker returns selected value and updated random state.
5. Caller writes returned random state back into `state["random"]`.
6. Caller applies owner-module gameplay effect.

### 12.3. Income Dice Flow

IncomeLogic must:

1. Call:

```gdscript
SeededRandom.roll_d6_pair(state["random"], "income_%s_round_%s" % [player_id, state["round"]])
```

2. Store returned `random` back into `state["random"]`.
3. Use `dice`, `sum`, and `is_double` for Income.
4. Never roll dice through Godot random APIs.

### 12.4. Market Generation Flow

MarketLogic must:

1. Build rotating pool from `06_ECONOMY_AND_MARKET.md`.
2. Determine slot count.
3. Call:

```gdscript
SeededPicker.pick_unique(
	state["random"],
	ROTATING_MARKET_POOL,
	rotating_slots,
	"market_round_%s" % state["round"]
)
```

4. Store returned random state.
5. Store selected cards in market.

Market generation must not use `game_seed + round` as a separate seed.

### 12.5. Contract Offer Flow

ContractLogic must:

1. Build all valid contract IDs.
2. Call `SeededPicker.pick_unique(state["random"], contract_ids, 3, "contract_offer_setup")`.
3. Store returned random state.
4. In setup preview, return selected IDs from the temporary state without touching active state.
5. In committed setup, store the same IDs in `state["contract_offer_ids"]`.

### 12.6. Street Deal Flow

StreetDealLogic must:

1. Build eligible weighted Street Deals.
2. Call `SeededPicker.pick_weighted(state["random"], weighted_deals, "street_deal_round_%s" % state["round"])`.
3. Store returned random state.
4. Store selected deal ID.

### 12.7. Contact Offer Flow

ContactLogic must:

1. Build available contact IDs.
2. Call `SeededPicker.pick_unique(state["random"], available_contact_ids, count, "contact_offer_%s" % source)`.
3. Store returned random state.
4. Store pending offer.

### 12.8. AI Setup Flow

AIBotController must:

1. Pick strong AI with `SeededPicker.pick_one`.
2. Pick 3 unique AI profiles with `SeededPicker.pick_unique`.
3. Store returned random state after each call.

### 12.9. AI Probability Flow

AI Action must:

1. Call `SeededRandom.next(state["random"], "ai_%s_attack_probability_round_%s" % [ai_id, state["round"]])`.
2. Compare value to `profile.attack_probability`.
3. Store returned random state.
4. Use no additional probability roll that turn.

## 13. API Expectations

### 13.1. SeededRandom.gd

Required API:

```gdscript
class_name SeededRandom

static func seeded_random(seed: String, step: int) -> float:
	return 0.0

static func next(random_state: Dictionary, tag: String = "") -> Dictionary:
	return {}

static func roll_d6_pair(random_state: Dictionary, tag: String = "") -> Dictionary:
	return {}

static func create_random_state(seed: String, history_enabled: bool = false) -> Dictionary:
	return {
		"seed": seed,
		"step": 0,
		"last_random_tag": "",
		"random_history_enabled": history_enabled,
		"history": []
	}
```

### 13.2. SeededPicker.gd

Required API:

```gdscript
class_name SeededPicker

static func pick_one(random_state: Dictionary, items: Array, tag: String = "") -> Dictionary:
	return {}

static func pick_unique(random_state: Dictionary, items: Array, count: int, tag: String = "") -> Dictionary:
	return {}

static func pick_weighted(random_state: Dictionary, weighted_items: Array[Dictionary], tag: String = "") -> Dictionary:
	return {}

static func pick_best_tie(random_state: Dictionary, tied_items: Array, tag: String = "") -> Dictionary:
	return {}
```

### 13.3. Random Draw Result Shape

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"value": 0.123456,
	"random": {}
}
```

If keeping PRD-minimal shape, `ok` and `error` may be omitted from `SeededRandom.next`, but picker results should include them.

### 13.4. D6 Pair Result Shape

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"dice": [3, 6],
	"sum": 9,
	"is_double": false,
	"steps_used": 2,
	"random": {}
}
```

### 13.5. Picker Result Shape

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"selected": "ai_1",
	"selected_items": [],
	"steps_used": 1,
	"random": {}
}
```

For `pick_unique`:

```gdscript
{
	"ok": true,
	"error": ValidationErrors.OK,
	"selected": null,
	"selected_items": ["stash", "laundry", "bruiser"],
	"steps_used": 3,
	"random": {}
}
```

## 14. Edge Cases

| Edge Case                 | Condition                                     | Expected Behavior                        | Error Code            | Mutation Rule                                   |
| ------------------------- | --------------------------------------------- | ---------------------------------------- | --------------------- | ----------------------------------------------- |
| Missing random state      | `state["random"]` missing.                    | State validation fails.                  | `REQUIREMENT_NOT_MET` | No gameplay random call.                        |
| Negative step             | `random["step"] < 0`.                         | State validation fails.                  | `REQUIREMENT_NOT_MET` | No mutation.                                    |
| Empty pick_one list       | `items.size() == 0`.                          | Return failed picker result.             | `REQUIREMENT_NOT_MET` | Random state unchanged.                         |
| pick_unique count 0       | `count <= 0`.                                 | Return empty selection.                  | `OK`                  | Random state unchanged.                         |
| pick_unique count > items | Count exceeds pool size.                      | Pick all unique items.                   | `OK`                  | Consumes one step per available item.           |
| Weighted pick all zero    | All weights <= 0.                             | Return failed picker result.             | `REQUIREMENT_NOT_MET` | Random state unchanged.                         |
| Single tied item          | `pick_best_tie` receives one item.            | Return it.                               | `OK`                  | Random state unchanged.                         |
| Tag empty                 | Caller omits tag.                             | Random still works.                      | `OK`                  | Step still increments.                          |
| History enabled           | `random_history_enabled == true`.             | Append debug history.                    | `OK`                  | Mutates history only as debug data.             |
| History disabled          | `random_history_enabled == false`.            | Keep history present and do not append.  | `OK`                  | History remains unchanged.                      |
| Visual random in UI       | UI animation uses Godot RNG.                  | Allowed if gameplay state cannot change. | N/A                   | Must not affect state.                          |
| Gameplay random in UI     | UI uses random to choose gameplay result.     | Forbidden.                               | Static test failure   | Must be removed.                                |
| Winner tie                | WinnerResolver needs tie-break.               | Use deterministic non-random rule.       | `OK`                  | No random mutation.                             |
| Replay mismatch           | Same seed/script gives different final state. | Test fails.                              | N/A                   | Fix random call order or hidden nondeterminism. |

## 15. Required Source Files

Required files:

```text
res://logic/random/SeededRandom.gd
res://logic/random/SeededPicker.gd
```

Related files that must use deterministic random:

```text
res://logic/economy/IncomeLogic.gd
res://logic/economy/MarketLogic.gd
res://logic/contracts/ContractLogic.gd
res://logic/street_deals/StreetDealLogic.gd
res://logic/contacts/ContactLogic.gd
res://logic/ai/AIBotController.gd
res://logic/ai/AIPurchaseLogic.gd
res://logic/ai/AITargetLogic.gd
res://logic/ai/AIActionLogic.gd
res://logic/game_state/GameStateFactory.gd
```

Related files that must not use random:

```text
res://logic/game_state/WinnerResolver.gd
```

Each source file must stay under:

```text
250 lines
```

If a random file approaches the limit:

* keep `SeededRandom.gd` for primitive draws;
* keep `SeededPicker.gd` for selection helpers;
* move test helpers into test fixtures, not gameplay logic.

## 16. Required GUT Tests

Recommended test file:

```text
res://tests/unit/test_seeded_random.gd
```

Recommended static scan test file:

```text
res://tests/static/test_static_random_scan.gd
```

### 16.1. SeededRandom Tests

Minimum tests:

* same seed and same step returns same value;
* same seed and different step usually returns different value;
* different seed and same step usually returns different value;
* locked `run_12345` sample vectors match Section 6.5;
* value is always `>= 0.0`;
* value is always `< 1.0`;
* `next` increments step by 1;
* `next` updates `last_random_tag`;
* `next` preserves seed;
* `create_random_state` starts step at 0;
* `create_random_state` always includes an empty history array;
* history is not written when disabled;
* history is written when enabled.

### 16.2. Dice Tests

Minimum tests:

* `roll_d6_pair` returns two dice;
* each die is from 1 to 6;
* sum equals dice total;
* `is_double` is correct;
* `roll_d6_pair` consumes exactly 2 steps;
* same seed and same starting step returns same dice;
* returned random state step advances by 2.
* `run_12345` returns `[5, 5]`, sum `10`, `is_double == true`, and final step `2`.

### 16.3. SeededPicker Tests

Minimum tests:

* `pick_one` selects an item from input list;
* `pick_one` consumes exactly 1 step;
* `pick_one` fails on empty list without consuming step;
* `pick_unique` returns no duplicates;
* `pick_unique` consumes one step per selected item;
* `pick_unique` with count 0 consumes no steps;
* `pick_unique` with count greater than pool returns all items without duplicates;
* `pick_weighted` ignores zero-weight items;
* `pick_weighted` fails if all weights are zero;
* `pick_weighted` consumes exactly 1 step;
* `pick_best_tie` with one item consumes no steps;
* `pick_best_tie` with multiple items consumes one step.

### 16.4. Consumer Tests

Minimum tests:

* MarketLogic uses SeededPicker and updates random step;
* IncomeLogic uses `roll_d6_pair` and updates random step by 2 per player;
* ContractLogic offer generation updates random step;
* StreetDealLogic generation updates random step;
* ContactLogic offer generation updates random step;
* AIBotController strong AI selection updates random step;
* AIBotController profile assignment updates random step;
* AIPurchaseLogic tie-break updates random step only when tie exists;
* AITargetLogic tie-break updates random step only when tie exists;
* AI attack probability roll updates random step once per AI Action turn.

### 16.5. Replay Tests

Minimum replay test:

1. Create GameState with seed:

```text
test_seed_001
```

2. Complete setup.
3. Generate round 1 market.
4. Select contract.
5. Assign AI profiles.
6. Select strong AI.
7. Run 15 rounds with scripted decisions.
8. Save final snapshot.
9. Repeat same run.
10. Compare:

* `winner_id`;
* `game_result`;
* final scores;
* market history;
* contract state;
* contact state;
* Street Deal used IDs;
* debt states;
* combat log;
* random step.

The two final snapshots must match exactly, except optional debug-only timestamps if any exist. Gameplay logs should avoid wall-clock timestamps.

### 16.6. Static Scan Tests

Static scan must fail if gameplay files contain:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

Static scan must search:

* `res://logic/`;
* `res://autoload/GameStateManager.gd`;
* gameplay helpers under `res://data/` if any.

Static scan may ignore:

* comments that explicitly mention forbidden APIs as banned;
* this Markdown document;
* test files that implement the static scan itself;
* visual-only UI scripts if they do not affect gameplay state.

## 17. Static Scan Requirements

Forbidden in gameplay logic:

```text
randf(
randi(
randomize(
RandomNumberGenerator
```

Forbidden architecture patterns:

* generating market from `game_seed + round` without consuming `state["random"]`;
* local random state inside individual modules;
* random tie-breaks that do not update `state["random"]`;
* random calls in UI that affect gameplay;
* random calls inside WinnerResolver;
* random calls inside Resource definitions;
* using system time as seed during an active run;
* changing seed mid-run.

Allowed:

* `SeededRandom.gd`;
* `SeededPicker.gd`;
* visual-only random in UI scripts, if gameplay state cannot change.

## 18. Implementation Notes For LLM Agents

When implementing deterministic random:

* Do not use Godot random APIs for gameplay.
* Do not use `RandomNumberGenerator` in gameplay logic.
* Do not use `game_seed + round` as a standalone random stream.
* Always pass and return `state["random"]`.
* Always update `state["random"]` after consuming random.
* Tags are labels only; do not mix tags into the seed.
* Use `SeededRandom.next` for one float.
* Use `roll_d6_pair` for Income dice.
* Use `SeededPicker.pick_unique` for unique offers and pools.
* Use `SeededPicker.pick_weighted` for weighted Street Deals.
* Use `SeededPicker.pick_best_tie` for random tie-breaks.
* Preview functions must not consume active `state["random"]`.
* The contract setup preview is the only random-consuming preview: it consumes a temporary setup RandomState and never commits it.
* Do not consume random for deterministic stable tie-break rules.
* Keep random source files under 250 lines.
* Add replay tests early.
* Add static scan tests before implementing AI and Street Deals.

If a new system needs gameplay random, update this file first and define:

* owner module;
* random call timing;
* tag;
* step consumption;
* replay test.

## 19. Acceptance Criteria

This module is complete when:

* `SeededRandom.gd` exists;
* `SeededPicker.gd` exists;
* `SeededRandom` uses `cyrb53 + mulberry32`;
* `seeded_random` follows the exact numerical contract and locked sample vectors from Section 6;
* random state starts with seed and step 0;
* every gameplay random call consumes unified `state["random"]`;
* `SeededRandom.next` increments step by 1;
* `roll_d6_pair` consumes exactly 2 steps;
* `pick_one` works deterministically;
* `pick_unique` returns unique items deterministically;
* `pick_weighted` works deterministically;
* `pick_best_tie` consumes random only for real ties;
* preview functions do not consume active random, and contract preview uses only temporary setup random;
* MarketLogic does not use `game_seed + round` standalone seeds;
* IncomeLogic uses deterministic dice;
* ContractLogic uses deterministic offers;
* StreetDealLogic uses deterministic generation;
* ContactLogic uses deterministic offers;
* AI uses deterministic setup, probability rolls, and tie-breaks;
* WinnerResolver uses no random;
* forbidden random APIs are absent from gameplay logic;
* replay test passes with identical final snapshots.

## 20. Final Rule

Gameplay random must flow only through the shared `state["random"]`; no module may create its own random stream.
