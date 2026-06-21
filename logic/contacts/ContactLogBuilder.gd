class_name ContactLogBuilder


static func append_offered(
	state: Dictionary,
	player_id: String,
	source: String,
	contact_offer_ids: Array[String],
	created_round: int
) -> void:
	_append(state, LogEventTypes.CONTACT_OFFERED, player_id, {
		"player_id": player_id,
		"source": source,
		"contact_offer_ids": contact_offer_ids.duplicate(),
		"created_round": created_round,
	})


static func append_unlocked(
	state: Dictionary,
	player_id: String,
	contact_id: String,
	source: String
) -> void:
	_append(state, LogEventTypes.CONTACT_UNLOCKED, player_id, {
		"player_id": player_id,
		"contact_id": contact_id,
		"source": source,
	})


static func append_activated(
	state: Dictionary,
	player_id: String,
	contact_id: String
) -> void:
	_append(state, LogEventTypes.CONTACT_ACTIVATED, player_id, {
		"player_id": player_id,
		"contact_id": contact_id,
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
