class_name ContractStateHelper


static func active_context(state: Dictionary) -> Dictionary:
	var human: Dictionary = find_player(state, GameIds.PLAYER_HUMAN)
	if human.is_empty() or human.get("contracts", []).is_empty():
		return {}
	var selected: String = state.get("selected_contract_id", "")
	var contract: Dictionary = contract_ref(human, selected)
	return {} if contract.is_empty() else {
		"player": human,
		"contract": contract,
	}


static func find_player(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func contract_ref(
	player: Dictionary,
	contract_id: String
) -> Dictionary:
	for contract: Dictionary in player.get("contracts", []):
		if contract_id.is_empty() or contract["contract_id"] == contract_id:
			return contract
	return {}


static func validate_candidate(
	original: Dictionary,
	candidate: Dictionary
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return {
			"ok": false,
			"error": validation["error"],
			"log_entries": [],
		}
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"log_entries": candidate["combat_log"].slice(
			original["combat_log"].size()
		),
	}


static func no_change(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var context: Dictionary = active_context(state)
	var contract: Dictionary = context.get("contract", {})
	var progress: int = contract.get("progress", 0)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"contract_id": contract.get("contract_id", ""),
		"changed": false,
		"completed_now": false,
		"failed_now": false,
		"progress_before": progress,
		"progress_after": progress,
		"contract": contract.duplicate(true),
		"state": state,
		"log_entries": [],
	}


static func failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": "",
		"contract_id": "",
		"changed": false,
		"completed_now": false,
		"failed_now": false,
		"progress_before": 0,
		"progress_after": 0,
		"contract": {},
		"state": state,
		"log_entries": [],
	}


static func hook_result(
	original: Dictionary,
	candidate: Dictionary,
	before: int,
	after: int,
	completed_now: bool,
	failed_now: bool
) -> Dictionary:
	var checked: Dictionary = validate_candidate(original, candidate)
	if not checked["ok"]:
		return failure(original, checked["error"])
	var context: Dictionary = active_context(candidate)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": GameIds.PLAYER_HUMAN,
		"contract_id": context["contract"]["contract_id"],
		"changed": before != after or completed_now or failed_now,
		"completed_now": completed_now,
		"failed_now": failed_now,
		"progress_before": before,
		"progress_after": after,
		"contract": context["contract"].duplicate(true),
		"state": candidate,
		"log_entries": checked["log_entries"],
	}
