class_name IncomeLogic


static func get_base_starting_resources() -> Dictionary:
	return {"nal": 5, "vp": 0}


## Resolves one player Income on a deep working copy.
static func resolve_player(state: Dictionary, player_id: String) -> Dictionary:
	var validation: Dictionary = _validate_income_state(state, player_id)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = _find_player(candidate, player_id)
	var dice: Dictionary = SeededRandom.roll_d6_pair(
		candidate["random"],
		"income_%s_round_%s" % [player_id, candidate["round"]]
	)
	if not dice["ok"]:
		return _failure(state, ValidationErrors.INVALID_RANDOM_STATE)
	candidate["random"] = dice["random"]
	var laundry_income: int = player["engine"]["laundries"] * 2
	var informant_income: int = player["engine"]["informers"]
	var brothel_income: int = _brothel_income(player, dice["is_double"])
	var total: int = dice["sum"] + laundry_income + informant_income + brothel_income
	var nal_before: int = player["nal"]
	player["nal"] += total
	_append_income_log(
		candidate, player, dice, laundry_income, informant_income,
		brothel_income, total, nal_before
	)
	var upkeep: Dictionary = _resolve_cops_upkeep(candidate, player)
	var contract_result: Dictionary = ContractLogic.on_income_resolved(
		candidate,
		{
			"player_id": player_id,
			"nal_after": player["nal"],
			"vp_after": player["vp"],
		}
	)
	if not contract_result["ok"]:
		return _failure(state, contract_result["error"])
	candidate = contract_result["state"]
	var final_validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not final_validation["ok"]:
		return _failure(state, final_validation["error"])
	return {
		"ok": true, "error": ValidationErrors.OK,
		"player_id": player_id, "dice": dice["dice"],
		"is_double": dice["is_double"], "laundry_income": laundry_income,
		"informant_income": informant_income,
		"brothel_income": brothel_income, "total_income": total,
		"cops_upkeep_result": upkeep, "debt_results": [],
		"contract_results": [contract_result], "state": candidate,
		"log_entries": _new_logs(state, candidate),
	}


## Resolves all four players in canonical order.
static func resolve_all_players(state: Dictionary) -> Dictionary:
	var blocker: Dictionary = validate_future_income_dependencies(state)
	if not blocker["ok"]:
		return _failure(state, blocker["error"])
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	var player_results: Array[Dictionary] = []
	for player_id: String in GameIds.PLAYER_IDS:
		var result: Dictionary = resolve_player(candidate, player_id)
		if not result["ok"]:
			return _failure(state, result["error"])
		candidate = result["state"]
		player_results.append(result)
	return {
		"ok": true, "error": ValidationErrors.OK,
		"state": candidate, "player_results": player_results,
		"log_entries": candidate["combat_log"].slice(log_start),
	}


## Rejects future-owner Income work before any random is consumed.
static func validate_future_income_dependencies(state: Dictionary) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		for debt: Dictionary in player.get("debts", []):
			if not debt.get("repaid", false):
				return {"ok": false, "error": ValidationErrors.PHASE_NOT_READY}
	return {"ok": true, "error": ValidationErrors.OK}


static func get_cops_upkeep_interval(
	state: Dictionary,
	player: Dictionary
) -> int:
	return 2 if state["turf_level"] >= 5 and not player["is_ai"] else 3


## Purely resolves Cops upkeep on an already-owned working state.
static func resolve_cops_upkeep(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = _find_player(candidate, player_id)
	if player.is_empty():
		return _failure(state, ValidationErrors.INVALID_PLAYER_ID)
	var result: Dictionary = _resolve_cops_upkeep(candidate, player)
	return {
		"ok": true, "error": ValidationErrors.OK,
		"state": candidate, "cops_upkeep_result": result,
		"log_entries": _new_logs(state, candidate),
	}


static func _resolve_cops_upkeep(
	state: Dictionary,
	player: Dictionary
) -> Dictionary:
	var defense: Dictionary = player["defense"]
	var interval: int = get_cops_upkeep_interval(state, player)
	var before: int = defense["cops_timer"]
	var result: Dictionary = {
		"was_due": false, "paid": false, "deactivated": false,
		"amount_paid": 0, "interval": interval,
		"timer_before": before, "timer_after": before,
	}
	if not defense["cops_active"]:
		return result
	defense["cops_timer"] += 1
	result["timer_after"] = defense["cops_timer"]
	if defense["cops_timer"] < interval:
		return result
	result["was_due"] = true
	defense["cops_timer"] = 0
	result["timer_after"] = 0
	if player["nal"] >= 1:
		var nal_before: int = player["nal"]
		player["nal"] -= 1
		result["paid"] = true
		result["amount_paid"] = 1
		_append_cops_paid(state, player, result, nal_before)
	else:
		defense["cops_active"] = false
		result["deactivated"] = true
		_append_cops_deactivated(state, player, result)
	return result


static func _brothel_income(player: Dictionary, is_double: bool) -> int:
	if not is_double or not player["engine"]["brothel"]:
		return 0
	return 6 if player["contacts"]["unlocked"].has(ContactIds.BLACK_CASH) else 5


static func _append_income_log(
	state: Dictionary,
	player: Dictionary,
	dice: Dictionary,
	laundry: int,
	informant: int,
	brothel: int,
	total: int,
	nal_before: int
) -> void:
	_append(state, LogEventTypes.INCOME_RESOLVED, player["id"], {
		"player_id": player["id"], "die_1": dice["dice"][0],
		"die_2": dice["dice"][1], "dice_sum": dice["sum"],
		"laundry_income": laundry, "informant_income": informant,
		"brothel_income": brothel, "total_income": total,
		"nal_before": nal_before, "nal_after": player["nal"],
	})


static func _append_cops_paid(
	state: Dictionary,
	player: Dictionary,
	result: Dictionary,
	nal_before: int
) -> void:
	_append(state, LogEventTypes.COPS_UPKEEP_PAID, player["id"], {
		"player_id": player["id"], "amount_paid": 1,
		"interval": result["interval"],
		"timer_before": result["timer_before"], "timer_after": 0,
		"nal_before": nal_before, "nal_after": player["nal"],
	})


static func _append_cops_deactivated(
	state: Dictionary,
	player: Dictionary,
	result: Dictionary
) -> void:
	_append(state, LogEventTypes.COPS_DEACTIVATED, player["id"], {
		"player_id": player["id"], "interval": result["interval"],
		"timer_before": result["timer_before"], "timer_after": 0,
		"nal": player["nal"],
	})


static func _append(
	state: Dictionary,
	event_type: String,
	player_id: String,
	details: Dictionary
) -> void:
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		event_type, {
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"], "phase": state["current_phase"],
			"actor_id": player_id, "summary": event_type,
			"details": details,
		}
	))


static func _validate_income_state(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return {"ok": false, "error": validation["error"]}
	if state["current_phase"] != PhaseIds.INCOME:
		return {"ok": false, "error": ValidationErrors.INVALID_PHASE}
	if not GameIds.PLAYER_IDS.has(player_id):
		return {"ok": false, "error": ValidationErrors.INVALID_PLAYER_ID}
	return validate_future_income_dependencies(state)


static func _new_logs(before: Dictionary, after: Dictionary) -> Array:
	return after["combat_log"].slice(before["combat_log"].size())


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false, "error": error, "state": state,
		"log_entries": [], "player_results": [],
	}
