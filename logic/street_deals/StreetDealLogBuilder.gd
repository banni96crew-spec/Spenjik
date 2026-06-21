class_name StreetDealLogBuilder


static func append_offered(
	state: Dictionary,
	deal_id: String,
	available_option_ids: Array[String]
) -> void:
	_append(state, LogEventTypes.STREET_DEAL_OFFERED, "", {
		"deal_id": deal_id,
		"available_option_ids": available_option_ids.duplicate(),
	})


static func append_resolved(
	state: Dictionary,
	player_id: String,
	deal_id: String,
	option_id: String
) -> void:
	_append(state, LogEventTypes.STREET_DEAL_RESOLVED, player_id, {
		"player_id": player_id,
		"deal_id": deal_id,
		"option_id": option_id,
	})


static func append_debt_created(
	state: Dictionary,
	player_id: String,
	debt: Dictionary
) -> void:
	_append(state, LogEventTypes.DEBT_CREATED, player_id, {
		"player_id": player_id,
		"debt_id": debt["id"],
		"source": debt["source"],
		"amount_due": debt["amount_due"],
		"deadline_round": debt["deadline_round"],
	})


static func append_contact_handoff(
	state: Dictionary,
	player_id: String,
	offer: Dictionary
) -> void:
	_append(state, LogEventTypes.CONTACT_OFFERED, player_id, {
		"player_id": player_id,
		"source": offer["source"],
		"contact_offer_ids": offer["contact_offer_ids"].duplicate(),
		"created_round": offer["created_round"],
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
