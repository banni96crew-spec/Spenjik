class_name GameStateFactory


## Creates the complete setup-working snapshot without resolving setup gameplay.
static func create_new_game_state(game_seed: String, turf_level: int) -> Dictionary:
	var players: Array[Dictionary] = []
	for player_id: String in GameIds.PLAYER_IDS:
		players.append(create_player_state(
			player_id,
			GameIds.AI_PLAYER_IDS.has(player_id),
			turf_level
		))
	return {
		"round": 1,
		"current_phase": PhaseIds.SETUP,
		"players": players,
		"game_seed": game_seed,
		"random": create_random_state(game_seed),
		"turf_level": turf_level,
		"selected_role_id": "",
		"selected_contract_id": "",
		"contract_offer_ids": [],
		"market": {},
		"street_deals": create_street_deal_state(),
		"contacts": create_global_contact_state(),
		"ai_bosses": [],
		"action_order": [],
		"active_action_player_id": "",
		"combat_log": [],
		"winner_id": "",
		"game_result": {},
		"debug": {
			"schema_version": "1.0.0",
			"last_validation_error": "",
		},
	}


## Creates one complete PlayerState with independent nested collections.
static func create_player_state(
	player_id: String,
	is_ai: bool,
	turf_level: int
) -> Dictionary:
	return {
		"id": player_id,
		"is_ai": is_ai,
		"nal": 5,
		"vp": 0,
		"turf_level": turf_level,
		"engine": GameStateObjectFactory.create_engine_state(),
		"status_buildings": GameStateObjectFactory.create_status_buildings_state(),
		"defense": GameStateObjectFactory.create_defense_state(),
		"hand": [],
		"purchased_this_round": [],
		"ready_for_action": false,
		"action_done": false,
		"skip_next_action": false,
		"contracts": [],
		"contacts": create_player_contact_state(),
		"debts": [],
		"role_flags": create_role_flags(),
		"turf_flags": create_turf_flags(),
		"temporary_modifiers": [],
		"is_strong_ai": false,
		"last_attacked_by": "",
	}


static func create_random_state(game_seed: String) -> Dictionary:
	return SeededRandom.create_random_state(game_seed)


static func create_market_state() -> Dictionary:
	return GameStateObjectFactory.create_market_state()


static func create_street_deal_state() -> Dictionary:
	return GameStateObjectFactory.create_street_deal_state()


static func create_global_contact_state() -> Dictionary:
	return GameStateObjectFactory.create_global_contact_state()


static func create_player_contact_state() -> Dictionary:
	return GameStateObjectFactory.create_player_contact_state()


static func create_contact_offer_state(
	player_id: String = "",
	source: String = "",
	contact_offer_ids: Array[String] = [],
	created_round: int = 0
) -> Dictionary:
	return GameStateObjectFactory.create_contact_offer_state(
		player_id, source, contact_offer_ids, created_round
	)


static func create_contract_runtime(contract_id: String, deadline: int) -> Dictionary:
	return GameStateObjectFactory.create_contract_runtime(contract_id, deadline)


static func create_role_flags() -> Dictionary:
	return GameStateObjectFactory.create_role_flags()


static func create_turf_flags() -> Dictionary:
	return GameStateObjectFactory.create_turf_flags()


static func create_debt_state(
	debt_id: String,
	amount_due: int,
	deadline_round: int,
	penalty: Dictionary,
	created_round: int
) -> Dictionary:
	return GameStateObjectFactory.create_debt_state(
		debt_id, amount_due, deadline_round, penalty, created_round
	)


static func create_temporary_modifier(data: Dictionary) -> Dictionary:
	return GameStateObjectFactory.create_temporary_modifier(data)


static func create_combat_log_entry(
	event_type: String,
	data: Dictionary
) -> Dictionary:
	return GameStateObjectFactory.create_combat_log_entry(event_type, data)


static func create_ai_boss_state(
	profile_id: String,
	is_strong: bool,
	assigned_player_id: String
) -> Dictionary:
	return GameStateObjectFactory.create_ai_boss_state(
		profile_id, is_strong, assigned_player_id
	)


static func create_game_result() -> Dictionary:
	return GameStateObjectFactory.create_game_result()
