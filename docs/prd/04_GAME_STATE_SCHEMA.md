# Game State Schema

## Document Role

This file defines only: runtime state structure, dictionary schemas, ownership rules, validation rules, reset rules, and state mutation boundaries for The Turf.

This file must not redefine:

card prices;
card effects;
role balance;
combat resolution;
AI scoring;
random algorithm implementation;
UI layout;
phase transition logic except where state fields require clarification.

Source of truth dependencies:

00_INDEX.md
02_CORE_LOOP_AND_PHASES.md
03_IDS_AND_CONSTANTS.md
05_CARDS_DATABASE.md
06_ECONOMY_AND_MARKET.md
07_COMBAT_SYSTEM.md
08_ROLES.md
09_CONTRACTS.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md
12_TURF_LEVELS.md
13_AI_SYSTEM.md
14_DETERMINISTIC_RANDOM.md
16_GAME_STATE_MANAGER_API.md
18_TEST_PLAN.md
20_LLM_AGENT_RULES.md

Implementation target:

Godot 4.6.2
GDScript
GUT tests

## 1. Purpose

This file defines the canonical runtime state shape for the game.

The state must be:

- deterministic;
- serializable;
- testable;
- independent from Godot Nodes;
- safe for logic-only unit tests;
- readable by UI through selectors;
- committed only through GameStateManager.gd;
- transformed only by pure logic modules operating on an explicit working-state copy.

The runtime state is stored as Dictionaries and Arrays.

Resources define static data.
Dictionaries define runtime data.

## 2. State Design Principles

The state schema follows these rules:

- GameState is the full runtime snapshot of one match.
- PlayerState stores all runtime data owned by one player.
- Static config data must not be copied into runtime state unless required.
- Runtime state must store IDs, counters, flags, and progress.
- UI must not mutate state directly.
- Logic modules must not store state inside Nodes.
- State must not depend on scene tree structure.
- State must be validatable after every mutating action.

### 2.1. Schema Authority

This file is the final source of truth for runtime GameState keys, nested object shapes, types, empty values, and cross-field invariants.

When another PRD document describes gameplay behavior, it must reference the field names from this file and must not introduce an alternative runtime key or object shape.

If a runtime shape in another PRD conflicts with this file, this file wins and the conflicting document must be corrected.

### 2.2. Machine-Checkable Contract Conventions

The following rules apply to every schema in this file:

- every field shown in a Required Shape is mandatory;
- fields not shown in the corresponding Required Shape are forbidden unless this file and `schema_version` are updated together;
- null is forbidden everywhere in runtime state;
- an absent optional value is represented only by the documented empty value: "", 0, false, [], or {};
- Array[T] means every element must validate as T;
- Dictionary[String, T] means every key is a String and every value must validate as T;
- int fields must not contain float values;
- String ID fields must use the canonical formats in section 2.4;
- all arrays whose rules require uniqueness must be validated for duplicate values;
- every mutating operation must validate the complete candidate GameState before commit;
- validation failure returns a canonical ValidationErrors code and leaves the active state byte-for-byte unchanged.

Runtime validation must check exact keys recursively. Compatibility aliases such as `contract_offers`, `active_debts`, `modifiers`, or player-level `street_deals` are forbidden.

Validation has two explicit modes:

- `setup_working`: local setup-only data may use documented empty values while the candidate is being built; this data is never active state and is never emitted;
- `committed`: the complete exact schema and every cross-field invariant are required.

`GameStateValidator.validate_game_state(state)` always means `committed` mode. Setup code may use `validate_setup_working_state(state)` before final committed validation.

### 2.3. Canonical Runtime Key Registry

The following keys are the only canonical owners for the named runtime concepts:

| Concept | Canonical key | Type | Forbidden alternatives |
| --- | --- | --- | --- |
| Setup contract offer IDs | `state["contract_offer_ids"]` | `Array[String]` | `contract_offers`, `offers`, `available_contracts` |
| Selected contract ID | `state["selected_contract_id"]` | `String` | player-level selected contract fields |
| Active contract runtime | `player["contracts"]` | `Array[Dictionary]` | root `contracts`, `active_contract` |
| Owned contacts | `player["contacts"]` | `Dictionary` | root unlocked-contact arrays |
| Pending contact offer | `state["contacts"]["pending_offer"]` | `Dictionary` | `contact_offer`, `pending_contacts` |
| Debts | `player["debts"]` | `Array[Dictionary]` | `state["active_debts"]`, `player["street_deals"]` |
| Temporary modifiers | `player["temporary_modifiers"]` | `Array[Dictionary]` | `modifiers`, root modifier arrays |
| Turf runtime flags | `player["turf_flags"]` | `Dictionary` | `turf_modifiers`, root turf flags |
| Street Deal offer state | `state["street_deals"]` | `Dictionary` | player-level Street Deal state |
| Gameplay event log | `state["combat_log"]` | `Array[Dictionary]` | additional gameplay log arrays |

The key `combat_log` is retained as the canonical MVP key for the complete append-only gameplay event log, including non-combat events.

### 2.4. Canonical ID Formats

| Entity | Canonical format and validation |
| --- | --- |
| Static definition IDs | Lowercase snake_case matching `^[a-z][a-z0-9_]*$` and contained in the owner constant class `ALL` array. |
| Human player ID | Exactly `player_1`. |
| AI player IDs | Exactly `ai_1`, `ai_2`, or `ai_3`; contained in `GameIds.AI_PLAYER_IDS`. |
| AI profile ID | Lowercase snake_case and contained in `AIProfileIds.ALL`. |
| Turf Level ID | Integer in `TurfLevelIds.ALL`; string Turf/territory IDs are forbidden in MVP. |
| Contract offer ID | A `ContractIds.ALL` value; an offer does not receive a separate runtime ID. |
| Contract runtime ID | The same value as `contract_id`; no second contract-instance ID exists in MVP. |
| Contact ID | A `ContactIds.ALL` value. |
| Street Deal option ID | Exactly `option_a` or `option_b`, from `StreetDealOptionIds.ALL`. |
| Debt runtime ID | `<street_deal_id>_round_<round>_<option_id>`, for example `loan_shark_round_8_option_a`. |
| Temporary modifier runtime ID | `<source_id>_<owner_player_id>_round_<round>`, for example `cheap_protection_player_1_round_4`. |
| Log entry ID | `log_%06d`, one-based append index, for example `log_000001`. |

Runtime IDs must be unique within their owning array. ID creation belongs to the logic module that creates the entity; GameStateValidator validates format, membership, and uniqueness before commit.

## 3. Root GameState Schema

### 3.1. Responsibility

GameState stores the full runtime state of one match.

It must be created by:

GameStateFactory.gd

It must be validated by:

GameStateValidator.gd

It must be mutated through:

GameStateManager.gd

### 3.2. Required Shape

The keys below are exact. Values shown are factory defaults for `setup_working`; committed-mode rules in Sections 3.3 and 23 override setup-only empty values.

{
	"round": 1,
	"current_phase": PhaseIds.SETUP,

	"players": [],

	"game_seed": "",
	"random": {
		"seed": "",
		"step": 0,
		"last_random_tag": "",
		"random_history_enabled": false,
		"history": []
	},

	"turf_level": 0,

	"selected_role_id": "",
	"selected_contract_id": "",
	"contract_offer_ids": [],

	"market": {},

	"street_deals": {
		"offered_this_round": false,
		"current_deal_id": "",
		"used_deal_ids": [],
		"choices_by_player": {},
		"option_availability": {}
	},
	"contacts": {
		"pending_offer": {}
	},

	"ai_bosses": [],

	"action_order": [],
	"active_action_player_id": "",

	"combat_log": [],

	"winner_id": "",
	"game_result": {},

	"debug": {
		"schema_version": "1.0.0",
		"last_validation_error": ""
	}
}

### 3.3. Required Field Contract

| Field | Type | Owner | Empty/default rule |
| --- | --- | --- | --- |
| `round` | `int` | GamePhaseController | `1..15`; starts at 1. |
| `current_phase` | `String` | GamePhaseController | One value from `PhaseIds.ALL`; committed state after `start_new_game` starts at `PhaseIds.INCOME`. |
| `players` | `Array[Dictionary]` | GameStateFactory / logic modules | Exactly four exact PlayerState dictionaries after successful setup. |
| `game_seed` | `String` | GameStateFactory | Non-empty after successful setup. |
| `random` | `Dictionary` | SeededRandom / SeededPicker | Exact RandomState shape. |
| `turf_level` | `int` | Setup / GameStateFactory | One value from `TurfLevelIds.ALL`. |
| `selected_role_id` | `String` | Setup | A value from `RoleIds.ALL` after successful setup. |
| `selected_contract_id` | `String` | Setup | A value from `ContractIds.ALL` and from `contract_offer_ids` after setup. |
| `contract_offer_ids` | `Array[String]` | ContractLogic / Setup | Exactly three unique values from `ContractIds.ALL` after setup. |
| `market` | `Dictionary` | MarketLogic | `{}` during Income before Market entry; exact MarketState in Market, Action, Street Deal, and Game Over. |
| `street_deals` | `Dictionary` | StreetDealLogic | Exact StreetDealState shape. |
| `contacts` | `Dictionary` | ContactLogic | Exact global contact shape `{ "pending_offer": {} }` or a valid pending offer. |
| `ai_bosses` | `Array[Dictionary]` | AIBotController | Exactly three valid AIBossState entries after setup. |
| `action_order` | `Array[String]` | GamePhaseController | Empty outside Action initialization or four unique player IDs in fixed order. |
| `active_action_player_id` | `String` | GamePhaseController | `""` outside an active Action turn; otherwise a value from `action_order`. |
| `combat_log` | `Array[Dictionary]` | CombatLogBuilder and logic modules | Empty allowed; append-only exact CombatLogEntry values. |
| `winner_id` | `String` | WinnerResolver | `""` before Game Over; valid player ID at Game Over. |
| `game_result` | `Dictionary` | WinnerResolver | `{}` before Game Over; exact GameResult at Game Over. |
| `debug` | `Dictionary` | Validator / debug tools | Exact shape `{ "schema_version": String, "last_validation_error": String }`; `schema_version == "1.0.0"` and committed active state keeps `last_validation_error == ""`. Validation failures are returned in result `details`, not written into active state. |

### 3.4. Active-State Lifecycle Rule

`GameStateManager.state` is either:

- `{}` before a game starts; or
- a complete GameState that passes `GameStateValidator.validate_game_state`.

Partially initialized setup dictionaries are allowed only as local working data inside setup logic. They must never be committed or emitted through `state_changed`.

## 4. PlayerState Schema

### 4.1. Responsibility

PlayerState stores all runtime data owned by one player.

There must be exactly 4 PlayerState dictionaries:

player_1
ai_1
ai_2
ai_3

### 4.2. Required Shape

{
	"id": "",
	"is_ai": false,

	"nal": 5,
	"vp": 0,
	"turf_level": 0,

	"engine": {
		"informers": 0,
		"laundries": 0,
		"accountants": 0,
		"brothel": false
	},

	"status_buildings": {
		"stash": 0,
		"workshop": 0,
		"district_control": 0,
		"can_rebuild_district_for_8": false
	},

	"defense": {
		"cops_active": false,
		"cops_timer": 0,
		"cartel_state": DefenseStates.NONE,
		"judge_state": DefenseStates.NONE
	},

	"hand": [],
	"purchased_this_round": [],

	"ready_for_action": false,
	"action_done": false,
	"skip_next_action": false,

	"contracts": [],
	"contacts": {
		"unlocked": [],
		"cooldowns": {},
		"used_this_round": []
	},

	"debts": [],

	"role_flags": {},
	"turf_flags": {
		"ai_first_war_discount_used_this_round": false
	},
	"temporary_modifiers": [],

	"is_strong_ai": false,
	"last_attacked_by": ""
}

### 4.3. Required Field Contract

| Field | Type | Empty/default rule |
| --- | --- | --- |
| `id` | `String` | One exact value from `GameIds.PLAYER_IDS`; never empty after factory creation. |
| `is_ai` | `bool` | `false` only for `player_1`; `true` for AI player IDs. |
| `nal` | `int` | `>= 0`. |
| `vp` | `int` | `>= 0`. |
| `turf_level` | `int` | Must equal root `state["turf_level"]`. |
| `engine` | `Dictionary` | Exact EngineState shape. |
| `status_buildings` | `Dictionary` | Exact StatusBuildingsState shape. |
| `defense` | `Dictionary` | Exact DefenseState shape. |
| `hand` | `Array[String]` | Empty array allowed; every value is a valid War card ID. |
| `purchased_this_round` | `Array[String]` | Empty array allowed; valid unique card IDs. |
| `ready_for_action` | `bool` | Defaults to `false`. |
| `action_done` | `bool` | Defaults to `false`. |
| `skip_next_action` | `bool` | Defaults to `false`. |
| `contracts` | `Array[Dictionary]` | Human: exactly one after setup; AI: always empty in MVP. |
| `contacts` | `Dictionary` | Exact ContactState shape. |
| `debts` | `Array[Dictionary]` | Empty allowed; every entry is an exact DebtState. |
| `role_flags` | `Dictionary` | Exact RoleFlags shape. |
| `turf_flags` | `Dictionary` | Exact TurfFlags shape. |
| `temporary_modifiers` | `Array[Dictionary]` | Empty allowed; exact TemporaryModifier entries with unique IDs. |
| `is_strong_ai` | `bool` | `false` for human; exactly one AI has `true`. |
| `last_attacked_by` | `String` | `""` or a different valid player ID from `GameIds.PLAYER_IDS`. |

## 5. State Ownership Rules

### 5.1. No Duplicate Runtime Ownership

A runtime concept must have exactly one owner.

This is mandatory because duplicated state causes logic and UI to drift apart. Tiny tragedy, huge debugging session.

### 5.2. Contacts Ownership

Contact ownership:

PlayerState owns unlocked contacts, cooldowns, and usage.
GameState owns only temporary contact offer state.

Therefore:

player["contacts"]

owns:

- unlocked contacts;
- contact cooldowns;
- contacts used this round.

And:

state["contacts"]["pending_offer"]

owns only:

- current contact choice offer;
- offered contacts;
- source of offer;
- target player.

### 5.3. Street Deals Ownership

Street Deal ownership:

GameState owns global Street Deal offer state.
PlayerState owns debts created by Street Deals.

Therefore:

state["street_deals"]

owns:

- whether a Street Deal was offered this round;
- current deal ID;
- used deal IDs;
- choices by player if needed;
- current option availability.

And:

player["debts"]

owns:

- debt runtime objects;
- debt repayment status;
- debt deadlines;
- debt penalties.

PlayerState must not contain a duplicate street_deals object.

### 5.4. Contracts Ownership

Contract ownership:

PlayerState owns contract runtime objects.

For MVP:

- the human player has one selected contract;
- AI players do not receive contracts in MVP;
- state["contract_offer_ids"] stores the three deterministic setup offers;
- selected_contract_id stores the human setup selection;
- player["contracts"] stores runtime contract state.

### 5.5. Market Ownership

Market ownership:

GameState owns the shared market.

Players own only:

player["purchased_this_round"]

### 5.6. AI Ownership

AI metadata ownership:

state["ai_bosses"] owns AI profile assignments and strong AI status metadata.
player["is_strong_ai"] stores quick runtime access.

The two must stay consistent.

## 6. RandomState Schema

### 6.1. Responsibility

RandomState tracks deterministic gameplay random.

It is owned by:

SeededRandom.gd
SeededPicker.gd

No other module may mutate random.step directly.

### 6.2. Required Shape

{
	"seed": "",
	"step": 0,
	"last_random_tag": "",
	"random_history_enabled": false,
	"history": []
}

### 6.3. Field Rules

Field	Type	Rule
seed	String	Must match state["game_seed"] at game start
step	int	Must be >= 0
last_random_tag	String	Debug label for last random call
random_history_enabled	bool	If false, history should remain empty
history	Array	Debug-only list of random calls

### 6.4. Random History Entry Shape

If enabled, every history entry must use exactly:

{
	"step": 0,
	"tag": "",
	"value": 0.0
}

### 6.5. Mutation Rule

Every gameplay random function must:

- accept random_state;
- return result and updated random_state;
- never use randf(), randi(), randomize(), or RandomNumberGenerator.

Detailed random rules are defined in:

14_DETERMINISTIC_RANDOM.md

## 7. MarketState Schema

### 7.1. Responsibility

MarketState stores the shared market for the current round.

It is owned by:

MarketLogic.gd

### 7.2. Required Shape

{
	"round": 1,
	"always_available_card_ids": [],
	"rotating_card_ids": [],
	"all_available_card_ids": []
}

### 7.3. Field Rules

Field	Type	Rule
round	int	Must match state["round"]
always_available_card_ids	Array[String]	Must match market constants
rotating_card_ids	Array[String]	Must contain unique card IDs
all_available_card_ids	Array[String]	Must equal always + rotating

### 7.4. Validation Rules

MarketState is valid when:

- all card IDs exist in GameIds.CARD_IDS;
- rotating_card_ids has no duplicates;
- always_available_card_ids has no duplicates;
- all_available_card_ids has no duplicates;
- all_available_card_ids contains every always available card;
- round matches state["round"].

Market rules are defined in:

06_ECONOMY_AND_MARKET.md

## 8. EngineState Schema

### 8.1. Responsibility

EngineState stores a player's engine cards that affect income or protection.

### 8.2. Required Shape

{
	"informers": 0,
	"laundries": 0,
	"accountants": 0,
	"brothel": false
}

### 8.3. Field Rules

Field	Type	Rule
informers	int	Must be >= 0
laundries	int	Must be >= 0
accountants	int	Must be >= 0
brothel	bool	true if player owns Brothel

## 9. StatusBuildingsState Schema

### 9.1. Responsibility

StatusBuildingsState stores a player's Victory Point buildings.

### 9.2. Required Shape

{
	"stash": 0,
	"workshop": 0,
	"district_control": 0,
	"can_rebuild_district_for_8": false
}

### 9.3. Field Rules

Field	Type	Rule
stash	int	Must be >= 0
workshop	int	Must be >= 0
district_control	int	Must be >= 0
can_rebuild_district_for_8	bool	Set by Federal Raid effect

### 9.4. District Control Requirement

A player can own District Control only within the requirement defined in:

06_ECONOMY_AND_MARKET.md
05_CARDS_DATABASE.md

The default rule:

district_control < workshop

when buying a new District Control.

## 10. DefenseState Schema

### 10.1. Responsibility

DefenseState stores active defense cards and defense runtime status.

### 10.2. Required Shape

{
	"cops_active": false,
	"cops_timer": 0,
	"cartel_state": DefenseStates.NONE,
	"judge_state": DefenseStates.NONE
}

### 10.3. Field Rules

Field	Type	Rule
cops_active	bool	True if Cops are currently active
cops_timer	int	Must be >= 0
cartel_state	String	Must be one of DefenseStates.ALL_CARTEL
judge_state	String	Must be one of DefenseStates.ALL_JUDGE

### 10.4. Defense State Values

Valid Cartel state values:

none
active
depleted

Valid Judge state values:

none
active

Detailed defense behavior is defined in:

07_COMBAT_SYSTEM.md

Cops upkeep behavior is defined in:

06_ECONOMY_AND_MARKET.md

## 11. ContractRuntime Schema

### 11.1. Responsibility

ContractRuntime stores a player's progress for one selected contract.

It is owned by:

ContractLogic.gd

### 11.2. Required Shape

{
	"contract_id": "",
	"progress": 0,
	"completed": false,
	"failed": false,
	"claimed": false,
	"deadline": 0,
	"failed_reason": "",
	"completed_round": 0,
	"claimed_round": 0
}

### 11.3. Field Rules

Field	Type	Rule
contract_id	String	Must exist in ContractIds.ALL
progress	int	Must be >= 0
completed	bool	True after completion condition is met
failed	bool	True after deadline failure
claimed	bool	True after reward is applied
deadline	int	Must be between 1 and 15
failed_reason	String	Empty unless the contract failed; exactly war_played or deadline_exceeded when failed
completed_round	int	0 until completion, otherwise the completion round
claimed_round	int	0 until claim, otherwise the claim round

### 11.4. Status Rules

A contract must not be both:

completed == true
failed == true

A contract must not have:

claimed == true

unless:

completed == true

Contract rules are defined in:

09_CONTRACTS.md

## 12. ContactState Schema

### 12.1. Responsibility

ContactState stores contacts owned by a player.

It is owned by:

ContactLogic.gd

### 12.2. Required Shape

{
	"unlocked": [],
	"cooldowns": {},
	"used_this_round": []
}

### 12.3. Field Rules

Field	Type	Rule
unlocked	Array[String]	Unique Contact IDs owned by the player
cooldowns	Dictionary[String, int]	contact_id -> remaining rounds; keys must also exist in unlocked
used_this_round	Array[String]	Unique unlocked active-contact IDs used this round

### 12.4. Contact Limit

In MVP:

A player may have at most 1 unlocked contact.

Therefore:

player["contacts"]["unlocked"].size() <= 1

### 12.5. Cooldown Rules

Cooldown keys must be valid contact IDs.

Cooldown values must be integers:

>= 0

Contact rules are defined in:

11_CONTACTS.md

## 13. ContactOfferState Schema

### 13.1. Responsibility

ContactOfferState stores a temporary contact choice offer.

It is owned by:

ContactLogic.gd

### 13.2. Required Shape

{
	"player_id": "",
	"source": "",
	"contact_offer_ids": [],
	"resolved": false,
	"created_round": 0
}

### 13.3. Field Rules

Field	Type	Rule
player_id	String	Must be exactly GameIds.PLAYER_HUMAN while an offer is pending
source	String	Must be exactly inside_contact or strong_ai_victory
contact_offer_ids	Array[String]	Must contain valid unique contact IDs; exactly 2 for inside_contact, exactly 3 for strong_ai_victory at Turf Level 0-6, exactly 2 for strong_ai_victory at Turf Level 7-10
resolved	bool	Must be false in every valid GameState; successful selection clears pending_offer atomically and never commits true
created_round	int	Round in which the offer was created; 1..15

### 13.4. MVP Rule

For MVP:

Contact offers target exactly `GameIds.PLAYER_HUMAN`.

In committed state, a non-empty pending offer has `resolved == false`. Resolution and clearing occur in the same atomic operation, so a resolved offer is not committed as active state.

Strong AI reward contact-offer behavior is defined in `11_CONTACTS.md` and recorded as resolved in `21_OPEN_QUESTIONS_AND_FIXES.md`.

## 14. StreetDealState Schema

### 14.1. Responsibility

StreetDealState stores global Street Deal offer state for the current match.

It is owned by:

StreetDealLogic.gd

### 14.2. Required Shape

{
	"offered_this_round": false,
	"current_deal_id": "",
	"used_deal_ids": [],
	"choices_by_player": {},
	"option_availability": {}
}

### 14.3. Field Rules

Field	Type	Rule
offered_this_round	bool	True after a deal is offered
current_deal_id	String	Empty or valid Street Deal ID
used_deal_ids	Array[String]	Deals already used this match
choices_by_player	Dictionary[String, String]	player_id -> option_id; keys are valid player IDs and values are in StreetDealOptionIds.ALL
option_availability	Dictionary[String, String]	option_id -> ValidationErrors code; ValidationErrors.OK means available

### 14.4. MVP Participant Rule

For MVP, as resolved in 21_OPEN_QUESTIONS_AND_FIXES.md:

Only the human player selects Street Deal options.
AI players do not make Street Deal choices.

Therefore, in MVP:

choices_by_player

must contain at most:

player_1

Street Deal rules are defined in:

10_STREET_DEALS_AND_DEBTS.md

## 15. DebtState Schema

### 15.1. Responsibility

DebtState stores one active or resolved debt for one player.

It is owned by:

DebtLogic.gd

DebtState objects are stored in:

player["debts"]

### 15.2. Required Shape

{
	"id": "",
	"source": "loan_shark",
	"amount_due": 0,
	"deadline_round": 0,
	"penalty": {},
	"repaid": false,
	"created_round": 0,
	"repaid_round": 0,
	"penalty_applied_round": 0
}

### 15.3. Field Rules

Field	Type	Rule
id	String	Unique debt runtime ID matching section 2.4
source	String	Must be exactly loan_shark in MVP
amount_due	int	Must be > 0
deadline_round	int	Must be between 1 and 15
penalty	Dictionary	Must use the exact DebtPenalty shape
repaid	bool	True after repayment or penalty resolution
created_round	int	Round in which the debt was created; 1..15 and <= deadline_round
repaid_round	int	0 until repaid, otherwise the repayment round
penalty_applied_round	int	0 until resolved by penalty, otherwise the penalty round

Debt resolution invariants:

- while `repaid == false`, `repaid_round == 0` and `penalty_applied_round == 0`;
- player repayment sets `repaid == true`, `repaid_round > 0`, and `penalty_applied_round == 0`;
- deadline penalty sets `repaid == true`, `repaid_round == 0`, and `penalty_applied_round > 0`.

### 15.4. DebtPenalty Required Shape

{
	"lose_all_nal": false,
	"vp_delta": 0
}

Field	Type	Rule
lose_all_nal	bool	True only for Loan Shark option_a
vp_delta	int	Must be 0 or -1 in MVP

No additional penalty keys are allowed in MVP.

### 15.5. Active Debt Rule

An active debt is:

repaid == false

Loan Shark must not create a new active debt if the player already has an unpaid active debt.

Debt rules are defined in:

10_STREET_DEALS_AND_DEBTS.md

## 16. TemporaryModifier Schema

### 16.1. Responsibility

TemporaryModifier stores short-lived gameplay modifiers created by roles, Street Deals, contacts, or Turf Levels.

It is owned by the module that creates it and consumed by the module that applies it.

### 16.2. Required Shape

{
	"id": "",
	"type": "",
	"source": "",
	"owner_player_id": "",
	"affected_card_id": "",
	"affected_card_type": "",
	"delta": 0,
	"multiplier": 1.0,
	"min_value": 0,
	"expires_at": "",
	"consumed": false
}

### 16.3. Field Rules

Field	Type	Rule
id	String	Unique runtime modifier ID matching section 2.4
type	String	Must exist in ModifierTypes.ALL
source	String	Static source ID matching lowercase snake_case
owner_player_id	String	Valid player ID
affected_card_id	String	Empty or valid card ID
affected_card_type	String	Empty or valid card type
delta	int	Additive value
multiplier	float	Multiplicative value
min_value	int	Lower bound if applicable
expires_at	String	Expiration rule
consumed	bool	True after one-use modifier is spent

### 16.4. Expiration Values

Allowed expires_at values:

next_purchase
end_of_round
end_of_market
end_of_action
never

### 16.5. Modifier Uniqueness and Stacking

`player["temporary_modifiers"]` may contain multiple modifiers only when their `id` values are distinct.

For the same `source`, `owner_player_id`, and `round`, a second modifier is forbidden in MVP. A creator must return `INVALID_MODIFIER_STATE` instead of silently replacing or merging an existing unconsumed modifier.

### 16.6. Usage Examples

Cheap Protection option_a creates:

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

## 17. RoleFlags Schema

### 17.1. Responsibility

RoleFlags store one-time and per-round role-related usage flags.

They are owned by:

RoleLogic.gd

### 17.2. Required Shape

{
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

### 17.3. Reset Rules

Per-round flags must reset at round start.

One-time flags must not reset during the match.

Role rules are defined in:

08_ROLES.md

### 17.4. TurfFlags Required Shape

{
	"ai_first_war_discount_used_this_round": false
}

Field	Type	Rule
ai_first_war_discount_used_this_round	bool	Per-round Turf Level 6 AI War discount consumption flag

This field exists for every player. It is relevant only to AI players at Turf Level 6 or higher and resets to false at round start.

## 18. AIBossState Schema

### 18.1. Responsibility

AIBossState stores assigned AI profile metadata.

It is owned by:

AIBotController.gd

### 18.2. Required Shape

{
	"profile_id": "",
	"is_strong": false,
	"assigned_player_id": ""
}

### 18.3. Field Rules

Field	Type	Rule
profile_id	String	Must exist in AIProfileIds.ALL
is_strong	bool	Exactly one AI must be strong
assigned_player_id	String	Must be one of AI player IDs

### 18.4. Consistency Rule

If:

ai_boss["is_strong"] == true

then the matching player must have:

player["is_strong_ai"] == true

Exactly one AI player must be strong.

`state["ai_bosses"]` must contain exactly three entries, one for each value in `GameIds.AI_PLAYER_IDS`. Assigned player IDs and profile IDs must each be unique.

## 19. CombatLogEntry Schema

### 19.1. Responsibility

CombatLogEntry stores player-facing and testable gameplay event records.

It is append-only during a match.

### 19.2. Required Shape

{
	"id": "",
	"round": 1,
	"phase": "",
	"event_type": "",
	"actor_id": "",
	"target_id": "",
	"card_id": "",
	"summary": "",
	"details": {}
}

### 19.3. Field Rules

Field	Type	Rule
id	String	Unique log entry ID matching log_%06d and append order
round	int	Must be 1 to 15
phase	String	Must be one of PhaseIds.ALL
event_type	String	Must be one of LogEventTypes.ALL
actor_id	String	Empty or valid player ID
target_id	String	Empty or valid player ID
card_id	String	Empty or valid card ID
summary	String	Human-readable summary
details	Dictionary	Exact event-specific payload defined by LogEventTypes in 03_IDS_AND_CONSTANTS.md

### 19.4. UI Rule

UI may display log entries.

UI must not create gameplay results through log entries.

## 20. GameResult Schema

### 20.1. Responsibility

GameResult stores the final match result after Game Over.

It is owned by:

WinnerResolver.gd

### 20.2. Required Shape

{
	"winner_id": "",
	"final_scores": [],
	"tie_break_used": false,
	"tie_break_steps": [],
	"turf_level_10_ai_win_applied": false
}

### 20.3. FinalScoreEntry Shape

{
	"player_id": "",
	"vp": 0,
	"nal": 0,
	"status_building_vp_value": 0,
	"status_building_count": 0
}

### 20.4. TieBreakStep Shape

{
	"tie_break_id": "",
	"candidates_before": [],
	"candidates_after": [],
	"explanation": ""
}

Winner resolution rules are defined in:

02_CORE_LOOP_AND_PHASES.md

## 21. GameStateFactory Responsibilities

GameStateFactory.gd must create valid default runtime objects.

Required factory functions:

static func create_new_game_state(game_seed: String, turf_level: int) -> Dictionary:
	return {}

static func create_player_state(player_id: String, is_ai: bool, turf_level: int) -> Dictionary:
	return {}

static func create_random_state(game_seed: String) -> Dictionary:
	return {}

static func create_market_state() -> Dictionary:
	return {}

static func create_street_deal_state() -> Dictionary:
	return {}

static func create_global_contact_state() -> Dictionary:
	return {}

static func create_player_contact_state() -> Dictionary:
	return {}

static func create_contact_offer_state(player_id: String, source: String, contact_offer_ids: Array[String], created_round: int) -> Dictionary:
	return {}

static func create_contract_runtime(contract_id: String, deadline: int) -> Dictionary:
	return {}

static func create_role_flags() -> Dictionary:
	return {}

static func create_turf_flags() -> Dictionary:
	return {}

static func create_debt_state(debt_id: String, amount_due: int, deadline_round: int, penalty: Dictionary, created_round: int) -> Dictionary:
	return {}

static func create_temporary_modifier(data: Dictionary) -> Dictionary:
	return {}

static func create_combat_log_entry(event_type: String, data: Dictionary) -> Dictionary:
	return {}

static func create_ai_boss_state(profile_id: String, is_strong: bool, assigned_player_id: String) -> Dictionary:
	return {}

static func create_game_result() -> Dictionary:
	return {}

Factory functions must not:

- resolve card effects;
- calculate AI decisions;
- resolve combat;
- generate non-deterministic random;
- access UI Nodes.

## 22. GameStateValidator Responsibilities

GameStateValidator.gd must validate state shape and critical invariants.

Required validator functions:

static func validate_game_state(state: Dictionary) -> Dictionary:
	return {}

static func validate_setup_working_state(state: Dictionary) -> Dictionary:
	return {}

static func validate_player_state(player: Dictionary) -> Dictionary:
	return {}

static func validate_market_state(market: Dictionary, round: int) -> Dictionary:
	return {}

static func validate_random_state(random_state: Dictionary) -> Dictionary:
	return {}

static func validate_contract_runtime(contract: Dictionary) -> Dictionary:
	return {}

static func validate_contact_state(contact_state: Dictionary) -> Dictionary:
	return {}

static func validate_global_contact_state(global_contacts: Dictionary) -> Dictionary:
	return {}

static func validate_contact_offer_state(contact_offer: Dictionary) -> Dictionary:
	return {}

static func validate_street_deal_state(street_deals: Dictionary) -> Dictionary:
	return {}

static func validate_debt_state(debt: Dictionary) -> Dictionary:
	return {}

static func validate_temporary_modifier(modifier: Dictionary) -> Dictionary:
	return {}

static func validate_role_flags(role_flags: Dictionary) -> Dictionary:
	return {}

static func validate_turf_flags(turf_flags: Dictionary) -> Dictionary:
	return {}

static func validate_ai_bosses(state: Dictionary) -> Dictionary:
	return {}

static func validate_combat_log_entry(entry: Dictionary, expected_index: int) -> Dictionary:
	return {}

Validator return shape:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"details": {}
}

## 23. Root Validation Rules

Committed GameState is valid when:

- state is a Dictionary;
- round is between 1 and 15;
- current_phase exists in PhaseIds.ALL;
- players is an Array;
- players.size() == 4;
- every player has a valid unique player ID;
- game_seed is not empty after setup;
- random state is valid;
- turf_level is an integer member of TurfLevelIds.ALL;
- selected_role_id is a valid RoleIds.ALL member;
- selected_contract_id is a valid ContractIds.ALL member;
- contract_offer_ids contains exactly 3 unique valid contract IDs after setup;
- selected_contract_id exists in contract_offer_ids;
- the human player has exactly one ContractRuntime matching selected_contract_id;
- market is `{}` during Income before Market entry and is a valid exact MarketState in Market, Action, Street Deal, and Game Over;
- street_deals state is valid;
- contacts.pending_offer state is valid;
- ai_bosses are valid after setup;
- action_order contains only valid player IDs;
- active_action_player_id is empty or valid;
- winner_id is empty unless current_phase is game_over;
- game_result is empty unless current_phase is game_over.

## 24. Player Validation Rules

PlayerState is valid when:

- id exists in GameIds.PLAYER_IDS;
- is_ai is bool;
- nal is >= 0;
- vp is >= 0;
- turf_level is an integer member of TurfLevelIds.ALL;
- engine state is valid;
- status_buildings state is valid;
- defense state is valid;
- every card in hand exists in GameIds.CARD_IDS;
- every card in hand is a War card;
- purchased_this_round contains valid card IDs;
- purchased_this_round has no duplicates;
- ready_for_action is bool;
- action_done is bool;
- skip_next_action is bool;
- contracts array contains valid ContractRuntime objects;
- human contracts contains exactly 1 entry after setup and AI contracts are empty;
- contacts state is valid;
- debts contains valid DebtState objects;
- role_flags contains required keys;
- turf_flags contains the exact required key;
- temporary_modifiers contains valid TemporaryModifier objects;
- is_strong_ai is bool;
- last_attacked_by is empty or a valid player ID different from the owning player ID.

## 25. Phase-Specific Validation Rules

### 25.1. Setup Phase

During Setup:

- `current_phase == setup` is allowed only in `setup_working` validation mode;
- players may be empty or partially initialized only in the local working state before `start_new_game` completes;
- no gameplay action may be executed.

After `start_new_game` completes, the committed active state must have `current_phase == income` and satisfy the complete committed schema according to:

02_CORE_LOOP_AND_PHASES.md

### 25.2. Income Phase

During Income:

- active_action_player_id must be empty;
- action_order may be empty;
- market must be `{}` until `advance_phase` successfully enters Market;
- no player may buy cards;
- no player may execute attacks.

Income resolution is not stored in a second runtime key. `advance_phase` resolves Income for all four players and enters Market in one atomic candidate-state transaction. The durable result is the updated player state plus canonical Income, Cops, debt, contract, and phase log entries.

### 25.3. Market Phase

During Market:

- market must be populated;
- active_action_player_id must be empty;
- players may have ready_for_action true or false;
- players must not execute attacks.

### 25.4. Action Phase

During Action:

- action_order must contain valid player IDs;
- active_action_player_id must be empty only if all players are action_done;
- active_action_player_id must be valid if at least one player is not action_done;
- attacks may be executed only by active_action_player_id.

### 25.5. Street Deal Phase

During Street Deal:

- round must be 4, 8, or 12;
- street_deals.current_deal_id must be valid if a deal is active;
- active_action_player_id must be empty;
- all players must have action_done == true.

### 25.6. Game Over Phase

During Game Over:

- round must be 15;
- winner_id must be a valid player ID;
- game_result must be populated;
- no gameplay mutations are allowed except start_new_game.

## 26. Reset Rules

### 26.1. Round Start Reset

At the start of a new round:

- ready_for_action = false for every player;
- action_done = false for every player;
- purchased_this_round = [] for every player;
- market = {};
- active_action_player_id = "";
- action_order may be cleared until Action Phase begins;
- per-round role flags reset;
- turf_flags.ai_first_war_discount_used_this_round = false;
- used_this_round contacts reset;
- expired temporary modifiers are removed.

### 26.2. Market Entry Reset

When entering Market Phase:

- purchased_this_round = [] for every player;
- ready_for_action = false for every player;
- market is generated for the current round.

### 26.3. Action Entry Reset

When entering Action Phase:

- action_done = false for every player;
- action_order is set;
- active_action_player_id is set to first player in action_order.

### 26.4. Street Deal Exit Reset

When leaving Street Deal Phase:

- street_deals.offered_this_round = false;
- street_deals.current_deal_id = "";
- street_deals.choices_by_player = {};
- street_deals.option_availability = {};

Do not clear:

street_deals.used_deal_ids

### 26.5. Contact Offer Reset

After a contact choice is resolved:

state["contacts"] = GameStateFactory.create_global_contact_state()

## 27. Mutation Boundaries

### 27.1. GameStateManager

Only GameStateManager may expose public mutating methods to UI.

Examples:

- start_new_game
- advance_phase
- buy_card
- execute_attack
- select_street_deal
- activate_contact
- end_market_for_player
- end_action_for_player

### 27.2. Logic Modules

Logic modules contain deterministic gameplay rules, calculations, validation, and state transitions.

They must:

- receive all inputs explicitly;
- have no access to GameStateManager active state, UI Nodes, signals, or scene-tree state;
- transform only the working-state Dictionary passed by the caller;
- return a structured result with canonical error codes;
- never commit active state.

GameStateManager is the facade. It deep-copies active state, calls logic, validates the candidate result, commits on success, emits signals after commit, and adapts results for UI or AI.

Facade code must not duplicate, override, or bypass gameplay business logic owned by logic modules.

Logic modules must not access UI nodes.

### 27.3. UI

UI must not directly mutate:

- state["round"]
- state["current_phase"]
- player["nal"]
- player["vp"]
- player["hand"]
- player["engine"]
- player["status_buildings"]
- player["defense"]
- player["contracts"]
- player["contacts"]
- player["debts"]
- player["turf_flags"]
- player["temporary_modifiers"]
- state["market"]
- state["street_deals"]
- state["winner_id"]
- state["game_result"]

UI may read state only through:

GameStateManager selectors

Selectors are defined in:

16_GAME_STATE_MANAGER_API.md

## 28. Serialization Rules

Runtime state must be serializable to JSON-compatible data.

Allowed value types:

- String
- int
- float
- bool
- Array
- Dictionary

Forbidden inside runtime state:

- Godot Node references;
- Resource instances;
- Callable;
- Signal;
- Object;
- SceneTree references;
- RandomNumberGenerator instances.

Static data must stay in .tres Resources.

Runtime state must store resource IDs, not Resource references.

## 29. Debug Snapshot Rule

MVP does not include campaign persistence.

Optional debug snapshots may save GameState to:

user://debug_run_snapshot.json

Debug snapshots are only for:

- testing;
- replay debugging;
- development diagnostics.

They are not campaign saves.

Save policy is defined in:

15_GODOT_ARCHITECTURE.md

## 30. State Versioning

The state must include:

state["debug"]["schema_version"]

Initial schema version:

1.0.0

Schema version is for debug and migration awareness only.

MVP does not require save migration.

## 31. Required GUT Tests

Required test file:

res://tests/unit/test_game_state_schema.gd

Minimum required tests:

- create_new_game_state returns a Dictionary.
- new game state has round == 1.
- new game state has valid current_phase.
- new game state has exactly 4 players after setup completion.
- every player ID is valid and unique.
- human player ID is player_1.
- exactly 3 AI players exist.
- exactly one AI is strong.
- random state has step >= 0.
- turf_level is an integer member of TurfLevelIds.ALL.
- player nal is >= 0.
- player vp is >= 0.
- every player hand contains only valid War card IDs.
- purchased_this_round has no duplicates.
- market state validates after market generation.
- contact state enforces max 1 contact.
- active debts validate.
- debt and modifier runtime IDs match canonical formats and are unique.
- contact pending offer is either {} or the exact ContactOfferState shape.
- Street Deal option IDs are option_a or option_b.
- every PlayerState contains exact turf_flags.
- exactly three unique AI profile assignments use ai_1, ai_2, and ai_3.
- combat log IDs and event payloads validate against LogEventTypes.
- contract runtime cannot be completed and failed at the same time.
- game_over state requires winner_id and game_result.
- runtime state contains no Node or Resource references.

## 32. Acceptance Criteria

This schema is complete when:

- GameState root fields are defined;
- PlayerState fields are defined;
- RandomState is defined;
- MarketState is defined;
- EngineState is defined;
- StatusBuildingsState is defined;
- DefenseState is defined;
- ContractRuntime is defined;
- ContactState is defined;
- ContactOfferState is defined;
- StreetDealState is defined;
- DebtState is defined;
- TemporaryModifier is defined;
- RoleFlags are defined;
- TurfFlags are defined;
- AIBossState is defined;
- CombatLogEntry is defined;
- GameResult is defined;
- ownership rules are explicit;
- setup_working and committed validation modes are explicit;
- every runtime object has an exact required key set, type contract, empty-value rule, and ID format;
- null and undocumented compatibility aliases are rejected;
- reset rules are explicit;
- validation rules are explicit;
- mutation boundaries are explicit;
- state is serializable;
- UI cannot directly mutate gameplay state;
- GUT tests can validate the schema.

## 33. Final Rule

GameState is the runtime truth.

Resources define what exists.
Logic modules define what changes.
GameState stores what happened.
UI displays state and sends intent.

No Node, no Resource, no hidden singleton state, no mystery side effects.
