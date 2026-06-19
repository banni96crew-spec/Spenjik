# IDs and Constants

## Document Role

This file defines only: canonical string IDs, constant groups, enum-like values, validation error codes, and naming rules for The Turf.

This file must not redefine:

card prices;
card effects;
role effects;
contract rewards;
combat resolution;
AI scoring;
UI behavior;
state schema beyond ID field names referenced for clarity.

Source of truth dependencies:

00_INDEX.md
02_CORE_LOOP_AND_PHASES.md
04_GAME_STATE_SCHEMA.md
05_CARDS_DATABASE.md
07_COMBAT_SYSTEM.md
08_ROLES.md
09_CONTRACTS.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md
12_TURF_LEVELS.md
13_AI_SYSTEM.md
20_LLM_AGENT_RULES.md

Implementation target:

Godot 4.6.2
GDScript
GUT tests

## 1. Purpose

This file is the canonical source of truth for all stable string IDs used by the project.

All gameplay systems must use constants from this file or from the corresponding .gd constant files generated from this specification.

No gameplay system should hardcode raw ID strings directly unless the string is defined in this document.

## 2. ID Rules

All IDs must follow these rules:

- IDs must use snake_case.
- IDs must be lowercase.
- IDs must be stable across the whole project.
- IDs must not be translated.
- IDs must not use display titles.
- IDs must not contain spaces.
- IDs must not contain hyphens.
- IDs must not be renamed after implementation begins.
- IDs must be used consistently in Resources, GameState dictionaries, tests, and UI selectors.

Correct:

district_control
federal_raid
gray_cardinal
black_market_cache

Incorrect:

District Control
district-control
districtControl
federal raid
FederalRaid

## 3. Constant File Location

All ID and constant files must be placed in:

res://data/ids/

Required files:

res://data/ids/GameIds.gd
res://data/ids/PhaseIds.gd
res://data/ids/AttackModes.gd
res://data/ids/ValidationErrors.gd
res://data/ids/RoleIds.gd
res://data/ids/ContractIds.gd
res://data/ids/ContactIds.gd
res://data/ids/StreetDealIds.gd
res://data/ids/AIProfileIds.gd
res://data/ids/CardTypes.gd
res://data/ids/CardDestinations.gd
res://data/ids/DefenseStates.gd
res://data/ids/RewardTypes.gd
res://data/ids/EffectTypes.gd
res://data/ids/ModifierTypes.gd
res://data/ids/LogEventTypes.gd
res://data/ids/TieBreakIds.gd
res://data/ids/TurfLevelIds.gd
res://data/ids/StreetDealOptionIds.gd
res://data/ids/StateKeys.gd

Each file must use class_name.

Each source file must stay under 250 lines.

## 4. GameIds.gd

### 4.1. Responsibility

GameIds.gd owns player IDs and card IDs.

It must not define:

phases;
roles;
contracts;
contacts;
Street Deals;
AI profiles;
validation errors.

### 4.2. Required Constants

class_name GameIds

const PLAYER_HUMAN := "player_1"
const PLAYER_AI_1 := "ai_1"
const PLAYER_AI_2 := "ai_2"
const PLAYER_AI_3 := "ai_3"

const PLAYER_IDS := [
	PLAYER_HUMAN,
	PLAYER_AI_1,
	PLAYER_AI_2,
	PLAYER_AI_3
]

const AI_PLAYER_IDS := [
	PLAYER_AI_1,
	PLAYER_AI_2,
	PLAYER_AI_3
]

const CARD_INFORMANT := "informant"
const CARD_LAUNDRY := "laundry"
const CARD_ACCOUNTANT := "accountant"
const CARD_BROTHEL := "brothel"
const CARD_STASH := "stash"
const CARD_WORKSHOP := "workshop"
const CARD_DISTRICT_CONTROL := "district_control"
const CARD_COPS := "cops"
const CARD_CARTEL := "cartel"
const CARD_JUDGE := "judge"
const CARD_THUG := "thug"
const CARD_BRUISER := "bruiser"
const CARD_CLEANER := "cleaner"
const CARD_INSIDER := "insider"
const CARD_SABOTEUR := "saboteur"
const CARD_FEDERAL_RAID := "federal_raid"

const CARD_IDS := [
	CARD_INFORMANT,
	CARD_LAUNDRY,
	CARD_ACCOUNTANT,
	CARD_BROTHEL,
	CARD_STASH,
	CARD_WORKSHOP,
	CARD_DISTRICT_CONTROL,
	CARD_COPS,
	CARD_CARTEL,
	CARD_JUDGE,
	CARD_THUG,
	CARD_BRUISER,
	CARD_CLEANER,
	CARD_INSIDER,
	CARD_SABOTEUR,
	CARD_FEDERAL_RAID
]

## 5. CardTypes.gd

### 5.1. Responsibility

CardTypes.gd owns card type constants.

### 5.2. Required Constants

class_name CardTypes

const ENGINE := "engine"
const STATUS := "status"
const DEFENSE := "defense"
const WAR := "war"

const ALL := [
	ENGINE,
	STATUS,
	DEFENSE,
	WAR
]

### 5.3. Usage Rules

Card type constants are used by:

card Resources;
MarketLogic;
PriceLogic;
CombatEngine;
UI selectors.

UI may display card types but must not use card type constants to resolve gameplay effects.

## 6. CardDestinations.gd

### 6.1. Responsibility

CardDestinations.gd owns card destination constants.

### 6.2. Required Constants

class_name CardDestinations

const TABLE := "table"
const HAND := "hand"

const ALL := [
	TABLE,
	HAND
]

### 6.3. Usage Rules

Destination determines where a purchased card goes:

- Engine cards go to table.
- Status cards go to table.
- Defense cards go to table.
- War cards go to hand.

The detailed purchase rules are defined in:

06_ECONOMY_AND_MARKET.md

## 7. PhaseIds.gd

### 7.1. Responsibility

PhaseIds.gd owns all valid phase IDs.

### 7.2. Required Constants

class_name PhaseIds

const SETUP := "setup"
const INCOME := "income"
const MARKET := "market"
const ACTION := "action"
const STREET_DEAL := "street_deal"
const GAME_OVER := "game_over"

const ALL := [
	SETUP,
	INCOME,
	MARKET,
	ACTION,
	STREET_DEAL,
	GAME_OVER
]

### 7.3. Usage Rules

Only these phase IDs are valid in MVP.

The current phase must be stored as:

state["current_phase"]

Phase transition rules are defined in:

02_CORE_LOOP_AND_PHASES.md

## 8. AttackModes.gd

### 8.1. Responsibility

AttackModes.gd owns attack mode constants.

### 8.2. Required Constants

class_name AttackModes

const STEAL_NAL := "steal_nal"
const DESTROY_STASH := "destroy_stash"
const DESTROY_WORKSHOP := "destroy_workshop"
const DESTROY_DISTRICT := "destroy_district"

const ALL := [
	STEAL_NAL,
	DESTROY_STASH,
	DESTROY_WORKSHOP,
	DESTROY_DISTRICT
]

### 8.3. Usage Rules

Attack modes are used in combat payloads:

{
	"attacker_id": "player_1",
	"target_id": "ai_1",
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"modifiers": ["insider"]
}

Mode requirements are defined in:

07_COMBAT_SYSTEM.md

## 9. ValidationErrors.gd

### 9.1. Responsibility

ValidationErrors.gd owns stable error codes returned by logic modules and GameStateManager.

Error codes must be stable and must not be translated.

UI may map these error codes to localized display text later.

### 9.2. Required Constants

class_name ValidationErrors

const OK := ""

const CARD_NOT_AVAILABLE_IN_MARKET := "CARD_NOT_AVAILABLE_IN_MARKET"
const NOT_ENOUGH_NAL := "NOT_ENOUGH_NAL"
const CARD_ALREADY_PURCHASED_THIS_ROUND := "CARD_ALREADY_PURCHASED_THIS_ROUND"
const REQUIREMENT_NOT_MET := "REQUIREMENT_NOT_MET"
const CARD_LIMIT_REACHED := "CARD_LIMIT_REACHED"

const INVALID_TARGET := "INVALID_TARGET"
const INVALID_PHASE := "INVALID_PHASE"
const PHASE_NOT_READY := "PHASE_NOT_READY"
const INVALID_ACTION_CARD := "INVALID_ACTION_CARD"
const TARGET_PROTECTED := "TARGET_PROTECTED"
const ATTACK_MODE_REQUIRED := "ATTACK_MODE_REQUIRED"
const INVALID_ATTACK_MODE := "INVALID_ATTACK_MODE"

const STREET_DEAL_CHOICE_UNAVAILABLE := "STREET_DEAL_CHOICE_UNAVAILABLE"
const INVALID_STREET_DEAL_OPTION := "INVALID_STREET_DEAL_OPTION"
const CONTACT_LOCKED := "CONTACT_LOCKED"
const CONTACT_ON_COOLDOWN := "CONTACT_ON_COOLDOWN"
const CONTACT_LIMIT_REACHED := "CONTACT_LIMIT_REACHED"
const CONTACT_OFFER_UNAVAILABLE := "CONTACT_OFFER_UNAVAILABLE"
const CONTACT_ALREADY_UNLOCKED := "CONTACT_ALREADY_UNLOCKED"
const CONTACT_ALREADY_USED := "CONTACT_ALREADY_USED"
const ACTIVE_DEBT_EXISTS := "ACTIVE_DEBT_EXISTS"
const INVALID_DEBT_STATE := "INVALID_DEBT_STATE"
const INVALID_MODIFIER_STATE := "INVALID_MODIFIER_STATE"

const CONTRACT_OFFER_UNAVAILABLE := "CONTRACT_OFFER_UNAVAILABLE"
const CONTRACT_NOT_SELECTED := "CONTRACT_NOT_SELECTED"
const CONTRACT_ALREADY_SELECTED := "CONTRACT_ALREADY_SELECTED"
const CONTRACT_ALREADY_COMPLETED := "CONTRACT_ALREADY_COMPLETED"
const CONTRACT_ALREADY_FAILED := "CONTRACT_ALREADY_FAILED"
const CONTRACT_ALREADY_CLAIMED := "CONTRACT_ALREADY_CLAIMED"
const CONTRACT_NOT_COMPLETED := "CONTRACT_NOT_COMPLETED"
const CONTRACT_NOT_CLAIMABLE := "CONTRACT_NOT_CLAIMABLE"

const INVALID_PLAYER_ID := "INVALID_PLAYER_ID"
const INVALID_CARD_ID := "INVALID_CARD_ID"
const INVALID_ROLE_ID := "INVALID_ROLE_ID"
const INVALID_CONTRACT_ID := "INVALID_CONTRACT_ID"
const INVALID_CONTACT_ID := "INVALID_CONTACT_ID"
const INVALID_STREET_DEAL_ID := "INVALID_STREET_DEAL_ID"
const INVALID_AI_PROFILE_ID := "INVALID_AI_PROFILE_ID"

const INVALID_STATE := "INVALID_STATE"
const INVALID_ROUND := "INVALID_ROUND"
const INVALID_TURF_LEVEL := "INVALID_TURF_LEVEL"
const INVALID_RANDOM_STATE := "INVALID_RANDOM_STATE"
const INVALID_ACTION_ORDER := "INVALID_ACTION_ORDER"
const INVALID_ACTIVE_ACTION_PLAYER := "INVALID_ACTIVE_ACTION_PLAYER"
const INVALID_AI_STATE := "INVALID_AI_STATE"
const NO_VALID_AI_ACTION := "NO_VALID_AI_ACTION"
const NO_VALID_AI_PURCHASE := "NO_VALID_AI_PURCHASE"

const NOT_ACTIVE_PLAYER := "NOT_ACTIVE_PLAYER"
const PLAYER_ALREADY_READY := "PLAYER_ALREADY_READY"
const PLAYER_ALREADY_ACTION_DONE := "PLAYER_ALREADY_ACTION_DONE"

const GAME_ALREADY_OVER := "GAME_ALREADY_OVER"
const GAME_NOT_STARTED := "GAME_NOT_STARTED"

const FORBIDDEN_RANDOM_API := "FORBIDDEN_RANDOM_API"

### 9.3. Error Return Rule

Logic modules must return errors using this shape:

{
	"ok": false,
	"error": ValidationErrors.INVALID_PHASE
}

Successful operations must return:

{
	"ok": true,
	"error": ValidationErrors.OK
}

The full GameStateManager return shape is defined in:

16_GAME_STATE_MANAGER_API.md

### 9.4. Canonical Validation Error Contract

Every non-OK validation error has the following invariant:

- the active GameState is unchanged;
- the working-state result is discarded;
- no gameplay log entry is appended;
- `state_changed`, `phase_changed`, `game_started`, and `game_ended` are not emitted;
- the facade returns the exact error code unchanged;
- UI maps the code to display text and must not infer a different gameplay reason.

`action_failed` may carry the same error code as a notification signal, but it does not change state.

| Error code | Triggering input or condition | Returning owner module | State on error | Propagation |
| --- | --- | --- | --- | --- |
| `CARD_NOT_AVAILABLE_IN_MARKET` | Requested `card_id` is valid but absent from current market. | MarketLogic | Unchanged | Facade -> UI disabled reason/result. |
| `NOT_ENOUGH_NAL` | Valid operation cost exceeds player Nal. | MarketLogic, StreetDealLogic | Unchanged | Facade -> UI. |
| `CARD_ALREADY_PURCHASED_THIS_ROUND` | Unique-per-round purchase is repeated. | MarketLogic | Unchanged | Facade -> UI. |
| `REQUIREMENT_NOT_MET` | A documented non-ID prerequisite fails and no more specific code exists. | Owning logic module | Unchanged | Facade -> UI. |
| `CARD_LIMIT_REACHED` | Card-specific ownership limit would be exceeded. | MarketLogic | Unchanged | Facade -> UI. |
| `INVALID_TARGET` | Target/player role is not legal for the requested action. | CombatEngine or domain logic | Unchanged | Facade -> UI/AI caller. |
| `INVALID_PHASE` | Operation is requested outside its legal phase. | GamePhaseController or owner logic | Unchanged | Facade -> UI/AI caller. |
| `PHASE_NOT_READY` | `advance_phase` is requested before the current phase completion conditions are satisfied. | GamePhaseController | Unchanged | Facade -> UI/AI orchestration. |
| `INVALID_ACTION_CARD` | Action card is missing from hand or is not a legal action card. | CombatEngine | Unchanged | Facade -> UI/AI caller. |
| `TARGET_PROTECTED` | Target protection blocks the requested attack before resolution. | CombatEngine | Unchanged | Facade -> UI/AI caller. |
| `ATTACK_MODE_REQUIRED` | A multi-mode attack omits `mode`. | CombatEngine | Unchanged | Facade -> UI/AI caller. |
| `INVALID_ATTACK_MODE` | `mode` is absent from `AttackModes.ALL` or illegal for the card. | CombatEngine | Unchanged | Facade -> UI/AI caller. |
| `STREET_DEAL_CHOICE_UNAVAILABLE` | No current/eligible deal, already resolved choice, or selected option is unavailable. | StreetDealLogic | Unchanged | Facade -> UI. |
| `INVALID_STREET_DEAL_OPTION` | `option_id` is not in `StreetDealOptionIds.ALL`. | StreetDealLogic | Unchanged | Facade -> UI. |
| `CONTACT_LOCKED` | Contact is valid but not unlocked or not part of pending offer. | ContactLogic | Unchanged | Facade -> UI. |
| `CONTACT_ON_COOLDOWN` | Unlocked active contact has positive cooldown. | ContactLogic | Unchanged | Facade -> UI. |
| `CONTACT_LIMIT_REACHED` | Human already owns the MVP maximum of one contact. | ContactLogic | Unchanged | Facade -> UI. |
| `CONTACT_OFFER_UNAVAILABLE` | Contact offer cannot be created/resolved because source, availability, or pending-offer state is invalid. | ContactLogic | Unchanged | Facade -> UI. |
| `CONTACT_ALREADY_UNLOCKED` | Selected contact already exists in `player["contacts"]["unlocked"]`. | ContactLogic | Unchanged | Facade -> UI. |
| `CONTACT_ALREADY_USED` | One-use active contact has already been consumed. | ContactLogic | Unchanged | Facade -> UI. |
| `ACTIVE_DEBT_EXISTS` | Loan Shark would create a debt while an unpaid debt exists. | StreetDealLogic / DebtLogic | Unchanged | Facade -> UI. |
| `INVALID_DEBT_STATE` | Debt shape, runtime ID, amount, deadline, penalty, or resolution fields are invalid. | DebtLogic / GameStateValidator | Unchanged | Facade -> UI or test failure detail. |
| `INVALID_MODIFIER_STATE` | Modifier shape/ID is invalid or the same source-owner-round modifier already exists. | PriceLogic / GameStateValidator | Unchanged | Facade -> UI or test failure detail. |
| `CONTRACT_OFFER_UNAVAILABLE` | Setup preview cannot produce exactly three unique deterministic valid contract IDs, or the selected valid contract ID is not in the regenerated offer set. | ContractLogic | Unchanged | Facade -> setup UI. |
| `CONTRACT_NOT_SELECTED` | Contract operation has no human runtime contract. | ContractLogic | Unchanged | Facade -> UI. |
| `CONTRACT_ALREADY_SELECTED` | Setup contract selection is attempted when the human already has a runtime contract or `selected_contract_id` is already committed. | ContractLogic | Unchanged | Facade -> setup UI/test caller. |
| `CONTRACT_ALREADY_COMPLETED` | An operation requires active incomplete contract but it is completed. | ContractLogic | Unchanged | Facade -> UI/test caller. |
| `CONTRACT_ALREADY_FAILED` | Operation targets a failed contract. | ContractLogic | Unchanged | Facade -> UI. |
| `CONTRACT_ALREADY_CLAIMED` | Claim is repeated after reward application. | ContractLogic | Unchanged | Facade -> UI. |
| `CONTRACT_NOT_COMPLETED` | Claim is requested before completion. | ContractLogic | Unchanged | Facade -> UI. |
| `CONTRACT_NOT_CLAIMABLE` | Contract exists but its state combination cannot legally be claimed. | ContractLogic | Unchanged | Facade -> UI. |
| `INVALID_PLAYER_ID` | Player ID is absent from `GameIds.PLAYER_IDS`. | Any boundary validator | Unchanged | Facade -> UI/AI caller. |
| `INVALID_CARD_ID` | Card ID is absent from `GameIds.CARD_IDS`. | Any card boundary validator | Unchanged | Facade -> UI/AI caller. |
| `INVALID_ROLE_ID` | Role ID is absent from `RoleIds.ALL`. | RoleLogic / setup | Unchanged | Facade -> setup UI. |
| `INVALID_CONTRACT_ID` | Contract ID is absent from `ContractIds.ALL`. | ContractLogic / setup | Unchanged | Facade -> setup UI. |
| `INVALID_CONTACT_ID` | Contact ID is absent from `ContactIds.ALL`. | ContactLogic | Unchanged | Facade -> UI. |
| `INVALID_STREET_DEAL_ID` | Street Deal ID is absent from `StreetDealIds.ALL`. | StreetDealLogic | Unchanged | Facade -> UI/test caller. |
| `INVALID_AI_PROFILE_ID` | AI profile ID is absent from `AIProfileIds.ALL`. | AIBotController / setup | Unchanged | Facade -> setup failure. |
| `INVALID_STATE` | Candidate GameState or required nested shape fails the canonical schema. | GameStateValidator | Unchanged | Facade -> caller; details identify path. |
| `INVALID_ROUND` | Round is outside `1..15` or incompatible with requested transition. | GamePhaseController | Unchanged | Facade -> UI/test caller. |
| `INVALID_TURF_LEVEL` | Turf Level is not an integer in `TurfLevelIds.ALL`. | TurfLevelLogic / setup | Unchanged | Facade -> setup UI. |
| `INVALID_RANDOM_STATE` | RandomState shape, seed, step, or deterministic operation is invalid. | SeededRandom / GameStateValidator | Unchanged | Facade -> caller/test. |
| `INVALID_ACTION_ORDER` | Action order is missing, duplicated, or not the canonical player order. | GamePhaseController | Unchanged | Facade -> UI/AI orchestration. |
| `INVALID_ACTIVE_ACTION_PLAYER` | Active player is empty/invalid while an Action turn remains, or not in action order. | GamePhaseController | Unchanged | Facade -> UI/AI orchestration. |
| `INVALID_AI_STATE` | AI player/profile assignment, strong-AI count, or required AI runtime data is invalid. | AIBotController / GameStateValidator | Unchanged | Facade -> AI orchestration/setup. |
| `NO_VALID_AI_ACTION` | No legal action and no legal fallback can complete the AI Action turn. | AIBotController | Unchanged | Facade -> phase orchestration; treated as hard failure. |
| `NO_VALID_AI_PURCHASE` | No legal purchase and no legal end-market fallback can complete the AI Market turn. | AIBotController | Unchanged | Facade -> phase orchestration; treated as hard failure. |
| `NOT_ACTIVE_PLAYER` | Player calls an Action operation while another player is active. | GamePhaseController / CombatEngine | Unchanged | Facade -> UI/AI caller. |
| `PLAYER_ALREADY_READY` | Market completion is submitted twice. | GamePhaseController | Unchanged | Facade -> UI/AI caller. |
| `PLAYER_ALREADY_ACTION_DONE` | Action completion/skip is submitted twice. | GamePhaseController | Unchanged | Facade -> UI/AI caller. |
| `GAME_ALREADY_OVER` | Gameplay mutator is called after Game Over. | GamePhaseController / facade guard | Unchanged | Facade -> UI/AI caller. |
| `GAME_NOT_STARTED` | Gameplay mutator or direct phase transition call receives `{}` before setup. | GameStateManager / GamePhaseController | Unchanged | Facade -> UI/AI caller. |
| `FORBIDDEN_RANDOM_API` | Static/runtime guard detects non-deterministic gameplay random API. | Determinism guard/tests | Unchanged | Build/test failure; never localized as normal UI state. |

## 10. RoleIds.gd

### 10.1. Responsibility

RoleIds.gd owns role IDs.

### 10.2. Required Constants

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

### 10.3. Usage Rules

Role IDs are used by:

role Resources;
setup flow;
RoleLogic;
PriceLogic;
GameState validation.

Role rules are defined in:

08_ROLES.md

## 11. ContractIds.gd

### 11.1. Responsibility

ContractIds.gd owns contract IDs.

### 11.2. Required Constants

class_name ContractIds

const SILENT_EXPANSION := "silent_expansion"
const BLOODY_TURF_WAR := "bloody_turf_war"
const GRAY_CAPITAL := "gray_capital"
const IRON_ROOF := "iron_roof"
const DISTRICT_UNDER_CONTROL := "district_under_control"
const PROXY_WAR := "proxy_war"
const BIG_CASHBOX := "big_cashbox"

const ALL := [
	SILENT_EXPANSION,
	BLOODY_TURF_WAR,
	GRAY_CAPITAL,
	IRON_ROOF,
	DISTRICT_UNDER_CONTROL,
	PROXY_WAR,
	BIG_CASHBOX
]

### 11.3. Usage Rules

Contract IDs are used by:

contract Resources;
ContractLogic;
GameState contract runtime;
setup flow;
tests.

Contract rules are defined in:

09_CONTRACTS.md

## 12. ContactIds.gd

### 12.1. Responsibility

ContactIds.gd owns contact IDs.

### 12.2. Required Constants

class_name ContactIds

const BLACK_CASH := "black_cash"
const CORRUPT_CLERK := "corrupt_clerk"
const STREET_MEDIC := "street_medic"

const ALL := [
	BLACK_CASH,
	CORRUPT_CLERK,
	STREET_MEDIC
]

### 12.3. Usage Rules

Contact IDs are used by:

contact Resources;
ContactLogic;
StreetDealLogic;
IncomeLogic;
DebtLogic;
GameState validation.

Contact rules are defined in:

11_CONTACTS.md

## 13. StreetDealIds.gd

### 13.1. Responsibility

StreetDealIds.gd owns Street Deal IDs.

### 13.2. Required Constants

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

### 13.3. Usage Rules

Street Deal IDs are used by:

StreetDealDefinition Resources;
StreetDealLogic;
DebtLogic;
ContactLogic;
GameState validation;
tests.

Street Deal rules are defined in:

10_STREET_DEALS_AND_DEBTS.md

## 14. AIProfileIds.gd

### 14.1. Responsibility

AIProfileIds.gd owns AI profile IDs.

### 14.2. Required Constants

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

### 14.3. Usage Rules

AI profile IDs are used by:

AIProfileDefinition Resources;
AIBotController;
AIPurchaseLogic;
AITargetLogic;
setup flow;
tests.

AI rules are defined in:

13_AI_SYSTEM.md

### 14.4. Naming Note

The Merchant AI profile uses the domain-scoped profile ID:

merchant

Its Resource file may be named `merchant_ai.tres`.

The role and AI profile share the string value `merchant`, but remain separate because they are validated through different constant classes:

RoleIds.MERCHANT = "merchant"
AIProfileIds.MERCHANT = "merchant"

## 15. DefenseStates.gd

### 15.1. Responsibility

DefenseStates.gd owns defense runtime state values.

### 15.2. Required Constants

class_name DefenseStates

const NONE := "none"
const ACTIVE := "active"
const DEPLETED := "depleted"

const ALL_CARTEL := [
	NONE,
	ACTIVE,
	DEPLETED
]

const ALL_JUDGE := [
	NONE,
	ACTIVE
]

### 15.3. Usage Rules

These values are used by:

player["defense"]["cartel_state"]
player["defense"]["judge_state"]

Cartel state must be validated against `ALL_CARTEL`.
Judge state must be validated against `ALL_JUDGE`.

Cops use explicit fields:

player["defense"]["cops_active"]
player["defense"]["cops_timer"]

Detailed defense behavior is defined in:

07_COMBAT_SYSTEM.md

## 16. RewardTypes.gd

### 16.1. Responsibility

RewardTypes.gd owns reward type values used by contracts, Street Deals, contacts, and other reward systems.

### 16.2. Required Constants

class_name RewardTypes

const NAL := "nal"
const VP := "vp"
const CARD_TO_HAND := "card_to_hand"
const CONTACT_CHOICE := "contact_choice"
const TEMPORARY_MODIFIER := "temporary_modifier"
const DEBT := "debt"
const DEFENSE := "defense"

const ALL := [
	NAL,
	VP,
	CARD_TO_HAND,
	CONTACT_CHOICE,
	TEMPORARY_MODIFIER,
	DEBT,
	DEFENSE
]

### 16.3. Usage Rules

Reward types identify what kind of reward or penalty is being applied.

They do not define the actual value of rewards.

Reward amounts and conditions are owned by the relevant system files:

09_CONTRACTS.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md

## 17. EffectTypes.gd

### 17.1. Responsibility

EffectTypes.gd owns generic effect type constants for data-driven effect payloads.

### 17.2. Required Constants

class_name EffectTypes

const ADD_NAL := "add_nal"
const LOSE_NAL := "lose_nal"
const ADD_VP := "add_vp"
const LOSE_VP := "lose_vp"

const ADD_CARD_TO_HAND := "add_card_to_hand"
const REMOVE_CARD_FROM_HAND := "remove_card_from_hand"

const ADD_TEMPORARY_MODIFIER := "add_temporary_modifier"
const REMOVE_TEMPORARY_MODIFIER := "remove_temporary_modifier"

const CREATE_DEBT := "create_debt"
const REPAY_DEBT := "repay_debt"
const APPLY_DEBT_PENALTY := "apply_debt_penalty"

const UNLOCK_CONTACT := "unlock_contact"
const ACTIVATE_CONTACT := "activate_contact"

const SET_SKIP_NEXT_ACTION := "set_skip_next_action"
const SET_DEFENSE_STATE := "set_defense_state"

const ALL := [
	ADD_NAL,
	LOSE_NAL,
	ADD_VP,
	LOSE_VP,
	ADD_CARD_TO_HAND,
	REMOVE_CARD_FROM_HAND,
	ADD_TEMPORARY_MODIFIER,
	REMOVE_TEMPORARY_MODIFIER,
	CREATE_DEBT,
	REPAY_DEBT,
	APPLY_DEBT_PENALTY,
	UNLOCK_CONTACT,
	ACTIVATE_CONTACT,
	SET_SKIP_NEXT_ACTION,
	SET_DEFENSE_STATE
]

### 17.3. Usage Rules

Effect types may be used by:

StreetDealDefinition option effects;
ContactLogic;
ContractLogic;
temporary modifiers.

Combat card effects should still be resolved by CombatEngine, not by generic text parsing.

## 18. ModifierTypes.gd

### 18.1. Responsibility

ModifierTypes.gd owns temporary and runtime modifier type constants.

### 18.2. Required Constants

class_name ModifierTypes

const CARD_PRICE_DELTA := "card_price_delta"
const NEXT_DEFENSE_CARD_PRICE_DELTA := "next_defense_card_price_delta"
const NEXT_WAR_CARD_PRICE_DELTA := "next_war_card_price_delta"
const NEXT_STATUS_CARD_PRICE_DELTA := "next_status_card_price_delta"
const IGNORE_COPS := "ignore_cops"
const WAR_PURCHASE_WEIGHT_MULTIPLIER := "war_purchase_weight_multiplier"

const ALL := [
	CARD_PRICE_DELTA,
	NEXT_DEFENSE_CARD_PRICE_DELTA,
	NEXT_WAR_CARD_PRICE_DELTA,
	NEXT_STATUS_CARD_PRICE_DELTA,
	IGNORE_COPS,
	WAR_PURCHASE_WEIGHT_MULTIPLIER
]

### 18.3. Usage Rules

Temporary modifiers must be stored in the game state as structured dictionaries.

A recommended shape:

{
	"id": "",
	"type": ModifierTypes.CARD_PRICE_DELTA,
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

The exact state schema is defined in:

04_GAME_STATE_SCHEMA.md

## 19. LogEventTypes.gd

### 19.1. Responsibility

LogEventTypes.gd owns stable event type constants for game logs and combat logs.

### 19.2. Required Constants

class_name LogEventTypes

const MATCH_STARTED := "match_started"
const ROUND_STARTED := "round_started"
const PHASE_CHANGED := "phase_changed"

const INCOME_RESOLVED := "income_resolved"
const COPS_UPKEEP_PAID := "cops_upkeep_paid"
const COPS_DEACTIVATED := "cops_deactivated"
const MARKET_STARTED := "market_started"
const CARD_PURCHASED := "card_purchased"
const MARKET_ENDED_FOR_PLAYER := "market_ended_for_player"

const ACTION_STARTED := "action_started"
const ATTACK_EXECUTED := "attack_executed"
const ATTACK_BLOCKED := "attack_blocked"
const CARD_DISCARDED := "card_discarded"
const ACTION_SKIPPED := "action_skipped"
const ACTION_ENDED_FOR_PLAYER := "action_ended_for_player"

const STREET_DEAL_OFFERED := "street_deal_offered"
const STREET_DEAL_RESOLVED := "street_deal_resolved"
const DEBT_CREATED := "debt_created"
const DEBT_REPAID := "debt_repaid"
const DEBT_PENALTY_APPLIED := "debt_penalty_applied"

const CONTACT_UNLOCKED := "contact_unlocked"
const CONTACT_OFFERED := "contact_offered"
const CONTACT_ACTIVATED := "contact_activated"

const CONTRACT_PROGRESS_UPDATED := "contract_progress_updated"
const CONTRACT_COMPLETED := "contract_completed"
const CONTRACT_FAILED := "contract_failed"
const CONTRACT_REWARD_CLAIMED := "contract_reward_claimed"

const GAME_OVER_REACHED := "game_over_reached"
const WINNER_RESOLVED := "winner_resolved"

const ALL := [
	MATCH_STARTED,
	ROUND_STARTED,
	PHASE_CHANGED,
	INCOME_RESOLVED,
	COPS_UPKEEP_PAID,
	COPS_DEACTIVATED,
	MARKET_STARTED,
	CARD_PURCHASED,
	MARKET_ENDED_FOR_PLAYER,
	ACTION_STARTED,
	ATTACK_EXECUTED,
	ATTACK_BLOCKED,
	CARD_DISCARDED,
	ACTION_SKIPPED,
	ACTION_ENDED_FOR_PLAYER,
	STREET_DEAL_OFFERED,
	STREET_DEAL_RESOLVED,
	DEBT_CREATED,
	DEBT_REPAID,
	DEBT_PENALTY_APPLIED,
	CONTACT_UNLOCKED,
	CONTACT_OFFERED,
	CONTACT_ACTIVATED,
	CONTRACT_PROGRESS_UPDATED,
	CONTRACT_COMPLETED,
	CONTRACT_FAILED,
	CONTRACT_REWARD_CLAIMED,
	GAME_OVER_REACHED,
	WINNER_RESOLVED
]

### 19.3. Usage Rules

Log event types are used by:

CombatLogBuilder;
GamePhaseController;
ContractLogic;
ContactLogic;
StreetDealLogic;
DebtLogic;
GameOver summary.

UI may display log entries but must not create gameplay results.

### 19.4. Canonical Event Envelope and Consumer Rule

Every event uses the exact CombatLogEntry envelope from `04_GAME_STATE_SCHEMA.md`.

`details` must contain every field listed below for its event type and must not contain undocumented keys. Empty IDs in the envelope are allowed only where the event has no actor, target, or card.

All event types are consumed by UI history, debug tooling, GUT tests, and optional read-only analytics export. AI decisions must not read `combat_log` as gameplay state; AI context comes from canonical state fields and selectors.

Events are appended to the same candidate GameState transaction as their state change. Failed validation appends no event.

### 19.5. Complete LogEventTypes Payload Contract

| Event type | Created when | Required `details` fields | State relationship | Consumers |
| --- | --- | --- | --- | --- |
| `MATCH_STARTED` | `start_new_game` commits. | `game_seed`, `turf_level`, `selected_role_id`, `contract_offer_ids`, `selected_contract_id`, `ai_profile_ids`, `strong_ai_player_id` | Records the committed setup snapshot. | UI, debug, tests, analytics; not AI state. |
| `ROUND_STARTED` | `advance_phase` increments the match to round 2..15. | `round` | Records round/reset commit; round 1 is covered by `MATCH_STARTED`. | UI, debug, tests, analytics; not AI state. |
| `PHASE_CHANGED` | `advance_phase` commits a transition. | `from_phase`, `to_phase`, `round_before`, `round_after` | Records the exact committed phase and round change. | UI, debug, tests, analytics; not AI state. |
| `INCOME_RESOLVED` | Income resolves for one player. | `player_id`, `die_1`, `die_2`, `dice_sum`, `laundry_income`, `informant_income`, `brothel_income`, `total_income`, `nal_before`, `nal_after` | Mirrors committed Nal change before upkeep/debt events. | UI, debug, tests, analytics; not AI state. |
| `COPS_UPKEEP_PAID` | Due Cops upkeep is paid during Income. | `player_id`, `amount_paid`, `interval`, `timer_before`, `timer_after`, `nal_before`, `nal_after` | Mirrors Nal deduction and Cops timer reset. | UI, debug, tests, analytics; not AI state. |
| `COPS_DEACTIVATED` | Due Cops upkeep cannot be paid during Income. | `player_id`, `interval`, `timer_before`, `timer_after`, `nal` | Mirrors `cops_active == false` and timer reset. | UI, debug, tests, analytics; not AI state. |
| `MARKET_STARTED` | Market entry setup completes. | `round`, `available_card_ids` | Mirrors committed MarketState. | UI, debug, tests, analytics; not AI state. |
| `CARD_PURCHASED` | A card purchase commits. | `player_id`, `card_id`, `base_price`, `final_price`, `nal_before`, `nal_after`, `destination`, `applied_modifier_ids` | Mirrors card placement, payment, and consumed modifiers. | UI, debug, tests, analytics; not AI state. |
| `MARKET_ENDED_FOR_PLAYER` | A player successfully becomes ready. | `player_id` | Mirrors `ready_for_action == true`. | UI, debug, tests, analytics; not AI state. |
| `ACTION_STARTED` | Action entry establishes turn order. | `action_order`, `active_player_id` | Mirrors committed action order and active player. | UI, debug, tests, analytics; not AI state. |
| `ATTACK_EXECUTED` | A legal unblocked attack commits. | `attacker_id`, `target_id`, `card_id`, `mode`, `modifiers`, `engine_target_card_id`, `cards_consumed` | Identifies the committed attack; canonical GameState contains the resulting Nal, VP, card, building, and flag changes. | UI, debug, tests, analytics; not AI state. |
| `ATTACK_BLOCKED` | A legal attack is consumed but blocked by defense. | `attacker_id`, `target_id`, `card_id`, `mode`, `modifiers`, `engine_target_card_id`, `cards_consumed`, `block_source` | Identifies the blocked attack and consumed cards; canonical GameState contains defense side effects. | UI, debug, tests, analytics; not AI state. |
| `CARD_DISCARDED` | An action card is discarded without attack resolution. | `player_id`, `card_id` | Mirrors removal from hand. | UI, debug, tests, analytics; not AI state. |
| `ACTION_SKIPPED` | A player legally skips Action. | `player_id` | Mirrors skip/action completion flags. | UI, debug, tests, analytics; not AI state. |
| `ACTION_ENDED_FOR_PLAYER` | A player's Action turn completes. | `player_id` | Mirrors `action_done == true` and next active player. | UI, debug, tests, analytics; not AI state. |
| `STREET_DEAL_OFFERED` | Street Deal generation commits. | `deal_id`, `available_option_ids` | Mirrors `current_deal_id` and `option_availability`. | UI, debug, tests, analytics; not AI state. |
| `STREET_DEAL_RESOLVED` | Human Street Deal selection commits. | `player_id`, `deal_id`, `option_id` | Identifies the committed choice; canonical GameState and any companion debt/contact event contain its effects. | UI, debug, tests, analytics; not AI state. |
| `DEBT_CREATED` | Loan Shark option creates debt. | `player_id`, `debt_id`, `source`, `amount_due`, `deadline_round` | Mirrors appended DebtState. | UI, debug, tests, analytics; not AI state. |
| `DEBT_REPAID` | Income debt processing auto-repays debt. | `player_id`, `debt_id`, `amount_paid`, `nal_before`, `nal_after` | Mirrors Nal deduction and resolved debt fields. | UI, debug, tests, analytics; not AI state. |
| `DEBT_PENALTY_APPLIED` | Overdue unpaid debt penalty commits. | `player_id`, `debt_id`, `lose_all_nal`, `vp_delta`, `nal_lost`, `vp_lost` | Mirrors penalty resource changes and resolved debt fields. | UI, debug, tests, analytics; not AI state. |
| `CONTACT_OFFERED` | ContactLogic commits a non-empty pending contact offer. | `player_id`, `source`, `contact_offer_ids`, `created_round` | Mirrors `state["contacts"]["pending_offer"]`. | UI, debug, tests, analytics; not AI state. |
| `CONTACT_UNLOCKED` | Pending contact selection commits. | `player_id`, `contact_id`, `source` | Mirrors owned contact and cleared pending offer. | UI, debug, tests, analytics; not AI state. |
| `CONTACT_ACTIVATED` | One-shot or passive contact effect is consumed. | `player_id`, `contact_id` | Mirrors contact usage/cooldown/flag changes. | UI, debug, tests, analytics; not AI state. |
| `CONTRACT_PROGRESS_UPDATED` | Contract progress changes without completion/failure. | `player_id`, `contract_id`, `progress_before`, `progress_after`, `source_event_type` | Mirrors committed ContractRuntime progress. | UI, debug, tests, analytics; not AI state. |
| `CONTRACT_COMPLETED` | Contract first reaches its condition by deadline. | `player_id`, `contract_id`, `completed_round` | Mirrors completed fields. | UI, debug, tests, analytics; not AI state. |
| `CONTRACT_FAILED` | A contract first enters failed state through its documented failure rule. | `player_id`, `contract_id`, `deadline`, `failed_reason` | Mirrors failed fields. | UI, debug, tests, analytics; not AI state. |
| `CONTRACT_REWARD_CLAIMED` | Manual claim commits. | `player_id`, `contract_id`, `reward_type`, `reward_amount`, `claimed_round` | Mirrors reward and claimed fields. | UI, debug, tests, analytics; not AI state. |
| `GAME_OVER_REACHED` | Round 15 completion enters Game Over. | `round` | Mirrors `current_phase == game_over`. | UI, debug, tests, analytics; not AI state. |
| `WINNER_RESOLVED` | WinnerResolver commits final result. | `winner_id`, `final_scores`, `tie_break_used`, `tie_break_steps`, `turf_level_10_ai_win_applied` | Mirrors `winner_id` and exact GameResult. | UI, debug, tests, analytics; not AI state. |

### 19.6. Log Payload Field Types

Every required `details` field uses the following type. Event payloads may not contain undocumented fields.

| Field | Type / domain |
| --- | --- |
| `game_seed` | non-empty `String` |
| `turf_level`, `round`, `round_before`, `round_after`, `die_1`, `die_2`, `dice_sum`, `laundry_income`, `informant_income`, `brothel_income`, `total_income`, `nal_before`, `nal_after`, `amount_paid`, `interval`, `timer_before`, `timer_after`, `nal`, `base_price`, `final_price`, `amount_due`, `deadline_round`, `vp_delta`, `nal_lost`, `vp_lost`, `created_round`, `progress_before`, `progress_after`, `completed_round`, `deadline`, `reward_amount`, `claimed_round` | `int` |
| `tie_break_used`, `turf_level_10_ai_win_applied`, `lose_all_nal` | `bool` |
| `selected_role_id` | `String` in `RoleIds.ALL` |
| `selected_contract_id`, `contract_id` | `String` in `ContractIds.ALL` |
| `contract_offer_ids` | three unique `String` values from `ContractIds.ALL` |
| `ai_profile_ids` | three unique `String` values from `AIProfileIds.ALL` |
| `strong_ai_player_id`, `player_id`, `active_player_id`, `attacker_id`, `target_id`, `winner_id` | canonical player ID `String`; strong AI ID must be in `GameIds.AI_PLAYER_IDS` |
| `from_phase`, `to_phase` | `String` in `PhaseIds.ALL` |
| `available_card_ids`, `cards_consumed`, `consumed_card_ids`, `modifiers` | unique `Array[String]` values from `GameIds.CARD_IDS` |
| `card_id`, `destroyed_card_id`, `engine_target_card_id` | `String`; empty only where the owner event explicitly permits it, otherwise in `GameIds.CARD_IDS` |
| `destination` | `String` in `CardDestinations.ALL` |
| `applied_modifier_ids` | unique `Array[String]` matching the modifier runtime ID format |
| `action_order` | exact `Array[String]` player order |
| `mode` | `String`; empty only for attacks that require no mode, otherwise in `AttackModes.ALL` |
| `block_source` | `String` exactly `cops`, `cartel`, or `judge` |
| `failed_reason` | `String` exactly `war_played` or `deadline_exceeded` |
| `source` | Event-specific `String`: `loan_shark` for `DEBT_CREATED`; `inside_contact` or `strong_ai_victory` for contact events |
| `source_event_type` | `String` in `LogEventTypes.ALL` |
| `reward_type` | `String` in `RewardTypes.ALL` |
| `deal_id` | `String` in `StreetDealIds.ALL` |
| `available_option_ids` | unique `Array[String]` from `StreetDealOptionIds.ALL` |
| `option_id` | `String` in `StreetDealOptionIds.ALL` |
| `debt_id` | `String` matching the canonical debt runtime ID format |
| `contact_id` | `String` in `ContactIds.ALL` |
| `contact_offer_ids` | unique non-empty `Array[String]` from `ContactIds.ALL` |
| `final_scores` | exact `Array[Dictionary]` of FinalScoreEntry from `04_GAME_STATE_SCHEMA.md` |
| `tie_break_steps` | exact `Array[Dictionary]` of TieBreakStep from `04_GAME_STATE_SCHEMA.md` |

Numeric event fields use the same bounds as their owning state fields. Validators must reject a missing required field, wrong type, out-of-domain ID, duplicate value where uniqueness is required, or extra payload field with `INVALID_STATE`.

## 20. TieBreakIds.gd

### 20.1. Responsibility

TieBreakIds.gd owns tie-break step IDs used by WinnerResolver.

### 20.2. Required Constants

class_name TieBreakIds

const VICTORY_POINTS := "victory_points"
const NAL := "nal"
const STATUS_BUILDING_VP_VALUE := "status_building_vp_value"
const STATUS_BUILDING_COUNT := "status_building_count"
const FIXED_PLAYER_ORDER := "fixed_player_order"
const TURF_LEVEL_10_AI_PRIORITY := "turf_level_10_ai_priority"

const ALL := [
	VICTORY_POINTS,
	NAL,
	STATUS_BUILDING_VP_VALUE,
	STATUS_BUILDING_COUNT,
	FIXED_PLAYER_ORDER,
	TURF_LEVEL_10_AI_PRIORITY
]

### 20.3. Usage Rules

Tie-break rules are defined in:

02_CORE_LOOP_AND_PHASES.md

WinnerResolver must use these constants when writing:

state["game_result"]["tie_break_steps"]

## 21. Turf Level Constants

### 21.1. File Ownership

Turf Level IDs are numeric, not string IDs.

They may be defined in:

res://data/ids/TurfLevelIds.gd

### 21.2. Required Constants

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

### 21.3. Usage Rules

Turf Level rules are defined in:

12_TURF_LEVELS.md

### 21.4. Canonical AI Player and Turf Level ID Lifecycle

AI player IDs are constants, not generated runtime strings:

- `GameStateFactory` creates players in exact order `player_1`, `ai_1`, `ai_2`, `ai_3`;
- `AIBotController` assigns profiles and strong status only to values from `GameIds.AI_PLAYER_IDS`;
- `GameStateValidator` validates player IDs, uniqueness, order, AI profile assignment, and strong-AI consistency before commit;
- action payloads, event payloads, UI view models, and tests must carry these exact IDs unchanged.

Turf Level uses one integer value:

- setup receives `turf_level: int`;
- valid values are exactly the members of `TurfLevelIds.ALL`;
- `GameStateFactory` copies the same integer to root `state["turf_level"]` and every `player["turf_level"]`;
- `GameStateValidator` rejects string values such as `"turf_5"`, `"level_5"`, or territory names with `INVALID_TURF_LEVEL`;
- event payloads, UI view models, selectors, and tests use the integer without string conversion.

No module may generate alternative AI player IDs or string Turf/territory IDs in MVP.

## 22. State Field Names

### 22.1. Purpose

State field names may be centralized if needed to reduce typo risk.

This is optional but recommended for frequently accessed fields.

### 22.2. Recommended File

res://data/ids/StateKeys.gd

### 22.3. Recommended Constants

class_name StateKeys

const ROUND := "round"
const CURRENT_PHASE := "current_phase"
const PLAYERS := "players"
const GAME_SEED := "game_seed"
const RANDOM := "random"
const TURF_LEVEL := "turf_level"
const SELECTED_ROLE_ID := "selected_role_id"
const SELECTED_CONTRACT_ID := "selected_contract_id"
const CONTRACT_OFFER_IDS := "contract_offer_ids"
const MARKET := "market"
const STREET_DEALS := "street_deals"
const CONTACTS := "contacts"
const AI_BOSSES := "ai_bosses"
const ACTION_ORDER := "action_order"
const ACTIVE_ACTION_PLAYER_ID := "active_action_player_id"
const COMBAT_LOG := "combat_log"
const WINNER_ID := "winner_id"
const GAME_RESULT := "game_result"

Player state keys:

const ID := "id"
const IS_AI := "is_ai"
const NAL := "nal"
const VP := "vp"
const ENGINE := "engine"
const STATUS_BUILDINGS := "status_buildings"
const DEFENSE := "defense"
const HAND := "hand"
const PURCHASED_THIS_ROUND := "purchased_this_round"
const READY_FOR_ACTION := "ready_for_action"
const ACTION_DONE := "action_done"
const SKIP_NEXT_ACTION := "skip_next_action"
const CONTRACTS := "contracts"
const DEBTS := "debts"
const ROLE_FLAGS := "role_flags"
const TURF_FLAGS := "turf_flags"
const TEMPORARY_MODIFIERS := "temporary_modifiers"
const IS_STRONG_AI := "is_strong_ai"
const LAST_ATTACKED_BY := "last_attacked_by"

### 22.4. Usage Rules

Using StateKeys.gd is recommended but not required.

If used, it must not replace the actual documented state schema in:

04_GAME_STATE_SCHEMA.md

## 23. Market Constants

### 23.1. File Ownership

Market card pools may be defined in:

res://logic/economy/MarketLogic.gd

or in a dedicated file:

res://data/ids/MarketConstants.gd

If a dedicated file is used, it must stay under 250 lines.

### 23.2. Required Values

class_name MarketConstants

const ALWAYS_AVAILABLE_CARD_IDS := [
	GameIds.CARD_INFORMANT,
	GameIds.CARD_STASH,
	GameIds.CARD_THUG,
	GameIds.CARD_COPS
]

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

### 23.3. Usage Rules

Market generation rules are defined in:

06_ECONOMY_AND_MARKET.md

## 24. Contract Runtime Status Constants

### 24.1. Optional File

Contract runtime status may be represented by booleans:

completed
failed

If explicit status values are preferred, use:

res://data/ids/ContractStatusIds.gd

### 24.2. Recommended Constants

class_name ContractStatusIds

const ACTIVE := "active"
const COMPLETED := "completed"
const FAILED := "failed"
const CLAIMED := "claimed"

const ALL := [
	ACTIVE,
	COMPLETED,
	FAILED,
	CLAIMED
]

### 24.3. Usage Rules

The final contract runtime schema is defined in:

09_CONTRACTS.md
04_GAME_STATE_SCHEMA.md

Do not introduce both boolean flags and status strings unless the schema explicitly allows it.

## 25. Street Deal Option Constants

### 25.1. Recommended File

res://data/ids/StreetDealOptionIds.gd

### 25.2. Required Constants

class_name StreetDealOptionIds

const OPTION_A := "option_a"
const OPTION_B := "option_b"

const ALL := [
	OPTION_A,
	OPTION_B
]

### 25.3. Usage Rules

Street Deal payloads should use these values:

{
	"player_id": "player_1",
	"deal_id": "loan_shark",
	"option_id": "option_a"
}

Street Deal rules are defined in:

10_STREET_DEALS_AND_DEBTS.md

## 26. Contact Kind Constants

### 26.1. Recommended File

res://data/ids/ContactKinds.gd

### 26.2. Required Constants

class_name ContactKinds

const PASSIVE := "passive"
const ACTIVE := "active"

const ALL := [
	PASSIVE,
	ACTIVE
]

### 26.3. Usage Rules

Contact kind values are used by ContactDefinition.gd.

Contact rules are defined in:

11_CONTACTS.md

## 27. AI Fallback Constants

### 27.1. Recommended File

res://data/ids/AIFallbackIds.gd

### 27.2. Required Constants

class_name AIFallbackIds

const END_PHASE := "end_phase"
const BUY_CHEAPEST_VALID := "buy_cheapest_valid"
const DISCARD_ACTION_CARDS := "discard_action_cards"
const ATTACK_BEST_TARGET := "attack_best_target"
const HOLD_NAL := "hold_nal"

const ALL := [
	END_PHASE,
	BUY_CHEAPEST_VALID,
	DISCARD_ACTION_CARDS,
	ATTACK_BEST_TARGET,
	HOLD_NAL
]

### 27.3. Usage Rules

AI fallback behavior is defined in:

13_AI_SYSTEM.md

## 28. Random Tag Naming Rules

Random tags are not gameplay IDs, but they must still be stable and readable.

Recommended format:

system_round_context

Examples:

market_round_1
income_player_1_round_3
ai_target_ai_2_round_7
street_deal_round_8
contract_offer_setup
strong_ai_selection_setup

Random tags must not affect gameplay results unless explicitly used as part of deterministic seed derivation.

Random rules are defined in:

14_DETERMINISTIC_RANDOM.md

## 29. Forbidden ID Practices

The following are forbidden:

- Hardcoding card IDs inside UI scenes.
- Using display names as IDs.
- Translating IDs.
- Creating new IDs inside implementation tasks without updating this file.
- Creating duplicate constants with different names for the same value.
- Creating multiple string values for the same concept.
- Renaming IDs after Resources or tests exist.
- Using enum values that are not listed in this document.

## 30. ID Validation Requirements

GameStateValidator must validate:

- every player ID exists in GameIds.PLAYER_IDS;
- every card ID exists in GameIds.CARD_IDS;
- current_phase exists in PhaseIds.ALL;
- attack mode exists in AttackModes.ALL when required;
- selected role ID exists in RoleIds.ALL;
- selected contract ID exists in ContractIds.ALL;
- contact IDs exist in ContactIds.ALL;
- Street Deal IDs exist in StreetDealIds.ALL;
- AI profile IDs exist in AIProfileIds.ALL;
- card types exist in CardTypes.ALL;
- card destinations exist in CardDestinations.ALL;
- Cartel defense state exists in DefenseStates.ALL_CARTEL;
- Judge defense state exists in DefenseStates.ALL_JUDGE;
- Turf Level is between TurfLevelIds.MIN and TurfLevelIds.MAX.

## 31. Resource Validation Requirements

Resource loading tests must validate:

- every CardDefinition id exists in GameIds.CARD_IDS;
- every CardDefinition type exists in CardTypes.ALL;
- every CardDefinition destination exists in CardDestinations.ALL;
- every RoleDefinition id exists in RoleIds.ALL;
- every ContractDefinition id exists in ContractIds.ALL;
- every ContactDefinition id exists in ContactIds.ALL;
- every StreetDealDefinition id exists in StreetDealIds.ALL;
- every AIProfileDefinition id exists in AIProfileIds.ALL;
- every TurfLevelDefinition level is between 0 and 10.

## 32. Required GUT Tests

Create tests for ID and constant validation.

Recommended file:

res://tests/unit/test_ids_and_constants.gd

Minimum required tests:

- PLAYER_IDS contains exactly 4 IDs.
- PLAYER_IDS contains player_1, ai_1, ai_2, ai_3.
- AI_PLAYER_IDS contains exactly 3 IDs.
- CARD_IDS contains exactly 16 IDs.
- CARD_IDS has no duplicates.
- RoleIds.ALL has no duplicates.
- ContractIds.ALL has no duplicates.
- ContactIds.ALL has no duplicates.
- StreetDealIds.ALL has no duplicates.
- AIProfileIds.ALL has no duplicates.
- PhaseIds.ALL has no duplicates.
- AttackModes.ALL has no duplicates.
- Validation error constants are unique except ValidationErrors.OK.
- ValidationErrors includes PHASE_NOT_READY and CONTRACT_ALREADY_SELECTED.
- LogEventTypes.ALL contains every constant declared in LogEventTypes.
- LogEventTypes.ALL has no duplicates.
- every LogEventTypes value has one payload contract and rejects missing, extra, or mistyped fields.
- AI player IDs are exactly ai_1, ai_2, ai_3.
- TurfLevelIds.ALL contains only integers from 0 through 10.
- CardTypes.ALL contains engine, status, defense, war.
- CardDestinations.ALL contains table and hand.
- DefenseStates.ALL_CARTEL contains none, active, depleted.
- DefenseStates.ALL_JUDGE contains none, active.
- TurfLevelIds.MIN == 0.
- TurfLevelIds.MAX == 10.

Recommended helper:

func assert_no_duplicates(values: Array) -> void:
	var seen := {}
	for value in values:
		assert_false(seen.has(value), "Duplicate value: %s" % value)
		seen[value] = true

## 33. Acceptance Criteria

This file is complete when:

- all player IDs are defined;
- all card IDs are defined;
- all phase IDs are defined;
- all attack modes are defined;
- all validation errors are defined;
- all role IDs are defined;
- all contract IDs are defined;
- all contact IDs are defined;
- all Street Deal IDs are defined;
- all AI profile IDs are defined;
- card type constants are defined;
- card destination constants are defined;
- defense state constants are defined;
- reward type constants are defined;
- effect type constants are defined;
- modifier type constants are defined;
- log event type constants are defined;
- tie-break IDs are defined;
- ID validation rules are clear;
- GUT tests can verify uniqueness and completeness;
- no gameplay balance is defined here;
- no gameplay effects are defined here.

## 34. Final Rule

IDs are infrastructure.

They must stay boring, stable, and centralized.

If a system needs a new ID, update this file first, then update Resources, logic, tests, and UI selectors.
