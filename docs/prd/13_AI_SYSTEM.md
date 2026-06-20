# AI System

## Document Role

This file defines only:

* AI player ownership and scope;
* AI profile IDs and profile Resource data;
* strong AI selection;
* deterministic AI profile assignment;
* AI boss runtime state;
* AI Market purchase behavior;
* AI purchase scoring;
* AI reserve handling;
* AI fallback behavior;
* AI Action behavior;
* AI attack probability;
* AI target scoring;
* AI attack payload construction;
* AI modifier usage;
* deterministic AI tie-break rules;
* AI validation rules;
* AI API expectations;
* AI-related edge cases;
* AI-related GUT tests.

This file must not redefine:

* card prices;
* card effects;
* market generation;
* purchase validation;
* purchase resolution;
* income resolution;
* combat resolution;
* role definitions;
* contract rules;
* Contact rules;
* Street Deal rules;
* debt rules;
* Turf Level definitions beyond AI-facing modifiers;
* deterministic random algorithm implementation;
* UI behavior;
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
* 12_TURF_LEVELS.md
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

The AI system controls the three local AI opponents in a single-player run.

AI must:

* receive deterministic profiles during setup;
* have exactly one strong AI among the three AI players;
* buy cards during Market through the same validation rules as the human;
* respect Nal reserve rules;
* play War cards during Action through the same CombatEngine rules as the human;
* use deterministic random only through `SeededRandom.gd` and `SeededPicker.gd`;
* never bypass card, market, combat, contact, contract, Street Deal, or Turf Level rules.

The AI system exists to coordinate decisions. It must not own the rules it calls.

## 2. Ownership Boundaries

This file owns:

* AI profile definitions;
* AI profile assignment;
* strong AI selection;
* AI Market decision loop;
* AI purchase scoring;
* AI reserve logic;
* AI fallback interpretation;
* AI attack probability roll;
* AI target scoring;
* AI attack option selection;
* AI use of `insider` as modifier;
* deterministic tie-breaks for AI choices.

This file references:

* `06_ECONOMY_AND_MARKET.md` for purchase validation, price calculation, and purchase resolution;
* `07_COMBAT_SYSTEM.md` for attack validation, attack previews, attack resolution, modifier rules, and War card discard;
* `10_STREET_DEALS_AND_DEBTS.md` for AI side effects caused by Street Deals;
* `11_CONTACTS.md` for strong AI victory hooks;
* `12_TURF_LEVELS.md` for Level 6 and Level 9 AI modifiers;
* `14_DETERMINISTIC_RANDOM.md` for replay-safe selection and probability rolls;
* `16_GAME_STATE_MANAGER_API.md` for public facade integration.

This file does not own:

* UI waiting states;
* card placement after purchase;
* combat effects;
* defense effects;
* phase advancement;
* winner resolution;
* contract ownership;
* contact ownership;
* Street Deal choices.

## 3. Core Terms

| Term               | Meaning                                                                                       |
| ------------------ | --------------------------------------------------------------------------------------------- |
| AI Player          | One of `ai_1`, `ai_2`, `ai_3`.                                                                |
| Human Player       | `player_1`.                                                                                   |
| AI Profile         | Resource defining purchase scores, attack probability, target weights, reserve, and fallback. |
| Strong AI          | Exactly one AI selected during setup as the stronger opponent.                                |
| AI Boss State      | Runtime link between AI player ID, profile ID, and strong status.                             |
| Purchase Score     | Profile-defined card preference score.                                                        |
| Target Score       | Calculated value used to choose attack target.                                                |
| Reserve Nal        | Minimum Nal an AI wants to keep after a purchase.                                             |
| Attack Probability | One deterministic roll per AI Action turn to decide whether AI attempts attacks.              |
| Fallback           | Profile-defined behavior when normal AI decision cannot produce an action.                    |
| Tie-break          | Deterministic selection when equal scores exist.                                              |
| Valid Candidate    | Card or attack option that passes owner-module validation.                                    |

## 4. Runtime State

### 4.1. GameState Fields

AI uses these `GameState` fields:

| Field | Type | Owner | Usage |
|---|---|---|
| `state["players"]` | Array[Dictionary] | GameStateFactory | Contains all AI player states. |
| `state["ai_bosses"]` | Array[Dictionary] | AIBotController | Runtime AI profile assignment and strong AI data. |
| `state["random"]` | Dictionary | SeededRandom | Used for AI profile assignment, strong AI selection, probability rolls, and tie-breaks. |
| `state["market"]` | Dictionary | MarketLogic | AI purchase candidate source. |
| `state["round"]` | int | GamePhaseController | Used in tags, reset timing, and logs. |
| `state["current_phase"]` | String | GamePhaseController | Must match phase for AI purchases/actions. |
| `state["active_action_player_id"]` | String | GamePhaseController | Must match active AI during Action. |
| `state["combat_log"]` | Array[Dictionary] | Owner logic modules | Receives canonical purchase, action, attack, discard, and phase events; AI does not define ad-hoc event types. |

### 4.2. PlayerState Fields

AI reads or mutates these `PlayerState` fields through owner modules:

| Field                            | Type          | Usage                                                   |
| -------------------------------- | ------------- | ------------------------------------------------------- |
| `player["id"]`                   | String        | AI identity.                                            |
| `player["is_ai"]`                | bool          | Must be true for AI logic.                              |
| `player["nal"]`                  | int           | Purchase reserve, combat rewards, costs.                |
| `player["vp"]`                   | int           | Target scoring and Turf Level 9.                        |
| `player["engine"]`               | Dictionary    | Target scoring, Saboteur target selection.              |
| `player["status_buildings"]`     | Dictionary    | Target scoring and attack option validation.            |
| `player["defense"]`              | Dictionary    | Target scoring and defense previews.                    |
| `player["hand"]`                 | Array[String] | War cards available in Action.                          |
| `player["purchased_this_round"]` | Array[String] | Purchase validation.                                    |
| `player["ready_for_action"]`     | bool          | Set through phase/manager API after AI Market.          |
| `player["action_done"]`          | bool          | Set through phase/manager API after AI Action.          |
| `player["skip_next_action"]`     | bool          | Respected by phase controller; AI does not override it. |
| `player["is_strong_ai"]`         | bool          | True for exactly one AI.                                |
| `player["last_attacked_by"]`     | String        | Used by revenge target scoring.                         |
| `player["turf_flags"]`           | Dictionary    | Turf Level 6 AI War discount flag.                      |

### 4.3. AIBossState

Required runtime shape:

```gdscript id="vmkduv"
static func create_ai_boss_state(profile_id: String, is_strong: bool, assigned_player_id: String) -> Dictionary:
	return {
		"profile_id": profile_id,
		"is_strong": is_strong,
		"assigned_player_id": assigned_player_id
	}
```

Rules:

* `state["ai_bosses"].size() == 3`;
* every AI player must have exactly one AIBossState;
* exactly one AIBossState has `is_strong == true`;
* exactly one AI player has `player["is_strong_ai"] == true`;
* AIBossState and PlayerState strong flags must match.

### 4.4. AIProfileDefinition Resource Schema

Required Resource:

```gdscript id="e5pjoy"
class_name AIProfileDefinition
extends Resource

@export var id: String
@export var purchase_scores: Dictionary
@export var attack_probability: float
@export var target_weights: Dictionary
@export var minimum_reserve_nal: int
@export_enum("end_phase", "buy_cheapest_valid", "discard_action_cards", "attack_best_target", "hold_nal") var fallback: String
```

Gameplay logic must not parse Resource filenames or display text as behavior.

### 4.5. AI Profile IDs

AI profile IDs must not be changed.

Canonical constants are owned by `03_IDS_AND_CONSTANTS.md`:

```gdscript id="i9w2xj"
class_name AIProfileIds

const BUILDER := "builder"
const RACKETEER := "racketeer"
const MERCHANT := "merchant"
const PARANOID := "paranoid"
const SCHEMER := "schemer"
const AVENGER := "avenger"

const ALL := [
	BUILDER,
	RACKETEER,
	MERCHANT,
	PARANOID,
	SCHEMER,
	AVENGER
]
```

Important:

* AI profile ID `merchant` is domain-scoped to AI profiles.
* Role ID `merchant` remains a separate role ID.
* The Resource file may be named `merchant_ai.tres`, but its profile ID remains `merchant`.
* `AIProfileIds.gd` is required; locally duplicated profile ID lists are forbidden.

AI player IDs are not profile IDs and are not generated by AI logic. `GameStateFactory` creates exactly `ai_1`, `ai_2`, and `ai_3` from `GameIds.AI_PLAYER_IDS`; AIBotController only assigns profiles and strong status to those IDs.

Turf Level is always the integer `state["turf_level"]` from `TurfLevelIds.ALL`. AI logic must not accept string territory IDs or derive a Turf ID from display text.

### 4.6. Required AI Validation Errors

Canonical AI errors are owned by `ValidationErrors.gd`:

```gdscript id="ct77yo"
const INVALID_AI_PROFILE_ID := "INVALID_AI_PROFILE_ID"
const INVALID_AI_STATE := "INVALID_AI_STATE"
const NO_VALID_AI_ACTION := "NO_VALID_AI_ACTION"
const NO_VALID_AI_PURCHASE := "NO_VALID_AI_PURCHASE"
```

Fallback and ad-hoc AI error strings are forbidden.

## 5. Rules

### 5.1. AI Player Rule

The game has exactly three local AI players:

```text id="d47r32"
ai_1
ai_2
ai_3
```

AI players:

* do not use human roles in MVP;
* do not receive contracts in MVP;
* do not choose Street Deals in MVP;
* may be affected by explicit Street Deal side effects;
* may be targeted by combat;
* may be selected as strong AI.

### 5.2. Strong AI Selection Rule

Strong AI is selected during setup.

Selection:

* choose exactly one ID from `ai_1`, `ai_2`, `ai_3`;
* use `SeededPicker.gd`;
* update `state["random"]`;
* set selected player:

```gdscript id="kcrde0"
player["is_strong_ai"] = true
```

* set all other AI players:

```gdscript id="xmol0q"
player["is_strong_ai"] = false
```

Strong AI selection must be deterministic and replay-safe.

### 5.3. AI Profile Assignment Rule

During setup:

1. Deterministically select 3 unique AI profiles from the 6 available profiles.
2. Use `SeededPicker.gd`.
3. Update `state["random"]`.
4. Assign selected profiles in stable player order:

   * first selected profile to `ai_1`;
   * second selected profile to `ai_2`;
   * third selected profile to `ai_3`.
5. Store assignment in `state["ai_bosses"]`.

Profiles must be unique within one run.

### 5.4. AI Setup Order

AI setup must happen in this order:

1. Create base players.
2. Select strong AI.
3. Assign AI profiles.
4. Write `state["ai_bosses"]`.
5. Apply Turf Level setup modifiers that depend on AI, including:

   * Turf Level 1 AI starting Nal bonus;
   * Turf Level 2 strong AI starting VP bonus.
6. Validate final state.

### 5.5. AI Market Rule

During Market:

* each AI may buy multiple cards;
* AI repeats purchase evaluation after every successful purchase;
* AI stops when no valid purchase candidate remains;
* AI must respect `minimum_reserve_nal`;
* AI must respect the normal one-copy-per-card-ID-per-round rule;
* AI must use MarketLogic / PriceLogic validation;
* AI must not mutate cards, Nal, or flags directly.

AI logic must end Market participation through:

```gdscript id="gb4x7q"
GamePhaseController.end_market_for_player(state, player_id)
```

The public facade exposes the corresponding `GameStateManager.end_market_for_player(player_id)` method but AIBotController must not call it.

### 5.6. AI Reserve Rule

A purchase candidate respects reserve if:

```gdscript id="gb70bu"
player["nal"] - final_price >= ai_profile.minimum_reserve_nal
```

If this condition fails, the card is not a normal purchase candidate.

Reserve does not change card price.

Reserve must not bypass `NOT_ENOUGH_NAL`.

### 5.7. AI Purchase Score Rule

AI purchase score comes from:

```gdscript id="rq2ior"
profile.purchase_scores[card_id]
```

If card ID is missing from `purchase_scores`, base score is:

```text id="52wo2f"
0
```

Normal purchase candidates require:

* card is available in market;
* purchase validation passes;
* reserve rule passes;
* base purchase score is greater than 0.

Turf Level 9 may multiply War purchase score by `1.2` if human strictly leads in VP.

Turf Level 9 ownership:

```text id="kz53oy"
12_TURF_LEVELS.md
```

### 5.8. AI Purchase Tie-break Rule

If multiple normal purchase candidates have the same highest final score:

* use deterministic `SeededPicker.gd`;
* update `state["random"]`;
* choose exactly one candidate.

Do not use stable order unless SeededPicker is unavailable in tests.

Do not use forbidden random APIs.

### 5.9. AI Market Fallback Rule

If no normal purchase candidate exists, apply the profile fallback in Market context:

| Fallback               | Market Behavior                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `end_phase`            | Buy nothing and end Market participation.                                                                                           |
| `hold_nal`             | Buy nothing and end Market participation.                                                                                           |
| `buy_cheapest_valid`   | Buy the cheapest valid card that still respects reserve. Tie-break via `SeededPicker.gd`. If none exists, end Market participation. |
| `discard_action_cards` | Not relevant in Market; end Market participation.                                                                                   |
| `attack_best_target`   | Not relevant in Market; end Market participation.                                                                                   |

Fallback must not bypass purchase validation.

### 5.10. AI Action Probability Rule

At the start of each AI Action turn:

1. If AI has no War cards in hand, end Action.
2. Roll once through `SeededRandom.gd`.
3. If `roll <= profile.attack_probability`, AI attempts attacks.
4. If `roll > profile.attack_probability`, AI ends Action.

Attack probability gates attacking. Fallback must not secretly bypass a failed attack probability roll.

### 5.11. AI Action Rule

If AI decides to attack:

* AI may play multiple valid War cards in one Action turn;
* after each resolved attack, AI re-evaluates hand and board state;
* AI stops when no valid unblocked attack option remains;
* unused War cards remain in hand unless fallback explicitly discards them;
* AI must resolve attacks through CombatEngine / GameStateManager;
* AI must not mutate hand or combat state directly.

### 5.12. AI Attack Option Rule

AI builds possible attack options from:

* AI hand;
* valid target players;
* valid card modes;
* valid `saboteur` engine targets;
* valid `insider` modifier usage;
* CombatEngine validation;
* CombatEngine preview.

AI should avoid attacks that preview as blocked if any unblocked valid attack option exists.

Blocked options may be used only if:

* no unblocked option exists; and
* profile fallback is `attack_best_target`.

### 5.13. AI War Card Priority Rule

When choosing among cards in hand, AI uses its profile `purchase_scores` as card preference scores.

If a War card is missing from profile `purchase_scores`, its card preference score is:

```text id="7s4nhm"
0
```

War cards with score `0` are still allowed only as fallback candidates.

### 5.14. AI Mode Selection Rule

AI must construct legal modes exactly as `07_COMBAT_SYSTEM.md` requires.

Mode behavior:

* `thug`: no mode;
* `bruiser`: prefer `destroy_stash` if valid and unblocked; otherwise use `steal_nal` if valid;
* `cleaner`: prefer `destroy_workshop` if valid and unblocked; otherwise use `steal_nal` if valid;
* `federal_raid`: use `destroy_district`;
* `saboteur`: no mode; requires `engine_target_card_id`;
* `insider`: never primary, modifier only.

### 5.15. AI Saboteur Target Card Rule

When AI uses `saboteur`, it chooses a target Engine card in this priority:

```text id="jv3u5r"
brothel
laundry
accountant
informant
```

Rules:

* choose the first owned valid Engine target from this priority list;
* do not use random;
* do not let target choose the card;
* do not attack with `saboteur` if no valid Engine target exists;
* Judge-block preview should be avoided if unblocked alternatives exist.

### 5.16. AI Insider Modifier Rule

AI may use `insider` only as defined in `07_COMBAT_SYSTEM.md`.

AI uses `insider` only if:

* AI has `thug` in hand;
* AI has `insider` in hand;
* target has active Cops;
* `thug` without `insider` would be blocked;
* `thug` with `insider` would not be blocked.

AI must not use `insider`:

* as a primary attack;
* with `bruiser`;
* with `cleaner`;
* with `saboteur`;
* with `federal_raid`.

### 5.17. AI Target Scoring Rule

AI scores each legal target using profile `target_weights`.

Target score formula:

```gdscript id="fule1p"
target_score =
	(vp_lead_value * weights["vpLead"])
	+ (available_nal_value * weights["availableNal"])
	+ (low_defense_value * weights["lowDefense"])
	+ (destructible_buildings_value * weights["destructibleBuildings"])
	+ (revenge_value * weights["revenge"])
	+ (human_bias_value * weights["humanBias"])
```

Feature values:

| Feature                        | Formula                                                                   |
| ------------------------------ | ------------------------------------------------------------------------- |
| `vp_lead_value`                | `max(0, target["vp"] - attacker["vp"])`                                   |
| `available_nal_value`          | `max(0, target["nal"] - protected_nal)`                                   |
| `low_defense_value`            | Number of missing active defenses from Cops, Cartel, Judge. Range `0..3`. |
| `destructible_buildings_value` | `stash + workshop + district_control`                                     |
| `revenge_value`                | `1` if `target["id"] == attacker["last_attacked_by"]`, else `0`.          |
| `human_bias_value`             | `1` if target is human, else `0`.                                         |

Protected Nal is calculated by the economy system:

```text id="3c230r"
06_ECONOMY_AND_MARKET.md
```

Target score must not mutate state.

### 5.18. AI Target Tie-break Rule

If multiple targets have equal highest target score:

* use deterministic `SeededPicker.gd`;
* update `state["random"]`;
* choose exactly one target.

### 5.19. AI Fallback Rule

Fallbacks must use the profile fallback ID exactly.

| Fallback               | Action Behavior                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `end_phase`            | End AI Action immediately.                                                                                                          |
| `hold_nal`             | End AI Action immediately.                                                                                                          |
| `buy_cheapest_valid`   | Not relevant in Action; end AI Action.                                                                                              |
| `discard_action_cards` | Discard War cards that have no valid unblocked attack option, then end Action.                                                      |
| `attack_best_target`   | If attack probability passed, allow the best blocked valid attack only when no unblocked valid attack exists. Otherwise end Action. |

Fallback must not override a failed attack probability roll.

### 5.20. AI Street Deal Rule

In MVP:

* AI players do not choose Street Deal options;
* AI may receive explicit Street Deal side effects;
* `dirty_tip` Option B may give deterministic random AI a `thug`;
* `risky_contract` Option B may give richest AI +1 Nal.

These side effects are owned by:

```text id="hkajk2"
10_STREET_DEALS_AND_DEBTS.md
```

## 6. AI Profiles

AI profiles must not be changed.

### 6.1. Profile Table

| AI Profile  | Purchase Priority Score                                                                 | Attack Probability | Target Scoring Weights                                                                              | Reserve | Fallback             |
| ----------- | --------------------------------------------------------------------------------------- | -----------------: | --------------------------------------------------------------------------------------------------- | ------: | -------------------- |
| `builder`   | `stash:100`, `workshop:90`, `district_control:85`, `laundry:65`, `cartel:55`, `cops:45` |             `0.25` | `vpLead:4`, `availableNal:1`, `lowDefense:1`, `destructibleBuildings:3`, `revenge:2`, `humanBias:1` |     `3` | `hold_nal`           |
| `racketeer` | `thug:100`, `bruiser:90`, `insider:75`, `cleaner:70`, `cops:45`, `stash:35`             |             `0.80` | `vpLead:2`, `availableNal:5`, `lowDefense:3`, `destructibleBuildings:2`, `revenge:2`, `humanBias:1` |     `1` | `attack_best_target` |
| `merchant`  | `laundry:100`, `informant:85`, `brothel:70`, `accountant:65`, `stash:50`, `judge:40`    |             `0.20` | `vpLead:2`, `availableNal:3`, `lowDefense:1`, `destructibleBuildings:1`, `revenge:1`, `humanBias:0` |     `6` | `hold_nal`           |
| `paranoid`  | `cops:100`, `cartel:90`, `judge:85`, `accountant:75`, `stash:55`, `workshop:40`         |             `0.20` | `vpLead:3`, `availableNal:1`, `lowDefense:1`, `destructibleBuildings:2`, `revenge:5`, `humanBias:1` |     `4` | `buy_cheapest_valid` |
| `schemer`   | `saboteur:100`, `insider:85`, `judge:70`, `accountant:65`, `bruiser:60`, `informant:45` |             `0.55` | `vpLead:3`, `availableNal:2`, `lowDefense:2`, `destructibleBuildings:1`, `revenge:2`, `humanBias:1` |     `3` | `end_phase`          |
| `avenger`   | `bruiser:100`, `cops:75`, `cartel:70`, `thug:65`, `cleaner:60`, `stash:35`              |             `0.65` | `vpLead:3`, `availableNal:2`, `lowDefense:2`, `destructibleBuildings:4`, `revenge:6`, `humanBias:1` |     `2` | `attack_best_target` |

### 6.2. Profile Resource Files

Required Resources:

```text id="430fyr"
res://data/resources/ai_profiles/builder.tres
res://data/resources/ai_profiles/racketeer.tres
res://data/resources/ai_profiles/merchant_ai.tres
res://data/resources/ai_profiles/paranoid.tres
res://data/resources/ai_profiles/schemer.tres
res://data/resources/ai_profiles/avenger.tres
```

`merchant_ai.tres` must have:

```gdscript id="j5hpng"
id = "merchant"
```

Do not rename the AI profile ID to `merchant_ai`.

## 7. Validation Rules

### 7.1. AI Setup Validation

GameStateValidator or AI validation must verify:

| Condition                                          | Error                                            |
| -------------------------------------------------- | ------------------------------------------------ |
| AI player count is not 3                           | `INVALID_AI_STATE`      |
| Unknown AI player ID                               | `INVALID_AI_STATE`      |
| `state["ai_bosses"].size() != 3`                   | `INVALID_AI_STATE`      |
| Unknown AI profile ID                              | `INVALID_AI_PROFILE_ID` |
| Duplicate assigned profile                         | `INVALID_AI_STATE`      |
| No strong AI                                       | `INVALID_AI_STATE`      |
| More than one strong AI                            | `INVALID_AI_STATE`      |
| AIBossState strong flag does not match PlayerState | `INVALID_AI_STATE`      |

### 7.2. AI Market Validation

Before AI Market decisions:

* current phase must be `PhaseIds.MARKET`;
* player must be AI;
* AI profile must exist;
* market must exist;
* all candidate purchases must pass `MarketLogic.can_buy_card`;
* reserve rule must pass for normal candidates.

Failed candidate validation must not mutate state.

### 7.3. AI Action Validation

Before AI Action decisions:

* current phase must be `PhaseIds.ACTION`;
* player must be AI;
* player must be the active action player;
* AI profile must exist;
* skipped players must already be handled by phase controller;
* every generated attack payload must pass CombatEngine validation before resolution.

Failed attack validation must not mutate state.

### 7.4. Random Validation

AI may use deterministic random only for:

* strong AI selection;
* AI profile assignment;
* purchase score tie-break;
* attack probability roll;
* target score tie-break;
* action option tie-break.

Forbidden:

* `randf()`;
* `randi()`;
* `randomize()`;
* `RandomNumberGenerator`.

### 7.5. Failed Validation Mutation Rule

Failed validation must not mutate:

* `player["nal"]`;
* `player["vp"]`;
* `player["hand"]`;
* `player["purchased_this_round"]`;
* `player["ready_for_action"]`;
* `player["action_done"]`;
* `state["ai_bosses"]`;
* `state["random"]`;
* `state["combat_log"]`.

Exception:

* a failed candidate inside an AI decision loop may be ignored without mutating state.

## 8. Resolution / Processing Flow

### 8.1. AI Setup Flow

AI setup must resolve in this order:

1. Get AI player IDs:

```text id="lpa7q1"
ai_1
ai_2
ai_3
```

2. Select strong AI through `SeededPicker`.
3. Set `is_strong_ai` on players.
4. Select 3 unique AI profiles through `SeededPicker`.
5. Assign profiles to AI players in stable order.
6. Create `state["ai_bosses"]`.
7. Return updated random state.
8. Validate AI setup.

### 8.2. AI Market Flow

For each AI during Market:

1. Get assigned AI profile.
2. Start loop.
3. Build normal purchase candidates from `state["market"]["all_available_card_ids"]`.
4. For each candidate:

   1. call `MarketLogic.can_buy_card`;
   2. call `PriceLogic` preview;
   3. reject if reserve would be violated;
   4. reject if purchase score is `0`;
   5. apply Turf Level 9 War score multiplier if active.
5. If one or more candidates exist:

   1. select highest score;
   2. tie-break with `SeededPicker`;
   3. call `MarketLogic.buy_card`;
   4. if purchase succeeds, loop again;
   5. if purchase fails unexpectedly, remove that candidate and continue.
6. If no candidates exist:

   1. apply Market fallback;
   2. if fallback purchases a card, loop again;
   3. otherwise end Market.
7. Mark AI ready for Action through phase-safe API.
8. Validate state.

Loop guard:

* the loop must not exceed the number of available market card IDs plus one;
* this prevents infinite loops if validation and purchase state desync.

### 8.3. AI Action Flow

For active AI during Action:

1. Get assigned AI profile.
2. If `player["hand"]` has no War cards, end Action.
3. Roll attack probability once through `SeededRandom.gd`.
4. If roll is greater than `profile.attack_probability`, end Action.
5. If roll passes:

   1. build valid unblocked attack options;
   2. if options exist, choose best option;
   3. resolve attack through CombatEngine / GameStateManager;
   4. loop and re-evaluate state;
   5. stop when no valid unblocked attack option remains.
6. If no unblocked options exist, apply Action fallback.
7. End Action through phase-safe API.
8. Validate state.

Loop guard:

* maximum attack resolutions in one AI Action turn must not exceed the number of War cards in hand at action start;
* if additional War cards are somehow added during the same Action, they are not played until a future Action.

### 8.4. Build Purchase Candidate Flow

Recommended candidate shape:

```gdscript id="z4ofuh"
{
	"player_id": "ai_1",
	"card_id": "stash",
	"base_score": 100,
	"final_score": 100.0,
	"price": 8,
	"reserve_after_purchase": 3,
	"modifiers": []
}
```

Candidate rules:

* preview functions must not mutate state;
* final score must not mutate AI profile Resource;
* candidate list may be empty.

### 8.5. Build Attack Option Flow

Recommended attack option shape:

```gdscript id="uvcv6y"
{
	"attacker_id": "ai_1",
	"target_id": "player_1",
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"modifiers": [],
	"engine_target_card_id": "",
	"card_preference_score": 90,
	"target_score": 12,
	"blocked": false,
	"final_score": 102
}
```

Final attack option score:

```gdscript id="dhm6nh"
final_score = card_preference_score + target_score
```

If scores tie:

* use deterministic `SeededPicker.gd`;
* update random state.

### 8.6. End AI Market Flow

AI ends Market by setting:

```gdscript id="8xipqe"
player["ready_for_action"] = true
```

Inside logic, this must be done through a pure phase-safe function owned by `GamePhaseController` operating on the same working state. `AIBotController` must never call `GameStateManager`.

The public facade method `GameStateManager.end_market_for_player(player_id)` delegates to that same GamePhaseController function for UI-originated requests.

AI must not directly advance phase.

### 8.7. End AI Action Flow

AI ends Action by setting:

```gdscript id="cz1p0e"
player["action_done"] = true
```

Inside logic, this must be done through a pure phase-safe function owned by `GamePhaseController` operating on the same working state. `AIBotController` must never call `GameStateManager`.

The public facade method `GameStateManager.end_action_for_player(player_id)` delegates to that same GamePhaseController function for UI-originated requests.

AI must not directly advance phase.

## 9. API Expectations

### 9.1. AIBotController.gd

Required file:

```text id="y748hv"
res://logic/ai/AIBotController.gd
```

Required API:

```gdscript id="qasbuo"
class_name AIBotController

static func setup_ai_bosses(state: Dictionary) -> Dictionary:
	return {}

static func run_market_for_ai(state: Dictionary, player_id: String) -> Dictionary:
	return {}

static func run_action_for_ai(state: Dictionary, player_id: String) -> Dictionary:
	return {}

static func get_ai_boss_state(state: Dictionary, player_id: String) -> Dictionary:
	return {}

static func get_ai_profile(profile_id: String) -> AIProfileDefinition:
	return null
```

### 9.2. AIPurchaseLogic.gd

Required file:

```text id="e2585w"
res://logic/ai/AIPurchaseLogic.gd
```

Recommended API:

```gdscript id="4j9gnl"
class_name AIPurchaseLogic

static func build_purchase_candidates(state: Dictionary, player_id: String, profile: AIProfileDefinition) -> Dictionary:
	return {}

static func score_purchase_candidate(state: Dictionary, player: Dictionary, card_id: String, profile: AIProfileDefinition) -> Dictionary:
	return {}

static func choose_purchase_candidate(state: Dictionary, candidates: Array[Dictionary]) -> Dictionary:
	return {}

static func apply_market_fallback(state: Dictionary, player_id: String, profile: AIProfileDefinition) -> Dictionary:
	return {}
```

### 9.3. AITargetLogic.gd

Required file:

```text id="2u5c48"
res://logic/ai/AITargetLogic.gd
```

Recommended API:

```gdscript id="hfcgnq"
class_name AITargetLogic

static func score_target(state: Dictionary, attacker_id: String, target_id: String, profile: AIProfileDefinition) -> Dictionary:
	return {}

static func get_valid_targets_for_ai(state: Dictionary, attacker_id: String) -> Array[String]:
	return []

static func choose_target(state: Dictionary, attacker_id: String, target_ids: Array[String], profile: AIProfileDefinition) -> Dictionary:
	return {}
```

### 9.4. AIFallbackLogic.gd

Required file:

```text id="5pnvmr"
res://logic/ai/AIFallbackLogic.gd
```

Recommended API:

```gdscript id="u1k6yh"
class_name AIFallbackLogic

static func apply_market_fallback(state: Dictionary, player_id: String, profile: AIProfileDefinition) -> Dictionary:
	return {}

static func apply_action_fallback(state: Dictionary, player_id: String, profile: AIProfileDefinition, context: Dictionary) -> Dictionary:
	return {}
```

### 9.5. AIActionLogic.gd

Recommended optional file if `AIBotController.gd` approaches 250 lines:

```text id="m8hvj9"
res://logic/ai/AIActionLogic.gd
```

Recommended API:

```gdscript id="3e99px"
class_name AIActionLogic

static func build_attack_options(state: Dictionary, player_id: String, profile: AIProfileDefinition) -> Dictionary:
	return {}

static func choose_attack_option(state: Dictionary, options: Array[Dictionary]) -> Dictionary:
	return {}

static func build_payload_from_option(option: Dictionary) -> Dictionary:
	return {}
```

### 9.6. AI Setup Result Shape

```gdscript id="h5bgn7"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"ai_bosses": [
		{
			"profile_id": "builder",
			"is_strong": false,
			"assigned_player_id": "ai_1"
		}
	],
	"strong_ai_player_id": "ai_2",
	"random": {},
	"state": {}
}
```

### 9.7. AI Market Result Shape

```gdscript id="gjggl1"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "ai_1",
	"profile_id": "builder",
	"purchases": [
		{
			"card_id": "stash",
			"price": 8,
			"score": 100
		}
	],
	"fallback_used": "",
	"state": {},
	"log_entries": []
}
```

### 9.8. AI Action Result Shape

```gdscript id="rr9ioh"
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "ai_1",
	"profile_id": "racketeer",
	"attack_roll": 0.42,
	"attack_probability": 0.8,
	"attacks": [
		{
			"target_id": "player_1",
			"card_id": "thug",
			"mode": "",
			"modifiers": [],
			"success": true,
			"blocked": false
		}
	],
	"fallback_used": "",
	"state": {},
	"log_entries": []
}
```

## 10. Edge Cases

| Edge Case                                   | Condition                                                 | Expected Behavior                                                 | Error Code                                       | Mutation Rule                                       |
| ------------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------ | --------------------------------------------------- |
| No AI players                               | Less than 3 AI players exist.                             | Setup validation fails.                                           | `INVALID_AI_STATE`      | No AI setup mutation.                               |
| More than one strong AI                     | Multiple AI have `is_strong_ai == true`.                  | Validation fails.                                                 | `INVALID_AI_STATE`      | No safe continuation.                               |
| No strong AI                                | No AI has `is_strong_ai == true`.                         | Validation fails.                                                 | `INVALID_AI_STATE`      | No safe continuation.                               |
| Duplicate AI profile assignment             | Same profile assigned to multiple AI.                     | Validation fails.                                                 | `INVALID_AI_STATE`      | No safe continuation.                               |
| Unknown profile ID                          | AIBossState references missing profile.                   | Validation fails.                                                 | `INVALID_AI_PROFILE_ID` | No safe continuation.                               |
| AI has no purchase candidates               | Normal candidate list empty.                              | Apply Market fallback.                                            | `OK`                                             | Mutation only if fallback purchase succeeds.        |
| AI cannot preserve reserve                  | All purchases would violate reserve.                      | No normal purchase.                                               | `OK`                                             | No purchase mutation.                               |
| `buy_cheapest_valid` fallback no valid card | No valid reserve-safe card.                               | End Market.                                                       | `OK`                                             | Mark ready only.                                    |
| Purchase tie                                | Equal highest purchase score.                             | Use deterministic `SeededPicker`.                                 | `OK`                                             | Random state mutates only for tie-break.            |
| AI purchase fails unexpectedly              | Candidate passed preview but buy fails.                   | Skip candidate and continue or end safely.                        | Purchase error in result                         | Failed purchase must not mutate state.              |
| AI has no War cards                         | AI Action starts with empty hand.                         | End Action.                                                       | `OK`                                             | Set action done only.                               |
| Attack probability fails                    | Roll is greater than probability.                         | End Action; fallback cannot force attack.                         | `OK`                                             | Random state and action_done mutate.                |
| No unblocked attack options                 | AI passed probability but all attacks blocked or invalid. | Apply Action fallback.                                            | `OK`                                             | Depends on fallback.                                |
| Target score tie                            | Equal highest target score.                               | Use deterministic `SeededPicker`.                                 | `OK`                                             | Random state mutates.                               |
| Insider in hand without Thug                | AI has Insider but no Thug.                               | Insider is not played.                                            | `OK`                                             | No mutation.                                        |
| Thug into Cops without Insider              | Target has Cops, AI lacks Insider.                        | Avoid if unblocked options exist.                                 | `OK`                                             | No mutation unless fallback permits blocked attack. |
| Saboteur target has no Engine cards         | No valid engine target.                                   | Do not build Saboteur option.                                     | `OK`                                             | No mutation.                                        |
| Federal Raid target has no District         | No valid district target.                                 | Do not build option.                                              | `OK`                                             | No mutation.                                        |
| Fallback discard_action_cards               | No useful action options and fallback matches.            | Discard War cards with no valid unblocked attack option.          | `OK`                                             | Mutates hand through CombatEngine discard API.      |
| Turf Level 6 AI War discount                | AI buys first War card each round.                        | PriceLogic applies discount and consumes turf flag after success. | `OK`                                             | PriceLogic/MarketLogic mutation.                    |
| Turf Level 9 human not leading              | Human tied or behind in VP.                               | No War weight multiplier.                                         | `OK`                                             | No profile mutation.                                |
| Turf Level 9 human leading                  | Human strictly leads VP.                                  | AI War purchase scores ×1.2.                                      | `OK`                                             | Candidate score only; Resource unchanged.           |

## 11. Required Source Files

Required files:

```text id="u4fq9u"
res://logic/ai/AIBotController.gd
res://logic/ai/AIPurchaseLogic.gd
res://logic/ai/AITargetLogic.gd
res://logic/ai/AIFallbackLogic.gd
res://data/resources/ai_profiles/AIProfileDefinition.gd
res://data/resources/ai_profiles/builder.tres
res://data/resources/ai_profiles/racketeer.tres
res://data/resources/ai_profiles/merchant_ai.tres
res://data/resources/ai_profiles/paranoid.tres
res://data/resources/ai_profiles/schemer.tres
res://data/resources/ai_profiles/avenger.tres
```

Recommended constants file:

```text id="muj24w"
res://data/ids/AIProfileIds.gd
```

Recommended optional helper files:

```text id="dn5bop"
res://logic/ai/AIActionLogic.gd
res://logic/ai/AISetupLogic.gd
res://logic/ai/AIScoreUtils.gd
```

Related files:

```text id="adpbvh"
res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/economy/MarketLogic.gd
res://logic/economy/PriceLogic.gd
res://logic/combat/CombatEngine.gd
res://logic/random/SeededRandom.gd
res://logic/random/SeededPicker.gd
res://logic/turf_levels/TurfLevelLogic.gd
res://autoload/GameStateManager.gd
```

Each source file must stay under:

```text id="snux5g"
250 lines
```

If `AIBotController.gd` approaches the limit, split setup, purchase, action, target scoring, and fallback logic.

## 12. Required GUT Tests

Recommended test file:

```text id="oy2t2c"
res://tests/unit/test_ai_bot_controller.gd
```

Recommended additional files:

```text id="80amp0"
res://tests/unit/test_ai_purchase_logic.gd
res://tests/unit/test_ai_target_logic.gd
res://tests/unit/test_ai_action_logic.gd
```

### 12.1. AI Profile Tests

Minimum tests:

* all 6 AI profile Resources exist;
* every profile has valid ID;
* every profile has `purchase_scores`;
* every profile has `attack_probability`;
* every profile has `target_weights`;
* every profile has `minimum_reserve_nal`;
* every profile has valid fallback;
* no duplicate AI profile IDs exist;
* `merchant_ai.tres` has `id == "merchant"`.

### 12.2. AI Setup Tests

Minimum tests:

* exactly three AI players exist;
* one strong AI is selected;
* strong AI selection is deterministic with same seed;
* different random step may select different strong AI;
* exactly three unique AI profiles are assigned;
* profile assignment is deterministic with same seed;
* profiles are assigned to `ai_1`, `ai_2`, `ai_3` in selected order;
* `state["ai_bosses"]` matches player strong flags;
* Turf Level 2 gives strong AI +1 VP after strong AI selection.

### 12.3. AI Market Tests

Minimum tests:

* AI buys valid card with highest purchase score;
* AI does not buy card outside market;
* AI does not buy card it cannot afford;
* AI respects one-copy-per-card-ID-per-round;
* AI respects `minimum_reserve_nal`;
* AI can buy multiple cards in one Market phase;
* AI re-evaluates after each purchase;
* equal purchase score tie-break uses deterministic `SeededPicker`;
* missing purchase score counts as 0;
* AI ends Market when no candidate exists;
* `buy_cheapest_valid` fallback buys cheapest reserve-safe valid card;
* fallback does not bypass validation;
* failed purchase does not mutate state;
* Turf Level 9 applies +20% War weight only when human strictly leads VP.

### 12.4. AI Target Tests

Minimum tests:

* target score includes VP lead value;
* target score includes available Nal value;
* target score accounts for protected Nal;
* target score includes low defense value;
* target score includes destructible buildings value;
* target score includes revenge value;
* target score includes human bias value;
* AI excludes itself as target;
* equal target score tie-break uses deterministic `SeededPicker`.

### 12.5. AI Action Tests

Minimum tests:

* AI makes one attack probability roll at start of Action;
* failed attack probability roll ends Action;
* fallback does not override failed attack probability;
* passed attack probability allows attacks;
* AI can play multiple War cards in one Action;
* AI re-evaluates after each attack;
* AI stops when no valid unblocked attack remains;
* unused War cards remain in hand;
* AI uses CombatEngine for attack resolution;
* AI does not mutate combat state directly.

### 12.6. AI Combat Option Tests

Minimum tests:

* AI builds valid `thug` payload;
* AI avoids `thug` into active Cops if no Insider and unblocked options exist;
* AI uses `insider` with `thug` against active Cops when beneficial;
* AI never uses `insider` as primary card;
* AI builds `bruiser destroy_stash` when valid and unblocked;
* AI falls back to `bruiser steal_nal` when destroy is invalid or blocked;
* AI builds `cleaner destroy_workshop` when valid and unblocked;
* AI falls back to `cleaner steal_nal` when destroy is invalid or blocked;
* AI builds `federal_raid destroy_district` only against valid target;
* AI selects Saboteur engine target by priority `brothel`, `laundry`, `accountant`, `informant`;
* AI avoids blocked attacks if unblocked options exist.

### 12.7. AI Fallback Tests

Minimum tests:

* `end_phase` ends phase participation;
* `hold_nal` ends Market without purchase;
* `buy_cheapest_valid` buys cheapest valid reserve-safe card;
* `discard_action_cards` discards War cards with no valid unblocked attack option;
* `attack_best_target` allows best blocked attack only after attack probability passed and no unblocked option exists;
* fallback never bypasses MarketLogic or CombatEngine validation.

### 12.8. Integration Tests

Minimum tests:

* full setup assigns AI profiles and strong AI deterministically;
* full Market phase can run AI purchases for all three AI;
* full Action phase can run AI actions in player array order after human;
* AI purchase uses PriceLogic including Turf Level modifiers;
* AI attack uses CombatEngine including defense rules;
* AI does not receive human roles;
* AI does not receive contracts in MVP;
* AI does not choose Street Deals in MVP;
* no AI logic exists in UI files;
* no forbidden random APIs exist in AI logic files.

## 13. Static Scan Requirements

Static scan must fail if AI logic contains:

```text id="4vprxz"
randf(
randi(
randomize(
RandomNumberGenerator
```

Allowed deterministic random owners:

* `SeededRandom.gd`;
* `SeededPicker.gd`.

Static scan must fail if AI implementation:

* reads or writes UI nodes;
* lives inside UI scene scripts;
* parses AI profile display text as gameplay logic;
* mutates AI profile Resource data at runtime;
* changes card prices directly;
* places purchased cards directly;
* resolves combat effects directly;
* bypasses MarketLogic validation;
* bypasses CombatEngine validation;
* gives AI human roles in MVP;
* gives AI contracts in MVP;
* makes AI choose Street Deals in MVP;
* advances phase directly without phase-safe API.

Allowed dependencies:

* `GameIds`
* `AIProfileIds`
* `ValidationErrors`
* `PhaseIds`
* `SeededRandom`
* `SeededPicker`
* `AIProfileDefinition`
* `MarketLogic`
* `PriceLogic`
* `CombatEngine`
* `TurfLevelLogic`
* `GameStateValidator`

## 14. Implementation Notes For LLM Agents

When implementing AI:

* Do not change AI profile IDs.
* Do not change AI profile scores.
* Do not change attack probabilities.
* Do not change reserves.
* Do not change fallbacks.
* Do not rename `merchant` AI profile ID.
* Select strong AI through deterministic `SeededPicker`.
* Assign 3 unique profiles through deterministic `SeededPicker`.
* Assign selected profiles to AI players in order `ai_1`, `ai_2`, `ai_3`.
* AI may buy multiple cards in Market.
* AI must respect reserve.
* AI must respect all MarketLogic validation.
* Use `SeededPicker` for equal purchase score tie-breaks.
* Roll attack probability once per AI Action turn.
* Do not let fallback override a failed attack probability roll.
* AI may play multiple War cards after a passed attack roll.
* Use `SeededPicker` for equal target score tie-breaks.
* Use CombatEngine previews and validation before resolving attacks.
* Use `insider` only with `thug` against active Cops.
* Use Saboteur engine target priority exactly as defined.
* Do not give AI roles.
* Do not give AI contracts.
* Do not make AI choose Street Deals in MVP.
* Do not write AI logic in UI.
* Do not use forbidden random APIs.
* Keep every source file under 250 lines.
* Add or update GUT tests with implementation.

If a future AI rule is unclear, do not invent behavior. Add it to:

```text id="hwbj7v"
21_OPEN_QUESTIONS_AND_FIXES.md
```

## 15. Acceptance Criteria

This module is complete when:

* all 6 AI profile Resources exist;
* AI profile IDs are stable;
* exactly one strong AI is selected deterministically;
* 3 unique AI profiles are assigned deterministically;
* `state["ai_bosses"]` is valid;
* AI Market decisions use profile purchase scores;
* AI Market tie-breaks use deterministic `SeededPicker`;
* AI can buy multiple cards while respecting reserve;
* AI fallback behavior is implemented and tested;
* AI attack probability uses one deterministic roll per Action turn;
* AI fallback does not override failed attack probability;
* AI target scoring uses all profile target weights;
* AI target tie-breaks use deterministic `SeededPicker`;
* AI attack payloads are valid CombatEngine payloads;
* AI uses `insider` only as a valid `thug` modifier;
* AI chooses Saboteur engine targets deterministically;
* AI avoids blocked attacks when unblocked options exist;
* AI uses MarketLogic for purchases;
* AI uses CombatEngine for attacks;
* AI does not receive roles in MVP;
* AI does not receive contracts in MVP;
* AI does not choose Street Deals in MVP;
* AI logic does not use UI nodes;
* AI logic does not use forbidden random APIs;
* all required GUT tests pass.

## 16. Final Rule

AI may choose actions, but it must never bypass the same validated game rules used by the human player.
