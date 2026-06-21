class_name DebtLogic


static func create_debt(
	id: String,
	amount_due: int,
	deadline_round: int,
	penalty: Dictionary,
	created_round: int
) -> Dictionary:
	return GameStateFactory.create_debt_state(
		id, amount_due, deadline_round, penalty, created_round
	)


static func has_active_debt(player: Dictionary) -> bool:
	for debt: Dictionary in player.get("debts", []):
		if not debt.get("repaid", false):
			return true
	return false


static func get_active_debts(player: Dictionary) -> Array:
	var active: Array = []
	for debt: Dictionary in player.get("debts", []):
		if not debt.get("repaid", false):
			active.append(debt.duplicate(true))
	return active


## Processes debts in stable array order with an optional prevention hook.
static func process_debts_for_player(
	state: Dictionary,
	player_id: String,
	before_penalty_hook: Callable = Callable()
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"], player_id)
	if state["current_phase"] != PhaseIds.INCOME:
		return _failure(state, ValidationErrors.INVALID_PHASE, player_id)
	if not GameIds.PLAYER_IDS.has(player_id):
		return _failure(state, ValidationErrors.INVALID_PLAYER_ID, player_id)
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = DebtResolver.find_player(candidate, player_id)
	var results: Array[Dictionary] = []
	var source_event_type: String = ""
	for index: int in player["debts"].size():
		var debt: Dictionary = player["debts"][index]
		if debt["repaid"]:
			continue
		var result: Dictionary = DebtResolver.base_result(debt["id"])
		if player["nal"] >= debt["amount_due"]:
			result = DebtResolver.repay_in_place(
				candidate, player_id, index
			)
			source_event_type = LogEventTypes.DEBT_REPAID
		elif candidate["round"] > debt["deadline_round"]:
			var hook_result: Dictionary
			if before_penalty_hook.is_valid():
				hook_result = DebtResolver.run_penalty_hook(
					candidate, player_id, debt, before_penalty_hook
				)
			else:
				var medic_result: Dictionary = (
					ContactLogic.before_debt_penalty_applied(
						candidate, player_id, debt
					)
				)
				if not medic_result["ok"]:
					return _failure(
						state, medic_result["error"], player_id
					)
				hook_result = {
					"ok": true,
					"error": ValidationErrors.OK,
					"state": medic_result["state"],
					"vp_loss_prevented": medic_result.get("prevented", false),
				}
			if not hook_result["ok"]:
				return _failure(state, hook_result["error"], player_id)
			candidate = hook_result["state"]
			player = DebtResolver.find_player(candidate, player_id)
			result = DebtResolver.apply_penalty_in_place(
				candidate, player_id, index,
				hook_result["vp_loss_prevented"]
			)
			source_event_type = LogEventTypes.DEBT_PENALTY_APPLIED
		results.append(result)
		player = DebtResolver.find_player(candidate, player_id)
	var contract_results: Array[Dictionary] = []
	if not source_event_type.is_empty():
		var contract_result: Dictionary = ContractLogic.on_state_changed(
			candidate,
			{
				"source": "debt",
				"source_event_type": source_event_type,
				"player_id": player_id,
			}
		)
		if not contract_result["ok"]:
			return _failure(state, contract_result["error"], player_id)
		candidate = contract_result["state"]
		contract_results.append(contract_result)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _failure(state, final_validation["error"], player_id)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"results": results,
		"contract_results": contract_results,
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(
			state["combat_log"].size()
		),
	}


## Internal automatic repayment boundary; not exposed through the facade.
static func repay_debt(
	state: Dictionary,
	player_id: String,
	debt_id: String
) -> Dictionary:
	var validation: Dictionary = _validate_debt_operation(
		state, player_id, debt_id
	)
	if not validation["ok"]:
		return _failure(state, validation["error"], player_id)
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = DebtResolver.find_player(candidate, player_id)
	var index: int = _debt_index(player, debt_id)
	if player["nal"] < player["debts"][index]["amount_due"]:
		return _failure(state, ValidationErrors.NOT_ENOUGH_NAL, player_id)
	var result: Dictionary = DebtResolver.repay_in_place(
		candidate, player_id, index
	)
	return _single_result(state, candidate, player_id, result)


static func apply_debt_penalty(
	state: Dictionary,
	player_id: String,
	debt_id: String,
	vp_loss_prevented: bool = false
) -> Dictionary:
	var validation: Dictionary = _validate_debt_operation(
		state, player_id, debt_id
	)
	if not validation["ok"]:
		return _failure(state, validation["error"], player_id)
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = DebtResolver.find_player(candidate, player_id)
	var index: int = _debt_index(player, debt_id)
	var result: Dictionary = DebtResolver.apply_penalty_in_place(
		candidate, player_id, index, vp_loss_prevented
	)
	return _single_result(state, candidate, player_id, result)


static func _validate_debt_operation(
	state: Dictionary,
	player_id: String,
	debt_id: String
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return validation
	if not GameIds.PLAYER_IDS.has(player_id):
		return {"ok": false, "error": ValidationErrors.INVALID_PLAYER_ID}
	var player: Dictionary = DebtResolver.find_player(state, player_id)
	var index: int = _debt_index(player, debt_id)
	if index < 0 or player["debts"][index]["repaid"]:
		return {"ok": false, "error": ValidationErrors.INVALID_DEBT_STATE}
	return {"ok": true, "error": ValidationErrors.OK}


static func _single_result(
	original: Dictionary,
	candidate: Dictionary,
	player_id: String,
	result: Dictionary
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failure(original, validation["error"], player_id)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"results": [result],
		"contract_results": [],
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(
			original["combat_log"].size()
		),
	}


static func _debt_index(player: Dictionary, debt_id: String) -> int:
	for index: int in player.get("debts", []).size():
		if player["debts"][index]["id"] == debt_id:
			return index
	return -1
static func _failure(
	state: Dictionary,
	error: String,
	player_id: String = ""
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"results": [],
		"contract_results": [],
		"state": state,
		"log_entries": [],
	}
