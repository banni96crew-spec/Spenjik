class_name AIPhaseCoordinator


static func run_all_market(state: Dictionary) -> Dictionary:
	var working: Dictionary = state
	var log_entries: Array = []
	var results: Array[Dictionary] = []
	for player_id: String in GameIds.AI_PLAYER_IDS:
		var result: Dictionary = AIBotController.run_market_for_ai(
			working, player_id
		)
		if not result["ok"]:
			return _failure(state, result["error"])
		working = result["state"]
		results.append(result.duplicate(true))
		log_entries.append_array(result["log_entries"])
	return {
		"ok": true, "error": ValidationErrors.OK,
		"results": results, "state": working, "log_entries": log_entries,
	}


static func run_action_and_advance(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var result: Dictionary = AIBotController.run_action_for_ai(state, player_id)
	if not result["ok"]:
		return result
	return _advance_if_needed(state, result)


static func run_all_actions(state: Dictionary) -> Dictionary:
	var working: Dictionary = state
	var results: Array[Dictionary] = []
	var log_entries: Array = []
	while not working.get("active_action_player_id", "").is_empty():
		var player_id: String = working["active_action_player_id"]
		if not GameIds.AI_PLAYER_IDS.has(player_id):
			return _failure(state, ValidationErrors.PHASE_NOT_READY)
		var result: Dictionary = AIBotController.run_action_for_ai(
			working, player_id
		)
		if not result["ok"]:
			return _failure(state, result["error"])
		var advanced: Dictionary = _advance_if_needed(working, result)
		if not advanced["ok"]:
			return _failure(state, advanced["error"])
		working = advanced["state"]
		results.append(advanced.duplicate(true))
		log_entries.append_array(advanced["log_entries"])
	return {
		"ok": true, "error": ValidationErrors.OK,
		"results": results, "state": working, "log_entries": log_entries,
	}


static func _advance_if_needed(
	original: Dictionary,
	result: Dictionary
) -> Dictionary:
	if result["state"]["active_action_player_id"].is_empty():
		return result
	var advanced: Dictionary = GamePhaseController.advance_action_player(
		result["state"]
	)
	if not advanced["ok"]:
		return _failure(original, advanced["error"])
	var combined: Dictionary = result.duplicate(true)
	combined["state"] = advanced["state"]
	combined["log_entries"].append_array(advanced["log_entries"])
	return combined


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false, "error": error,
		"results": [], "state": state, "log_entries": [],
	}
