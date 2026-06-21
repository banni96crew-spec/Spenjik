class_name ContactOfferLogic


static func get_strong_ai_offer_count(state: Dictionary) -> int:
	return TurfLevelLogic.get_strong_ai_victory_contact_offer_count(
		state["turf_level"]
	)


static func generate_contact_offer(
	state: Dictionary,
	player_id: String,
	count: int,
	source: String
) -> Dictionary:
	var validation: Dictionary = ContactValidator.validate_offer_generation(
		state, player_id, count, source
	)
	if not validation["ok"]:
		return _offer_failure(state, validation["error"], player_id, source)
	var available: Array[String] = ContactValidator.build_available_contact_ids(
		state, player_id
	)
	var picked: Dictionary = SeededPicker.pick_unique(
		state["random"],
		available,
		count,
		"contact_offer_%s" % source
	)
	if (
		not picked["ok"]
		or picked["selected_items"].size() != count
		or picked["steps_used"] != count
	):
		return _offer_failure(
			state,
			ValidationErrors.CONTACT_OFFER_UNAVAILABLE,
			player_id,
			source
		)
	var candidate: Dictionary = state.duplicate(true)
	candidate["random"] = picked["random"]
	var offer_ids: Array[String] = []
	for item: Variant in picked["selected_items"]:
		offer_ids.append(str(item))
	var pending: Dictionary = GameStateFactory.create_contact_offer_state(
		player_id, source, offer_ids, candidate["round"]
	)
	candidate["contacts"]["pending_offer"] = pending
	ContactLogBuilder.append_offered(
		candidate,
		player_id,
		source,
		offer_ids,
		candidate["round"]
	)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _offer_failure(state, final_validation["error"], player_id, source)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"source": source,
		"contact_offer_ids": offer_ids.duplicate(),
		"random": candidate["random"].duplicate(true),
		"steps_used": picked["steps_used"],
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(state["combat_log"].size()),
	}


static func _offer_failure(
	state: Dictionary,
	error: String,
	player_id: String,
	source: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"source": source,
		"contact_offer_ids": [],
		"state": state,
	}
