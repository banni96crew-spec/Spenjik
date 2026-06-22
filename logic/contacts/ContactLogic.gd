class_name ContactLogic


static func create_empty_state() -> Dictionary:
	return GameStateFactory.create_player_contact_state()


static func create_empty_global_state() -> Dictionary:
	return GameStateFactory.create_global_contact_state()


static func has_contact(player: Dictionary, contact_id: String) -> bool:
	return ContactEffectResolver.has_contact(player, contact_id)


static func is_valid_contact_id(contact_id: String) -> bool:
	return ContactValidator.is_valid_contact_id(contact_id)


static func get_available_contact_ids(
	state: Dictionary,
	player_id: String
) -> Array[String]:
	return ContactValidator.build_available_contact_ids(state, player_id)


static func generate_contact_offer(
	state: Dictionary,
	player_id: String,
	count: int,
	source: String
) -> Dictionary:
	return ContactOfferLogic.generate_contact_offer(
		state, player_id, count, source
	)


static func validate_contact_selection(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return ContactSelectionLogic.validate_contact_selection(state, payload)


static func select_contact(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return ContactSelectionLogic.select_contact(state, payload)


## Manual activation is API-compatible but no active contact supports it in MVP.
static func activate_contact(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var player_id: String = str(payload.get("player_id", ""))
	var contact_id: String = str(payload.get("contact_id", ""))
	if not GameIds.PLAYER_IDS.has(player_id):
		return _activation_failure(
			state, ValidationErrors.INVALID_PLAYER_ID, player_id, contact_id
		)
	if not ContactIds.ALL.has(contact_id):
		return _activation_failure(
			state, ValidationErrors.INVALID_CONTACT_ID, player_id, contact_id
		)
	return _activation_failure(
		state, ValidationErrors.REQUIREMENT_NOT_MET, player_id, contact_id
	)


static func get_contact_price_modifiers(
	state: Dictionary,
	player: Dictionary,
	card_def: CardDefinition
) -> Array[Dictionary]:
	return ContactEffectResolver.get_contact_price_modifiers(
		state, player, card_def
	)


static func consume_contact_flags_after_purchase(
	state: Dictionary,
	player_id: String,
	card_id: String,
	applied_modifiers: Array[Dictionary]
) -> Dictionary:
	return ContactEffectResolver.consume_contact_flags_after_purchase(
		state, player_id, card_id, applied_modifiers
	)


static func before_debt_penalty_applied(
	state: Dictionary,
	player_id: String,
	debt: Dictionary
) -> Dictionary:
	return ContactEffectResolver.before_debt_penalty_applied(
		state, player_id, debt
	)


static func on_attack_resolved(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	return ContactAttackHookLogic.on_attack_resolved(state, event)


static func reset_round_contact_usage(player: Dictionary) -> Dictionary:
	return ContactEffectResolver.reset_round_contact_usage(player)


static func _activation_failure(
	state: Dictionary,
	error: String,
	player_id: String,
	contact_id: String
) -> Dictionary:
	return {
		"ok": false, "error": error,
		"player_id": player_id, "contact_id": contact_id,
		"state": state, "log_entries": [],
	}
