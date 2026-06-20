# Combat System

## Document Role

This file defines only:

Action-phase War card validation;
attack payload requirements;
valid targets and target-card selection for attacks;
combat preview rules;
combat resolution order;
defense resolution for Cops, Cartel, and Judge;
War card effects;
insider modifier behavior;
saboteur engine-target behavior;
hand mutation for used and discarded War cards;
combat log requirements;
combat-related contract/contact hooks;
combat-related edge cases;
combat-related GUT tests.

This file must not redefine:

card prices;
market generation;
purchase validation;
income resolution;
Cops upkeep;
role definitions beyond combat-facing flags;
contract completion rules beyond combat hook timing;
contact unlock rules beyond combat hook timing;
Street Deal effects;
Turf Level definitions;
AI scoring;
phase transition logic;
UI behavior;
deterministic random algorithm implementation.

Source of truth dependencies:

00_INDEX.md
02_CORE_LOOP_AND_PHASES.md
03_IDS_AND_CONSTANTS.md
04_GAME_STATE_SCHEMA.md
05_CARDS_DATABASE.md
06_ECONOMY_AND_MARKET.md
08_ROLES.md
09_CONTRACTS.md
10_STREET_DEALS_AND_DEBTS.md
11_CONTACTS.md
12_TURF_LEVELS.md
13_AI_SYSTEM.md
14_DETERMINISTIC_RANDOM.md
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

## 1. Purpose

The combat system controls how War cards are played during the Action phase.

It exists to provide a deterministic, validation-first, implementation-ready combat contract for:

selecting an attacker;
selecting a War card from hand;
selecting a target player;
selecting an attack mode when required;
selecting a specific target card when required;
applying optional modifiers;
resolving defenses;
applying exactly one selected effect;
removing used cards from hand;
writing combat logs;
calling contract/contact progress hooks.

Combat must be deterministic and replay-safe. No combat logic may depend on UI state, animation state, or non-deterministic random APIs.

## 2. Ownership Boundaries

This file owns:

combat validation;
attack resolution;
defense resolution;
War card hand consumption;
combat previews;
attack log entries;
last_attacked_by updates;
skip-action flag setting caused by cleaner;
District Control rebuild flag setting caused by federal_raid.

This file references:

06_ECONOMY_AND_MARKET.md for protected Nal from Accountants;
09_CONTRACTS.md for contract progress rules;
11_CONTACTS.md for contact progress/unlock hooks;
13_AI_SYSTEM.md for AI usage of combat APIs;
16_GAME_STATE_MANAGER_API.md for public facade methods;
17_UI_UX_SPEC.md for display requirements.

This file does not own:

Action phase turn order;
when Action starts or ends;
AI target scoring;
UI target-selection widgets;
card purchase placement;
price calculation;
contract reward claiming;
contact selection rules;
debt penalties;
deterministic random implementation.

## 3. Core Terms

Term	Meaning
Attacker	Player who plays or discards a War card.
Target	Opponent selected as the recipient of an attack.
War Card	Card with type == "war" and destination == "hand".
Attack Mode	Required mode for cards with multiple effects.
Modifier	Optional card used to alter an attack. In MVP combat, only insider is a modifier.
Engine Target	Specific Engine card chosen for saboteur to destroy.
Defense	Target-owned protection that can block specific attacks.
Blocked Attack	A valid attack whose effect is prevented by defense.
Successful Attack	A valid attack that is not blocked and applies its selected effect.
Discard	Removing a War card from hand without applying its effect.
Protected Nal	Nal that cannot be stolen because of Accountants. Defined in 06_ECONOMY_AND_MARKET.md.
Combat Log	Runtime log entry appended to state["combat_log"].

## 4. Runtime State

### 4.1. GameState Fields Used

Combat reads or mutates these GameState fields:

Field	Type	Usage
state["current_phase"]	String	Must be PhaseIds.ACTION for attacks and discards.
state["players"]	Array[Dictionary]	Source of attacker and target states.
state["action_order"]	Array[String]	Read-only reference for phase owner logic.
state["active_action_player_id"]	String	Must match attacker for normal player-driven attacks.
state["combat_log"]	Array[Dictionary]	Combat appends log entries.
state["random"]	Dictionary	Reserved for future random combat effects. MVP combat does not use random.

### 4.2. PlayerState Fields Used

Combat reads or mutates these PlayerState fields:

Field	Type	Usage
player["id"]	String	Player identity.
player["is_ai"]	bool	Used by AI caller, not by core combat rules.
player["nal"]	int	Stolen or awarded Nal.
player["vp"]	int	Lost VP from destroyed status buildings.
player["engine"]	Dictionary	Target for saboteur; source of Accountant protection.
player["status_buildings"]	Dictionary	Target for status-building destruction.
player["defense"]	Dictionary	Cops, Cartel, Judge state.
player["hand"]	Array[String]	War cards available to play or discard.
player["action_done"]	bool	Not set by individual attacks; set by phase controller.
player["skip_next_action"]	bool	Set by successful cleaner workshop destruction.
player["contracts"]	Array[Dictionary]	Passed to ContractLogic hooks.
player["contacts"]	Dictionary	Passed to ContactLogic hooks.
player["role_flags"]	Dictionary	Used only by external hooks if needed.
player["last_attacked_by"]	String	Updated after any valid resolved attack against this player.

### 4.3. Engine State

player["engine"] = {
	"informers": 0,
	"laundries": 0,
	"accountants": 0,
	"brothel": false
}

informant, laundry, and accountant are counted cards.

brothel is a boolean single-copy card.

### 4.4. Status Building State

player["status_buildings"] = {
	"stash": 0,
	"workshop": 0,
	"district_control": 0,
	"can_rebuild_district_for_8": false
}

### 4.5. Defense State

player["defense"] = {
	"cops_active": false,
	"cops_timer": 0,
	"cartel_state": "none",
	"judge_state": "none"
}

Allowed cartel_state values:

Value	Meaning
none	No active Cartel protection.
active	Cartel can block status-building destruction.
depleted	Cartel was depleted by cleaner; it no longer blocks.

Allowed judge_state values:

Value	Meaning
none	No Judge protection.
active	Judge can block one saboteur.

Canonical constants from 03_IDS_AND_CONSTANTS.md:

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

If DefenseStates.gd is not implemented yet, combat logic must still validate these exact string values.

### 4.6. Attack Payload Shape

All attacks use this Dictionary shape:

{
	"attacker_id": "player_1",
	"target_id": "ai_1",
	"card_id": "bruiser",
	"mode": "destroy_stash",
	"modifiers": [],
	"engine_target_card_id": ""
}

Required fields:

Field	Required	Cards	Description
attacker_id	yes	all attacks	Player playing the War card.
target_id	yes	all attacks	Target opponent.
card_id	yes	all attacks	Primary War card played.
mode	conditional	bruiser, cleaner, federal_raid	Selected effect mode.
modifiers	no	thug only in MVP	Optional modifier card IDs.
engine_target_card_id	conditional	saboteur	Specific Engine card to destroy.

Missing optional fields must be treated as:

"mode": ""
"modifiers": []
"engine_target_card_id": ""

### 4.7. Combat Result Shape

All combat functions that resolve an attack must return:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"attacker_id": "",
	"target_id": "",
	"card_id": "",
	"mode": "",
	"modifiers": [],
	"blocked": false,
	"blocker": "",
	"success": true,
	"effect_result": {},
	"cards_consumed": [],
	"contract_results": [],
	"contact_results": [],
	"log_entries": [],
	"state": {}
}

Failed validation result:

{
	"ok": false,
	"error": ValidationErrors.INVALID_TARGET,
	"attacker_id": "",
	"target_id": "",
	"card_id": "",
	"mode": "",
	"modifiers": [],
	"blocked": false,
	"success": false,
	"effect_result": {},
	"cards_consumed": [],
	"log_entries": [],
	"state": {}
}

Failed validation must not mutate state.

## 5. Rules

### 5.1. Combat Phase Rule

Attacks and War card discards are allowed only when:

state["current_phase"] == PhaseIds.ACTION

If false, return:

ValidationErrors.INVALID_PHASE

### 5.2. Active Player Rule

For player-driven actions, the attacker must be:

state["active_action_player_id"] == payload["attacker_id"]

If false, return:

ValidationErrors.INVALID_TARGET

AI systems must also use the same API and must not bypass this rule.

Scripted tests may call lower-level logic with an explicit test flag only if the public GameStateManager.gd API remains strict.

### 5.3. Attacker Rule

The attacker must:

exist in state["players"];
have payload["card_id"] in player["hand"];
play only a valid primary War card.

If the card is missing from hand, return:

ValidationErrors.INVALID_ACTION_CARD

### 5.4. Target Rule

The target must:

exist in state["players"];
not be the attacker;
be a valid opponent.

If invalid, return:

ValidationErrors.INVALID_TARGET

### 5.5. Primary War Cards

Valid primary War cards:

Card ID	Primary Action?	Notes
thug	yes	Steals up to 6 Nal.
bruiser	yes	Requires mode.
cleaner	yes	Requires mode.
saboteur	yes	Requires engine_target_card_id.
federal_raid	yes	Requires mode == "destroy_district".
insider	no	Modifier only in MVP.

insider must not be played as a standalone primary attack.

If payload["card_id"] == "insider", return:

ValidationErrors.INVALID_ACTION_CARD

### 5.6. Modifier Rule

In MVP combat, the only valid modifier is:

GameIds.CARD_INSIDER

insider may be used only with:

payload["card_id"] == GameIds.CARD_THUG

insider may be used only when:

attacker has insider in hand;
target has active Cops;
the selected primary card is thug.

If insider is used with any primary card other than thug, return:

ValidationErrors.INVALID_ACTION_CARD

If insider is listed but attacker does not have it in hand, return:

ValidationErrors.INVALID_ACTION_CARD

If insider is listed more than once, return:

ValidationErrors.INVALID_ACTION_CARD

When insider is valid and used:

thug ignores active Cops;
thug is consumed;
one insider card is also consumed;
both card IDs must appear in cards_consumed.

### 5.7. Used Card Consumption Rule

A valid resolved attack always consumes the primary War card, even if the attack is blocked by defense.

Examples:

thug blocked by Cops consumes thug;
saboteur blocked by Judge consumes saboteur;
bruiser destroy_stash blocked by Cartel consumes bruiser;
cleaner destroy_workshop blocked by Cartel consumes cleaner.

Failed validation must not consume cards.

### 5.8. Discard Rule

A player may discard any War card from hand during their Action turn without applying its effect.

Discarding:

requires PhaseIds.ACTION;
requires active player ownership;
requires the card to exist in hand;
removes exactly one copy of the card from hand;
writes a combat log entry with event_type == LogEventTypes.CARD_DISCARDED;
does not update contracts;
does not update contacts;
does not update last_attacked_by.

### 5.9. No Automatic Fallback Rule

If a chosen destructive mode is blocked or invalid, CombatEngine must not automatically convert it into a steal mode.

Examples:

blocked bruiser destroy_stash does not steal Nal;
blocked cleaner destroy_workshop does not steal Nal;
invalid destroy_stash against a target with no Stash does not fallback to steal_nal.

### 5.10. Nal Steal Rule

Nal stealing must respect protected Nal from Accountants.

Protected Nal calculation is owned by:

06_ECONOMY_AND_MARKET.md

Stealable Nal:

var protected_nal: int = PriceLogic.get_protected_nal(target["engine"]["accountants"])
var stealable_nal: int = max(0, target["nal"] - protected_nal)
var stolen_nal: int = min(max_steal, stealable_nal)

After successful steal:

target loses stolen_nal;
attacker gains stolen_nal;
Nal must never go below 0.

If stolen_nal == 0, the attack is still successful if validation passed and it was not blocked.

### 5.11. VP Clamp Rule

If combat reduces Victory Points, final VP must be clamped to:

0

### 5.12. Contract Hook Rule

After a successful, unblocked attack, CombatEngine must call ContractLogic combat hooks.

Blocked attacks must not grant combat progress.

Discarding must not grant combat progress.

Contract rule ownership:

09_CONTRACTS.md

### 5.13. Contact Hook Rule

After a successful, unblocked attack, CombatEngine may call ContactLogic combat hooks if the contact system requires it.

Blocked attacks must not trigger success-only contact progress.

Contact rule ownership:

11_CONTACTS.md

### 5.14. Last Attacked By Rule

After any valid resolved attack against a target, including blocked attacks:

target["last_attacked_by"] = attacker["id"]

Failed validation and discards must not update last_attacked_by.

## 6. Validation Rules

### 6.1. Validation Order

Combat validation must run in this exact order:

Validate state["current_phase"] == PhaseIds.ACTION.
Validate payload has attacker_id, target_id, and card_id.
Validate attacker exists.
Validate target exists.
Validate attacker and target are different players.
Validate attacker is the active action player.
Validate primary card is a valid primary War card.
Validate attacker has primary card in hand.
Validate modifiers.
Validate required attack mode.
Validate mode is legal for the selected card.
Validate selected target has required target resource/building/card.
Validate selected engine target for saboteur.
Return ValidationErrors.OK.

Validation must not mutate state.

### 6.2. Validation Error Mapping

Condition	Error
Not Action phase	INVALID_PHASE
Missing attacker	INVALID_TARGET
Missing target	INVALID_TARGET
Attacker equals target	INVALID_TARGET
Attacker is not active player	INVALID_TARGET
Invalid primary War card	INVALID_ACTION_CARD
Primary card not in hand	INVALID_ACTION_CARD
Invalid modifier	INVALID_ACTION_CARD
Modifier card not in hand	INVALID_ACTION_CARD
Required mode missing	ATTACK_MODE_REQUIRED
Mode not allowed for card	INVALID_ATTACK_MODE
Target lacks required building/card/resource	INVALID_TARGET
Target protected by defense	Validation passes; attack resolves as blocked.
Attack would steal 0 Nal	Validation passes.

### 6.3. Card Mode Validation

Card ID	Required Mode	Valid Modes	Missing Mode Error	Invalid Mode Error
thug	no	"" only	N/A	INVALID_ATTACK_MODE
bruiser	yes	steal_nal, destroy_stash	ATTACK_MODE_REQUIRED	INVALID_ATTACK_MODE
cleaner	yes	steal_nal, destroy_workshop	ATTACK_MODE_REQUIRED	INVALID_ATTACK_MODE
saboteur	no mode	"" only	N/A	INVALID_ATTACK_MODE
federal_raid	yes	destroy_district	ATTACK_MODE_REQUIRED	INVALID_ATTACK_MODE

### 6.4. Target Requirement Validation

Card / Mode	Requirement	Error if Missing
thug	target exists	INVALID_TARGET
bruiser + steal_nal	target exists	INVALID_TARGET
bruiser + destroy_stash	target has stash > 0	INVALID_TARGET
cleaner + steal_nal	target exists	INVALID_TARGET
cleaner + destroy_workshop	target has workshop > 0	INVALID_TARGET
saboteur	target has selected Engine card	INVALID_TARGET
federal_raid + destroy_district	target has district_control > 0	INVALID_TARGET

### 6.5. Saboteur Engine Target Validation

saboteur requires:

payload["engine_target_card_id"]

Valid engine targets:

Engine Target Card ID	Runtime Requirement
informant	target["engine"]["informers"] > 0
laundry	target["engine"]["laundries"] > 0
accountant	target["engine"]["accountants"] > 0
brothel	target["engine"]["brothel"] == true

If engine_target_card_id is missing, empty, invalid, or not owned by the target, return:

ValidationErrors.INVALID_TARGET

The attacker chooses engine_target_card_id.

The target does not choose which Engine card is destroyed.

saboteur must not select randomly.

### 6.6. Defense Validation Rule

Defenses do not usually make an attack invalid.

Instead:

validation passes;
resolution marks the attack as blocked;
selected defense effects are applied;
primary War card is consumed;
no successful attack effect is applied.

Exception:

If target lacks the required building/card before defense resolution, validation fails with INVALID_TARGET.

## 7. Resolution / Processing Flow

### 7.1. General Attack Flow

CombatEngine must resolve attacks in this exact order:

Normalize payload defaults.
Validate attack without mutation.
If validation fails, return failed result and do not mutate state.
Locate attacker and target in mutable state.
Resolve defense block status.
If blocked:
apply defense side effects;
consume primary card and valid modifiers;
update target["last_attacked_by"];
write blocked log entry;
validate state;
return blocked result.
If not blocked:
apply selected card effect;
consume primary card and valid modifiers;
update target["last_attacked_by"];
call ContractLogic success hooks;
call ContactLogic success hooks if required;
write success log entry;
validate state;
return success result.

### 7.2. Defense Resolution Order

Defense resolution must run in this order:

Cops check for thug.
Cartel check for destroy_stash or destroy_workshop.
Judge check for saboteur.

Only one defense should block a single attack in MVP.

federal_raid is not blocked by Cops, Cartel, or Judge.

### 7.3. Thug Resolution

Card:

thug

Effect:

Steal up to 6 Nal.

Rules:

thug does not require mode.
If mode is non-empty, return INVALID_ATTACK_MODE.
If target has active Cops and no valid insider modifier, attack is blocked.
If target has active Cops and valid insider modifier, Cops are ignored.
If not blocked, steal:
min(6, max(0, target["nal"] - protected_nal))
Consumed cards:
thug;
insider only if used as a valid modifier.

Cops are not consumed or deactivated when they block thug.

### 7.4. Bruiser Resolution

Card:

bruiser

Required mode:

steal_nal
destroy_stash

#### 7.4.1. Bruiser Steal Nal

Effect:

Steal up to 8 Nal.

Rules:

Must use mode == "steal_nal".
Cartel does not reduce stolen Nal.
Cops do not block bruiser.
Judge does not block bruiser.
Steal:
min(8, max(0, target["nal"] - protected_nal))

#### 7.4.2. Bruiser Destroy Stash

Effect:

Destroy one Stash; attacker gains +3 Nal; target loses 1 VP.

Rules:

Must use mode == "destroy_stash".
Target must have:
target["status_buildings"]["stash"] > 0
If target has active Cartel:
attack is blocked;
Stash is not destroyed;
attacker gains no Nal;
target loses no VP;
no steal fallback is applied;
Cartel remains active.
If not blocked:
subtract 1 from target Stash;
add 3 Nal to attacker;
subtract 1 VP from target, clamped to 0.

### 7.5. Cleaner Resolution

Card:

cleaner

Required mode:

steal_nal
destroy_workshop

#### 7.5.1. Cleaner Steal Nal

Effect:

Steal up to 14 Nal.

Rules:

Must use mode == "steal_nal".
Cartel does not reduce stolen Nal.
Cops do not block cleaner.
Judge does not block cleaner.
Steal:
min(14, max(0, target["nal"] - protected_nal))

#### 7.5.2. Cleaner Destroy Workshop

Effect:

Destroy one Workshop; attacker gains +5 Nal; target loses 2 VP; target skips next Action.

Rules:

Must use mode == "destroy_workshop".
Target must have:
target["status_buildings"]["workshop"] > 0
If target has active Cartel:
attack is blocked;
Workshop is not destroyed;
attacker gains no Nal;
target loses no VP;
skip_next_action is not set;
no steal fallback is applied;
target Cartel becomes depleted.
If not blocked:
subtract 1 from target Workshop;
add 5 Nal to attacker;
subtract 2 VP from target, clamped to 0;
set:
target["skip_next_action"] = true

### 7.6. Saboteur Resolution

Card:

saboteur

Effect:

Destroy one selected Engine card.

Rules:

saboteur does not use mode.
If mode is non-empty, return INVALID_ATTACK_MODE.
Attacker must choose a valid engine_target_card_id.
Valid choices:
informant;
laundry;
accountant;
brothel.
If target has active Judge:
attack is blocked;
selected Engine card is not destroyed;
Judge becomes none;
saboteur is consumed;
no contract success progress is granted.
If not blocked, destroy exactly one selected Engine card.

Engine mutation table:

engine_target_card_id	Mutation
informant	target["engine"]["informers"] -= 1
laundry	target["engine"]["laundries"] -= 1
accountant	target["engine"]["accountants"] -= 1
brothel	target["engine"]["brothel"] = false

Counts must not go below 0.

The target never chooses which Engine card is destroyed.

No random selection is used.

### 7.7. Federal Raid Resolution

Card:

federal_raid

Required mode:

destroy_district

Effect:

Destroy one District Control; target loses 3 VP; target may rebuild District Control for 8 Nal.

Rules:

Must use:
payload["mode"] == AttackModes.DESTROY_DISTRICT
Target must have:
target["status_buildings"]["district_control"] > 0
Cops do not block federal_raid.
Cartel does not block federal_raid.
Judge does not block federal_raid.
If successful:
subtract 1 from target District Control;
subtract 3 VP from target, clamped to 0;
set:
target["status_buildings"]["can_rebuild_district_for_8"] = true

Rebuild pricing and resolution are owned by:

06_ECONOMY_AND_MARKET.md

## 8. API Expectations

### 8.1. CombatEngine.gd

Recommended public static API:

class_name CombatEngine

static func validate_attack(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func resolve_attack(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func discard_war_card(state: Dictionary, player_id: String, card_id: String) -> Dictionary:
	return {}

static func get_combat_preview(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func get_valid_targets(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func get_valid_engine_targets(state: Dictionary, attacker_id: String, target_id: String) -> Dictionary:
	return {}

### 8.2. AttackValidator.gd

Recommended helper API:

class_name AttackValidator

static func normalize_payload(payload: Dictionary) -> Dictionary:
	return {}

static func validate_payload_shape(payload: Dictionary) -> Dictionary:
	return {}

static func validate_attacker(state: Dictionary, attacker_id: String) -> Dictionary:
	return {}

static func validate_target(state: Dictionary, attacker_id: String, target_id: String) -> Dictionary:
	return {}

static func validate_card_in_hand(attacker: Dictionary, card_id: String) -> Dictionary:
	return {}

static func validate_mode(card_id: String, mode: String) -> Dictionary:
	return {}

static func validate_modifiers(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func validate_target_requirement(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

Validation helpers must not mutate state.

### 8.3. DefenseResolver.gd

Recommended helper API:

class_name DefenseResolver

static func resolve_defense_preview(state: Dictionary, payload: Dictionary) -> Dictionary:
	return {}

static func apply_block_side_effects(state: Dictionary, payload: Dictionary, defense_result: Dictionary) -> Dictionary:
	return {}

Recommended defense result shape:

{
	"blocked": false,
	"blocker": "",
	"side_effects": [],
	"description": ""
}

Allowed blocker values:

Blocker	Meaning
""	Not blocked.
cops	Blocked by Cops.
cartel	Blocked by Cartel.
judge	Blocked by Judge.

### 8.4. CombatLogBuilder.gd

Recommended helper API:

class_name CombatLogBuilder

static func build_attack_log(result: Dictionary) -> Dictionary:
	return {}

static func build_discard_log(player_id: String, card_id: String) -> Dictionary:
	return {}

Required combat log envelope and unblocked-attack payload:

{
	"id": "log_000001",
	"round": 1,
	"phase": PhaseIds.ACTION,
	"event_type": LogEventTypes.ATTACK_EXECUTED,
	"actor_id": "",
	"target_id": "",
	"card_id": "",
	"summary": "",
	"details": {
		"attacker_id": "",
		"target_id": "",
		"card_id": "",
		"mode": "",
		"modifiers": [],
		"engine_target_card_id": "",
		"cards_consumed": []
	}
}

For `ATTACK_BLOCKED`, `details` has the same fields plus:

{
	"block_source": ""
}

Allowed combat event_type values:

Constant	String value	Meaning
LogEventTypes.ATTACK_EXECUTED	attack_executed	War card attack resolved.
LogEventTypes.ATTACK_BLOCKED	attack_blocked	War card attack resolved as blocked.
LogEventTypes.CARD_DISCARDED	card_discarded	War card discarded.
LogEventTypes.ACTION_SKIPPED	action_skipped	Phase controller skipped player action.

The exact envelope is owned by `04_GAME_STATE_SCHEMA.md`; the exact event payload fields and types are owned by `03_IDS_AND_CONSTANTS.md`. Undocumented envelope or `details` fields are forbidden. For attack events, `actor_id`, `target_id`, and `card_id` in the envelope must equal `details.attacker_id`, `details.target_id`, and `details.card_id`.

### 8.5. GameStateManager.gd Facade

Required public API references:

func execute_attack(payload: Dictionary) -> Dictionary:
	return {}

func get_combat_preview(payload: Dictionary) -> Dictionary:
	return {}

func get_disabled_reason(action_payload: Dictionary) -> String:
	return ""

func end_action_for_player(player_id: String) -> Dictionary:
	return {}

Recommended additions to 16_GAME_STATE_MANAGER_API.md:

func discard_war_card(player_id: String, card_id: String) -> Dictionary:
	return {}

func get_valid_targets(action_payload: Dictionary) -> Dictionary:
	return {}

func get_valid_engine_targets(attacker_id: String, target_id: String) -> Dictionary:
	return {}

UI must call GameStateManager only. UI must not call CombatEngine directly unless explicitly allowed for read-only previews.

### 8.6. Preview Result Shape

get_combat_preview should return:

{
	"ok": true,
	"error": ValidationErrors.OK,
	"attacker_id": "",
	"target_id": "",
	"card_id": "",
	"mode": "",
	"modifiers": [],
	"engine_target_card_id": "",
	"would_be_blocked": false,
	"blocker": "",
	"stealable_nal": 0,
	"protected_nal": 0,
	"max_steal": 0,
	"vp_loss": 0,
	"nal_gain": 0,
	"would_set_skip_next_action": false,
	"would_deplete_cartel": false,
	"would_remove_judge": false,
	"would_destroy": "",
	"cards_that_would_be_consumed": []
}

Preview functions must not mutate state.

## 9. Edge Cases

Edge Case	Condition	Expected Behavior	Error Code	Mutation Rule
Wrong phase	Current phase is not ACTION.	Attack or discard fails.	INVALID_PHASE	No mutation.
Invalid attacker	Attacker ID does not exist.	Attack fails.	INVALID_TARGET	No mutation.
Invalid target	Target ID does not exist.	Attack fails.	INVALID_TARGET	No mutation.
Self-target	Attacker equals target.	Attack fails.	INVALID_TARGET	No mutation.
Inactive attacker	Attacker is not active_action_player_id.	Attack fails.	INVALID_TARGET	No mutation.
Card not in hand	Attacker lacks primary card.	Attack fails.	INVALID_ACTION_CARD	No mutation.
Insider as primary card	card_id == insider.	Attack fails.	INVALID_ACTION_CARD	No mutation.
Insider with non-thug	Modifier contains insider, primary card is not thug.	Attack fails.	INVALID_ACTION_CARD	No mutation.
Duplicate Insider modifier	Modifier list contains insider more than once.	Attack fails.	INVALID_ACTION_CARD	No mutation.
Insider not in hand	Modifier contains insider, but hand does not.	Attack fails.	INVALID_ACTION_CARD	No mutation.
Thug with mode	thug payload has non-empty mode.	Attack fails.	INVALID_ATTACK_MODE	No mutation.
Thug blocked by Cops	Target has active Cops, no Insider modifier.	Attack is blocked; Cops stay active; Thug consumed.	OK	Mutates hand, log, last_attacked_by.
Thug with Insider vs Cops	Target has active Cops, valid Insider used.	Cops ignored; steal resolves; Thug and Insider consumed.	OK	Mutates hand, Nal, log, last_attacked_by.
Steal target has only protected Nal	stealable_nal == 0.	Attack succeeds, steals 0, card consumed.	OK	Mutates hand, log, last_attacked_by.
Bruiser missing mode	mode == "".	Attack fails.	ATTACK_MODE_REQUIRED	No mutation.
Bruiser invalid mode	Mode is not steal_nal or destroy_stash.	Attack fails.	INVALID_ATTACK_MODE	No mutation.
Bruiser destroy without Stash	Target has no Stash.	Attack fails.	INVALID_TARGET	No mutation.
Bruiser destroy blocked by Cartel	Target has Stash and active Cartel.	Attack blocked; no fallback; Cartel remains active; Bruiser consumed.	OK	Mutates hand, log, last_attacked_by.
Cleaner missing mode	mode == "".	Attack fails.	ATTACK_MODE_REQUIRED	No mutation.
Cleaner invalid mode	Mode is not steal_nal or destroy_workshop.	Attack fails.	INVALID_ATTACK_MODE	No mutation.
Cleaner destroy without Workshop	Target has no Workshop.	Attack fails.	INVALID_TARGET	No mutation.
Cleaner blocked by Cartel	Target has Workshop and active Cartel.	Attack blocked; Cartel becomes depleted; no skip; Cleaner consumed.	OK	Mutates hand, Cartel, log, last_attacked_by.
Cleaner successful destroy	Target has Workshop and no active Cartel.	Destroy Workshop, +5 Nal attacker, -2 VP target, set skip.	OK	Mutates hand, Nal, VP, status, skip, log.
Saboteur missing engine target	engine_target_card_id == "".	Attack fails.	INVALID_TARGET	No mutation.
Saboteur invalid engine target	Target does not own selected Engine card.	Attack fails.	INVALID_TARGET	No mutation.
Saboteur blocked by Judge	Target has active Judge.	Attack blocked; Judge becomes none; Saboteur consumed.	OK	Mutates hand, judge, log, last_attacked_by.
Saboteur successful	Valid selected Engine card, no active Judge.	Destroy selected Engine card.	OK	Mutates hand, engine, log, last_attacked_by.
Federal Raid missing mode	mode == "".	Attack fails.	ATTACK_MODE_REQUIRED	No mutation.
Federal Raid wrong mode	Mode is not destroy_district.	Attack fails.	INVALID_ATTACK_MODE	No mutation.
Federal Raid no District	Target has no District Control.	Attack fails.	INVALID_TARGET	No mutation.
Federal Raid with active Cartel	Target has District Control and active Cartel.	Raid succeeds; Cartel does not block.	OK	Mutates hand, VP, district, rebuild flag, log.
VP loss below zero	Target VP lower than loss amount.	Clamp VP to 0.	OK	Mutates VP safely.
Discard missing card	Player discards card not in hand.	Discard fails.	INVALID_ACTION_CARD	No mutation.
Discard valid card	Player discards owned War card.	Remove one copy and log discard.	OK	Mutates hand and log only.
Blocked attack and contracts	Defense blocks attack.	No success contract progress.	OK	Mutates defense/hand/log only.
Failed validation and contracts	Validation fails.	No hooks called.	Error from validation	No mutation.

## 10. Required Source Files

Required combat files:

res://logic/combat/CombatEngine.gd
res://logic/combat/AttackValidator.gd
res://logic/combat/DefenseResolver.gd
res://logic/combat/CombatLogBuilder.gd

Recommended optional helper files if splitting is needed:

res://logic/combat/CombatPreviewBuilder.gd
res://logic/combat/CombatEffectResolver.gd
res://logic/combat/CombatHandMutator.gd
res://logic/combat/CombatConstants.gd

Related source files:

res://autoload/GameStateManager.gd
res://data/ids/GameIds.gd
res://data/ids/ValidationErrors.gd
res://data/ids/AttackModes.gd
res://data/ids/PhaseIds.gd
res://logic/economy/PriceLogic.gd
res://logic/contracts/ContractLogic.gd
res://logic/contacts/ContactLogic.gd
res://logic/game_state/GameStateValidator.gd

Recommended technical addition:

res://data/ids/DefenseStates.gd

Each source file must stay under:

250 lines

If any file approaches the limit, split validators, effect resolvers, previews, or log building into separate files.

## 11. Required GUT Tests

Recommended test file:

res://tests/unit/test_combat_engine.gd

### 11.1. Validation Tests

Minimum tests:

attack outside Action phase returns INVALID_PHASE;
invalid attacker returns INVALID_TARGET;
invalid target returns INVALID_TARGET;
attacker cannot target self;
inactive attacker cannot attack;
primary card missing from hand returns INVALID_ACTION_CARD;
insider as primary card returns INVALID_ACTION_CARD;
insider modifier with non-thug card returns INVALID_ACTION_CARD;
duplicate insider modifier returns INVALID_ACTION_CARD;
bruiser without mode returns ATTACK_MODE_REQUIRED;
bruiser invalid mode returns INVALID_ATTACK_MODE;
cleaner without mode returns ATTACK_MODE_REQUIRED;
cleaner invalid mode returns INVALID_ATTACK_MODE;
federal_raid without mode returns ATTACK_MODE_REQUIRED;
federal_raid invalid mode returns INVALID_ATTACK_MODE;
saboteur without engine_target_card_id returns INVALID_TARGET;
saboteur against unowned Engine card returns INVALID_TARGET;
failed validation does not mutate state.

### 11.2. Thug Tests

Minimum tests:

thug steals up to 6 Nal;
thug respects Accountant protected Nal;
thug can steal 0 and still consumes card;
active Cops block thug;
Cops remain active after blocking thug;
blocked thug is consumed;
thug with valid insider ignores Cops;
thug with valid insider consumes both thug and insider.

### 11.3. Bruiser Tests

Minimum tests:

bruiser steal_nal steals up to 8 Nal;
bruiser steal_nal respects Accountant protected Nal;
bruiser destroy_stash destroys one Stash;
successful destroy_stash gives attacker +3 Nal;
successful destroy_stash removes 1 VP from target;
destroy_stash against no Stash returns INVALID_TARGET;
active Cartel blocks destroy_stash;
blocked destroy_stash gives no Nal and removes no VP;
blocked destroy_stash does not fallback to steal;
Cartel remains active after blocking bruiser.

### 11.4. Cleaner Tests

Minimum tests:

cleaner steal_nal steals up to 14 Nal;
cleaner steal_nal respects Accountant protected Nal;
cleaner destroy_workshop destroys one Workshop;
successful destroy_workshop gives attacker +5 Nal;
successful destroy_workshop removes 2 VP from target;
successful destroy_workshop sets skip_next_action = true;
destroy_workshop against no Workshop returns INVALID_TARGET;
active Cartel blocks destroy_workshop;
blocked destroy_workshop gives no Nal and removes no VP;
blocked destroy_workshop does not set skip_next_action;
blocked destroy_workshop does not fallback to steal;
blocked cleaner destroy_workshop changes Cartel from active to depleted.

### 11.5. Saboteur Tests

Minimum tests:

saboteur destroys selected informant;
saboteur destroys selected laundry;
saboteur destroys selected accountant;
saboteur destroys selected brothel;
saboteur cannot destroy unowned selected Engine card;
saboteur does not use random selection;
active Judge blocks saboteur;
Judge becomes none after blocking;
blocked saboteur does not destroy Engine card;
blocked saboteur is consumed;
blocked saboteur does not grant contract progress.

### 11.6. Federal Raid Tests

Minimum tests:

federal_raid requires destroy_district;
federal_raid destroys one District Control;
federal_raid removes 3 VP from target;
federal_raid sets can_rebuild_district_for_8 = true;
federal_raid against no District Control returns INVALID_TARGET;
active Cartel does not block federal_raid;
active Judge does not block federal_raid;
Cops do not block federal_raid.

### 11.7. Discard Tests

Minimum tests:

valid discard removes one War card from hand;
discard writes log entry;
discard does not call contract hooks;
discard does not call contact hooks;
discard does not update last_attacked_by;
invalid discard does not mutate state.

### 11.8. Integration Tests

Minimum tests:

multiple attacks can be played by the same player during one Action turn;
used War cards are removed from hand after each valid resolved attack;
unused War cards remain in hand;
blocked attacks consume cards;
successful attacks update last_attacked_by;
blocked attacks update last_attacked_by;
failed validation does not update last_attacked_by;
successful combat calls ContractLogic hooks;
blocked combat does not grant success-only contract progress;
combat preview does not mutate state;
no forbidden random APIs exist in combat logic files.

## 12. Static Scan Requirements

Static scan must fail if combat logic contains:

randf(
randi(
randomize(
RandomNumberGenerator

Combat MVP does not require random.

If future combat effects require random, they must use only:

SeededRandom.gd
SeededPicker.gd

Static scan must also fail if combat logic:

imports UI scenes;
reads UI nodes;
writes UI labels;
calculates card prices;
generates markets;
changes phase directly;
advances rounds directly;
performs AI scoring;
parses effect_summary strings to determine gameplay behavior.

Forbidden architecture patterns:

combat logic inside ActionPanel.gd;
defense resolution inside UI;
AI bypassing CombatEngine.resolve_attack;
hidden fallback from blocked destroy to steal;
random target-card destruction for saboteur;
standalone primary use of insider.

## 13. Implementation Notes For LLM Agents

When implementing combat:

Use constants from GameIds.gd, AttackModes.gd, PhaseIds.gd, and ValidationErrors.gd.
Do not hardcode card prices.
Do not implement market logic here.
Do not implement phase transitions here.
Do not implement AI scoring here.
Do not implement UI behavior here.
Do not parse .tres effect_summary text as logic.
Implement validation before mutation.
Failed validation must not mutate state.
Preview functions must not mutate state.
Blocked valid attacks must consume the primary card.
insider is not a standalone attack.
insider is only a modifier for thug against active Cops.
Valid insider usage consumes both thug and one insider.
saboteur requires attacker-selected engine_target_card_id.
saboteur must not randomly select Engine cards.
Cartel blocks only destroy_stash and destroy_workshop.
Cartel does not block Nal theft.
Cartel does not block federal_raid.
Cleaner depletes active Cartel only when Cartel blocks destroy_workshop.
Judge blocks saboteur once and then becomes none.
Cops block thug unless valid insider is used.
Cops are not consumed when they block.
Keep each source file under 250 lines.
Add GUT tests before expanding UI.

If an implementation detail is still unclear, do not invent it. Add it to:

21_OPEN_QUESTIONS_AND_FIXES.md

## 14. Acceptance Criteria

This module is complete when:

attack payload validation is implemented;
every War card has deterministic validation;
every War card has deterministic resolution;
thug steals up to 6 Nal;
bruiser steal_nal steals up to 8 Nal;
cleaner steal_nal steals up to 14 Nal;
Accountant protected Nal is respected;
Cops block thug;
valid insider lets thug ignore Cops;
insider cannot be used as a primary attack;
insider is consumed when used as a valid modifier;
bruiser destroy_stash works;
blocked bruiser destroy_stash has no steal fallback;
cleaner destroy_workshop works;
blocked cleaner destroy_workshop has no skip and no steal fallback;
Cleaner depletes Cartel when blocked by active Cartel;
saboteur destroys the attacker-selected Engine card;
saboteur does not use random target selection;
Judge blocks saboteur and becomes none;
federal_raid destroys District Control;
federal_raid sets can_rebuild_district_for_8;
Cartel does not block federal_raid;
valid resolved attacks consume used War cards;
failed validation does not mutate state;
combat preview does not mutate state;
combat logs are written for attacks, blocks, and discards;
success-only contract hooks are not called for blocked attacks;
UI does not own combat logic;
AI uses the same combat validation and resolution rules;
combat logic does not use forbidden random APIs;
all required GUT tests pass.

## 15. Final Rule

Combat resolves exactly the selected War card effect and never invents fallback behavior.
