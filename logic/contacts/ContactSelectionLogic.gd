class_name ContactSelectionLogic


static func validate_contact_selection(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return ContactValidator.validate_selection(state, payload)


static func select_contact(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var validation: Dictionary = validate_contact_selection(state, payload)
	var player_id: String = str(payload.get("player_id", ""))
	var contact_id: String = str(payload.get("contact_id", ""))
	if not validation["ok"]:
		return _selection_failure(
			state, validation["error"], player_id, contact_id
		)
	var offer: Dictionary = state["contacts"]["pending_offer"]
	var source: String = str(offer["source"])
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = ContactValidator._find_player(
		candidate, player_id
	)
	player["contacts"]["unlocked"].append(contact_id)
	var definition: ContactDefinition = ContactCatalog.get_by_id(contact_id)
	if definition != null and definition.cooldown_rounds > 0:
		player["contacts"]["cooldowns"][contact_id] = definition.cooldown_rounds
	candidate["contacts"] = GameStateFactory.create_global_contact_state()
	ContactLogBuilder.append_unlocked(
		candidate, player_id, contact_id, source
	)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _selection_failure(
			state, final_validation["error"], player_id, contact_id
		)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"contact_id": contact_id,
		"source": source,
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(
			state["combat_log"].size()
		),
	}


static func _selection_failure(
	state: Dictionary,
	error: String,
	player_id: String,
	contact_id: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"contact_id": contact_id,
		"state": state,
	}
