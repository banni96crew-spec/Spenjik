class_name ContractClaimLogic


static func claim(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	var validation: Dictionary = _validate(
		state, player_id, contract_id
	)
	if not validation["ok"]:
		return _failure(
			state, validation["error"], player_id, contract_id
		)
	var candidate: Dictionary = state.duplicate(true)
	var human: Dictionary = ContractStateHelper.find_player(
		candidate, player_id
	)
	var contract: Dictionary = ContractStateHelper.contract_ref(
		human, contract_id
	)
	var definition: ContractDefinition = ContractCatalog.get_by_id(
		contract_id
	)
	var reward: Dictionary = ContractRewardResolver.apply(
		human, definition
	)
	if not reward["ok"]:
		return _failure(
			state, reward["error"], player_id, contract_id
		)
	contract["claimed"] = true
	contract["claimed_round"] = candidate["round"]
	ContractLogBuilder.append_claimed(
		candidate, player_id, contract, definition
	)
	var checked: Dictionary = ContractStateHelper.validate_candidate(
		state, candidate
	)
	if not checked["ok"]:
		return _failure(
			state, checked["error"], player_id, contract_id
		)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"contract_id": contract_id,
		"reward_type": reward["reward_type"],
		"reward_amount": reward["reward_amount"],
		"state": candidate,
		"log_entries": checked["log_entries"],
	}


static func _validate(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	if player_id != GameIds.PLAYER_HUMAN:
		return {"ok": false, "error": ValidationErrors.INVALID_TARGET}
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return {
			"ok": false,
			"error": ValidationErrors.CONTRACT_NOT_SELECTED,
		}
	var contract: Dictionary = context["contract"]
	if contract["contract_id"] != contract_id:
		return {
			"ok": false,
			"error": ValidationErrors.INVALID_CONTRACT_ID,
		}
	if contract["failed"]:
		return {
			"ok": false,
			"error": ValidationErrors.CONTRACT_ALREADY_FAILED,
		}
	if not contract["completed"]:
		return {
			"ok": false,
			"error": ValidationErrors.CONTRACT_NOT_COMPLETED,
		}
	if contract["claimed"]:
		return {
			"ok": false,
			"error": ValidationErrors.CONTRACT_ALREADY_CLAIMED,
		}
	return {"ok": true, "error": ValidationErrors.OK}


static func _failure(
	state: Dictionary,
	error: String,
	player_id: String,
	contract_id: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"contract_id": contract_id,
		"reward_type": "",
		"reward_amount": 0,
		"state": state,
		"log_entries": [],
	}
