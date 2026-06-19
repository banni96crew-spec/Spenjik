Contracts
Document Role

This file defines only:

contract IDs and contract Resource data;
contract offer generation;
contract selection;
contract runtime state;
contract progress tracking;
contract completion timing;
contract failure timing;
contract claim rules;
contract reward application;
contract validation rules;
ContractLogic API expectations;
contract-related hooks from Economy, Market, Combat, Setup, and phase flow;
contract-related edge cases;
contract-related GUT tests.

This file must not redefine:

card prices;
card effects outside contract progress interpretation;
market generation;
purchase validation;
income resolution;
combat resolution;
role definitions;
contact definitions;
Street Deal rules;
debt rules;
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
08_ROLES.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md
12_TURF_LEVELS.md
13_AI_SYSTEM.md
14_DETERMINISTIC_RANDOM.md
15_GODOT_ARCHITECTURE.md
16_GAME_STATE_MANAGER_API.md
17_UI_UX_SPEC.md
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
1. Purpose

The contract system gives the human player one optional objective for the run.

Contracts create a focused side goal that can reward:

Victory Points;
Nal.

In MVP:

only the human player receives a contract;
AI players do not receive contracts;
contracts are selected during setup;
the game deterministically offers 3 contracts;
the human selects 1 contract;
completed contracts must be claimed manually through claim_contract().

The contract system must be deterministic, data-driven, and validation-first. It must not rely on UI state or hidden gameplay assumptions.

2. Ownership Boundaries

This file owns:

contract IDs;
contract Resource schema;
contract offer generation;
contract selection rules;
contract runtime schema;
contract progress events;
contract completion conditions;
contract failure conditions;
contract reward claiming;
contract reward mutation;
contract validation;
contract API expectations;
contract tests.

This file references:

06_ECONOMY_AND_MARKET.md for purchases, income, Nal, VP, and status buildings;
07_COMBAT_SYSTEM.md for successful attacks, blocked attacks, War card play, and destroyed buildings;
14_DETERMINISTIC_RANDOM.md for deterministic contract offer generation;
16_GAME_STATE_MANAGER_API.md for public API exposure;
17_UI_UX_SPEC.md for display and disabled reason requirements.

This file does not own:

card placement after purchase;
attack resolution;
phase advancement;
AI scoring;
UI rendering;
final winner resolution;
deterministic random algorithm internals.
3. Core Terms
Term	Meaning
Contract	A run objective selected by the human player during setup.
Contract Offer	One of 3 deterministic contract options shown during setup.
Selected Contract	The single contract chosen by the human player.
Runtime Contract	Player-owned Dictionary tracking progress, completion, failure, and claim state.
Progress	Numeric or event-based advancement toward a contract condition.
Completed	Contract condition has been satisfied before failure.
Claimed	Contract reward has been applied.
Failed	Contract deadline has passed before completion.
Deadline Round	Last round during which the contract may be completed.
Claim	Manual action that applies the reward after completion.
Hook	A call from another system to ContractLogic after a relevant event.
4. Runtime State
4.1. GameState Fields
Field	Type	Owner	Usage
state["round"]	int	GamePhaseController	Used for deadline checks.
state["current_phase"]	String	GamePhaseController	Used for setup and claim validation.
state["players"]	Array[Dictionary]	GameStateFactory	Contains the human contract runtime.
state["selected_contract_id"]	String	ContractLogic / setup	Stores selected human contract ID.
state["random"]	Dictionary	SeededRandom	Used for deterministic offer generation.
state["combat_log"]	Array[Dictionary]	Multiple systems	May receive contract completion, failure, and claim logs.

Required setup field in GameState:

"contract_offer_ids": []

This field stores the 3 contract IDs offered during setup.

4.2. PlayerState Fields

Contracts use these human PlayerState fields:

Field	Type	Usage
player["id"]	String	Must be GameIds.PLAYER_HUMAN for selected contract.
player["is_ai"]	bool	AI players must not receive contracts in MVP.
player["nal"]	int	Used by gray_capital, big_cashbox, and Nal rewards.
player["vp"]	int	Used by rewards and some condition checks.
player["engine"]	Dictionary	Used by big_cashbox.
player["status_buildings"]	Dictionary	Used by silent_expansion and district_under_control.
player["defense"]	Dictionary	Used by iron_roof and district_under_control.
player["contracts"]	Array[Dictionary]	Setup working state: empty; committed human state: exactly 1 runtime contract; AI state: always empty.
4.3. ContractDefinition Resource Schema

Required Resource:

class_name ContractDefinition
extends Resource

@export var id: String
@export var title: String
@export var deadline_round: int
@export var progress_required: int
@export var reward_type: String
@export var reward_amount: int
@export var description: String

Allowed reward_type values:

Value	Meaning
vp	Add Victory Points.
nal	Add Nal.

Gameplay logic must not parse description to determine behavior.

4.4. Contract Runtime Schema

Required runtime shape:

static func create_contract_runtime(contract_id: String, deadline: int) -> Dictionary:
	return {
		"contract_id": contract_id,
		"progress": 0,
		"completed": false,
		"failed": false,
		"claimed": false,
		"deadline": deadline,
		"failed_reason": "",
		"completed_round": 0,
		"claimed_round": 0
	}

The original PRD runtime shape did not include claimed, but claim behavior is required because repeated claim must be rejected.

4.5. Contract IDs

Canonical constants are owned by `03_IDS_AND_CONSTANTS.md`:

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

`ContractIds.gd` is required. Raw alternative strings or locally duplicated contract ID lists are forbidden.

4.6. Required Validation Errors

Canonical contract errors are owned by `ValidationErrors.gd`:

const INVALID_CONTRACT_ID := "INVALID_CONTRACT_ID"
const CONTRACT_OFFER_UNAVAILABLE := "CONTRACT_OFFER_UNAVAILABLE"
const CONTRACT_NOT_SELECTED := "CONTRACT_NOT_SELECTED"
const CONTRACT_ALREADY_SELECTED := "CONTRACT_ALREADY_SELECTED"
const CONTRACT_ALREADY_COMPLETED := "CONTRACT_ALREADY_COMPLETED"
const CONTRACT_ALREADY_FAILED := "CONTRACT_ALREADY_FAILED"
const CONTRACT_ALREADY_CLAIMED := "CONTRACT_ALREADY_CLAIMED"
const CONTRACT_NOT_COMPLETED := "CONTRACT_NOT_COMPLETED"
const CONTRACT_NOT_CLAIMABLE := "CONTRACT_NOT_CLAIMABLE"

Fallback or ad-hoc contract error strings are forbidden.
5. Rules
5.1. MVP Contract Scope

In MVP:

only the human player may receive a contract;
AI players must not receive contracts;
the human player may have exactly 1 selected contract;
contract selection happens during setup;
contracts are not changed mid-run.
5.2. Contract List

Contracts must not be changed.

ID	Title	Condition	Deadline	Reward
silent_expansion	Silent Expansion	Build 2 Status buildings and do not play War.	8	+1 VP
bloody_turf_war	Bloody Turf War	Destroy 2 AI Status buildings.	12	+6 Nal
gray_capital	Gray Capital	Have 30+ Nal.	10	+1 VP
iron_roof	Iron Roof	Have Cops, Cartel, and Judge.	9	+4 Nal
district_under_control	District Under Control	Build District Control and have protection.	12	+1 VP
proxy_war	Proxy War	Successfully play Saboteur.	11	+5 Nal
big_cashbox	Big Cashbox	Have 2 Laundries, 1 Accountant, and 20 Nal.	13	+1 VP
5.3. Contract Offer Generation

During setup, the game must deterministically offer 3 unique contracts.

Required behavior:

Use SeededPicker.gd.
Pick 3 unique IDs from all contract IDs.
Return the offer IDs in stable order during preview and store the same IDs in `state["contract_offer_ids"]` during committed setup.
Do not use forbidden random APIs.
Do not offer duplicate contracts.

Required owner:

ContractLogic.generate_contract_offers(state)

Random behavior must follow 14_DETERMINISTIC_RANDOM.md.

5.4. Contract Selection

The human player selects exactly 1 contract from the 3 offered contracts.

Selection rules:

selected ID must be in contract_offer_ids;
selected ID must be a valid contract ID;
selection creates a runtime contract in human["contracts"];
state["selected_contract_id"] must equal the selected ID;
human["contracts"].size() must become 1.

AI players must not receive contract runtimes.

5.5. Contract Completion

A contract becomes completed when its condition is satisfied on or before its deadline round.

A completed contract:

remains completed after deadline;
must not later become failed;
can be claimed manually;
can be claimed after the deadline if it was completed on time.

Completion does not automatically apply the reward.

5.6. Contract Claim

Rewards are claimed manually through:

GameStateManager.claim_contract(player_id: String, contract_id: String) -> Dictionary

Claim rules:

contract must exist;
contract must be completed;
contract must not be failed;
contract must not already be claimed;
reward is applied once;
claimed becomes true;
claimed_round becomes state["round"].

Repeated claim must fail.

5.7. Deadline Rule

A contract may be completed through the end of its deadline round.

If:

state["round"] > contract["deadline"]
and contract["completed"] == false

then the contract becomes:

contract["failed"] = true

This failure check should happen at the start of each round before regular round actions, and may also be safely called during validation checkpoints.

A completed but unclaimed contract must not fail after deadline.

5.8. Failed Contract Rule

A failed contract:

cannot become completed;
cannot be claimed;
remains in player["contracts"];
should be visible to UI as failed state.
5.9. Progress Hook Rule

ContractLogic must receive explicit event hooks from owner systems.

Allowed hook sources:

Source Module	Hook Timing
MarketLogic.gd	After successful purchase and placement.
IncomeLogic.gd	After income, Cops upkeep, and debt processing.
CombatEngine.gd	After valid resolved attack; success-specific hooks only after unblocked success.
GamePhaseController.gd	At round start and phase checkpoints for deadline/failure checks.
StreetDealLogic.gd	After successful Street Deal effects if Nal/VP/building conditions can change.

ContractLogic must not duplicate purchase, income, combat, or Street Deal resolution.

5.10. No Hidden Contract Mutation Rule

Contract progress must only change through:

explicit ContractLogic API calls;
known event hooks;
setup selection;
claim action;
deadline check.

UI must never mutate contract runtime directly.

AI must not override contract rules.

6. Contract Conditions
6.1. Silent Expansion

ID:

silent_expansion

Deadline:

8

Reward:

+1 VP

Condition:

Build 2 Status buildings and do not play War.

Implementation rules:

Count successful human purchases of Status cards after contract selection.
Status cards:
stash
workshop
district_control
Progress target:
contract["progress"] >= 2
“Do not play War” means the human must not call execute_attack() with a valid War-card attack after selecting the contract and before completion.
A valid attack attempt with a War card breaks the contract even if the attack is blocked.
Failed attack validation does not break the contract.
Discarding a War card does not break the contract.
Buying a War card does not break the contract.
Having War cards in hand does not break the contract.

If the human validly plays a War card before silent_expansion is completed:

contract["failed"] = true
contract["failed_reason"] = "war_played"

Silent Expansion completion check:

after successful Status purchase;
before deadline failure check if both occur in same round.
6.2. Bloody Turf War

ID:

bloody_turf_war

Deadline:

12

Reward:

+6 Nal

Condition:

Destroy 2 AI Status buildings.

Implementation rules:

Count only successful, unblocked destruction of AI-owned Status buildings.
Valid destroyed Status buildings:
stash
workshop
district_control
Target must be AI:
target["is_ai"] == true
Blocked attacks do not count.
Failed validation does not count.
Destruction of human-owned buildings does not count.
Progress target:
contract["progress"] >= 2

Valid progress sources:

successful bruiser destroy_stash against AI;
successful cleaner destroy_workshop against AI;
successful federal_raid destroy_district against AI.
6.3. Gray Capital

ID:

gray_capital

Deadline:

10

Reward:

+1 VP

Condition:

Have 30+ Nal.

Implementation rules:

Check current human Nal.
Complete when:
human["nal"] >= 30
Progress may be represented as current Nal clamped to 30:
contract["progress"] = min(human["nal"], 30)
This condition should be checked after any event that changes human Nal:
Income;
purchase;
combat steal/gain;
Street Deal;
debt processing;
contract reward claim from other contract is not possible in MVP because only one contract exists.
6.4. Iron Roof

ID:

iron_roof

Deadline:

9

Reward:

+4 Nal

Condition:

Have Cops, Cartel, and Judge.

Implementation rules:

Complete when all are true:
human["defense"]["cops_active"] == true
human["defense"]["cartel_state"] == "active"
human["defense"]["judge_state"] == "active"
cartel_state == "depleted" does not satisfy the condition.
judge_state == "none" does not satisfy the condition.
Progress should be the number of active required defenses:
0..3
Check after:
successful Defense card purchase;
Cops upkeep if Cops may deactivate;
combat if Judge or Cartel state changes.
6.5. District Under Control

ID:

district_under_control

Deadline:

12

Reward:

+1 VP

Condition:

Build District Control and have protection.

Implementation rules:

Human must have at least one District Control:
human["status_buildings"]["district_control"] > 0
Human must have at least one active protection.
Active protection means any of:
cops_active == true;
cartel_state == "active";
judge_state == "active".
Complete only when both District Control and protection are present at the same check.
Progress should be:
0 if neither condition is met;
1 if either District Control or protection is met;
2 if both are met.
Check after:
successful District Control purchase or rebuild;
successful Defense card purchase;
combat if protection is depleted or removed;
Income if Cops upkeep deactivates Cops.
6.6. Proxy War

ID:

proxy_war

Deadline:

11

Reward:

+5 Nal

Condition:

Successfully play Saboteur.

Implementation rules:

Count only successful, unblocked saboteur.
Blocked saboteur does not count.
Failed validation does not count.
Discarded saboteur does not count.
Buying saboteur does not count.
Completion target:
contract["progress"] >= 1
6.7. Big Cashbox

ID:

big_cashbox

Deadline:

13

Reward:

+1 VP

Condition:

2 Laundries, 1 Accountant, 20 Nal.

Implementation rules:

Complete when all are true:
human["engine"]["laundries"] >= 2
human["engine"]["accountants"] >= 1
human["nal"] >= 20
Progress should be number of satisfied subconditions:
0..3
Check after:
successful Engine card purchase;
Income;
purchase that spends Nal;
debt processing;
combat that changes Nal;
Street Deal that changes Nal.
7. Validation Rules
7.1. Contract Offer Validation

Contract offers must satisfy:

Condition	Error
Offer count is not 3	CONTRACT_OFFER_UNAVAILABLE
Duplicate contract ID in offers	CONTRACT_OFFER_UNAVAILABLE
Unknown contract ID in offers	INVALID_CONTRACT_ID
Forbidden random API used	Static test failure
7.2. Contract Selection Validation

Selection is valid only if:

Condition	Error
Player is not human	INVALID_TARGET
Selected contract ID is invalid	INVALID_CONTRACT_ID
Selected contract ID is not in offers	CONTRACT_OFFER_UNAVAILABLE
Human already has a contract	CONTRACT_ALREADY_SELECTED
state["selected_contract_id"] is already non-empty	CONTRACT_ALREADY_SELECTED

Failed selection must not mutate state.

7.3. Completion Validation

A contract can become completed only if:

Condition	Error / Behavior
Contract exists	Otherwise CONTRACT_NOT_SELECTED.
failed == false	Failed contracts cannot complete.
completed == false	Already completed contracts do not complete again.
state["round"] <= deadline	Otherwise deadline failure applies first.
Condition is satisfied	Set completed state.

Completion must not apply reward.

7.4. Claim Validation

Claim is valid only if:

Condition	Error
Contract exists	CONTRACT_NOT_SELECTED
Contract ID matches selected contract	INVALID_CONTRACT_ID
completed == true	CONTRACT_NOT_COMPLETED
failed == false	CONTRACT_ALREADY_FAILED
claimed == false	CONTRACT_ALREADY_CLAIMED

Failed claim must not mutate state.

7.5. Deadline Validation

At round-start deadline processing:

Condition	Expected Behavior
completed == true	Do not fail.
claimed == true	Do not fail.
failed == true	No-op.
state["round"] <= deadline	No-op.
state["round"] > deadline and not completed	Set failed.
7.6. Mutation Rule

Failed validation must not mutate:

player["nal"];
player["vp"];
player["contracts"];
state["selected_contract_id"];
state["contract_offer_ids"];
state["combat_log"].
8. Resolution / Processing Flow
8.1. Setup Contract Flow

Contract setup has exactly two stages.

Stage 1 - preview:

1. UI supplies `game_seed`, `turf_level`, and `selected_role_id`.
2. `GameStateManager.generate_contract_offers(config)` creates a temporary `setup_working` state.
3. `ContractLogic.generate_contract_offers(state)` consumes only the temporary random state and returns exactly three unique `ContractIds.ALL` values in stable order.
4. Active GameState, active random state, and active log remain unchanged.
5. UI displays the returned IDs; no runtime ContractRuntime exists yet.

Stage 2 - commit:

1. UI adds one `selected_contract_id` from the preview and calls `start_new_game(config)`.
2. `start_new_game` creates a fresh working state from the same complete config.
3. ContractLogic regenerates the same three offers from the same seed, Turf Level, and role setup sequence.
4. ContractLogic stores the IDs only in `state["contract_offer_ids"]`.
5. ContractLogic validates `selected_contract_id` as a valid ID and member of that array.
6. ContractLogic creates one ContractRuntime whose `contract_id` equals `selected_contract_id`.
7. The runtime is stored only in `human["contracts"]`, and `state["selected_contract_id"]` is set to the same ID.
8. Final committed-state validation runs.
9. On success, `MATCH_STARTED` records `contract_offer_ids` and `selected_contract_id`; preview creates no gameplay event.

An offer has no separate runtime object or offer-instance ID. If any Stage 2 step fails, active state remains byte-for-byte unchanged and no setup event is appended.
8.2. Contract Offer Generation Flow

Committed setup flow:

Read state["random"].
Call SeededPicker.pick_unique(...).
Select 3 unique contract IDs.
Update state["random"] according to 14_DETERMINISTIC_RANDOM.md.
Store result in state["contract_offer_ids"].
Return structured result.
8.3. Purchase Hook Flow

After a successful purchase:

MarketLogic places the card.
MarketLogic builds event Dictionary.
MarketLogic calls:
ContractLogic.on_card_purchased(state, event)
ContractLogic checks:
silent_expansion;
iron_roof;
district_under_control;
big_cashbox;
any current-state contract condition.
ContractLogic returns updated state and contract result entries.

Purchase hook event shape:

{
	"player_id": "player_1",
	"card_id": "stash",
	"card_type": "status",
	"destination": "table"
}
8.4. Income Hook Flow

After Income, Cops upkeep, and DebtLogic:

IncomeLogic builds event Dictionary.
IncomeLogic calls:
ContractLogic.on_income_resolved(state, event)
ContractLogic checks:
gray_capital;
iron_roof;
district_under_control;
big_cashbox.

Income hook event shape:

{
	"player_id": "player_1",
	"nal_after": 30,
	"vp_after": 2
}
8.5. Combat Hook Flow

After CombatEngine resolves a valid attack:

CombatEngine validates and resolves the attack.
CombatEngine builds event Dictionary.
CombatEngine calls:
ContractLogic.on_attack_resolved(state, event)
ContractLogic handles:
silent_expansion failure on valid human War attack attempt before completion;
bloody_turf_war progress on successful AI Status building destruction;
proxy_war completion on successful unblocked saboteur;
current-state checks if Nal, VP, defense, or buildings changed.

Combat hook event shape:

{
	"attacker_id": "player_1",
	"target_id": "ai_1",
	"target_is_ai": true,
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"engine_target_card_id": "",
	"blocked": false,
	"success": true,
	"valid_attack": true,
	"destroyed_status_card_id": "stash",
	"destroyed_engine_card_id": ""
}
8.6. Street Deal Hook Flow

After a successful Street Deal effect:

ContractLogic.on_state_changed(state, {
	"source": "street_deal",
	"player_id": "player_1"
})

ContractLogic should re-check current-state conditions:

gray_capital;
iron_roof;
district_under_control;
big_cashbox.

Street Deal rules remain owned by 10_STREET_DEALS_AND_DEBTS.md.

8.7. Deadline Processing Flow

At the start of each round:

Read state["round"].
For the human selected contract:
if completed, do nothing;
if claimed, do nothing;
if failed, do nothing;
if round > deadline, mark failed and set failed_reason = "deadline_exceeded".
Write log entry if failure occurs.
Validate state.
8.8. Claim Flow

When player claims contract:

Validate player is human.
Validate contract exists.
Validate contract is completed.
Validate contract is not failed.
Validate contract is not claimed.
Apply reward.
Set:
contract["claimed"] = true
contract["claimed_round"] = state["round"]
Append contract log entry.
Validate state.
Return structured result.

8.9. Contract Logging

ContractLogic uses only these canonical events:

- `CONTRACT_PROGRESS_UPDATED` when progress changes without completion or failure;
- `CONTRACT_COMPLETED` when completion is first committed;
- `CONTRACT_FAILED` when either `war_played` or `deadline_exceeded` first commits failed state;
- `CONTRACT_REWARD_CLAIMED` when manual reward claim commits.

No event is appended for a no-op hook, unchanged progress, repeated completion check, or failed validation.
9. API Expectations
9.1. ContractLogic.gd

Required file:

res://logic/contracts/ContractLogic.gd

Required API:

class_name ContractLogic

static func create_contract_runtime(contract_id: String, deadline: int) -> Dictionary:
	return {}

static func generate_contract_offers(state: Dictionary) -> Dictionary:
	return {}

static func select_contract(state: Dictionary, player_id: String, contract_id: String) -> Dictionary:
	return {}

static func validate_contract_selection(state: Dictionary, player_id: String, contract_id: String) -> Dictionary:
	return {}

static func get_player_contract(player: Dictionary, contract_id: String = "") -> Dictionary:
	return {}

static func on_card_purchased(state: Dictionary, event: Dictionary) -> Dictionary:
	return {}

static func on_income_resolved(state: Dictionary, event: Dictionary) -> Dictionary:
	return {}

static func on_attack_resolved(state: Dictionary, event: Dictionary) -> Dictionary:
	return {}

static func on_state_changed(state: Dictionary, event: Dictionary) -> Dictionary:
	return {}

static func check_contract_completion(state: Dictionary, player_id: String) -> Dictionary:
	return {}

static func process_deadlines(state: Dictionary) -> Dictionary:
	return {}

static func claim_contract(state: Dictionary, player_id: String, contract_id: String) -> Dictionary:
	return {}
9.2. GameStateManager.gd API

Required addition to 16_GAME_STATE_MANAGER_API.md:

func claim_contract(player_id: String, contract_id: String) -> Dictionary:
	return {}

Required setup preview API:

func generate_contract_offers(config: Dictionary) -> Dictionary:
	return {}

Contract selection is handled inside `start_new_game(config)`, and config must include:

{
	"game_seed": "run_12345",
	"turf_level": 0,
	"selected_role_id": "merchant",
	"selected_contract_id": "gray_capital"
}
9.3. Contract Offer Result Shape
{
	"ok": true,
	"error": ValidationErrors.OK,
	"contract_offer_ids": [
		"silent_expansion",
		"gray_capital",
		"iron_roof"
	]
}
9.4. Contract Selection Result Shape
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"selected_contract_id": "gray_capital",
	"contract": {},
	"state": {},
	"log_entries": []
}
9.5. Contract Hook Result Shape
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"contract_id": "gray_capital",
	"changed": false,
	"completed_now": false,
	"failed_now": false,
	"progress_before": 0,
	"progress_after": 0,
	"contract": {},
	"state": {},
	"log_entries": []
}
9.6. Claim Result Shape
{
	"ok": true,
	"error": ValidationErrors.OK,
	"player_id": "player_1",
	"contract_id": "gray_capital",
	"reward_type": "vp",
	"reward_amount": 1,
	"state": {},
	"log_entries": []
}

Failed claim result:

{
	"ok": false,
	"error": ValidationErrors.CONTRACT_ALREADY_CLAIMED,
	"player_id": "player_1",
	"contract_id": "gray_capital",
	"state": {}
}

Failed claim must not mutate state.

10. Edge Cases
Edge Case	Condition	Expected Behavior	Error Code	Mutation Rule
No contract selected	Human has no contract runtime.	Operation fails.	CONTRACT_NOT_SELECTED	No mutation.
AI contract selection	player["is_ai"] == true.	Reject selection.	INVALID_TARGET	No mutation.
Invalid contract ID	Unknown contract ID.	Reject selection or claim.	INVALID_CONTRACT_ID	No mutation.
Selected contract not in offers	Contract ID valid but not offered.	Reject selection.	CONTRACT_OFFER_UNAVAILABLE	No mutation.
Duplicate offers	Offer list contains duplicate IDs.	Offer validation fails.	CONTRACT_OFFER_UNAVAILABLE	No mutation.
Contract already selected	Human already has 1 contract.	Reject second selection.	CONTRACT_ALREADY_SELECTED	No mutation.
Deadline round active	round == deadline.	Contract can still complete.	OK	Completion mutation allowed.
Round after deadline	round > deadline, contract not completed.	Mark failed.	OK	Mutate contract failed fields.
Completed before deadline, claimed after deadline	completed == true, claimed == false, round > deadline.	Claim allowed.	OK	Reward mutation allowed.
Failed contract later satisfies condition	failed == true.	Hook returns success without mutation.	OK	No completion mutation.
Claim before completion	completed == false.	Claim fails.	CONTRACT_NOT_COMPLETED	No mutation.
Claim twice	claimed == true.	Claim fails.	CONTRACT_ALREADY_CLAIMED	No mutation.
Silent Expansion valid War attempt	Human executes valid War attack before completion.	Contract fails even if blocked.	OK	Mutate contract failed fields.
Silent Expansion failed attack validation	Invalid War attack payload.	Does not fail contract.	Combat error	No contract mutation.
Silent Expansion discard War card	Human discards War card.	Does not fail contract.	OK	No contract mutation.
Silent Expansion buys War card	Human buys War card.	Does not fail contract.	OK	No contract mutation.
Bloody Turf War blocked attack	Status destruction blocked by defense.	No progress.	OK	No progress mutation.
Bloody Turf War destroys human building	Human target or non-AI target.	No progress.	OK	No progress mutation.
Proxy War blocked Saboteur	Judge blocks Saboteur.	No completion.	OK	No progress mutation.
Iron Roof Cartel depleted	cartel_state == "depleted".	Does not count as active Cartel.	OK	No completion unless restored.
District Under Control no protection	Has District Control but no active protection.	Not completed.	OK	Progress may update to 1.
Big Cashbox spends below 20 Nal	Condition was near complete but purchase lowers Nal.	Not completed unless already completed.	OK	Progress may decrease before completion.
Completed current-state contract later loses condition	Contract already completed.	Remains completed.	OK	Do not undo completion.
11. Required Source Files

Required files:

res://logic/contracts/ContractLogic.gd
res://data/resources/contracts/ContractDefinition.gd
res://data/resources/contracts/silent_expansion.tres
res://data/resources/contracts/bloody_turf_war.tres
res://data/resources/contracts/gray_capital.tres
res://data/resources/contracts/iron_roof.tres
res://data/resources/contracts/district_under_control.tres
res://data/resources/contracts/proxy_war.tres
res://data/resources/contracts/big_cashbox.tres

Recommended constants file:

res://data/ids/ContractIds.gd

Related files that must call or support ContractLogic:

res://logic/game_state/GameStateFactory.gd
res://logic/game_state/GameStateValidator.gd
res://logic/game_state/GamePhaseController.gd
res://logic/economy/MarketLogic.gd
res://logic/economy/IncomeLogic.gd
res://logic/combat/CombatEngine.gd
res://logic/street_deals/StreetDealLogic.gd
res://autoload/GameStateManager.gd

Recommended optional helper files if splitting is needed:

res://logic/contracts/ContractOfferLogic.gd
res://logic/contracts/ContractConditionChecker.gd
res://logic/contracts/ContractRewardResolver.gd
res://logic/contracts/ContractLogBuilder.gd

Each source file must stay under:

250 lines

If ContractLogic.gd approaches the limit, split offer generation, condition checks, reward resolution, and logs.

12. Required GUT Tests

Recommended test file:

res://tests/unit/test_contract_logic.gd
12.1. Contract Definition Tests

Minimum tests:

all 7 contract IDs exist;
every contract Resource has valid ID;
every contract has deadline;
every contract has valid reward type;
every contract has reward amount;
no duplicate contract IDs exist.
12.2. Offer Generation Tests

Minimum tests:

setup generates exactly 3 contract offers;
offers contain unique IDs;
offers contain only valid contract IDs;
same seed and random state generates same offers;
different random step can generate different offers;
offer generation updates random state according to 14_DETERMINISTIC_RANDOM.md;
preview offer generation does not mutate active state or active random state;
preview creates no ContractRuntime and no gameplay event;
offer generation does not use forbidden random APIs.
12.3. Selection Tests

Minimum tests:

human can select contract from offers;
selected contract creates runtime contract;
selected contract sets state["selected_contract_id"];
committed setup stores the same 3 IDs returned by preview;
committed setup appends MATCH_STARTED with offer and selected IDs;
AI cannot select contract;
contract outside offers returns CONTRACT_OFFER_UNAVAILABLE;
invalid contract ID is rejected;
selecting second contract returns CONTRACT_ALREADY_SELECTED;
failed selection does not mutate state.
12.4. Silent Expansion Tests

Minimum tests:

successful first Status purchase increments progress to 1;
successful second Status purchase completes contract;
buying War card does not fail contract;
discarding War card does not fail contract;
valid human War attack before completion fails contract;
blocked valid War attack before completion fails contract;
failed War attack validation does not fail contract;
completed Silent Expansion does not fail from later War attack.
12.5. Bloody Turf War Tests

Minimum tests:

successful bruiser destroy_stash against AI increments progress;
successful cleaner destroy_workshop against AI increments progress;
successful federal_raid destroy_district against AI increments progress;
blocked status destruction does not increment progress;
destruction against human does not increment progress;
second valid AI Status destruction completes contract.
12.6. Gray Capital Tests

Minimum tests:

human with 29 Nal does not complete;
human with 30 Nal completes;
progress reflects current Nal clamped to 30;
completion can occur after Income;
completion can occur after Street Deal Nal gain;
completed Gray Capital remains completed if Nal later drops.
12.7. Iron Roof Tests

Minimum tests:

Cops only does not complete;
Cops + Cartel does not complete;
Cops + Cartel + Judge completes;
depleted Cartel does not count;
inactive Judge does not count;
completion can occur after Defense purchase;
completed Iron Roof remains completed if defense later changes.
12.8. District Under Control Tests

Minimum tests:

District Control without protection does not complete;
protection without District Control does not complete;
District Control with active Cops completes;
District Control with active Cartel completes;
District Control with active Judge completes;
depleted Cartel does not count as protection;
completion can occur after rebuild;
completed contract remains completed after protection is lost.
12.9. Proxy War Tests

Minimum tests:

successful unblocked saboteur completes contract;
blocked saboteur does not complete;
failed saboteur validation does not complete;
discarded saboteur does not complete;
bought saboteur does not complete.
12.10. Big Cashbox Tests

Minimum tests:

2 Laundries only does not complete;
2 Laundries + 1 Accountant but less than 20 Nal does not complete;
2 Laundries + 1 Accountant + 20 Nal completes;
progress reflects number of satisfied subconditions;
completion can occur after Income;
completed Big Cashbox remains completed if Nal later drops.
12.11. Claim Tests

Minimum tests:

completed VP contract can be claimed;
completed Nal contract can be claimed;
claim applies reward exactly once;
claim before completion fails;
claim after failure fails;
claim twice fails;
failed claim does not mutate state;
completed before deadline can be claimed after deadline.
12.12. Deadline Tests

Minimum tests:

contract does not fail before deadline;
contract does not fail on deadline round;
incomplete contract fails when round > deadline;
completed contract does not fail after deadline;
failed contract cannot complete later.
12.13. Integration Tests

Minimum tests:

Market purchase hook updates relevant contracts;
Income hook updates relevant contracts;
Combat hook updates relevant contracts;
Street Deal state-change hook updates current-state contracts;
blocked combat does not grant success-only progress;
failed validation does not mutate contracts;
no contract logic is implemented in UI files;
no forbidden random APIs exist in contract logic files.
13. Static Scan Requirements

Static scan must fail if contract logic contains:

randf(
randi(
randomize(
RandomNumberGenerator

Allowed deterministic random owners:

SeededRandom.gd
SeededPicker.gd

Static scan must fail if contract implementation:

reads or writes UI nodes;
lives inside UI scene scripts;
parses description text for gameplay behavior;
hardcodes card prices;
resolves combat;
places purchased cards;
advances phases directly;
assigns AI profiles;
gives contracts to AI players in MVP;
auto-claims rewards without claim_contract().

Allowed dependencies:

GameIds
ContractIds
ValidationErrors
PhaseIds
SeededPicker
ContractDefinition
GameStateValidator
14. Implementation Notes For LLM Agents

When implementing contracts:

Do not change contract IDs.
Do not change contract conditions.
Do not change deadlines.
Do not change rewards.
Do not give contracts to AI in MVP.
Generate exactly 3 deterministic contract offers during setup.
Let the human select exactly 1 offered contract.
Store selected contract in state["selected_contract_id"].
Store runtime contract in human["contracts"].
Add claimed to runtime contract state.
Do not auto-apply rewards on completion.
Apply rewards only through claim_contract().
Let completed contracts be claimed after deadline.
Fail incomplete contracts only when round > deadline.
Treat deadline round as still valid for completion.
Treat Silent Expansion War violation as any valid human attack attempt before completion.
Do not treat War discard or War purchase as Silent Expansion violation.
Count only successful, unblocked AI Status building destruction for Bloody Turf War.
Count only successful, unblocked saboteur for Proxy War.
Do not parse Resource descriptions as logic.
Do not write contract logic in UI.
Keep every source file under 250 lines.
Add GUT tests with implementation.

If a future contract rule is unclear, do not invent behavior. Add it to:

21_OPEN_QUESTIONS_AND_FIXES.md
15. Acceptance Criteria

This module is complete when:

all 7 contract Resources exist;
contract IDs are centralized or consistently validated;
deterministic setup offers exactly 3 unique contracts;
human can select exactly 1 offered contract;
AI players do not receive contracts in MVP;
runtime contract state includes claimed;
state["selected_contract_id"] is set correctly;
Silent Expansion progresses from Status purchases;
Silent Expansion fails on valid War attack attempt before completion;
Silent Expansion ignores War purchases and discards;
Bloody Turf War counts successful unblocked AI Status building destruction;
Gray Capital completes at 30+ Nal;
Iron Roof completes with active Cops, active Cartel, and active Judge;
District Under Control completes with District Control plus active protection;
Proxy War completes from successful unblocked Saboteur;
Big Cashbox completes with 2 Laundries, 1 Accountant, and 20 Nal;
incomplete contracts fail only when round > deadline;
completed contracts do not fail after deadline;
completed contracts can be claimed manually;
claim applies reward exactly once;
claim twice is rejected;
failed validation does not mutate state;
contract hooks are called from Economy, Market, Combat, Street Deal, and phase systems where relevant;
contract logic does not use UI nodes;
contract logic does not use forbidden random APIs;
all required GUT tests pass.
16. Final Rule

Contracts track human objectives and rewards only; they must never secretly resolve purchases, combat, AI behavior, or phase flow.
