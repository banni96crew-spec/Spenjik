class_name ReplayScriptRunner

const ERROR_COMMAND_FAILED := "replay_command_failed"
const ERROR_INVALID_SCRIPT := "replay_invalid_script"
const ERROR_STALLED := "replay_stalled"
const MAX_COMMANDS := 128


static func run_scripted_game(
	seed_value: String,
	script: Array[Dictionary]
) -> Dictionary:
	GameStateManager.reset_game()
	var trace: Array[Dictionary] = []
	var commands_executed: int = 0
	if script.is_empty() or script.size() > MAX_COMMANDS:
		return _failure(ERROR_INVALID_SCRIPT, 0, {}, trace, 0)
	for command_index: int in script.size():
		var command: Dictionary = script[command_index]
		var before: Dictionary = GameStateManager.get_state_snapshot()
		var result: Dictionary = _dispatch(seed_value, command)
		if not result.get("ok", false):
			return _failure(
				result.get("error", ERROR_COMMAND_FAILED),
				command_index,
				command,
				trace,
				commands_executed
			)
		commands_executed += 1
		var snapshot: Dictionary = GameStateManager.get_state_snapshot()
		if snapshot == before:
			return _failure(
				ERROR_STALLED,
				command_index,
				command,
				trace,
				commands_executed
			)
		if not snapshot.is_empty():
			var validation: Dictionary = GameStateValidator.validate_game_state(
				snapshot
			)
			if not validation["ok"]:
				return _failure(
					validation["error"],
					command_index,
					command,
					trace,
					commands_executed
				)
		trace.append(_checkpoint(command_index, command, result, snapshot))
	var state: Dictionary = GameStateManager.get_state_snapshot()
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"failed_command_index": -1,
		"failed_command": {},
		"state": state,
		"random_step": _random_step(state),
		"trace": trace,
		"commands_executed": commands_executed,
	}


static func normalize_snapshot(snapshot: Dictionary) -> Dictionary:
	return snapshot.duplicate(true)


static func _dispatch(seed_value: String, command: Dictionary) -> Dictionary:
	if not command.has("operation"):
		return _command_failure(ERROR_INVALID_SCRIPT)
	var operation: String = command["operation"]
	var payload: Dictionary = command.get("payload", {})
	match operation:
		"start_new_game":
			if not _has_keys(
				payload,
				["turf_level", "selected_role_id", "selected_contract_id"]
			):
				return _command_failure(ERROR_INVALID_SCRIPT)
			var config: Dictionary = payload.duplicate(true)
			config["game_seed"] = seed_value
			return GameStateManager.start_new_game(config)
		"advance_phase":
			return GameStateManager.advance_phase()
		"end_market_for_player":
			if not _has_keys(payload, ["player_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.end_market_for_player(payload["player_id"])
		"run_all_ai_market":
			return GameStateManager.run_all_ai_market()
		"buy_card":
			if not _has_keys(payload, ["player_id", "card_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.buy_card(
				payload["player_id"], payload["card_id"]
			)
		"end_action_for_player":
			if not _has_keys(payload, ["player_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.end_action_for_player(payload["player_id"])
		"run_all_ai_actions":
			return GameStateManager.run_all_ai_actions()
		"execute_attack":
			if payload.is_empty():
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.execute_attack(payload)
		"discard_war_card":
			if not _has_keys(payload, ["player_id", "card_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.discard_war_card(
				payload["player_id"], payload["card_id"]
			)
		"select_street_deal":
			if not _has_keys(payload, ["player_id", "deal_id", "option_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.select_street_deal(payload)
		"select_contact":
			if not _has_keys(payload, ["player_id", "contact_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.select_contact(payload)
		"claim_contract":
			if not _has_keys(payload, ["player_id", "contract_id"]):
				return _command_failure(ERROR_INVALID_SCRIPT)
			return GameStateManager.claim_contract(
				payload["player_id"], payload["contract_id"]
			)
	return _command_failure(ERROR_INVALID_SCRIPT)


static func _checkpoint(
	command_index: int,
	command: Dictionary,
	result: Dictionary,
	snapshot: Dictionary
) -> Dictionary:
	var checkpoint: Dictionary = {
		"command_index": command_index,
		"operation": command["operation"],
		"round": int(snapshot.get("round", 0)),
		"phase": str(snapshot.get("current_phase", "")),
		"random_step": _random_step(snapshot),
		"result_ids": _result_ids(result),
		"market": {},
		"street_deal": {},
		"contact_offer_ids": [],
		"ai_bosses": [],
		"winner_id": str(snapshot.get("winner_id", "")),
		"game_result": snapshot.get("game_result", {}).duplicate(true),
	}
	if (
		command["operation"] == "advance_phase"
		and checkpoint["phase"] == PhaseIds.MARKET
	):
		checkpoint["market"] = snapshot.get("market", {}).duplicate(true)
	if command["operation"] == "select_street_deal":
		checkpoint["street_deal"] = command.get("payload", {}).duplicate(true)
	var pending: Dictionary = snapshot.get("contacts", {}).get(
		"pending_offer", {}
	)
	if not pending.is_empty():
		checkpoint["contact_offer_ids"] = pending.get(
			"contact_offer_ids", []
		).duplicate()
	if command["operation"] == "start_new_game":
		checkpoint["ai_bosses"] = snapshot.get("ai_bosses", []).duplicate(true)
	return checkpoint


static func _result_ids(result: Dictionary) -> Dictionary:
	var ids: Dictionary = {}
	for key: String in [
		"player_id", "card_id", "target_id", "selected_ai_id",
		"selected_contract_id",
	]:
		if result.has(key):
			ids[key] = result[key]
	if result.has("results"):
		var ai_results: Array[Dictionary] = []
		for ai_result: Dictionary in result["results"]:
			ai_results.append({
				"player_id": ai_result.get("player_id", ""),
				"profile_id": ai_result.get("profile_id", ""),
				"purchases": ai_result.get("purchases", []).duplicate(true),
				"attacks": ai_result.get("attacks", []).duplicate(true),
				"fallback_used": ai_result.get("fallback_used", ""),
				"attack_roll": ai_result.get("attack_roll", -1.0),
			})
		ids["ai_results"] = ai_results
	return ids


static func _failure(
	error: String,
	command_index: int,
	command: Dictionary,
	trace: Array[Dictionary],
	commands_executed: int
) -> Dictionary:
	var state: Dictionary = GameStateManager.get_state_snapshot()
	return {
		"ok": false,
		"error": error,
		"failed_command_index": command_index,
		"failed_command": command.duplicate(true),
		"state": state,
		"random_step": _random_step(state),
		"trace": trace,
		"commands_executed": commands_executed,
	}


static func _command_failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}


static func _has_keys(payload: Dictionary, keys: Array[String]) -> bool:
	for key: String in keys:
		if not payload.has(key):
			return false
	return true


static func _random_step(snapshot: Dictionary) -> int:
	return int(snapshot.get("random", {}).get("step", 0))
