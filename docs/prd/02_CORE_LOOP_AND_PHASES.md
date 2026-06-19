Core Loop and Phases
Document Role

This file defines only: the match structure, round flow, phase state machine, phase transition rules, turn order, phase flags, skip-action behavior, game-over timing, and winner resolution entry point for The Turf.

This file must not redefine:

card prices;
card effects;
combat resolution details;
market price logic;
AI scoring;
random implementation;
UI layout;
state schema outside the phase-related fields needed here.

Source of truth dependencies:

00_INDEX.md
03_IDS_AND_CONSTANTS.md
04_GAME_STATE_SCHEMA.md
06_ECONOMY_AND_MARKET.md
07_COMBAT_SYSTEM.md
10_STREET_DEALS_AND_DEBTS.md
13_AI_SYSTEM.md
14_DETERMINISTIC_RANDOM.md
16_GAME_STATE_MANAGER_API.md
18_TEST_PLAN.md
20_LLM_AGENT_RULES.md
21_OPEN_QUESTIONS_AND_FIXES.md

Implementation target:

Godot 4.6.2
GDScript
GUT tests
1. Core Loop Summary

A match in The Turf lasts exactly 15 rounds.

Each round follows this structure:

Round Start
  -> Income Phase
  -> Market Phase
  -> Action Phase
  -> Optional Street Deal Phase after rounds 4, 8, and 12
  -> Next Round or Game Over

The match ends after the Action Phase of round 15 is fully resolved.

Street Deals occur only after the Action Phase of rounds 4, 8, and 12.

2. Phase IDs

The phase IDs are defined in:

03_IDS_AND_CONSTANTS.md

Required phase IDs:

setup
income
market
action
street_deal
game_over

No other phase IDs are allowed in MVP.

3. Match Length

A match always lasts exactly:

15 rounds

The current round value must satisfy:

1 <= round <= 15

The game must never create round 16.

After round 15 Action Phase is complete, the next phase must be:

game_over
4. Player Count

A match always has 4 participants:

1 human player
3 local AI players

Required player order:

player_1
ai_1
ai_2
ai_3

The human player always has ID:

player_1

The AI players always have IDs:

ai_1
ai_2
ai_3
5. Phase Ownership

Phase transitions are owned by:

GamePhaseController.gd

The public entry point for phase transitions is:

GameStateManager.advance_phase()

UI must not directly change:

state["current_phase"]
state["round"]
state["action_order"]
state["active_action_player_id"]

UI must only call public methods on:

GameStateManager.gd
6. Setup Phase
6.1. Purpose

The Setup Phase initializes the match before round 1 begins.

6.2. Setup Responsibilities

Setup must create and validate:

- game seed;
- selected Turf Level;
- selected human role;
- selected human contract;
- player states;
- AI player states;
- AI profiles;
- strong AI assignment;
- initial random state;
- `market = {}` until the first Income -> Market transition;
- empty combat log;
- empty runtime states.
6.3. Setup Completion

Setup is complete when:

- the game state exists;
- exactly 4 players exist;
- the human player has a selected role;
- the human player has a selected contract;
- AI players have assigned profiles;
- exactly one AI is marked as strong AI;
- the selected Turf Level is valid;
- GameStateValidator accepts the state.
6.4. Setup Transition

When Setup is complete:

setup -> income

Side effects:

- current_phase becomes income;
- round is set to 1;
- phase flags are reset;
- the state is validated.
7. Income Phase
7.1. Purpose

The Income Phase gives each player Nal income and resolves upkeep/debt effects.

7.2. Income Resolution Order

For each player, Income must resolve in this order:

1. Add +2 Nal for each Laundry.
2. Roll 2d6 through SeededRandom.
3. Add the 2d6 sum to the income amount.
4. Add +1 Nal for each Informant.
5. If the dice roll is a double and the player has Brothel, add Brothel bonus.
6. If black_cash contact is active, Brothel bonus is +6 instead of +5.
7. Add the final income amount to the player.
8. Process Cops upkeep.
9. Process active debts.
10. Update contract progress if any contract checks income-related conditions.
11. Write relevant log entries.

ASSUMPTION: the 2d6 sum is part of Income. This interpretation is used because the Income Phase defines a gameplay income roll, and otherwise the rolled total would have no economic effect beyond detecting doubles.

Detailed economy rules are defined in:

06_ECONOMY_AND_MARKET.md

Debt processing is defined in:

10_STREET_DEALS_AND_DEBTS.md

Random rules are defined in:

14_DETERMINISTIC_RANDOM.md
7.3. Income Completion

Income is complete when:

- all 4 players have resolved income;
- all required dice rolls have consumed deterministic random steps;
- Cops upkeep has been processed for all players;
- active debts have been processed for all players;
- income-related contract checks are complete;
- the state is valid.
7.4. Income Transition

When `advance_phase()` is called during Income, it resolves Income for all four players in canonical player order and, if every step succeeds, transitions:

income -> market

Side effects:

- resolve Income, Cops upkeep, debts, and contract hooks for `player_1`, `ai_1`, `ai_2`, `ai_3`;
- generate or refresh the market for the current round;
- reset purchased_this_round for every player;
- set ready_for_action = false for every player;
- set action_done = false for every player;
- clear round-scoped temporary purchase modifiers if expired;
- append canonical Income/Cops/debt/contract events followed by `PHASE_CHANGED`;
- validate and commit the complete result atomically.

There is no separately committed "Income complete" flag. If any player resolution, random operation, hook, market generation, or final validation fails, the complete candidate is discarded and the active state remains unchanged.
- validate state.
8. Market Phase
8.1. Purpose

The Market Phase lets players buy cards from the shared market.

The market is shared by all players.

8.2. Market Availability

A card can be bought only if it exists in:

state["market"]["all_available_card_ids"]

Market generation and purchase validation are defined in:

06_ECONOMY_AND_MARKET.md
8.3. Purchase Rules Summary

During Market Phase:

- each player may buy cards while they can afford them;
- a player cannot buy more than 1 copy of the same card_id in the same round;
- Engine, Status, and Defense cards go to the table;
- War cards go to the hand;
- purchase requirements must be satisfied;
- card limits must not be exceeded.
8.4. Human Market Flow

The human player may:

- inspect the market;
- preview prices and disabled reasons;
- buy valid cards;
- end Market participation.

When the human player ends Market participation:

player["ready_for_action"] = true
8.5. AI Market Flow

Each AI player must complete its purchase behavior during Market Phase.

AI purchase logic is defined in:

13_AI_SYSTEM.md

After an AI has finished buying:

ai_player["ready_for_action"] = true
8.6. Market Completion

Market Phase is complete when:

ready_for_action == true

for all 4 players.

8.7. Market Transition

When all players are ready:

market -> action

Side effects:

- build action_order;
- set active_action_player_id to the first valid action player;
- validate state.

Required Action order:

player_1
ai_1
ai_2
ai_3

The human player always acts first.

9. Action Phase
9.1. Purpose

The Action Phase lets players play War cards from their hands.

9.2. Action Order

Action order is fixed for MVP:

1. player_1
2. ai_1
3. ai_2
4. ai_3

This order is stored in:

state["action_order"]

The current acting player is stored in:

state["active_action_player_id"]
9.3. Human Action Flow

During the human action turn, the player may:

- inspect War cards in hand;
- select a War card;
- select a valid target;
- select an attack mode if required;
- select an optional modifier if available;
- preview the result;
- execute the attack;
- discard a War card without applying it;
- keep unused War cards in hand;
- end Action participation.

The human player may play any number of valid War cards during their Action turn.

When the human player ends their Action turn:

player["action_done"] = true
9.4. AI Action Flow

During an AI action turn, the AI must:

1. Check its hand.
2. Choose whether to attack according to its AI profile.
3. Choose a valid War card.
4. Choose a valid target.
5. Choose attack mode if required.
6. Use modifiers if beneficial and valid.
7. Execute valid attacks.
8. Apply fallback behavior if no valid action exists.
9. Set action_done = true.

AI behavior is defined in:

13_AI_SYSTEM.md
9.5. War Card Handling

When a War card is successfully played:

- the card effect is resolved;
- the card is removed from the player's hand;
- combat/contact/contract progress is updated if applicable;
- a combat log entry is written.

When a War card is discarded:

- the card is removed from the player's hand;
- no card effect is applied;
- no combat progress is awarded;
- a log entry may be written.

Unused War cards remain in hand.

9.6. Action Completion Per Player

A player is done with the Action Phase when:

player["action_done"] == true

A player can become action_done by:

- manually ending their Action turn;
- AI finishing its action flow;
- skip_next_action resolving;
- fallback behavior ending the action;
- having no valid action and ending the phase.
9.7. Action Completion For Phase

The Action Phase is complete when:

action_done == true

for all 4 players.

9.8. Action Transition

When all players are done:

action -> street_deal

only if:

round == 4
round == 8
round == 12

Otherwise:

action -> income

if:

round < 15

Otherwise:

action -> game_over

if:

round == 15
10. Skip Action Rules
10.1. Purpose

Some effects can force a player to skip their next Action Phase.

This is tracked by:

player["skip_next_action"]
10.2. Skip Check Timing

Skip Action is checked when the player becomes the active action player during Action Phase.

10.3. Skip Resolution

If:

player["skip_next_action"] == true

then:

- the player does not play or discard War cards;
- a combat log entry is written;
- player["skip_next_action"] = false;
- player["action_done"] = true;
- active_action_player_id advances to the next player.
10.4. Skip Restrictions

A skipped player cannot:

- play War cards;
- discard War cards;
- use attack modifiers;
- trigger attack-based contract progress.

A skipped player keeps all cards in hand.

11. Street Deal Phase
11.1. Purpose

Street Deals create special event choices after specific rounds.

Street Deals occur only after Action Phase in rounds:

4
8
12
11.2. Street Deal Entry Condition

The game enters Street Deal Phase only if:

current_phase == action
all players have action_done == true
round in [4, 8, 12]
11.3. Street Deal Selection

Street Deal rules are defined in:

10_STREET_DEALS_AND_DEBTS.md

For MVP, unless overridden by 21_OPEN_QUESTIONS_AND_FIXES.md, Street Deal selection should be treated as:

human player selects one available option;
AI players do not make Street Deal choices;
AI players may still be affected by specific Street Deal effects.
11.4. Street Deal Completion

Street Deal Phase is complete when:

- the current Street Deal has been selected and resolved;
- selected option effects have been applied;
- debts or temporary modifiers have been created if applicable;
- used_deal_ids has been updated;
- combat log has been updated if applicable;
- state is valid.
11.5. Street Deal Transition

After Street Deal Phase is complete:

street_deal -> income

Side effects:

- increment round by 1;
- reset ready_for_action = false for every player;
- reset action_done = false for every player;
- reset purchased_this_round for every player;
- clear active_action_player_id;
- clear or reset current Street Deal runtime fields;
- validate state.

Street Deal Phase can never occur after round 15 in MVP.

12. Game Over Phase
12.1. Purpose

Game Over resolves the final winner and produces the final match summary.

12.2. Game Over Entry Condition

The game enters Game Over when:

current_phase == action
round == 15
all players have action_done == true

Then:

action -> game_over
12.3. Game Over Responsibilities

When entering Game Over:

- resolve final scores;
- resolve winner_id;
- apply tie-break rules;
- create game_result;
- write final summary log entry;
- prevent further gameplay actions.
12.4. Allowed Actions During Game Over

During Game Over, UI may:

- display final scores;
- display winner;
- display tie-break explanation;
- display completed/failed contracts;
- display final combat log;
- start a new game through GameStateManager.start_new_game().

During Game Over, UI must not:

- buy cards;
- play cards;
- resolve income;
- trigger Street Deals;
- modify player resources;
- advance to another round.
13. Winner Resolution
13.1. WinnerResolver Ownership

Winner resolution is owned by:

WinnerResolver.gd

GamePhaseController must call WinnerResolver when entering:

game_over
13.2. Primary Win Condition

The primary win condition is:

highest Victory Points

The player with the highest vp wins.

13.3. Tie-Break Rules Below Turf Level 10

If multiple players are tied for highest Victory Points and Turf Level is below 10, apply tie-breaks in this order:

1. Highest Victory Points.
2. Highest Nal.
3. Highest total Status building VP value.
4. Highest number of Status buildings.
5. Fixed player order.

Fixed player order:

player_1
ai_1
ai_2
ai_3

This means the human player wins the final fixed-order tie if all previous tie-break values are equal.

13.4. Tie-Break Rule At Turf Level 10

At Turf Level 10:

If the human player and at least one AI are tied for highest Victory Points, the AI wins.

If multiple AI players are tied with the human player at Turf Level 10, use fixed AI order:

ai_1
ai_2
ai_3

If only AI players are tied with each other, use the normal tie-break order:

1. Highest Victory Points.
2. Highest Nal.
3. Highest total Status building VP value.
4. Highest number of Status buildings.
5. Fixed player order.
13.5. Status Building VP Value

For tie-break purposes only, Status building VP value is calculated from owned Status buildings:

stash = 1
workshop = 2
district_control = 3

This must not create additional Victory Points.
It is only a tie-break calculation.

13.6. Game Result Shape

WinnerResolver must produce a game result object with at least:

{
	"winner_id": "",
	"final_scores": [],
	"tie_break_used": false,
	"tie_break_steps": [],
	"turf_level_10_ai_win_applied": false
}

The exact state schema is defined in:

04_GAME_STATE_SCHEMA.md
14. Round Increment Rules
14.1. When Round Increments

The round increments only when moving from a completed round to the next round.

Round increments after:

- Action Phase, if no Street Deal occurs and round < 15;
- Street Deal Phase, if Street Deal occurs and round < 15.
14.2. When Round Does Not Increment

The round does not increment:

- during Setup;
- during Income;
- during Market;
- during Action before all players are done;
- after round 15;
- after entering Game Over.
14.3. Round Transition Examples

Round 1:

income -> market -> action -> income
round becomes 2 after Action is complete

Round 4:

income -> market -> action -> street_deal -> income
round becomes 5 after Street Deal is complete

Round 8:

income -> market -> action -> street_deal -> income
round becomes 9 after Street Deal is complete

Round 12:

income -> market -> action -> street_deal -> income
round becomes 13 after Street Deal is complete

Round 15:

income -> market -> action -> game_over
round remains 15
15. Phase Flags
15.1. ready_for_action

Field:

player["ready_for_action"]

Purpose:

Tracks whether a player has finished Market Phase participation.

Set to false:

- when a new round starts;
- when entering Income;
- when entering Market;
- when resetting phase flags.

Set to true:

- when the human player ends Market participation;
- when an AI player completes its Market logic.

Market Phase can transition to Action only when all players have:

ready_for_action == true
15.2. action_done

Field:

player["action_done"]

Purpose:

Tracks whether a player has finished Action Phase participation.

Set to false:

- when a new round starts;
- when entering Income;
- when entering Market;
- when entering Action;
- when resetting phase flags.

Set to true:

- when the human player ends Action participation;
- when an AI player completes its Action logic;
- when skip_next_action resolves;
- when fallback logic ends an AI turn.

Action Phase can transition only when all players have:

action_done == true
15.3. skip_next_action

Field:

player["skip_next_action"]

Purpose:

Tracks whether the player must skip their next Action turn.

Set to true by:

specific combat effects or other systems defined in their own files

Set to false only when:

the skip is consumed during Action Phase
16. Active Action Player
16.1. Field

The active action player is stored in:

state["active_action_player_id"]
16.2. During Non-Action Phases

Outside Action Phase:

active_action_player_id == ""
16.3. During Action Phase

During Action Phase:

active_action_player_id

must be one of:

player_1
ai_1
ai_2
ai_3
16.4. Advancing Active Player

After the current player becomes action_done, GamePhaseController must advance to the next player in:

state["action_order"]

If there is no next player:

active_action_player_id = ""

Then Action Phase completion is checked.

17. Phase Transition Table
Current Phase	Condition	Next Phase	Side Effects
setup	Setup complete and state valid	income	Set round to 1, reset phase flags
income	`advance_phase` can resolve all four players successfully	market	Resolve Income atomically, generate market, reset purchase flags
market	All players have ready_for_action == true	action	Build action order, set first active player
action	All players done and round is 4, 8, or 12	street_deal	Generate or offer Street Deal
action	All players done, round < 15, not Street Deal round	income	Increment round, reset phase flags
action	All players done and round == 15	game_over	Resolve winner and game result
street_deal	Street Deal resolved and round < 15	income	Increment round, reset phase flags
game_over	`start_new_game` requested	income	Replace the complete match state; this is not an `advance_phase` transition
18. Invalid Transitions

The following transitions are invalid:

setup -> market
setup -> action
income -> action
income -> street_deal
market -> income
market -> street_deal
action -> setup
street_deal -> market
street_deal -> action
game_over -> income
game_over -> market
game_over -> action
game_over -> street_deal

Invalid transitions must return a validation error and must not mutate state.

19. Required GamePhaseController API

GamePhaseController should expose small functions.

Recommended functions:

static func can_advance_phase(state: Dictionary) -> Dictionary:
	return {}

static func advance_phase(state: Dictionary) -> Dictionary:
	return {}

static func enter_income_phase(state: Dictionary) -> Dictionary:
	return {}

static func enter_market_phase(state: Dictionary) -> Dictionary:
	return {}

static func enter_action_phase(state: Dictionary) -> Dictionary:
	return {}

static func advance_action_player(state: Dictionary) -> Dictionary:
	return {}

static func enter_street_deal_phase(state: Dictionary) -> Dictionary:
	return {}

static func enter_game_over_phase(state: Dictionary) -> Dictionary:
	return {}

static func reset_round_flags(state: Dictionary) -> Dictionary:
	return {}

static func reset_market_flags(state: Dictionary) -> Dictionary:
	return {}

static func reset_action_flags(state: Dictionary) -> Dictionary:
	return {}

19.1. Canonical advance_phase Contract

`GamePhaseController.advance_phase(state)` owns all transition decisions. It receives a deep-copied working state and returns a structured result; it never reads or commits `GameStateManager.state`.

Before mutation it must:

- validate the complete committed GameState;
- reject an empty game with `GAME_NOT_STARTED`;
- reject Game Over with `GAME_ALREADY_OVER`;
- validate `current_phase`, `round`, action order, and active player invariants;
- validate current-phase completion conditions;
- return `PHASE_NOT_READY` when Market, Action, or Street Deal completion conditions are not satisfied.

It performs exactly one phase transition:

- Income -> Market resolves all four Income turns and Market entry in one transaction;
- Market -> Action requires all players ready and creates action order;
- Action -> Street Deal, Income, or Game Over requires all players done;
- Street Deal -> Income requires the human choice resolved;
- Setup -> Income is used only by the local `start_new_game` working flow, not by UI against active state.

Advancing from one active Action player to the next is owned by `end_action_for_player` plus `GamePhaseController.advance_action_player`; it is not a phase transition and must not call public `advance_phase`.

On success it may change:

- `current_phase`;
- `round`;
- phase flags and action order;
- `market` and Street Deal entry state;
- Income-owned player resources and nested runtime state;
- winner fields when entering Game Over;
- `combat_log` through canonical `LogEventTypes`.

Owner logic appends domain events in execution order. A transition that increments the round then appends `ROUND_STARTED`. `PHASE_CHANGED` is the final event appended by every successful `advance_phase` transaction.

The operation is atomic: any delegated error or final schema failure discards the complete working state, appends no active-state events, and emits no success signals.

GamePhaseController must not:

- calculate card prices;
- resolve attacks;
- choose AI targets;
- apply Street Deal effects;
- apply contact effects directly;
- use forbidden random APIs;
- contain UI code.
20. GameStateManager Phase API

GameStateManager must expose:

func advance_phase() -> Dictionary:
	return {}

GameStateManager may also expose:

func end_market_for_player(player_id: String) -> Dictionary:
	return {}

func end_action_for_player(player_id: String) -> Dictionary:
	return {}

These methods must delegate phase logic to:

GamePhaseController.gd

`GameStateManager.advance_phase()` deep-copies active state, calls `GamePhaseController.advance_phase`, validates the returned candidate, commits only on success, and returns delegated errors unchanged. It must not contain transition conditions or Income/Market/Game Over business rules.

21. Logging Requirements

The following successful phase operations must write the corresponding canonical `LogEventTypes` entries:

- match started;
- round started;
- Income resolved;
- Market started;
- player ended Market;
- Action started;
- player skipped Action;
- player ended Action;
- Street Deal offered;
- Street Deal resolved;
- Game Over reached;
- winner resolved.

Combat-specific logs are defined in:

07_COMBAT_SYSTEM.md

Street Deal logs are defined in:

10_STREET_DEALS_AND_DEBTS.md
22. UI Requirements Related To Phases

UI must display:

- current round;
- current phase;
- active action player;
- whose Market participation is complete;
- whose Action participation is complete;
- waiting_for_ai state;
- disabled reasons for unavailable actions;
- Game Over summary.

UI must not:

- directly change phase;
- directly set ready_for_action;
- directly set action_done;
- directly increment round;
- directly resolve skip_next_action;
- directly resolve winner.

UI must call:

GameStateManager.gd

Detailed UI rules are defined in:

17_UI_UX_SPEC.md
23. Edge Cases
23.1. Not All Players Ready

Condition:

current_phase == market
at least one player has ready_for_action == false

Expected behavior:

- do not transition to Action;
- keep current_phase as market;
- expose waiting state through selector.
23.2. Not All Players Done

Condition:

current_phase == action
at least one player has action_done == false

Expected behavior:

- do not transition to Street Deal;
- do not transition to Income;
- do not transition to Game Over;
- continue Action Phase.
23.3. Skipped Player

Condition:

current_phase == action
active player has skip_next_action == true

Expected behavior:

- write log entry;
- set skip_next_action = false;
- set action_done = true;
- advance active action player.
23.4. Round 4 Action Complete

Condition:

round == 4
current_phase == action
all players action_done == true

Expected behavior:

action -> street_deal
23.5. Round 8 Action Complete

Condition:

round == 8
current_phase == action
all players action_done == true

Expected behavior:

action -> street_deal
23.6. Round 12 Action Complete

Condition:

round == 12
current_phase == action
all players action_done == true

Expected behavior:

action -> street_deal
23.7. Round 15 Action Complete

Condition:

round == 15
current_phase == action
all players action_done == true

Expected behavior:

action -> game_over
23.8. Invalid Round

Condition:

round < 1
round > 15

Expected behavior:

- state validation fails;
- no phase transition should proceed.
23.9. Empty Action Order

Condition:

current_phase == action
action_order is empty

Expected behavior:

- state validation fails;
- GamePhaseController must not resolve actions.
23.10. Invalid Active Action Player

Condition:

active_action_player_id is not empty
active_action_player_id is not in PLAYER_IDS

Expected behavior:

- state validation fails;
- no action resolution should proceed.
24. Testing Requirements

Phase tests are defined in:

18_TEST_PLAN.md

Minimum required GUT tests:

- setup transitions to income when valid;
- income transitions to market after all income is resolved;
- market does not transition if not all players are ready;
- market transitions to action when all players are ready;
- action order is player_1, ai_1, ai_2, ai_3;
- skipped player sets skip_next_action false and action_done true;
- action does not transition while any player has action_done false;
- action round 4 transitions to street_deal;
- action round 8 transitions to street_deal;
- action round 12 transitions to street_deal;
- action round 15 transitions to game_over;
- street_deal transitions to income and increments round;
- no round 16 is created;
- invalid transition does not mutate state;
- WinnerResolver selects highest VP winner;
- WinnerResolver applies non-Turf-10 tie-breaks;
- WinnerResolver applies Turf Level 10 AI tie-break.
25. Acceptance Criteria

This system is complete when:

- all phase IDs are valid and centralized;
- setup can create a valid round 1 state;
- Income Phase can complete and transition to Market;
- Market Phase waits for all players to be ready;
- Action Phase follows fixed action order;
- skip_next_action is resolved correctly;
- Street Deal Phase occurs only after rounds 4, 8, and 12;
- Game Over occurs after round 15 Action Phase;
- WinnerResolver produces deterministic winner_id;
- invalid transitions are rejected;
- phase transitions do not contain UI logic;
- phase transitions do not contain card price logic;
- phase transitions do not contain combat resolution logic;
- phase transitions do not use forbidden random APIs;
- all required GUT tests pass.
26. Final Rule

The phase system controls when systems run.

It must not decide how economy, combat, AI, contracts, contacts, or Street Deals work internally.

Phase logic is orchestration only.
