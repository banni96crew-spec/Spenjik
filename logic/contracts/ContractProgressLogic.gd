class_name ContractProgressLogic


static func on_card_purchased(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return ContractStateHelper.no_change(
			state, event.get("player_id", "")
		)
	var progress: int = ContractConditionChecker.purchase_progress(
		context["contract"], event
	)
	if progress < 0:
		progress = ContractConditionChecker.current_progress(
			context["contract"]["contract_id"], context["player"]
		)
	return ContractRuntimeMutator.apply_progress(
		state, progress, LogEventTypes.CARD_PURCHASED
	)


static func on_income_resolved(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	if event.get("player_id") != GameIds.PLAYER_HUMAN:
		return ContractStateHelper.no_change(
			state, event.get("player_id", "")
		)
	return check_completion(
		state, GameIds.PLAYER_HUMAN, LogEventTypes.INCOME_RESOLVED
	)


static func on_attack_resolved(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return ContractStateHelper.no_change(
			state, event.get("attacker_id", "")
		)
	var contract: Dictionary = context["contract"]
	if (
		contract["contract_id"] == ContractIds.SILENT_EXPANSION
		and not contract["completed"]
		and not contract["failed"]
		and ContractConditionChecker.breaks_silent_expansion(event)
	):
		return ContractRuntimeMutator.fail_contract(
			state, "war_played"
		)
	var progress: int = ContractConditionChecker.attack_progress(
		contract, event
	)
	if progress >= 0:
		var source: String = (
			LogEventTypes.ATTACK_BLOCKED
			if event.get("blocked", false)
			else LogEventTypes.ATTACK_EXECUTED
		)
		return ContractRuntimeMutator.apply_progress(
			state, progress, source
		)
	return check_completion(
		state, GameIds.PLAYER_HUMAN,
		LogEventTypes.ATTACK_EXECUTED
	)


static func on_state_changed(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	var source: String = event.get(
		"source_event_type", LogEventTypes.STREET_DEAL_RESOLVED
	)
	if not LogEventTypes.ALL.has(source):
		return ContractStateHelper.failure(
			state, ValidationErrors.REQUIREMENT_NOT_MET
		)
	return check_completion(
		state,
		event.get("player_id", GameIds.PLAYER_HUMAN),
		source
	)


static func check_completion(
	state: Dictionary,
	player_id: String,
	source_event_type: String
) -> Dictionary:
	if player_id != GameIds.PLAYER_HUMAN:
		return ContractStateHelper.no_change(state, player_id)
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return ContractStateHelper.no_change(state, player_id)
	var progress: int = ContractConditionChecker.current_progress(
		context["contract"]["contract_id"], context["player"]
	)
	return (
		ContractStateHelper.no_change(state, player_id)
		if progress < 0
		else ContractRuntimeMutator.apply_progress(
			state, progress, source_event_type
		)
	)


static func process_deadlines(state: Dictionary) -> Dictionary:
	var context: Dictionary = ContractStateHelper.active_context(state)
	if context.is_empty():
		return ContractStateHelper.no_change(
			state, GameIds.PLAYER_HUMAN
		)
	var contract: Dictionary = context["contract"]
	if (
		contract["completed"]
		or contract["claimed"]
		or contract["failed"]
		or state["round"] <= contract["deadline"]
	):
		return ContractStateHelper.no_change(
			state, GameIds.PLAYER_HUMAN
		)
	return ContractRuntimeMutator.fail_contract(
		state, "deadline_exceeded"
	)
