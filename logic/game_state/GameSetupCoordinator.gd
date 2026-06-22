class_name GameSetupCoordinator


## Builds one complete committed setup candidate in the canonical random order.
static func start(config: Dictionary) -> Dictionary:
	var checked: Dictionary = _validate_config(config, true)
	if not checked["ok"]:
		return _failure(config, checked["error"])
	var state: Dictionary = GameStateFactory.create_new_game_state(
		config["game_seed"], config["turf_level"]
	)
	var role: Dictionary = RoleLogic.apply_role_setup(
		state, config["selected_role_id"]
	)
	if not role["ok"]:
		return _failure(config, role["error"])
	var offers: Dictionary = ContractLogic.generate_contract_offers(role["state"])
	if not offers["ok"]:
		return _failure(config, offers["error"])
	var selected: Dictionary = ContractLogic.select_contract(
		offers["state"],
		GameIds.PLAYER_HUMAN,
		config["selected_contract_id"]
	)
	if not selected["ok"]:
		return _failure(config, selected["error"])
	var ai: Dictionary = AIBotController.setup_ai_bosses(selected["state"])
	if not ai["ok"]:
		return _failure(config, ai["error"])
	var phased: Dictionary = GamePhaseController.advance_phase(ai["state"])
	if not phased["ok"]:
		return _failure(config, phased["error"])
	var candidate: Dictionary = phased["state"]
	_append_match_started(candidate, ai["strong_ai_player_id"])
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failure(config, validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"config": config.duplicate(true),
		"state": candidate,
		"log_entries": candidate["combat_log"].duplicate(true),
	}


## Generates setup offers on an isolated temporary setup state.
static func preview_contract_offers(config: Dictionary) -> Dictionary:
	var checked: Dictionary = _validate_config(config, false)
	if not checked["ok"]:
		return _preview_failure(checked["error"])
	var state: Dictionary = GameStateFactory.create_new_game_state(
		config["game_seed"], config["turf_level"]
	)
	var role: Dictionary = RoleLogic.apply_role_setup(
		state, config["selected_role_id"]
	)
	if not role["ok"]:
		return _preview_failure(role["error"])
	var offers: Dictionary = ContractLogic.generate_contract_offers(role["state"])
	if not offers["ok"]:
		return _preview_failure(offers["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"contract_offer_ids": offers["contract_offer_ids"].duplicate(),
		"steps_used": offers["steps_used"],
	}


static func _validate_config(config: Dictionary, require_contract: bool) -> Dictionary:
	var required: Array[String] = [
		"game_seed", "turf_level", "selected_role_id",
	]
	if require_contract:
		required.append("selected_contract_id")
	for key: String in required:
		if not config.has(key):
			return _check_failure(ValidationErrors.REQUIREMENT_NOT_MET)
	if (
		typeof(config["game_seed"]) != TYPE_STRING
		or str(config["game_seed"]).is_empty()
	):
		return _check_failure(ValidationErrors.REQUIREMENT_NOT_MET)
	if (
		typeof(config["turf_level"]) != TYPE_INT
		or not TurfLevelLogic.is_valid_turf_level(config["turf_level"])
	):
		return _check_failure(ValidationErrors.INVALID_TURF_LEVEL)
	if (
		typeof(config["selected_role_id"]) != TYPE_STRING
		or not RoleLogic.is_valid_role_id(config["selected_role_id"])
	):
		return _check_failure(ValidationErrors.INVALID_ROLE_ID)
	if require_contract and (
		typeof(config["selected_contract_id"]) != TYPE_STRING
		or not ContractIds.ALL.has(config["selected_contract_id"])
	):
		return _check_failure(ValidationErrors.INVALID_CONTRACT_ID)
	return {"ok": true, "error": ValidationErrors.OK}


static func _append_match_started(state: Dictionary, strong_ai_id: String) -> void:
	var profile_ids: Array[String] = []
	for boss: Dictionary in state["ai_bosses"]:
		profile_ids.append(boss["profile_id"])
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		LogEventTypes.MATCH_STARTED, {
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"],
			"phase": state["current_phase"],
			"summary": LogEventTypes.MATCH_STARTED,
			"details": {
				"game_seed": state["game_seed"],
				"turf_level": state["turf_level"],
				"selected_role_id": state["selected_role_id"],
				"contract_offer_ids": state["contract_offer_ids"].duplicate(),
				"selected_contract_id": state["selected_contract_id"],
				"ai_profile_ids": profile_ids,
				"strong_ai_player_id": strong_ai_id,
			},
		}
	))


static func _check_failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}


static func _preview_failure(error: String) -> Dictionary:
	return {
		"ok": false, "error": error,
		"contract_offer_ids": [], "steps_used": 0,
	}


static func _failure(config: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false, "error": error, "config": config.duplicate(true),
		"state": {}, "log_entries": [],
	}
