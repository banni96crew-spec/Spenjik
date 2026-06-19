# Roles

## Document Role

This file defines only:

role IDs and role Resource data;
role selection rules;
role setup effects;
role runtime flags;
role price modifiers;
role purchase requirement modifiers;
role-specific rebuild pricing;
role reset timing;
role validation rules;
RoleLogic API expectations;
role-related edge cases;
role-related GUT tests.

This file must not redefine:

card prices except role modifiers applied on top of prices;
card effects outside role-specific modifiers;
market generation;
income resolution;
combat resolution;
contract completion rules;
Contact rules;
Street Deal rules;
Turf Level definitions;
AI profiles;
UI behavior;
deterministic random algorithm implementation;
phase transition logic.

Source of truth dependencies:

00_INDEX.md
02_CORE_LOOP_AND_PHASES.md
03_IDS_AND_CONSTANTS.md
04_GAME_STATE_SCHEMA.md
05_CARDS_DATABASE.md
06_ECONOMY_AND_MARKET.md
07_COMBAT_SYSTEM.md
09_CONTRACTS.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md
12_TURF_LEVELS.md
13_AI_SYSTEM.md
14_DETERMINISTIC_RANDOM.md
15_GODOT_ARCHITECTURE.md
16_GAME_STATE_MANAGER_API.md
18_TEST_PLAN.md
20_LLM_AGENT_RULES.md
21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

Godot 4.6.2
GDScript
.tres Resources
Dictionary state snapshots
GameStateManager.gd Autoload
GUT tests

## 1. Purpose

The role system defines the player’s selected gameplay identity for a run.

Roles modify:

starting Nal;
starting defense;
purchase prices;
purchase requirements;
District Control rebuild pricing.

Roles must be deterministic, explicit, and data-driven. They must not be implemented as hidden UI behavior or parsed from text summaries.

In MVP, state["selected_role_id"] applies to the human player only. AI players use AI profiles from 13_AI_SYSTEM.md, not player roles.

## 2. Ownership Boundaries

This file owns:

role IDs;
role definition schema;
selected role setup;
role-specific starting effects;
role-specific price modifiers;
role-specific purchase requirement bypasses;
role-specific runtime flags;
role-specific reset timing;
role-specific validation;
role-related tests.

This file references:

06_ECONOMY_AND_MARKET.md for base prices, final price calculation, card purchase resolution, and District Control rebuild flow;
04_GAME_STATE_SCHEMA.md for selected_role_id, role_flags, and player state fields;
05_CARDS_DATABASE.md for card IDs, types, and base prices;
12_TURF_LEVELS.md for Turf Level setup modifiers;
16_GAME_STATE_MANAGER_API.md for setup and purchase facade calls.

This file does not own:

base card prices;
market availability;
actual card placement after purchase;
final price calculation order outside role modifier insertion;
combat effects;
AI scoring;
UI display text;
random behavior.

## 3. Core Terms

Term	Meaning
Role	Human player run modifier selected before gameplay starts.
Role ID	Stable string ID stored in state["selected_role_id"].
Starting Effect	One-time effect applied during game setup.
Price Modifier	Role effect that changes the final purchase price of a matching card.
Requirement Bypass	Role effect that allows a purchase despite a normal requirement.
Role Flag	Runtime boolean that tracks whether a limited role effect has been used.
Once Per Run	Effect can be used only once during the whole 15-round game.
Once Per Round	Effect can be used once per round and resets at round start.
Human Player	Player with ID GameIds.PLAYER_HUMAN.

## 4. Runtime State

### 4.1. GameState Fields

Field	Type	Owner	Usage
state["selected_role_id"]	String	RoleLogic / setup	Selected human role ID.
state["players"]	Array[Dictionary]	GameStateFactory	Contains human player state to receive role effects.
state["round"]	int	GamePhaseController	Used for per-round role flag reset.
state["current_phase"]	String	GamePhaseController	Role purchase modifiers apply during Market.

### 4.2. PlayerState Fields

RoleLogic reads or mutates these human PlayerState fields:

Field	Type	Usage
player["id"]	String	Must be GameIds.PLAYER_HUMAN for selected role effects.
player["nal"]	int	Modified by starting Nal effects and purchase costs.
player["vp"]	int	Used for Accountant requirement validation.
player["engine"]	Dictionary	Used for Engine ownership and purchase checks.
player["status_buildings"]	Dictionary	Used for Stash and rebuild rules.
player["defense"]	Dictionary	Enforcer starts with active Cops.
player["hand"]	Array[String]	Not directly mutated by RoleLogic.
player["purchased_this_round"]	Array[String]	Used by price modifier checks where needed.
player["role_flags"]	Dictionary	Tracks limited role effects.
player["temporary_modifiers"]	Array[Dictionary]	RoleLogic may read but should not store permanent role effects here.

### 4.3. Role Flags

Required default shape:

static func create_empty_role_flags() -> Dictionary:
	return {
		"merchant_first_engine_discount_used": false,
		"merchant_first_war_tax_applied_this_round": false,
		"enforcer_first_war_discount_used": false,
		"gray_cardinal_first_accountant_bypass_used": false,
		"gray_cardinal_first_saboteur_discount_used": false,
		"gray_cardinal_first_stash_tax_used": false,
		"district_boss_first_stash_discount_used": false,
		"district_boss_first_laundry_tax_used": false,
		"district_boss_rebuild_discount_used": false,
		"used_first_card_discount": false,
		"used_emergency_protection": false,
		"used_one_time_contact_bonus": false
	}

Role-specific ownership:

Flag	Owner	Reset Timing
merchant_first_engine_discount_used	Merchant	Never resets during run.
merchant_first_war_tax_applied_this_round	Merchant	Resets at start of each round before Market.
enforcer_first_war_discount_used	Enforcer	Never resets during run.
gray_cardinal_first_accountant_bypass_used	Gray Cardinal	Never resets during run.
gray_cardinal_first_saboteur_discount_used	Gray Cardinal	Never resets during run.
gray_cardinal_first_stash_tax_used	Gray Cardinal	Never resets during run.
district_boss_first_stash_discount_used	District Boss	Never resets during run.
district_boss_first_laundry_tax_used	District Boss	Never resets during run.
district_boss_rebuild_discount_used	District Boss	Never resets during run.
used_first_card_discount	Shared / legacy-safe helper	Must not replace role-specific flags.
used_emergency_protection	Contact system	Owned by 11_CONTACTS.md.
used_one_time_contact_bonus	Contact system	Owned by 11_CONTACTS.md.

### 4.4. RoleDefinition Resource Schema

Required Resource:

class_name RoleDefinition
extends Resource

@export var id: String
@export var title: String
@export var starting_nal: int = 5
@export var effect_summary: String
@export var limitation_summary: String

Recommended extension for implementation clarity:

@export var applies_to_human_only: bool = true

Gameplay logic must not parse effect_summary or limitation_summary. They are display text only.

### 4.5. Role IDs

Recommended constants for 03_IDS_AND_CONSTANTS.md:

class_name RoleIds

const MERCHANT := "merchant"
const ENFORCER := "enforcer"
const GRAY_CARDINAL := "gray_cardinal"
const DISTRICT_BOSS := "district_boss"

const ALL := [
	MERCHANT,
	ENFORCER,
	GRAY_CARDINAL,
	DISTRICT_BOSS
]

If RoleIds.gd is not created, these exact string IDs must still be used.

## 5. Rules

### 5.1. Role List

Roles must not be changed.

Role ID	Title	Starting / Bonus	Limitation
merchant	Merchant	Starts with 7 Nal; first Engine card is cheaper by 1.	First War card each round is more expensive by 1.
enforcer	Enforcer	Starts with active Cops; first War card is cheaper by 1.	All Laundries are more expensive by 1.
gray_cardinal	Gray Cardinal	Starts with 4 Nal; first Accountant may be bought without 1+ VP; first Saboteur is cheaper by 1.	First Stash is more expensive by 1.
district_boss	District Boss	First Stash is cheaper by 2; District Control rebuild costs 7.	First Laundry is more expensive by 1.

### 5.2. Role Selection Rule

Exactly one role must be selected for the human player before gameplay starts.

Valid values:

merchant
enforcer
gray_cardinal
district_boss

Invalid role IDs must fail setup validation.

Required canonical error code from `03_IDS_AND_CONSTANTS.md`:

const INVALID_ROLE_ID := "INVALID_ROLE_ID"

Setup must return `ValidationErrors.INVALID_ROLE_ID` for an unknown role ID. Fallback error codes are forbidden.

### 5.3. Human-Only Rule

In MVP:

roles apply only to GameIds.PLAYER_HUMAN;
AI players do not receive roles;
AI behavior is defined by AI profiles in 13_AI_SYSTEM.md.

AI must not silently receive role discounts, role starting bonuses, or role limitations.

### 5.4. Setup Application Order

Role setup must be applied during new game setup in this order:

Create base GameState.
Create all four players with base starting values.
Assign state["selected_role_id"].
Apply selected role starting effects to the human player.
Apply Turf Level setup modifiers from 12_TURF_LEVELS.md.
Apply strong AI setup modifiers from 13_AI_SYSTEM.md.
Validate final state.

Role setup must not use random.

### 5.5. Starting Nal Rules

Role ID	Human Starting Nal Before Turf Level Modifiers
merchant	7
enforcer	5
gray_cardinal	4
district_boss	5

Turf Level 3 modifies human starting Nal after role setup:

Human starts with -1 Nal after role, minimum 3.

This Turf Level rule is owned by 12_TURF_LEVELS.md.

### 5.6. Enforcer Starting Cops

If selected role is enforcer, setup must set:

human["defense"]["cops_active"] = true
human["defense"]["cops_timer"] = 0

This does not add a cops card to hand.

This does not add cops to purchased_this_round.

Cops upkeep is still handled by 06_ECONOMY_AND_MARKET.md.

### 5.7. “First” Effects Rule

All role effects that say “first” are once per run unless the rule explicitly says “each round”.

Once per run:

Merchant first Engine card discount;
Enforcer first War card discount;
Gray Cardinal first Accountant requirement bypass;
Gray Cardinal first Saboteur discount;
Gray Cardinal first Stash tax;
District Boss first Stash discount;
District Boss first Laundry tax;
District Boss rebuild discount.

Once per round:

Merchant first War card tax.

### 5.8. Merchant Rules

Role ID:

merchant

#### 5.8.1. Merchant Starting Nal

Merchant starts with:

human["nal"] = 7

before Turf Level modifiers.

#### 5.8.2. Merchant First Engine Discount

The first Engine card bought by Merchant during the run is cheaper by:

-1 Nal

Applies to card type:

engine

Engine cards:

informant
laundry
accountant
brothel

Flag:

player["role_flags"]["merchant_first_engine_discount_used"]

When a matching purchase succeeds:

apply -1 to final price calculation;
clamp final price according to 06_ECONOMY_AND_MARKET.md;
set flag to true.

Failed purchase must not consume the flag.

#### 5.8.3. Merchant First War Tax Each Round

The first War card bought by Merchant each round is more expensive by:

+1 Nal

Applies to card type:

war

War cards:

thug
bruiser
cleaner
insider
saboteur
federal_raid

Flag:

player["role_flags"]["merchant_first_war_tax_applied_this_round"]

When a matching purchase succeeds:

apply +1 to final price calculation;
set flag to true.

Failed purchase must not consume the flag.

This flag resets to false at the start of each round before Market.

### 5.9. Enforcer Rules

Role ID:

enforcer

#### 5.9.1. Enforcer Starting Defense

Enforcer starts with active Cops:

human["defense"]["cops_active"] = true
human["defense"]["cops_timer"] = 0

#### 5.9.2. Enforcer First War Discount

The first War card bought by Enforcer during the run is cheaper by:

-1 Nal

Flag:

player["role_flags"]["enforcer_first_war_discount_used"]

When a matching purchase succeeds:

apply -1 to final price calculation;
clamp final price according to 06_ECONOMY_AND_MARKET.md;
set flag to true.

Failed purchase must not consume the flag.

This effect is once per run and does not reset each round.

#### 5.9.3. Enforcer Laundry Tax

All Laundry purchases by Enforcer are more expensive by:

+1 Nal

Applies to:

laundry

This modifier has no flag and applies every time Enforcer buys Laundry.

### 5.10. Gray Cardinal Rules

Role ID:

gray_cardinal

#### 5.10.1. Gray Cardinal Starting Nal

Gray Cardinal starts with:

human["nal"] = 4

before Turf Level modifiers.

#### 5.10.2. Accountant Base Requirement

Accountant has a base purchase requirement:

player["vp"] >= 1

This requirement is validated by MarketLogic / purchase validation.

If a non-Gray-Cardinal player or a Gray Cardinal without an available bypass attempts to buy Accountant with vp < 1, purchase fails with:

ValidationErrors.REQUIREMENT_NOT_MET

This fixes the previously implicit rule required by Gray Cardinal’s bypass.

#### 5.10.3. Gray Cardinal First Accountant Bypass

Gray Cardinal may buy the first Accountant during the run without the normal vp >= 1 requirement.

Applies only to:

accountant

Condition:

player["vp"] < 1
and player["role_flags"]["gray_cardinal_first_accountant_bypass_used"] == false

If purchase succeeds:

allow the purchase despite vp < 1;
set:
player["role_flags"]["gray_cardinal_first_accountant_bypass_used"] = true

If purchase fails for any other reason:

do not consume the flag.

If Gray Cardinal buys Accountant while already having vp >= 1, the bypass is not needed and should not be consumed.

#### 5.10.4. Gray Cardinal First Saboteur Discount

The first Saboteur bought by Gray Cardinal during the run is cheaper by:

-1 Nal

Applies to:

saboteur

Flag:

player["role_flags"]["gray_cardinal_first_saboteur_discount_used"]

When purchase succeeds:

apply -1;
clamp final price according to 06_ECONOMY_AND_MARKET.md;
set flag to true.

Failed purchase must not consume the flag.

#### 5.10.5. Gray Cardinal First Stash Tax

The first Stash bought by Gray Cardinal during the run is more expensive by:

+1 Nal

Applies to:

stash

Flag:

player["role_flags"]["district_boss_first_stash_discount_used"]

Do not reuse the District Boss flag for Gray Cardinal.

Canonical flag:

Add a separate flag:

"gray_cardinal_first_stash_tax_used": false

The required role flags include:

static func create_empty_role_flags() -> Dictionary:
	return {
		"merchant_first_engine_discount_used": false,
		"merchant_first_war_tax_applied_this_round": false,
		"enforcer_first_war_discount_used": false,
		"gray_cardinal_first_accountant_bypass_used": false,
		"gray_cardinal_first_saboteur_discount_used": false,
		"gray_cardinal_first_stash_tax_used": false,
		"district_boss_first_stash_discount_used": false,
		"district_boss_first_laundry_tax_used": false,
		"district_boss_rebuild_discount_used": false,
		"used_first_card_discount": false,
		"used_emergency_protection": false,
		"used_one_time_contact_bonus": false
	}

When purchase succeeds:

apply +1;
set gray_cardinal_first_stash_tax_used = true.

Failed purchase must not consume the flag.

### 5.11. District Boss Rules

Role ID:

district_boss

#### 5.11.1. District Boss Starting Nal

District Boss uses base starting Nal:

human["nal"] = 5

before Turf Level modifiers.

#### 5.11.2. District Boss First Stash Discount

The first Stash bought by District Boss during the run is cheaper by:

-2 Nal

Applies to:

stash

Flag:

player["role_flags"]["district_boss_first_stash_discount_used"]

When purchase succeeds:

apply -2;
clamp final price according to 06_ECONOMY_AND_MARKET.md;
set flag to true.

Failed purchase must not consume the flag.

#### 5.11.3. District Boss District Control Rebuild Discount

District Boss rebuilds District Control for:

7 Nal

instead of the default:

8 Nal

Applies only when:

player["status_buildings"]["can_rebuild_district_for_8"] == true

The rebuild flow is owned by 06_ECONOMY_AND_MARKET.md.

Flag:

player["role_flags"]["district_boss_rebuild_discount_used"]

This discount is once per run.

If the first eligible rebuild succeeds:

final rebuild price is 7;
set district_boss_rebuild_discount_used = true.

If the flag is already true:

use default rebuild price from 06_ECONOMY_AND_MARKET.md.

Failed rebuild validation must not consume the flag.

#### 5.11.4. District Boss First Laundry Tax

The first Laundry bought by District Boss during the run is more expensive by:

+1 Nal

Applies to:

laundry

Canonical flag:

Add a dedicated flag:

"district_boss_first_laundry_tax_used": false

When purchase succeeds:

apply +1;
set district_boss_first_laundry_tax_used = true.

Failed purchase must not consume the flag.

## 6. Validation Rules

### 6.1. Role ID Validation

Selected role ID must be one of:

merchant
enforcer
gray_cardinal
district_boss

Invalid role ID must return:

ValidationErrors.INVALID_ROLE_ID

### 6.2. Role Setup Validation

Setup validation must verify:

Condition	Error
selected_role_id == ""	INVALID_ROLE_ID
unknown role ID	INVALID_ROLE_ID
human player missing	INVALID_TARGET
role applied to AI	REQUIREMENT_NOT_MET
missing role_flags dictionary	REQUIREMENT_NOT_MET
missing required role flag	REQUIREMENT_NOT_MET

### 6.3. Role Modifier Validation

Role price modifier validation must verify:

Condition	Expected Behavior
Player is not human	No role modifier applies.
Role ID does not match modifier owner	Modifier does not apply.
Matching flag already used	Once-per-run modifier does not apply.
Matching per-round flag already used	Once-per-round modifier does not apply again this round.
Purchase validation fails	Modifier flag is not consumed.
Purchase succeeds	Matching modifier flag is consumed after price is paid and card is placed.

### 6.4. Accountant Requirement Validation

Base Accountant requirement:

player["vp"] >= 1

Exception:

selected_role_id == "gray_cardinal"
and player["role_flags"]["gray_cardinal_first_accountant_bypass_used"] == false

If requirement fails:

ValidationErrors.REQUIREMENT_NOT_MET

### 6.5. Failed Validation Mutation Rule

Failed validation must not mutate:

player["nal"];
player["vp"];
player["defense"];
player["engine"];
player["status_buildings"];
player["hand"];
player["purchased_this_round"];
player["role_flags"];
state["selected_role_id"].

## 7. Resolution / Processing Flow

### 7.1. New Game Role Setup Flow

Role setup must resolve in this order:

Receive setup config with selected_role_id.
Validate selected role ID.
Create base players.
Get human player by GameIds.PLAYER_HUMAN.
Initialize role_flags with RoleLogic.create_empty_role_flags().
Apply role starting Nal.
Apply role starting defense if any.
Store selected role in:
state["selected_role_id"] = selected_role_id
Apply Turf Level setup modifiers.
Validate final GameState.

### 7.2. Price Modifier Flow

Role price modifiers must be applied inside PriceLogic.gd.

Required order inside full price calculation:

Start with base or scaled card price.
Apply rebuild override if applicable.
Apply role modifiers.
Apply Turf Level modifiers.
Apply temporary modifiers.
Clamp to minimum price.

RoleLogic should expose pure preview helpers. It should not subtract Nal.

### 7.3. Purchase Success Flag Consumption Flow

Role flags must be consumed only after a successful purchase or successful rebuild.

Purchase success order:

MarketLogic validates purchase.
PriceLogic calculates final price and includes role modifiers.
MarketLogic subtracts Nal.
MarketLogic places card.
MarketLogic adds card_id to purchased_this_round.
RoleLogic consumes matching role flags.
Temporary modifiers are consumed.
Contract hooks run if needed.
State is validated.
Result is returned.

If any validation fails before step 3, no role flags are consumed.

### 7.4. Round Reset Flow

At the start of each round before Market begins:

player["role_flags"]["merchant_first_war_tax_applied_this_round"] = false

No other role flags reset.

The exact phase reset owner is 02_CORE_LOOP_AND_PHASES.md.

RoleLogic may provide:

static func reset_round_role_flags(player: Dictionary, selected_role_id: String) -> Dictionary:
	return player

## 8. API Expectations

### 8.1. RoleLogic.gd

Required file:

res://logic/roles/RoleLogic.gd

Recommended API:

class_name RoleLogic

static func create_empty_role_flags() -> Dictionary:
	return {}

static func is_valid_role_id(role_id: String) -> bool:
	return false

static func apply_role_setup(state: Dictionary, selected_role_id: String) -> Dictionary:
	return {}

static func get_starting_nal_for_role(role_id: String) -> int:
	return 5

static func get_role_price_modifiers(state: Dictionary, player: Dictionary, card_def: CardDefinition) -> Array[Dictionary]:
	return []

static func can_bypass_purchase_requirement(state: Dictionary, player: Dictionary, card_id: String, requirement_id: String) -> bool:
	return false

static func consume_role_flags_after_purchase(state: Dictionary, player_id: String, card_id: String, applied_modifiers: Array[Dictionary]) -> Dictionary:
	return {}

static func get_district_rebuild_price(state: Dictionary, player: Dictionary) -> Dictionary:
	return {}

static func consume_role_flags_after_rebuild(state: Dictionary, player_id: String, applied_modifiers: Array[Dictionary]) -> Dictionary:
	return {}

static func reset_round_role_flags(player: Dictionary, selected_role_id: String) -> Dictionary:
	return player

### 8.2. Price Modifier Result Shape

Recommended modifier shape:

{
	"source": "role",
	"role_id": "merchant",
	"flag": "merchant_first_engine_discount_used",
	"type": "CARD_PRICE_DELTA",
	"delta": -1,
	"applies_to_card_id": "",
	"applies_to_card_type": "engine",
	"consume_on_success": true,
	"description": "Merchant first Engine card discount"
}

### 8.3. Role Setup Result Shape

Recommended result:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"selected_role_id": "merchant",
	"player_id": GameIds.PLAYER_HUMAN,
	"state": {},
	"log_entries": []
}

Failed result:

{
	"ok": false,
	"error": ValidationErrors.REQUIREMENT_NOT_MET,
	"selected_role_id": "",
	"player_id": GameIds.PLAYER_HUMAN,
	"state": {}
}

### 8.4. Rebuild Price Result Shape

Recommended result:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"base_rebuild_price": 8,
	"final_rebuild_price": 7,
	"modifiers": [
		{
			"source": "role",
			"role_id": "district_boss",
			"flag": "district_boss_rebuild_discount_used",
			"type": "REBUILD_PRICE_OVERRIDE",
			"delta": -1,
			"consume_on_success": true
		}
	]
}

Preview functions must not mutate state.

## 9. Edge Cases

Edge Case	Condition	Expected Behavior	Error Code	Mutation Rule
Invalid selected role	selected_role_id not in valid role IDs.	Setup fails.	INVALID_ROLE_ID	No mutation after validation failure.
Missing human player	Human player does not exist.	Setup fails.	INVALID_TARGET	No mutation.
Role applied to AI	RoleLogic tries to apply selected role to AI.	Reject role application.	REQUIREMENT_NOT_MET	AI state must not receive role effects.
Merchant at Turf Level 3	Merchant starts with 7, then Turf Level 3 applies -1.	Human starts with 6 Nal.	OK	Setup mutation allowed.
Gray Cardinal at Turf Level 3	Gray Cardinal starts with 4, then Turf Level 3 applies -1 minimum 3.	Human starts with 3 Nal.	OK	Setup mutation allowed.
Enforcer at Turf Level 3	Enforcer starts with 5, then Turf Level 3 applies -1.	Human starts with 4 Nal and active Cops.	OK	Setup mutation allowed.
District Boss at Turf Level 3	District Boss starts with 5, then Turf Level 3 applies -1.	Human starts with 4 Nal.	OK	Setup mutation allowed.
Merchant first Engine discount already used	Flag is true.	No discount applies.	OK	No flag mutation.
Merchant first War tax already applied this round	Flag is true.	No second War tax this round.	OK	No flag mutation.
Merchant first War tax next round	New round starts.	Tax flag resets to false.	OK	Reset only this flag.
Enforcer first War discount already used	Flag is true.	No discount applies.	OK	No flag mutation.
Enforcer buys Laundry	Any Laundry purchase.	Price increases by +1.	OK	No role flag needed.
Gray Cardinal buys Accountant with 0 VP and bypass unused	Requirement bypass applies.	Purchase allowed if all other checks pass.	OK	Consume bypass only on success.
Gray Cardinal buys Accountant with 1+ VP	Normal requirement passes.	Bypass should not be consumed.	OK	No bypass flag mutation.
Non-Gray-Cardinal buys Accountant with 0 VP	Requirement fails.	Purchase rejected.	REQUIREMENT_NOT_MET	No mutation.
Gray Cardinal first Saboteur already used	Flag is true.	No discount applies.	OK	No flag mutation.
Gray Cardinal first Stash tax already used	Flag is true.	No tax applies.	OK	No flag mutation.
District Boss first Stash discount already used	Flag is true.	No discount applies.	OK	No flag mutation.
District Boss first Laundry tax already used	Flag is true.	No tax applies.	OK	No flag mutation.
District Boss rebuild discount already used	Flag is true.	Default rebuild price applies.	OK	No flag mutation.
Failed purchase with role modifier	Purchase fails for any reason.	Role flag is not consumed.	Purchase error	No role flag mutation.
Price modifier would reduce price below 1	Final price after role discount < 1.	Clamp to 1.	OK	Purchase mutation only if purchase succeeds.
Role flags missing new fields	Save/test fixture lacks required flags.	Factory/validator must add defaults or fail validation.	REQUIREMENT_NOT_MET	Do not run gameplay with incomplete flags.

## 10. Required Source Files

Required files:

res://logic/roles/RoleLogic.gd
res://data/resources/roles/RoleDefinition.gd
res://data/resources/roles/merchant.tres
res://data/resources/roles/enforcer.tres
res://data/resources/roles/gray_cardinal.tres
res://data/resources/roles/district_boss.tres

Recommended constants file:

res://data/ids/RoleIds.gd

Related files that must call or support RoleLogic:

res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/economy/PriceLogic.gd
res://logic/economy/MarketLogic.gd
res://autoload/GameStateManager.gd

Recommended optional helper files if splitting is needed:

res://logic/roles/RolePriceModifiers.gd
res://logic/roles/RoleSetupResolver.gd
res://logic/roles/RoleFlagValidator.gd

Each source file must stay under:

250 lines

If RoleLogic.gd approaches the limit, split setup, price modifiers, and flag validation.

## 11. Required GUT Tests

Recommended test file:

res://tests/unit/test_role_logic.gd

### 11.1. Role ID Tests

Minimum tests:

merchant is valid;
enforcer is valid;
gray_cardinal is valid;
district_boss is valid;
unknown role ID is invalid;
setup with invalid role fails;
setup stores state["selected_role_id"].

### 11.2. Setup Tests

Minimum tests:

Merchant starts with 7 Nal before Turf Level modifiers;
Enforcer starts with 5 Nal before Turf Level modifiers;
Enforcer starts with active Cops;
Enforcer Cops timer starts at 0;
Gray Cardinal starts with 4 Nal before Turf Level modifiers;
District Boss starts with 5 Nal before Turf Level modifiers;
Turf Level 3 applies after role starting Nal;
roles do not apply to AI players.

### 11.3. Merchant Tests

Minimum tests:

Merchant first Engine card gets -1 price;
Merchant first Engine discount is consumed on successful purchase;
failed purchase does not consume Merchant Engine discount;
Merchant second Engine card gets no discount;
Merchant first War card each round gets +1 price;
Merchant War tax is consumed on successful War purchase;
Merchant second War card in same round gets no tax;
Merchant War tax resets next round.

### 11.4. Enforcer Tests

Minimum tests:

Enforcer first War card gets -1 price;
Enforcer first War discount is consumed on successful purchase;
failed purchase does not consume Enforcer War discount;
Enforcer second War card gets no discount;
Enforcer War discount does not reset next round;
Enforcer Laundry price is always +1;
Enforcer Laundry tax applies to first, second, and later Laundries.

### 11.5. Gray Cardinal Tests

Minimum tests:

non-Gray-Cardinal cannot buy Accountant with 0 VP;
Gray Cardinal can buy first Accountant with 0 VP;
Gray Cardinal Accountant bypass is consumed only on successful bypass purchase;
Gray Cardinal buying Accountant with 1+ VP does not consume bypass;
Gray Cardinal cannot use bypass twice;
Gray Cardinal first Saboteur gets -1 price;
Gray Cardinal first Saboteur discount is consumed on successful purchase;
Gray Cardinal second Saboteur gets no discount;
Gray Cardinal first Stash gets +1 price;
Gray Cardinal first Stash tax is consumed on successful purchase;
Gray Cardinal second Stash gets no tax.

### 11.6. District Boss Tests

Minimum tests:

District Boss first Stash gets -2 price;
District Boss first Stash discount is consumed on successful purchase;
failed purchase does not consume District Boss Stash discount;
District Boss second Stash gets no discount;
District Boss first Laundry gets +1 price;
District Boss first Laundry tax is consumed on successful purchase;
District Boss second Laundry gets no tax;
District Boss first rebuild costs 7;
District Boss rebuild discount is consumed only on successful rebuild;
District Boss second rebuild uses default rebuild price.

### 11.7. Integration Tests

Minimum tests:

Role modifiers apply after base/scaled prices and before Turf Level and temporary modifiers;
role price modifiers are included in price preview result;
purchase result includes applied role modifiers;
failed purchase does not mutate role flags;
role flags persist across rounds except explicitly reset per-round flags;
no role logic is implemented in UI files;
no forbidden random APIs exist in role logic files.

## 12. Static Scan Requirements

Static scan must fail if role logic contains:

randf(
randi(
randomize(
RandomNumberGenerator

Role logic must not use gameplay random.

Static scan must fail if role implementation:

reads or writes UI nodes;
lives inside UI scenes;
parses effect_summary or limitation_summary for gameplay behavior;
hardcodes card base prices;
performs purchase placement;
resolves combat;
advances phases;
assigns AI profiles;
mutates AI players with human role effects.

Allowed dependencies:

GameIds
RoleIds
ValidationErrors
PhaseIds only when needed for validation
CardDefinition
PriceLogic only through clean integration
GameStateFactory
GameStateValidator

## 13. Implementation Notes For LLM Agents

When implementing roles:

Do not change role IDs.
Do not change role effects.
Do not change card prices.
Do not change card effects.
Do not make roles apply to AI in MVP.
Do not implement role logic in UI.
Do not parse Resource summary strings as logic.
Use explicit role IDs and flags.
Add RoleLogic.gd; do not leave RoleLogic.create_empty_role_flags() undefined.
Add dedicated flags for Gray Cardinal first Stash tax and District Boss first Laundry tax.
Treat “first” as once per run unless the rule says “each round”.
Treat Merchant first War tax as once per round.
Treat Enforcer first War discount as once per run.
Treat Accountant as requiring vp >= 1 unless Gray Cardinal uses the first Accountant bypass.
Consume flags only after successful purchase or rebuild.
Never consume flags on failed validation.
Keep every source file under 250 lines.
Add or update GUT tests together with implementation.

If a future rule is unclear, do not invent behavior. Add it to:

21_OPEN_QUESTIONS_AND_FIXES.md

## 14. Acceptance Criteria

This module is complete when:

all four role Resources exist;
valid role IDs are centralized or consistently validated;
RoleLogic.gd exists;
RoleLogic.create_empty_role_flags() exists;
selected role is stored in state["selected_role_id"];
selected role applies only to the human player;
Merchant starts with 7 Nal;
Merchant first Engine discount works once per run;
Merchant first War tax works once per round;
Enforcer starts with active Cops;
Enforcer first War discount works once per run;
Enforcer Laundry tax applies to every Laundry purchase;
Gray Cardinal starts with 4 Nal;
Accountant normally requires vp >= 1;
Gray Cardinal first Accountant bypass works once per run;
Gray Cardinal first Saboteur discount works once per run;
Gray Cardinal first Stash tax works once per run;
District Boss first Stash discount works once per run;
District Boss first Laundry tax works once per run;
District Boss first rebuild discount works once per run;
role flags reset only where specified;
role modifiers appear in price previews;
failed purchases do not consume role flags;
role logic does not use UI nodes;
role logic does not use forbidden random APIs;
all required GUT tests pass.

## 15. Final Rule

Roles modify setup and prices only through explicit role flags; they must never secretly rewrite card effects or AI behavior.
