class_name DebtResolver


static func repay_in_place(
	state: Dictionary,
	player_id: String,
	index: int
) -> Dictionary:
	var player: Dictionary = find_player(state, player_id)
	var debt: Dictionary = player["debts"][index]
	var nal_before: int = player["nal"]
	player["nal"] -= debt["amount_due"]
	debt["repaid"] = true
	debt["repaid_round"] = state["round"]
	DebtLogBuilder.append_repaid(
		state, player_id, debt["id"], debt["amount_due"],
		nal_before, player["nal"]
	)
	var result: Dictionary = base_result(debt["id"])
	result["repaid"] = true
	result["auto_repaid"] = true
	result["amount_paid"] = debt["amount_due"]
	return result


static func apply_penalty_in_place(
	state: Dictionary,
	player_id: String,
	index: int,
	vp_loss_prevented: bool
) -> Dictionary:
	var player: Dictionary = find_player(state, player_id)
	var debt: Dictionary = player["debts"][index]
	var nal_before: int = player["nal"]
	var vp_before: int = player["vp"]
	if debt["penalty"]["lose_all_nal"]:
		player["nal"] = 0
	var vp_delta: int = int(debt["penalty"]["vp_delta"])
	if vp_delta < 0 and not vp_loss_prevented:
		player["vp"] = maxi(0, player["vp"] + vp_delta)
	debt["repaid"] = true
	debt["penalty_applied_round"] = state["round"]
	var nal_lost: int = nal_before - player["nal"]
	var vp_lost: int = vp_before - player["vp"]
	DebtLogBuilder.append_penalty(
		state, player_id, debt, nal_lost, vp_lost
	)
	var result: Dictionary = base_result(debt["id"])
	result["repaid"] = true
	result["penalty_applied"] = true
	result["nal_lost"] = nal_lost
	result["vp_lost"] = vp_lost
	result["vp_loss_prevented"] = vp_loss_prevented and vp_delta < 0
	return result


static func run_penalty_hook(
	state: Dictionary,
	player_id: String,
	debt: Dictionary,
	hook: Callable
) -> Dictionary:
	if not hook.is_valid():
		return {
			"ok": true,
			"error": ValidationErrors.OK,
			"state": state,
			"vp_loss_prevented": false,
		}
	var value: Variant = hook.call(
		state, player_id, debt.duplicate(true)
	)
	if typeof(value) != TYPE_DICTIONARY:
		return _hook_failure(state, ValidationErrors.REQUIREMENT_NOT_MET)
	var result: Dictionary = value
	if not result.get("ok", false):
		return _hook_failure(
			state,
			str(result.get("error", ValidationErrors.REQUIREMENT_NOT_MET))
		)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": result.get("state", state),
		"vp_loss_prevented": bool(
			result.get("vp_loss_prevented", false)
		),
	}


static func base_result(debt_id: String) -> Dictionary:
	return {
		"debt_id": debt_id,
		"was_active": true,
		"repaid": false,
		"auto_repaid": false,
		"penalty_applied": false,
		"amount_paid": 0,
		"nal_lost": 0,
		"vp_lost": 0,
		"vp_loss_prevented": false,
	}


static func find_player(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _hook_failure(
	state: Dictionary,
	error: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"state": state,
		"vp_loss_prevented": false,
	}
