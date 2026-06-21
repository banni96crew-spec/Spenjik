class_name DebtLogBuilder


static func append_repaid(
	state: Dictionary,
	player_id: String,
	debt_id: String,
	amount_paid: int,
	nal_before: int,
	nal_after: int
) -> void:
	_append(state, LogEventTypes.DEBT_REPAID, player_id, {
		"player_id": player_id,
		"debt_id": debt_id,
		"amount_paid": amount_paid,
		"nal_before": nal_before,
		"nal_after": nal_after,
	})


static func append_penalty(
	state: Dictionary,
	player_id: String,
	debt: Dictionary,
	nal_lost: int,
	vp_lost: int
) -> void:
	_append(state, LogEventTypes.DEBT_PENALTY_APPLIED, player_id, {
		"player_id": player_id,
		"debt_id": debt["id"],
		"lose_all_nal": debt["penalty"]["lose_all_nal"],
		"vp_delta": debt["penalty"]["vp_delta"],
		"nal_lost": nal_lost,
		"vp_lost": vp_lost,
	})


static func _append(
	state: Dictionary,
	event_type: String,
	actor_id: String,
	details: Dictionary
) -> void:
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		event_type,
		{
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"],
			"phase": state["current_phase"],
			"actor_id": actor_id,
			"summary": event_type,
			"details": details,
		}
	))
