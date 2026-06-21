class_name ContactEffectResolver


static func has_contact(player: Dictionary, contact_id: String) -> bool:
	return player["contacts"]["unlocked"].has(contact_id)


static func get_contact_price_modifiers(
	state: Dictionary,
	player: Dictionary,
	card_def: CardDefinition
) -> Array[Dictionary]:
	if (
		card_def.type != CardTypes.STATUS
		or not has_contact(player, ContactIds.CORRUPT_CLERK)
		or player["role_flags"]["used_one_time_contact_bonus"]
	):
		return []
	return [{
		"id": "corrupt_clerk_%s_round_%d" % [player["id"], state["round"]],
		"source": "contact",
		"contact_id": ContactIds.CORRUPT_CLERK,
		"flag": "used_one_time_contact_bonus",
		"type": ModifierTypes.NEXT_STATUS_CARD_PRICE_DELTA,
		"delta": -1,
		"applies_to_card_type": CardTypes.STATUS,
		"consume_on_success": true,
		"description": "Corrupt Clerk first Status card discount",
	}]


static func consume_contact_flags_after_purchase(
	state: Dictionary,
	player_id: String,
	_card_id: String,
	applied_modifiers: Array[Dictionary]
) -> Dictionary:
	var consumed: bool = false
	for modifier: Dictionary in applied_modifiers:
		if (
			modifier.get("source") != "contact"
			or modifier.get("contact_id") != ContactIds.CORRUPT_CLERK
			or not modifier.get("consume_on_success", false)
		):
			continue
		var candidate: Dictionary = state.duplicate(true)
		var player: Dictionary = ContactValidator._find_player(
			candidate, player_id
		)
		if player.is_empty():
			return _failure(state, ValidationErrors.INVALID_PLAYER_ID)
		player["role_flags"]["used_one_time_contact_bonus"] = true
		ContactLogBuilder.append_activated(
			candidate, player_id, ContactIds.CORRUPT_CLERK
		)
		consumed = true
		return {
			"ok": true,
			"error": ValidationErrors.OK,
			"consumed": consumed,
			"state": candidate,
		}
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"consumed": false,
		"state": state,
	}


static func before_debt_penalty_applied(
	state: Dictionary,
	player_id: String,
	debt: Dictionary
) -> Dictionary:
	var player: Dictionary = ContactValidator._find_player(state, player_id)
	if player.is_empty():
		return _no_prevention(state)
	if not has_contact(player, ContactIds.STREET_MEDIC):
		return _no_prevention(state)
	if player["role_flags"]["used_emergency_protection"]:
		return _no_prevention(state)
	var vp_delta: int = int(debt.get("penalty", {}).get("vp_delta", 0))
	if vp_delta >= 0:
		return _no_prevention(state)
	var effective_loss: int = mini(abs(vp_delta), player["vp"])
	if effective_loss <= 0:
		return _no_prevention(state)
	var candidate: Dictionary = state.duplicate(true)
	player = ContactValidator._find_player(candidate, player_id)
	player["role_flags"]["used_emergency_protection"] = true
	ContactLogBuilder.append_activated(
		candidate, player_id, ContactIds.STREET_MEDIC
	)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"prevented": true,
		"contact_id": ContactIds.STREET_MEDIC,
		"vp_loss_prevented": effective_loss,
		"consume_contact": true,
		"state": candidate,
	}


static func reset_round_contact_usage(player: Dictionary) -> Dictionary:
	player["contacts"]["used_this_round"] = []
	return player


static func _no_prevention(state: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"prevented": false,
		"contact_id": "",
		"vp_loss_prevented": 0,
		"consume_contact": false,
		"state": state,
	}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"consumed": false,
		"state": state,
	}
