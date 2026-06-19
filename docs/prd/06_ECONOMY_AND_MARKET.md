Economy and Market
Document Role

This file defines only: starting resources, income resolution, price calculation, price modifiers, market generation, purchase validation, purchase resolution, Cops upkeep, rebuild pricing, and economy-related edge cases for The Turf.

This file must not redefine:

card effects outside economy and purchase placement;
combat resolution details;
role definitions beyond economy modifiers;
contract completion rules;
Street Deal option definitions;
contact definitions;
AI scoring;
UI behavior;
phase transition logic;
random algorithm implementation.

Source of truth dependencies:

00_INDEX.md
02_CORE_LOOP_AND_PHASES.md
03_IDS_AND_CONSTANTS.md
04_GAME_STATE_SCHEMA.md
05_CARDS_DATABASE.md
08_ROLES.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md
12_TURF_LEVELS.md
13_AI_SYSTEM.md
14_DETERMINISTIC_RANDOM.md
16_GAME_STATE_MANAGER_API.md
18_TEST_PLAN.md
20_LLM_AGENT_RULES.md
21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

Godot 4.6.2
GDScript
.tres Resources
GUT tests
1. Purpose

The economy system controls how players gain Nal, spend Nal, buy cards, apply price modifiers, maintain certain defenses, and interact with the shared market.

The market system controls which cards are available each round and whether a player is allowed to buy a card.

This file is the source of truth for:

- starting Nal;
- starting Victory Points;
- income calculation;
- price calculation;
- card purchase validation;
- purchase resolution;
- market composition;
- market generation;
- Cops upkeep;
- District Control rebuild pricing;
- economy-related edge cases;
- economy-related tests.
2. Core Economy Terms
2.1. Nal

Nal is the main spendable resource.

Players use Nal to:

- buy cards;
- pay some Street Deal costs;
- repay debts;
- pay Cops upkeep;
- meet some contract conditions.

Nal must never be negative.

If an effect would reduce Nal below 0, clamp it to:

0

unless another system explicitly defines a different behavior.

2.2. Victory Points

Victory Points are the main scoring resource.

Status cards grant Victory Points.

Victory Points must never be negative.

If an effect would reduce Victory Points below 0, clamp them to:

0

unless another system explicitly defines a different behavior.

3. Starting Values

Default starting values:

const STARTING_NAL := 5
const STARTING_VP := 0

Each player starts with:

nal = 5
vp = 0

Role and Turf Level effects may modify starting Nal or starting Victory Points.

The application order is:

1. Apply base starting values.
2. Apply role starting values.
3. Apply Turf Level starting modifiers.
4. Apply strong AI starting modifiers.
5. Apply initial defense or status setup.
6. Validate final state.

Role rules are defined in:

08_ROLES.md

Turf Level rules are defined in:

12_TURF_LEVELS.md
4. Income Phase Overview

Income is resolved during:

PhaseIds.INCOME

Income must be resolved once per player per round.

Income order is defined in:

02_CORE_LOOP_AND_PHASES.md

Detailed income logic is owned by:

IncomeLogic.gd
5. Income Resolution Order

For each player, Income must resolve in this exact order:

1. Start income_total at 0.
2. Add +2 Nal for each Laundry.
3. Roll 2d6 through SeededRandom.
4. Add the 2d6 sum to income_total.
5. Add +1 Nal for each Informant.
6. If the 2d6 roll is a double and the player has Brothel, add Brothel bonus.
7. If black_cash contact is active, Brothel bonus is +6 instead of +5.
8. Add income_total to player["nal"].
9. Process Cops upkeep.
10. Process active debts.
11. Update income-related contract checks.
12. Append `INCOME_RESOLVED` and any due `COPS_UPKEEP_PAID`, `COPS_DEACTIVATED`, debt, and contract events in resolution order.
13. Validate state.

This order must not be changed.

ASSUMPTION: the 2d6 sum is included in Income. This is the canonical MVP interpretation because the existing Income roll otherwise has no economic effect beyond the doubles check.

6. Income Formula
6.1. Base Formula
income_total =
	dice_sum
	+ (laundries * 2)
	+ informers
	+ brothel_bonus_if_doubles

Canonical calculation rules:

- all inputs and the result are integers;
- `dice_sum` is the sum of two deterministic d6 values and is in `2..12`;
- `laundries`, `informers`, and their contributions are non-negative;
- `brothel_bonus_if_doubles` is `0`, `5`, or `6`;
- `black_cash` replaces the Brothel bonus `5` with `6`; it is not an additional `+1` applied after another Income modifier;
- no other role, Turf Level, debt, or temporary price modifier changes `income_total` in MVP;
- no rounding is performed;
- no explicit minimum or maximum clamp is applied to `income_total`;
- `income_total` is calculated once per player per Income phase in canonical player order.

The result is not stored in a separate GameState field. It is added once to `player["nal"]`, returned as `total_income`, and recorded in `LogEventTypes.INCOME_RESOLVED`.

Income errors use canonical codes:

| Condition | Error |
| --- | --- |
| No active game | `GAME_NOT_STARTED` |
| Current phase is not Income | `INVALID_PHASE` |
| Invalid player ID | `INVALID_PLAYER_ID` |
| Invalid random state | `INVALID_RANDOM_STATE` |
| Invalid input or final GameState | `INVALID_STATE` |

Any Income error aborts the complete `advance_phase` transaction; no player Income, random step, log entry, Market state, or phase field is committed.
6.2. Laundry Income

Each Laundry gives:

+2 Nal

Runtime field:

player["engine"]["laundries"]

Calculation:

var laundry_income: int = player["engine"]["laundries"] * 2
6.3. Informant Income

Each Informant gives:

+1 Nal

Runtime field:

player["engine"]["informers"]

Calculation:

var informant_income: int = player["engine"]["informers"]
6.4. Brothel Income

Brothel gives bonus Nal only if the Income 2d6 roll is a double.

Default Brothel bonus:

+5 Nal

If the player has the black_cash contact unlocked:

+6 Nal

Runtime field:

player["engine"]["brothel"]

Contact rules are defined in:

11_CONTACTS.md
6.5. Dice Roll Requirement

Income dice must be rolled through deterministic random only.

Forbidden:

randf()
randi()
randomize()
RandomNumberGenerator

Required owner:

SeededRandom.gd

Random rules are defined in:

14_DETERMINISTIC_RANDOM.md
7. Income Result Shape

IncomeLogic.gd should return a structured result.

Recommended shape:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "",
	"dice": [1, 1],
	"is_double": true,
	"laundry_income": 0,
	"informant_income": 0,
	"brothel_income": 0,
	"total_income": 0,
	"cops_upkeep_result": {},
	"debt_results": [],
	"contract_results": [],
	"log_entries": [],
	"state": {}
}
8. Price System Overview

Price calculation is owned by:

PriceLogic.gd

PriceLogic must calculate the final purchase price for a card.

Final price may be affected by:

- base card price;
- card-specific scaling;
- role modifiers;
- Turf Level modifiers;
- temporary modifiers;
- rebuild pricing;
- minimum price rules.

PriceLogic must not:

- mutate player state;
- remove Nal;
- add cards;
- resolve combat;
- run AI decisions;
- access UI nodes;
- use random.
9. Base Prices

Base prices are defined in:

05_CARDS_DATABASE.md

Fixed base prices:

Card ID	Base Price
informant	5
laundry	8
accountant	4
brothel	6
stash	8
workshop	12
district_control	15
cops	2
cartel	6
judge	3
thug	2
bruiser	5
cleaner	9
insider	3
saboteur	6
federal_raid	14

These values must not be changed during MVP implementation.

10. Informant Price Scaling

Informant price scales by the number of Informants already owned by the player.

Runtime field:

player["engine"]["informers"]

Required function:

static func get_informant_price(player: Dictionary) -> int:
	var count: int = player["engine"]["informers"]
	if count == 0:
		return 5
	if count == 1:
		return 6
	return 7

Price table:

Owned Informants	Price
0	5
1	6
2+	7
11. Laundry Price Scaling

Laundry price scales by the number of Laundries already owned by the player.

Runtime field:

player["engine"]["laundries"]

Required function:

static func get_laundry_price(player: Dictionary) -> int:
	var count: int = player["engine"]["laundries"]
	if count == 0:
		return 8
	if count == 1:
		return 10
	return 12

Price table:

Owned Laundries	Price
0	8
1	10
2+	12
12. Accountant Protection

Accountant protects Nal from theft.

Runtime field:

player["engine"]["accountants"]

Required function:

static func get_protected_nal(accountants: int) -> int:
	if accountants <= 0:
		return 0
	if accountants == 1:
		return 4
	if accountants == 2:
		return 6
	return 6 + (accountants - 2)

Protection table:

Accountants	Protected Nal
0	0
1	4
2	6
3	7
4	8
N	6 + (N - 2) for N > 2

Combat uses this value when resolving Nal theft.

Combat rules are defined in:

07_COMBAT_SYSTEM.md
13. Minimum Price Rule

Unless a specific rule says otherwise, final card price must not go below:

1

Recommended helper:

static func clamp_price(price: int, min_price: int = 1) -> int:
	return max(price, min_price)

This applies to:

role discounts;
Street Deal discounts;
temporary modifiers;
Turf Level modifiers.
14. Role Price Modifiers

Role price modifiers are defined in:

08_ROLES.md

PriceLogic must support role modifiers but must not define role identity here.

Known role-related economy effects:

- Merchant: first Engine card is cheaper by 1.
- Merchant: first War card each round is more expensive by 1.
- Enforcer: first War card is cheaper by 1.
- Enforcer: all Laundries are more expensive by 1.
- Gray Cardinal: first Saboteur is cheaper by 1.
- Gray Cardinal: first Stash is more expensive by 1.
- District Boss: first Stash is cheaper by 2.
- District Boss: District Control rebuild costs 7 instead of 8.
- District Boss: first Laundry is more expensive by 1.

Role flags are defined in:

04_GAME_STATE_SCHEMA.md
08_ROLES.md
15. Turf Level Economy Modifiers

Turf Level rules are defined in:

12_TURF_LEVELS.md

Economy-related Turf Level effects:

Turf Level	Economy Effect	Owner
1	All AI start with +1 Nal	GameStateFactory / Setup
3	Human starts with -1 Nal after role, minimum 3	GameStateFactory / Setup
4	Rotating market has 3 cards instead of 4	MarketLogic
5	Human Cops upkeep interval is every 2 rounds instead of 3	IncomeLogic
6	First War card bought by each AI each round is cheaper by 1	PriceLogic
8	Human Street Deal payments increase by +1	StreetDealLogic / PriceLogic for previews
9	If human leads in VP, AI War purchase weight increases by 20%	AIPurchaseLogic

This file owns only the economy implementation impact, not the Turf Level definitions.

16. Temporary Modifiers

Temporary modifiers are stored in:

player["temporary_modifiers"]

Temporary modifier schema is defined in:

04_GAME_STATE_SCHEMA.md

PriceLogic must support these modifier types:

- CARD_PRICE_DELTA
- NEXT_DEFENSE_CARD_PRICE_DELTA
- NEXT_WAR_CARD_PRICE_DELTA
- NEXT_STATUS_CARD_PRICE_DELTA
16.1. Temporary Modifier Processing Order

When calculating price:

1. Start with base or scaled card price.
2. Apply rebuild override if applicable.
3. Apply role modifiers.
4. Apply Turf Level modifiers.
5. Apply temporary modifiers.
6. Clamp to minimum price.
16.2. Consuming Temporary Modifiers

If a modifier has:

expires_at == "next_purchase"

then after a matching purchase:

modifier["consumed"] = true

Consumed modifiers must be removed at the next cleanup point.

Recommended cleanup points:

- after purchase resolution;
- at end of Market Phase;
- at round start.
17. Final Price Result Shape

PriceLogic should return a structured result.

Recommended shape:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"card_id": "",
	"base_price": 0,
	"scaled_price": 0,
	"modifiers": [],
	"final_price": 0
}

Example modifier entry:

{
	"source": "",
	"type": "",
	"delta": 0,
	"multiplier": 1.0,
	"description": ""
}
18. Market Overview

Market logic is owned by:

MarketLogic.gd

The market is shared by all players.

Runtime field:

state["market"]

MarketState schema is defined in:

04_GAME_STATE_SCHEMA.md
19. Market Composition
19.1. Always Available Cards

The following cards are always available:

const ALWAYS_AVAILABLE_CARD_IDS := [
	GameIds.CARD_INFORMANT,
	GameIds.CARD_STASH,
	GameIds.CARD_THUG,
	GameIds.CARD_COPS
]
19.2. Rotating Market Pool

The rotating market pool contains:

const ROTATING_MARKET_POOL := [
	GameIds.CARD_LAUNDRY,
	GameIds.CARD_ACCOUNTANT,
	GameIds.CARD_BROTHEL,
	GameIds.CARD_WORKSHOP,
	GameIds.CARD_DISTRICT_CONTROL,
	GameIds.CARD_CARTEL,
	GameIds.CARD_JUDGE,
	GameIds.CARD_BRUISER,
	GameIds.CARD_CLEANER,
	GameIds.CARD_INSIDER,
	GameIds.CARD_SABOTEUR,
	GameIds.CARD_FEDERAL_RAID
]
19.3. Market Pool Rule

Always available cards and rotating market cards must not overlap.

The market must never contain duplicate card IDs.

20. Rotating Slot Count

Default rotating slots:

4

At Turf Level 4 or higher:

3

Required helper:

static func get_rotating_slot_count(turf_level: int) -> int:
	if turf_level >= 4:
		return 3
	return 4
21. Market Generation

Market generation must be deterministic.

Required function shape:

static func generate_market(state: Dictionary) -> Dictionary:
	return {}

Recommended return shape:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"market": {},
	"random": {},
	"log_entries": []
}
21.1. Generation Rules

Market generation must:

- use the current round;
- use the current Turf Level;
- include all always available cards;
- pick unique cards from the rotating market pool;
- use SeededPicker for rotating selection;
- update state["random"];
- produce no duplicates;
- validate all card IDs.
21.2. Required Market Shape
{
	"round": state["round"],
	"always_available_card_ids": ALWAYS_AVAILABLE_CARD_IDS,
	"rotating_card_ids": [],
	"all_available_card_ids": []
}
21.3. Random State Rule

Market generation must not derive random only from:

game_seed + round

Instead, it must use the unified random state contract:

- accept state["random"];
- call SeededPicker;
- return updated random state;
- store updated random state back into state["random"].

Random rules are defined in:

14_DETERMINISTIC_RANDOM.md
22. Purchase Validation

Purchase validation is owned by:

MarketLogic.gd

Required function:

static func can_buy_card(state: Dictionary, player_id: String, card_id: String) -> Dictionary:
	return {}

A card can be bought only if all conditions are true:

- current phase is Market;
- player_id is valid;
- card_id is valid;
- card_id exists in state["market"]["all_available_card_ids"];
- player has enough Nal for the final price;
- player has not bought this card_id this round;
- card-specific requirements are met;
- card limit is not reached;
- state is valid.
23. Purchase Validation Errors
Condition	Error
Not Market Phase	INVALID_PHASE
Invalid player ID	INVALID_PLAYER_ID
Invalid card ID	INVALID_CARD_ID
Card not in market	CARD_NOT_AVAILABLE_IN_MARKET
Not enough Nal	NOT_ENOUGH_NAL
Already bought this card this round	CARD_ALREADY_PURCHASED_THIS_ROUND
Requirement not met	REQUIREMENT_NOT_MET
Card limit reached	CARD_LIMIT_REACHED
Invalid state	INVALID_STATE

Validation error constants are defined in:

03_IDS_AND_CONSTANTS.md
24. Purchase Result Shape

Recommended result shape:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "",
	"card_id": "",
	"price": 0,
	"destination": "",
	"state": {},
	"log_entries": []
}

Failed result shape:

{
	"ok": false,
	"error": ValidationErrors.NOT_ENOUGH_NAL,
	"player_id": "",
	"card_id": "",
	"price": 0,
	"state": {}
}

Failed validation must not mutate state.

25. Purchase Resolution

Purchase resolution is owned by:

MarketLogic.gd

Required function:

static func buy_card(state: Dictionary, player_id: String, card_id: String) -> Dictionary:
	return {}

Purchase resolution must:

1. Validate purchase.
2. Calculate final price.
3. Subtract final price from player["nal"].
4. Apply card placement.
5. Add card_id to player["purchased_this_round"].
6. Consume matching temporary modifiers.
7. Update contracts if purchase triggers progress.
8. Write log entry.
9. Validate state.
10. Return structured result.
26. Card Placement Rules

Card placement is determined by card destination.

Destination values are defined in:

03_IDS_AND_CONSTANTS.md
05_CARDS_DATABASE.md
26.1. Engine Card Placement
Card ID	Runtime Update
informant	player["engine"]["informers"] += 1
laundry	player["engine"]["laundries"] += 1
accountant	player["engine"]["accountants"] += 1
brothel	player["engine"]["brothel"] = true
26.2. Status Card Placement
Card ID	Runtime Update
stash	stash += 1, vp += 1
workshop	workshop += 1, vp += 2
district_control	district_control += 1, vp += 3
26.3. Defense Card Placement
Card ID	Runtime Update
cops	cops_active = true, cops_timer = 0
cartel	cartel_state = active
judge	judge_state = active
26.4. War Card Placement

War cards are added to hand:

player["hand"].append(card_id)

War cards:

thug
bruiser
cleaner
insider
saboteur
federal_raid
27. Card-Specific Purchase Requirements
27.1. District Control Requirement

A player can buy District Control only if:

player["status_buildings"]["district_control"] < player["status_buildings"]["workshop"]

If false, return:

ValidationErrors.REQUIREMENT_NOT_MET
27.2. Brothel Limit

A player can buy Brothel only if:

player["engine"]["brothel"] == false

If false, return:

ValidationErrors.CARD_LIMIT_REACHED
27.3. Cops Limit

A player can buy Cops only if:

player["defense"]["cops_active"] == false

If false, return:

ValidationErrors.CARD_LIMIT_REACHED
27.4. Cartel Limit

A player can buy Cartel only if:

player["defense"]["cartel_state"] != DefenseStates.ACTIVE

If false, return:

ValidationErrors.CARD_LIMIT_REACHED

If Cartel is depleted, buying Cartel sets it back to:

active
27.5. Judge Limit

A player can buy Judge only if:

player["defense"]["judge_state"] != DefenseStates.ACTIVE

If false, return:

ValidationErrors.CARD_LIMIT_REACHED

If Judge is none, buying Judge sets it to:

active
28. Per-Round Purchase Limit

A player cannot buy more than one copy of the same card_id in the same round.

Tracked by:

player["purchased_this_round"]

Validation:

if player["purchased_this_round"].has(card_id):
	return {
		"ok": false,
		"error": ValidationErrors.CARD_ALREADY_PURCHASED_THIS_ROUND
	}

Reset timing is defined in:

02_CORE_LOOP_AND_PHASES.md
04_GAME_STATE_SCHEMA.md
29. District Control Rebuild
29.1. Purpose

Federal Raid can destroy District Control and set:

player["status_buildings"]["can_rebuild_district_for_8"] = true

This unlocks a rebuild purchase rule.

29.2. Rebuild Price

Default rebuild price:

8 Nal

District Boss rebuild price:

7 Nal
29.3. Rebuild Requirements

A player can rebuild District Control only if:

- can_rebuild_district_for_8 == true;
- player has enough Nal;
- current phase is Market;
- District Control ownership requirement is still valid unless explicitly waived by final rules.

Default MVP rule:

Rebuild still requires district_control < workshop.
29.4. Rebuild Resolution

Rebuild resolution must:

1. Validate rebuild.
2. Subtract rebuild price.
3. Add 1 District Control.
4. Add +3 Victory Points.
5. Set can_rebuild_district_for_8 = false.
6. Write log entry.
7. Validate state.
29.5. Rebuild API

Recommended function:

static func rebuild_district_control(state: Dictionary, player_id: String) -> Dictionary:
	return {}

GameStateManager may expose this through a dedicated method or through a special market action.

The public API must be finalized in:

16_GAME_STATE_MANAGER_API.md
30. Cops Upkeep
30.1. Purpose

Cops are a cheap defense card with recurring upkeep.

Runtime fields:

player["defense"]["cops_active"]
player["defense"]["cops_timer"]
30.2. Upkeep Interval

Required function:

static func get_cops_upkeep_interval(state: Dictionary, player: Dictionary) -> int:
	if state["turf_level"] >= 5 and not player["is_ai"]:
		return 2
	return 3

Default interval:

Every 3 Income phases while Cops are active.

At Turf Level 5 or higher, for the human player only:

Every 2 Income phases while Cops are active.
30.3. Upkeep Cost

Cops upkeep cost:

1 Nal

This cost is paid automatically when the upkeep interval is reached.

30.4. Timer Rule

During Income Phase, after income is added:

If cops_active == true:
	Increase cops_timer by 1.
	If cops_timer >= upkeep_interval:
		Resolve upkeep payment.
30.5. Successful Payment

If the player has at least 1 Nal:

- subtract 1 Nal;
- set cops_timer = 0;
- keep cops_active = true;
- append `LogEventTypes.COPS_UPKEEP_PAID`.
30.6. Failed Payment

If the player has less than 1 Nal:

- set cops_active = false;
- set cops_timer = 0;
- append `LogEventTypes.COPS_DEACTIVATED`.

Cops are not stored in hand or refunded.

30.7. Cops Rebuy

If Cops become inactive due to failed upkeep, the player may buy Cops again in a later Market Phase if Cops are available and purchase validation passes.

30.8. Upkeep Result Shape

Recommended shape:

{
	"was_due": false,
	"paid": false,
	"deactivated": false,
	"amount_paid": 0,
	"interval": 3,
	"timer_before": 0,
	"timer_after": 0
}
31. Debt Processing Hook

Debt logic is owned by:

DebtLogic.gd

Debt processing happens during Income after income and Cops upkeep.

Debt rules are defined in:

10_STREET_DEALS_AND_DEBTS.md

IncomeLogic must call DebtLogic but must not implement debt penalties directly unless delegated.

Recommended call:

var debt_result := DebtLogic.process_debts_for_player(state, player["id"])
32. Contract Progress Hooks

Contract logic is owned by:

ContractLogic.gd

Economy-related contract checks may occur after:

- Income resolution;
- purchase resolution;
- debt processing;
- Market Phase completion.

Examples:

- gray_capital checks whether player has 30+ Nal.
- big_cashbox checks whether player has 2 Laundries, 1 Accountant, and 20 Nal.

This file does not define contract completion rules.

Contract rules are defined in:

09_CONTRACTS.md
33. Market Phase Flow

During Market Phase, each player may buy valid cards.

Human flow:

1. Inspect market.
2. Preview final prices.
3. Inspect disabled reasons.
4. Buy valid card.
5. Repeat until done.
6. End Market participation.

AI flow:

1. Evaluate available cards.
2. Calculate final prices.
3. Respect reserve Nal.
4. Buy according to AI profile.
5. End Market participation.

AI purchase behavior is defined in:

13_AI_SYSTEM.md
34. End Market For Player

When a player ends Market participation:

player["ready_for_action"] = true

This is exposed through:

GameStateManager.end_market_for_player(player_id)

UI must not set ready_for_action directly.

Phase rules are defined in:

02_CORE_LOOP_AND_PHASES.md
35. Economy Selectors

GameStateManager should expose read-only economy selectors.

Recommended selectors:

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

Selectors must not mutate state.

36. Disabled Reason Requirements

UI must be able to show exact disabled reasons for purchases.

Common disabled reasons:

- not enough Nal;
- card not available in market;
- already purchased this card this round;
- card requirement not met;
- card limit reached;
- wrong phase.

The selector must return stable error codes from:

ValidationErrors.gd

UI may map error codes to display text later.

37. Economy Edge Cases
37.1. Player Has 0 Nal

Condition:

player["nal"] == 0

Expected behavior:

- player cannot buy cards with price > 0;
- player can still receive income;
- player can still end Market;
- player can still play War cards already in hand.
37.2. Not Enough Nal

Condition:

player["nal"] < final_price

Expected behavior:

- purchase fails;
- return NOT_ENOUGH_NAL;
- state is not mutated.
37.3. Card Not In Market

Condition:

card_id not in state["market"]["all_available_card_ids"]

Expected behavior:

- purchase fails;
- return CARD_NOT_AVAILABLE_IN_MARKET;
- state is not mutated.
37.4. Duplicate Purchase This Round

Condition:

card_id in player["purchased_this_round"]

Expected behavior:

- purchase fails;
- return CARD_ALREADY_PURCHASED_THIS_ROUND;
- state is not mutated.
37.5. District Control Without Workshop

Condition:

player["status_buildings"]["district_control"] >= player["status_buildings"]["workshop"]

Expected behavior:

- buying District Control fails;
- return REQUIREMENT_NOT_MET;
- state is not mutated.
37.6. Brothel Already Owned

Condition:

player["engine"]["brothel"] == true

Expected behavior:

- buying Brothel fails;
- return CARD_LIMIT_REACHED;
- state is not mutated.
37.7. Active Cops Already Owned

Condition:

player["defense"]["cops_active"] == true

Expected behavior:

- buying Cops fails;
- return CARD_LIMIT_REACHED;
- state is not mutated.
37.8. Active Cartel Already Owned

Condition:

player["defense"]["cartel_state"] == DefenseStates.ACTIVE

Expected behavior:

- buying Cartel fails;
- return CARD_LIMIT_REACHED;
- state is not mutated.
37.9. Depleted Cartel Rebuy

Condition:

player["defense"]["cartel_state"] == DefenseStates.DEPLETED

Expected behavior:

- buying Cartel is allowed if other validation passes;
- cartel_state becomes active.
37.10. Active Judge Already Owned

Condition:

player["defense"]["judge_state"] == DefenseStates.ACTIVE

Expected behavior:

- buying Judge fails;
- return CARD_LIMIT_REACHED;
- state is not mutated.
37.11. Cops Upkeep Due With Enough Nal

Condition:

cops_active == true
cops_timer reaches upkeep interval
player["nal"] >= 1

Expected behavior:

- subtract 1 Nal;
- reset cops_timer to 0;
- keep Cops active.
37.12. Cops Upkeep Due Without Nal

Condition:

cops_active == true
cops_timer reaches upkeep interval
player["nal"] < 1

Expected behavior:

- set cops_active = false;
- reset cops_timer to 0;
- write log entry.
37.13. Market Has Duplicate Cards

Condition:

state["market"]["all_available_card_ids"] contains duplicates

Expected behavior:

- state validation fails;
- no purchases should resolve until corrected.
37.14. Price Modifier Would Make Price Negative

Condition:

final_price < 1

Expected behavior:

- clamp final_price to 1.
38. Required Source Files

Economy and market implementation should be split into small files.

Required files:

res://logic/economy/IncomeLogic.gd
res://logic/economy/MarketLogic.gd
res://logic/economy/PriceLogic.gd

Recommended optional helper files if needed:

res://logic/economy/PurchaseValidator.gd
res://logic/economy/PurchaseResolver.gd
res://logic/economy/MarketConstants.gd
res://logic/economy/EconomyLogBuilder.gd

Each source file must stay under:

250 lines

If a file approaches the limit, split it.

Do not create an economy mega-file. Humanity has suffered enough.

39. Required GUT Tests

Recommended test files:

res://tests/unit/test_price_logic.gd
res://tests/unit/test_market_logic.gd
res://tests/unit/test_income_logic.gd
40. PriceLogic Tests

Minimum required tests:

- informant price is 5 when player owns 0 Informants;
- informant price is 6 when player owns 1 Informant;
- informant price is 7 when player owns 2 or more Informants;
- laundry price is 8 when player owns 0 Laundries;
- laundry price is 10 when player owns 1 Laundry;
- laundry price is 12 when player owns 2 or more Laundries;
- accountant protected Nal is 0 with 0 Accountants;
- accountant protected Nal is 4 with 1 Accountant;
- accountant protected Nal is 6 with 2 Accountants;
- accountant protected Nal is 7 with 3 Accountants;
- final price is clamped to minimum 1;
- role modifiers apply in the correct order;
- temporary modifiers apply in the correct order;
- consumed temporary modifiers are marked consumed after matching purchase.
41. MarketLogic Tests

Minimum required tests:

- generated market contains all always available cards;
- generated market has 4 rotating cards below Turf Level 4;
- generated market has 3 rotating cards at Turf Level 4 or higher;
- generated market has no duplicate cards;
- generated market only uses valid card IDs;
- same seed and scripted random state produces same market;
- different random step can produce different rotating cards;
- card outside market returns CARD_NOT_AVAILABLE_IN_MARKET;
- player with insufficient Nal returns NOT_ENOUGH_NAL;
- duplicate purchase in same round returns CARD_ALREADY_PURCHASED_THIS_ROUND;
- District Control without requirement returns REQUIREMENT_NOT_MET;
- Brothel already owned returns CARD_LIMIT_REACHED;
- active Cops already owned returns CARD_LIMIT_REACHED;
- active Cartel already owned returns CARD_LIMIT_REACHED;
- depleted Cartel can be bought and becomes active;
- active Judge already owned returns CARD_LIMIT_REACHED;
- buying Engine card updates engine state;
- buying Status card updates status state and VP;
- buying Defense card updates defense state;
- buying War card adds card_id to hand;
- failed purchase does not mutate state.
42. IncomeLogic Tests

Minimum required tests:

- Laundry adds +2 Nal each;
- Informant adds +1 Nal each;
- 2d6 sum is included exactly once;
- Brothel gives +5 Nal on double;
- Brothel gives no bonus without double;
- black_cash changes Brothel bonus to +6;
- black_cash replaces +5 rather than stacking another +1 modifier;
- Income performs no rounding or total clamp;
- total_income is not stored in a duplicate GameState field;
- INCOME_RESOLVED payload matches the canonical event contract;
- income dice use SeededRandom;
- income updates random.step correctly;
- Cops timer increments when Cops are active;
- Cops upkeep is paid when interval is reached;
- Cops deactivate when upkeep is due and player cannot pay;
- Turf Level 5 changes human Cops interval to 2;
- AI Cops interval remains 3 at Turf Level 5;
- DebtLogic is called after Cops upkeep;
- Nal never becomes negative.
43. Integration Tests

Minimum required integration tests:

- full Income Phase resolves for all 4 players;
- full Market Phase allows all players to buy and end Market;
- Market Phase does not advance until all players are ready;
- purchasing updates contract progress when relevant;
- same seed replay produces same market history;
- same seed replay produces same income dice results;
- no forbidden random APIs exist in economy logic files.
44. Static Scan Requirements

Static scan must fail if economy or market logic contains:

randf(
randi(
randomize(
RandomNumberGenerator

Allowed:

SeededRandom
SeededPicker

Static scan tests are defined in:

18_TEST_PLAN.md
45. Implementation Notes For LLM Agents

When implementing economy and market logic:

- Do not change card prices.
- Do not change card effects.
- Do not change market pools.
- Do not add new cards.
- Do not remove cards.
- Do not rename IDs.
- Do not use forbidden random APIs.
- Do not write gameplay logic in UI.
- Do not parse effect_summary.
- Use constants from 03_IDS_AND_CONSTANTS.md.
- Keep every source file under 250 lines.
- Add or update GUT tests.

If a rule is unclear, do not invent a hidden mechanic.

Add the issue to:

21_OPEN_QUESTIONS_AND_FIXES.md
46. Acceptance Criteria

This system is complete when:

- starting Nal and VP are implemented correctly;
- Income resolves in the required order;
- Laundry income works;
- Informant income works;
- Brothel double bonus works;
- black_cash Brothel modifier works;
- Cops upkeep works;
- DebtLogic is called after upkeep;
- base prices match the card database;
- Informant price scaling works;
- Laundry price scaling works;
- protected Nal calculation works;
- role price modifiers are supported;
- Turf Level economy modifiers are supported;
- temporary modifiers are supported;
- market generation is deterministic;
- always available cards are always present;
- rotating market uses the correct slot count;
- purchase validation returns stable error codes;
- purchase resolution updates the correct runtime fields;
- failed purchases do not mutate state;
- market and economy logic do not use UI nodes;
- market and economy logic do not use forbidden random APIs;
- required GUT tests pass.
47. Final Rule

Economy logic decides whether a player can afford something.

Market logic decides whether a card can be bought.

Neither system may secretly resolve combat, make AI decisions, or write UI behavior.
