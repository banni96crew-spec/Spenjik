class_name AIPhaseCoordinator


static func complete_human_market(state: Dictionary) -> Dictionary:
	var human: Dictionary = GamePhaseController.end_market_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	if not human["ok"]:
		return human
	var ai: Dictionary = run_all_market(human["state"])
	if not ai["ok"]:
		return _failure(state, ai["error"])
	var advanced: Dictionary = GamePhaseController.advance_phase(ai["state"])
	if not advanced["ok"]:
		return _failure(state, advanced["error"])
	return _combined_result(human, ai, advanced)


static func complete_human_action(state: Dictionary) -> Dictionary:
	var human: Dictionary = GamePhaseController.end_action_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	if not human["ok"]:
		return human
	var first_ai: Dictionary = GamePhaseController.advance_action_player(
		human["state"]
	)
	if not first_ai["ok"]:
		return _failure(state, first_ai["error"])
	var ai: Dictionary = run_all_actions(first_ai["state"])
	if not ai["ok"]:
		return _failure(state, ai["error"])
	var advanced: Dictionary = GamePhaseController.advance_phase(ai["state"])
	if not advanced["ok"]:
		return _failure(state, advanced["error"])
	return _combined_result(human, first_ai, ai, advanced)


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


static func _combined_result(
	first: Dictionary,
	second: Dictionary,
	third: Dictionary,
	fourth: Dictionary = {}
) -> Dictionary:
	var result: Dictionary = first.duplicate(true)
	var steps: Array[Dictionary] = [second, third]
	if not fourth.is_empty():
		steps.append(fourth)
	result["results"] = []
	result["log_entries"] = first.get("log_entries", []).duplicate(true)
	for step: Dictionary in steps:
		if step.has("results"):
			result["results"] = step["results"].duplicate(true)
		result["log_entries"].append_array(
			step.get("log_entries", []).duplicate(true)
		)
		result["state"] = step["state"]
	return result
