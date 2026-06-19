# Cards Database

## Document Role

This file defines only: the canonical card database, card IDs, card types, card destinations, card requirements, card ownership model, runtime representation, and card effect summaries for The Turf.

This file must not redefine:

market generation rules;
price scaling rules beyond base card prices;
role modifiers;
combat resolution flow;
AI scoring;
UI behavior;
random rules;
phase transitions.

Source of truth dependencies:

00_INDEX.md
03_IDS_AND_CONSTANTS.md
04_GAME_STATE_SCHEMA.md
06_ECONOMY_AND_MARKET.md
07_COMBAT_SYSTEM.md
08_ROLES.md
12_TURF_LEVELS.md
16_GAME_STATE_MANAGER_API.md
18_TEST_PLAN.md
20_LLM_AGENT_RULES.md

Implementation target:

Godot 4.6.2
GDScript
.tres Resources
GUT tests

## 1. Purpose

This file is the canonical source of truth for all cards in the MVP.

The card database must remain stable during MVP implementation.

LLM agents must not:

- add new cards;
- remove cards;
- rename card IDs;
- change card base prices;
- change card types;
- change card destinations;
- change card effects;
- reinterpret effect summaries as executable logic;
- move gameplay logic into UI.

## 2. Card Count

The MVP contains exactly:

16 cards

Required card IDs:

informant
laundry
accountant
brothel
stash
workshop
district_control
cops
cartel
judge
thug
bruiser
cleaner
insider
saboteur
federal_raid

These IDs are defined in:

03_IDS_AND_CONSTANTS.md

## 3. Card Types

Cards use exactly four card types:

engine
status
defense
war

Card type constants are defined in:

CardTypes.gd

### 3.1. Engine Cards

Engine cards improve income or resource protection.

Engine cards are placed on the table after purchase.

### 3.2. Status Cards

Status cards provide Victory Points.

Status cards are placed on the table after purchase.

### 3.3. Defense Cards

Defense cards protect against specific War card effects.

Defense cards are placed on the table after purchase.

### 3.4. War Cards

War cards are attack cards.

War cards are placed into the player's hand after purchase and can be played during Action Phase.

## 4. Card Destinations

Cards use exactly two destinations:

table
hand

Destination constants are defined in:

CardDestinations.gd

Destination rules:

- Engine cards go to table.
- Status cards go to table.
- Defense cards go to table.
- War cards go to hand.

## 5. CardDefinition Resource Schema

Each card must be represented by a .tres Resource using:

res://data/resources/cards/CardDefinition.gd

Required schema:

class_name CardDefinition
extends Resource

@export var id: String
@export var title: String
@export_enum("engine", "status", "defense", "war") var type: String
@export var base_price: int
@export_enum("table", "hand") var destination: String
@export var max_per_player: int = 0
@export var effect_summary: String

## 6. CardDefinition Field Rules

Field	Rule
id	Must exist in GameIds.CARD_IDS
title	Display name only
type	Must exist in CardTypes.ALL
base_price	Must match this file
destination	Must exist in CardDestinations.ALL
max_per_player	0 means no explicit numeric limit
effect_summary	Display-only summary, not executable logic

## 7. Effect Summary Rule

effect_summary is for UI display and human readability only.

Gameplay systems must not parse effect_summary.

Correct:

CombatEngine resolves bruiser by card_id.
IncomeLogic resolves informant by card_id.
MarketLogic places purchased cards by type and destination.

Incorrect:

Parse effect_summary text and apply whatever it says.

That would be a beautiful little machine for manufacturing bugs.

## 8. Complete Card Database

| ID | Title | Type | Base Price | Destination | Effect Summary |
|---|---|---:|---|---|
| informant | Informant | engine | 5 | table | +1 Nal during Income |
| laundry | Laundry | engine | 8 | table | +2 Nal during Income |
| accountant | Shadow Accountant | engine | 4 | table | Protects Nal from theft |
| brothel | Brothel | engine | 6 | table | On doubles from 2d6, grants +5 Nal |
| stash | Stash | status | 8 | table | +1 Victory Point |
| workshop | Underground Workshop | status | 12 | table | +2 Victory Points |
| district_control | District Control | status | 15 | table | +3 Victory Points |
| cops | Friendly Cops | defense | 2 | table | Blocks Thug |
| cartel | Armed Cartel | defense | 6 | table | Blocks destruction of Stash and Workshop |
| judge | Pocket Judge | defense | 3 | table | Blocks Saboteur once |
| thug | Thug | war | 2 | hand | Steals up to 6 Nal |
| bruiser | Bruiser | war | 5 | hand | Steal Nal or destroy Stash |
| cleaner | Elite Cleaner | war | 9 | hand | Steal Nal or destroy Workshop |
| insider | Insider | war | 3 | hand | Modifier that ignores Cops |
| saboteur | Saboteur | war | 6 | hand | Destroys an Engine card |
| federal_raid | Federal Raid | war | 14 | hand | Destroys District Control |

## 9. Card Resource Files

Each card must have exactly one .tres Resource.

Required files:

res://data/resources/cards/informant.tres
res://data/resources/cards/laundry.tres
res://data/resources/cards/accountant.tres
res://data/resources/cards/brothel.tres
res://data/resources/cards/stash.tres
res://data/resources/cards/workshop.tres
res://data/resources/cards/district_control.tres
res://data/resources/cards/cops.tres
res://data/resources/cards/cartel.tres
res://data/resources/cards/judge.tres
res://data/resources/cards/thug.tres
res://data/resources/cards/bruiser.tres
res://data/resources/cards/cleaner.tres
res://data/resources/cards/insider.tres
res://data/resources/cards/saboteur.tres
res://data/resources/cards/federal_raid.tres

## 10. Engine Cards

Engine cards are stored in:

player["engine"]

Engine state is defined in:

04_GAME_STATE_SCHEMA.md

### 10.1. Informant

Field	Value
ID	informant
Title	Informant
Type	engine
Base Price	5
Destination	table
Runtime Field	player["engine"]["informers"]
Effect Owner	IncomeLogic.gd

Effect:

Each Informant gives +1 Nal during Income.

Runtime representation:

player["engine"]["informers"] += 1

Price scaling is defined in:

06_ECONOMY_AND_MARKET.md

### 10.2. Laundry

Field	Value
ID	laundry
Title	Laundry
Type	engine
Base Price	8
Destination	table
Runtime Field	player["engine"]["laundries"]
Effect Owner	IncomeLogic.gd

Effect:

Each Laundry gives +2 Nal during Income.

Runtime representation:

player["engine"]["laundries"] += 1

Price scaling is defined in:

06_ECONOMY_AND_MARKET.md

### 10.3. Shadow Accountant

Field	Value
ID	accountant
Title	Shadow Accountant
Type	engine
Base Price	4
Destination	table
Runtime Field	player["engine"]["accountants"]
Effect Owner	CombatEngine.gd / PriceLogic.gd for previews

Effect:

Protects Nal from theft.

Runtime representation:

player["engine"]["accountants"] += 1

Protected Nal calculation is defined in:

06_ECONOMY_AND_MARKET.md
07_COMBAT_SYSTEM.md

### 10.4. Brothel

Field	Value
ID	brothel
Title	Brothel
Type	engine
Base Price	6
Destination	table
Runtime Field	player["engine"]["brothel"]
Effect Owner	IncomeLogic.gd

Effect:

If the Income 2d6 roll is a double, Brothel gives +5 Nal.

If the player has the black_cash contact:

Brothel bonus becomes +6 Nal instead of +5 Nal.

Runtime representation:

player["engine"]["brothel"] = true

Card limit:

A player can have only one Brothel because the runtime field is boolean.

## 11. Status Cards

Status cards are stored in:

player["status_buildings"]

Status building state is defined in:

04_GAME_STATE_SCHEMA.md

### 11.1. Stash

Field	Value
ID	stash
Title	Stash
Type	status
Base Price	8
Destination	table
Runtime Field	player["status_buildings"]["stash"]
Effect Owner	MarketLogic.gd / CombatEngine.gd

Effect:

Gives +1 Victory Point.

Runtime representation on purchase:

player["status_buildings"]["stash"] += 1
player["vp"] += 1

Can be destroyed by:

bruiser with mode destroy_stash

### 11.2. Underground Workshop

Field	Value
ID	workshop
Title	Underground Workshop
Type	status
Base Price	12
Destination	table
Runtime Field	player["status_buildings"]["workshop"]
Effect Owner	MarketLogic.gd / CombatEngine.gd

Effect:

Gives +2 Victory Points.

Runtime representation on purchase:

player["status_buildings"]["workshop"] += 1
player["vp"] += 2

Can be destroyed by:

cleaner with mode destroy_workshop

### 11.3. District Control

Field	Value
ID	district_control
Title	District Control
Type	status
Base Price	15
Destination	table
Runtime Field	player["status_buildings"]["district_control"]
Effect Owner	MarketLogic.gd / CombatEngine.gd

Effect:

Gives +3 Victory Points.

Runtime representation on purchase:

player["status_buildings"]["district_control"] += 1
player["vp"] += 3

Purchase requirement:

player["status_buildings"]["district_control"] < player["status_buildings"]["workshop"]

Can be destroyed by:

federal_raid with mode destroy_district

Federal Raid destruction sets:

player["status_buildings"]["can_rebuild_district_for_8"] = true

Rebuild pricing and rules are defined in:

06_ECONOMY_AND_MARKET.md
07_COMBAT_SYSTEM.md

## 12. Defense Cards

Defense cards are stored in:

player["defense"]

Defense state is defined in:

04_GAME_STATE_SCHEMA.md

Defense behavior is defined in:

07_COMBAT_SYSTEM.md

### 12.1. Friendly Cops

Field	Value
ID	cops
Title	Friendly Cops
Type	defense
Base Price	2
Destination	table
Runtime Field	player["defense"]["cops_active"]
Effect Owner	DefenseResolver.gd / IncomeLogic.gd

Effect:

Blocks Thug unless Insider modifier is used.

Runtime representation on purchase:

player["defense"]["cops_active"] = true
player["defense"]["cops_timer"] = 0

Cops upkeep is defined in:

06_ECONOMY_AND_MARKET.md

Card limit:

A player can have only one active Cops state because the runtime field is boolean.

### 12.2. Armed Cartel

Field	Value
ID	cartel
Title	Armed Cartel
Type	defense
Base Price	6
Destination	table
Runtime Field	player["defense"]["cartel_state"]
Effect Owner	DefenseResolver.gd

Effect:

Blocks destruction of Stash and Workshop by level 2/3 attack cards.

Runtime representation on purchase:

player["defense"]["cartel_state"] = DefenseStates.ACTIVE

Valid states:

none
active
depleted

Combat rules:

- Cartel blocks destruction of Stash and Workshop.
- Cartel does not reduce stolen Nal.
- Cartel is depleted only by Cleaner according to combat rules.

Card limit:

A player can have only one Cartel state because the runtime field is a single state value.

### 12.3. Pocket Judge

Field	Value
ID	judge
Title	Pocket Judge
Type	defense
Base Price	3
Destination	table
Runtime Field	player["defense"]["judge_state"]
Effect Owner	DefenseResolver.gd

Effect:

Blocks Saboteur once.

Runtime representation on purchase:

player["defense"]["judge_state"] = DefenseStates.ACTIVE

After blocking Saboteur:

player["defense"]["judge_state"] = DefenseStates.NONE

Card limit:

A player can have only one Judge state because the runtime field is a single state value.

## 13. War Cards

War cards are stored in:

player["hand"]

War card effects are resolved by:

CombatEngine.gd

Combat rules are defined in:

07_COMBAT_SYSTEM.md

### 13.1. Thug

Field	Value
ID	thug
Title	Thug
Type	war
Base Price	2
Destination	hand
Runtime Field	player["hand"]
Effect Owner	CombatEngine.gd

Effect:

Steals up to 6 Nal.

Defense interaction:

Blocked by active Cops unless Insider modifier is used.

Required mode:

none

### 13.2. Bruiser

Field	Value
ID	bruiser
Title	Bruiser
Type	war
Base Price	5
Destination	hand
Runtime Field	player["hand"]
Effect Owner	CombatEngine.gd

Bruiser requires an attack mode.

Allowed modes:

steal_nal
destroy_stash

Mode effects:

Mode	Effect
steal_nal	Steal up to 8 Nal
destroy_stash	Destroy one Stash; attacker gains +3 Nal; target loses 1 Victory Point

Rules:

- The attacker chooses the mode before resolution.
- The mode cannot change after resolve_attack begins.
- If destroy_stash is blocked, there is no fallback to steal_nal.
- If the target has no Stash, destroy_stash is invalid.

### 13.3. Elite Cleaner

Field	Value
ID	cleaner
Title	Elite Cleaner
Type	war
Base Price	9
Destination	hand
Runtime Field	player["hand"]
Effect Owner	CombatEngine.gd

Cleaner requires an attack mode.

Allowed modes:

steal_nal
destroy_workshop

Mode effects:

Mode	Effect
steal_nal	Steal up to 14 Nal
destroy_workshop	Destroy one Workshop; attacker gains +5 Nal; target loses 2 Victory Points; target skips next Action

Rules:

- If destroy_workshop succeeds, target["skip_next_action"] = true.
- If destruction is blocked by Cartel, skip_next_action is not applied.
- Cleaner changes the target's active Cartel to depleted according to combat rules.
- If the target has no Workshop, destroy_workshop is invalid.

### 13.4. Insider

Field	Value
ID	insider
Title	Insider
Type	war
Base Price	3
Destination	hand
Runtime Field	player["hand"]
Effect Owner	CombatEngine.gd

Effect:

Acts as a modifier that allows an attack to ignore Cops.

Modifier behavior:

- Insider may be used as a modifier in an attack payload.
- Insider is consumed when used as a modifier.
- Insider must be removed from hand after successful attack resolution or valid blocked resolution where the modifier was applied.
- Insider does not directly steal Nal or destroy buildings by itself.

Required clarification:

The exact list of attacks compatible with Insider must be finalized in 07_COMBAT_SYSTEM.md.

Default MVP rule:

Insider can be used with Thug to ignore Cops.

### 13.5. Saboteur

Field	Value
ID	saboteur
Title	Saboteur
Type	war
Base Price	6
Destination	hand
Runtime Field	player["hand"]
Effect Owner	CombatEngine.gd

Effect:

Destroys one Engine card.

Defense interaction:

Blocked by active Judge.

Required target condition:

Target must have at least one destroyable Engine card.

Required clarification:

The exact target selection rule for which Engine card is destroyed must be finalized in 07_COMBAT_SYSTEM.md.

Default MVP rule:

The attacker selects the specific Engine card type to destroy.

Allowed engine targets:

informant
laundry
accountant
brothel

### 13.6. Federal Raid

Field	Value
ID	federal_raid
Title	Federal Raid
Type	war
Base Price	14
Destination	hand
Runtime Field	player["hand"]
Effect Owner	CombatEngine.gd

Federal Raid requires mode:

destroy_district

Effect:

Destroy one District Control.
Target loses 3 Victory Points.
Target can rebuild District Control for 8 Nal.

Runtime effect on target:

target["status_buildings"]["district_control"] -= 1
target["vp"] -= 3
target["status_buildings"]["can_rebuild_district_for_8"] = true

Required target condition:

Target must have at least one District Control.

## 14. Runtime Card Storage

Cards are not stored as Resource instances in runtime state.

Runtime state stores:

- card IDs;
- counters;
- booleans;
- state strings.

### 14.1. Engine Runtime Storage

"engine": {
	"informers": 0,
	"laundries": 0,
	"accountants": 0,
	"brothel": false
}

### 14.2. Status Runtime Storage

"status_buildings": {
	"stash": 0,
	"workshop": 0,
	"district_control": 0,
	"can_rebuild_district_for_8": false
}

### 14.3. Defense Runtime Storage

"defense": {
	"cops_active": false,
	"cops_timer": 0,
	"cartel_state": DefenseStates.NONE,
	"judge_state": DefenseStates.NONE
}

### 14.4. War Runtime Storage

"hand": []

War cards are stored as card IDs in hand:

player["hand"].append(GameIds.CARD_THUG)

## 15. Card Limits

### 15.1. General Rule

max_per_player = 0 means:

No explicit numeric limit from the CardDefinition field.

However, runtime representation can still imply a practical limit.

### 15.2. Counter-Based Cards

These cards use counters and can have multiple copies unless restricted elsewhere:

informant
laundry
accountant
stash
workshop
district_control

### 15.3. Boolean or State-Based Cards

These cards are limited by runtime representation:

brothel
cops
cartel
judge

Rules:

- Brothel uses a boolean field.
- Cops use active/timer fields.
- Cartel uses one state field.
- Judge uses one state field.

A player cannot stack multiple independent copies of these cards unless the PRD is explicitly updated.

### 15.4. War Cards

War cards are stored in hand and can have multiple copies.

Per-round purchase rule:

A player cannot buy more than 1 copy of the same card_id in the same round.

This rule is enforced by:

player["purchased_this_round"]

## 16. Card Requirements

### 16.1. Purchase Requirements

Card ID	Requirement
district_control	district_control < workshop
brothel	Player does not already have Brothel
cops	Player does not already have active Cops
cartel	Player does not already have active Cartel
judge	Player does not already have active Judge
All other cards	No special purchase requirement unless defined by another system

Role-based exceptions and discounts are defined in:

08_ROLES.md

Price and market validation rules are defined in:

06_ECONOMY_AND_MARKET.md

### 16.2. Action Requirements

Card ID	Requirement
thug	Valid target with stealable Nal unless blocked
bruiser	Valid target and selected mode
cleaner	Valid target and selected mode
insider	Valid compatible attack payload
saboteur	Target has destroyable Engine card
federal_raid	Target has District Control and mode destroy_district

Detailed action validation is defined in:

07_COMBAT_SYSTEM.md

## 17. Base Price Table

Base prices are fixed.

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

Dynamic price scaling and modifiers are defined in:

06_ECONOMY_AND_MARKET.md
08_ROLES.md
10_STREET_DEALS_AND_DEBTS.md
12_TURF_LEVELS.md

## 18. Victory Point Values

Status cards grant Victory Points on purchase.

Card ID	VP Value
stash	1
workshop	2
district_control	3

These values are also used by WinnerResolver for status building tie-break calculations.

Tie-break rules are defined in:

02_CORE_LOOP_AND_PHASES.md

## 19. Attack Mode Requirements

Card ID	Requires Mode	Allowed Modes
thug	No	none
bruiser	Yes	steal_nal, destroy_stash
cleaner	Yes	steal_nal, destroy_workshop
insider	No direct mode	used as modifier
saboteur	No	target engine selection required
federal_raid	Yes	destroy_district

Attack mode constants are defined in:

03_IDS_AND_CONSTANTS.md

Combat behavior is defined in:

07_COMBAT_SYSTEM.md

## 20. Defense Interaction Summary

Defense Card	Blocks	Notes
cops	thug	Does not block Thug if Insider modifier is applied
cartel	destroy_stash, destroy_workshop	Does not reduce stolen Nal
judge	saboteur	Blocks once, then becomes none

Detailed defense resolution is defined in:

07_COMBAT_SYSTEM.md

## 21. Market Availability Groups

Market availability is defined here only as card grouping.

Market generation rules are defined in:

06_ECONOMY_AND_MARKET.md

### 21.1. Always Available Cards

[
	"informant",
	"stash",
	"thug",
	"cops"
]

### 21.2. Rotating Market Pool

[
	"laundry",
	"accountant",
	"brothel",
	"workshop",
	"district_control",
	"cartel",
	"judge",
	"bruiser",
	"cleaner",
	"insider",
	"saboteur",
	"federal_raid"
]

## 22. Card Logic Ownership

Card ID	Main Logic Owner	Secondary Owner
informant	IncomeLogic.gd	PriceLogic.gd
laundry	IncomeLogic.gd	PriceLogic.gd
accountant	CombatEngine.gd	PriceLogic.gd
brothel	IncomeLogic.gd	ContactLogic.gd
stash	MarketLogic.gd	CombatEngine.gd
workshop	MarketLogic.gd	CombatEngine.gd
district_control	MarketLogic.gd	CombatEngine.gd
cops	DefenseResolver.gd	IncomeLogic.gd
cartel	DefenseResolver.gd	none
judge	DefenseResolver.gd	none
thug	CombatEngine.gd	AttackValidator.gd
bruiser	CombatEngine.gd	AttackValidator.gd
cleaner	CombatEngine.gd	AttackValidator.gd
insider	CombatEngine.gd	AttackValidator.gd
saboteur	CombatEngine.gd	DefenseResolver.gd
federal_raid	CombatEngine.gd	AttackValidator.gd

UI owns none of these effects.

## 23. Resource Validation Requirements

Card Resources are valid only if:

- every required card has exactly one .tres file;
- every .tres id exists in GameIds.CARD_IDS;
- every .tres type exists in CardTypes.ALL;
- every .tres destination exists in CardDestinations.ALL;
- every .tres base_price matches this file;
- every .tres effect_summary is non-empty;
- there are no duplicate card IDs;
- CARD_IDS contains exactly 16 IDs;
- every card in CARD_IDS has a Resource file.

## 24. GameState Validation Requirements

GameStateValidator must verify:

- every card ID in player["hand"] exists in GameIds.CARD_IDS;
- every card ID in player["hand"] is a War card;
- every card ID in player["purchased_this_round"] exists in GameIds.CARD_IDS;
- purchased_this_round has no duplicates;
- engine counters are >= 0;
- status building counters are >= 0;
- defense state values are valid;
- boolean cards use boolean runtime fields;
- status building VP does not become negative;
- player VP does not become negative;
- no player owns an impossible District Control count according to validation policy.

## 25. Required GUT Tests

Recommended test file:

res://tests/unit/test_cards_database.gd

Minimum required tests:

- CardDefinition.gd exists.
- All 16 card Resources load successfully.
- Every card Resource has a valid ID.
- Every card Resource has a valid type.
- Every card Resource has a valid destination.
- Every card Resource has the correct base price.
- Every card Resource has a non-empty title.
- Every card Resource has a non-empty effect_summary.
- No duplicate card IDs exist.
- Engine cards have destination table.
- Status cards have destination table.
- Defense cards have destination table.
- War cards have destination hand.
- Always available cards exist in CARD_IDS.
- Rotating market cards exist in CARD_IDS.
- Always available and rotating market pools do not overlap.
- CARD_IDS contains exactly 16 cards.

Additional integration tests:

- Buying Informant increments informers.
- Buying Laundry increments laundries.
- Buying Accountant increments accountants.
- Buying Brothel sets brothel to true.
- Buying Stash increments stash and VP by 1.
- Buying Workshop increments workshop and VP by 2.
- Buying District Control increments district_control and VP by 3.
- Buying Cops activates cops.
- Buying Cartel sets cartel_state to active.
- Buying Judge sets judge_state to active.
- Buying War cards adds card IDs to hand.

## 26. Implementation Notes For LLM Agents

When implementing card Resources or card-related logic:

- Do not change card IDs.
- Do not change card prices.
- Do not change card effects.
- Do not add new cards.
- Do not remove cards.
- Do not infer new hidden effects.
- Do not parse effect_summary.
- Do not write card effect logic in UI.
- Use constants from 03_IDS_AND_CONSTANTS.md.
- Keep each source file under 250 lines.
- Add or update GUT tests.

If a rule is unclear, do not invent a new rule inside implementation.

Add the issue to:

21_OPEN_QUESTIONS_AND_FIXES.md

## 27. Acceptance Criteria

This file is complete when:

- all 16 MVP cards are listed;
- every card has a stable ID;
- every card has a type;
- every card has a base price;
- every card has a destination;
- every card has an effect summary;
- runtime storage for each card category is clear;
- card requirements are listed;
- card limits are listed;
- attack mode requirements are listed;
- defense interactions are summarized;
- market availability groups are listed;
- card logic ownership is explicit;
- Resource validation requirements are clear;
- GUT test requirements are clear;
- no UI logic is defined here;
- no AI scoring is defined here;
- no market generation algorithm is defined here.

## 28. Final Rule

Cards are fixed data.

Logic modules may interpret card IDs according to this file and their own system specs.

UI may display cards.

No system may secretly invent new card behavior just because it feels helpful.
