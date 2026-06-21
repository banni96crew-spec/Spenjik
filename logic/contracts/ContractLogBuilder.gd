class_name ContractLogBuilder


static func append_progress(
	state: Dictionary,
	player_id: String,
	contract_id: String,
	before: int,
	after: int,
	source_event_type: String
) -> void:
	_append(state, LogEventTypes.CONTRACT_PROGRESS_UPDATED, player_id, {
		"player_id": player_id,
		"contract_id": contract_id,
		"progress_before": before,
		"progress_after": after,
		"source_event_type": source_event_type,
	})


static func append_completed(
	state: Dictionary,
	player_id: String,
	contract: Dictionary
) -> void:
	_append(state, LogEventTypes.CONTRACT_COMPLETED, player_id, {
		"player_id": player_id,
		"contract_id": contract["contract_id"],
		"completed_round": contract["completed_round"],
	})


static func append_failed(
	state: Dictionary,
	player_id: String,
	contract: Dictionary
) -> void:
	_append(state, LogEventTypes.CONTRACT_FAILED, player_id, {
		"player_id": player_id,
		"contract_id": contract["contract_id"],
		"deadline": contract["deadline"],
		"failed_reason": contract["failed_reason"],
	})


static func append_claimed(
	state: Dictionary,
	player_id: String,
	contract: Dictionary,
	definition: ContractDefinition
) -> void:
	_append(state, LogEventTypes.CONTRACT_REWARD_CLAIMED, player_id, {
		"player_id": player_id,
		"contract_id": contract["contract_id"],
		"reward_type": definition.reward_type,
		"reward_amount": definition.reward_amount,
		"claimed_round": contract["claimed_round"],
	})


static func _append(
	state: Dictionary,
	event_type: String,
	player_id: String,
	details: Dictionary
) -> void:
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		event_type,
		{
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"],
			"phase": state["current_phase"],
			"actor_id": player_id,
			"summary": event_type,
			"details": details,
		}
	))
