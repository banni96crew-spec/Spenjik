class_name ContractRuntimeMutator


static func apply_progress(
	state: Dictionary,
	new_progress: int,
	source_event_type: String
) -> Dictionary:
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return ContractStateHelper.no_change(
			state, GameIds.PLAYER_HUMAN
		)
	var current: Dictionary = context["contract"]
	if current["completed"] or current["failed"]:
		return ContractStateHelper.no_change(
			state, GameIds.PLAYER_HUMAN
		)
	if state["round"] > current["deadline"]:
		return fail_contract(state, "deadline_exceeded")
	var definition: ContractDefinition = ContractCatalog.get_by_id(
		current["contract_id"]
	)
	if definition == null:
		return ContractStateHelper.failure(
			state, ValidationErrors.INVALID_CONTRACT_ID
		)
	var candidate: Dictionary = state.duplicate(true)
	var contract: Dictionary = ContractStateHelper.contract_ref(
		ContractStateHelper.find_player(
			candidate, GameIds.PLAYER_HUMAN
		),
		current["contract_id"]
	)
	var before: int = contract["progress"]
	contract["progress"] = clampi(
		new_progress, 0, definition.progress_required
	)
	var completed_now: bool = (
		contract["progress"] >= definition.progress_required
	)
	if completed_now:
		contract["completed"] = true
		contract["completed_round"] = candidate["round"]
		ContractLogBuilder.append_completed(
			candidate, GameIds.PLAYER_HUMAN, contract
		)
	elif contract["progress"] != before:
		ContractLogBuilder.append_progress(
			candidate, GameIds.PLAYER_HUMAN,
			contract["contract_id"], before, contract["progress"],
			source_event_type
		)
	return ContractStateHelper.hook_result(
		state, candidate, before, contract["progress"],
		completed_now, false
	)


static func fail_contract(
	state: Dictionary,
	reason: String
) -> Dictionary:
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return ContractStateHelper.no_change(
			state, GameIds.PLAYER_HUMAN
		)
	if context["contract"]["completed"] or context["contract"]["failed"]:
		return ContractStateHelper.no_change(
			state, GameIds.PLAYER_HUMAN
		)
	var candidate: Dictionary = state.duplicate(true)
	var contract: Dictionary = ContractStateHelper.contract_ref(
		ContractStateHelper.find_player(
			candidate, GameIds.PLAYER_HUMAN
		),
		context["contract"]["contract_id"]
	)
	var before: int = contract["progress"]
	contract["failed"] = true
	contract["failed_reason"] = reason
	ContractLogBuilder.append_failed(
		candidate, GameIds.PLAYER_HUMAN, contract
	)
	return ContractStateHelper.hook_result(
		state, candidate, before, contract["progress"], false, true
	)
