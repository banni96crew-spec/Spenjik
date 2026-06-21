class_name ContactValidator

const STRONG_AI_VICTORY_SOURCE := "strong_ai_victory"

const ALLOWED_SOURCES: Array[String] = [
	StreetDealIds.INSIDE_CONTACT,
	STRONG_AI_VICTORY_SOURCE,
]

const STATUS_CARD_IDS: Array[String] = [
	GameIds.CARD_STASH,
	GameIds.CARD_WORKSHOP,
	GameIds.CARD_DISTRICT_CONTROL,
]


static func is_valid_contact_id(contact_id: String) -> bool:
	return ContactIds.ALL.has(contact_id)


static func has_owned_contact(player: Dictionary) -> bool:
	return player["contacts"]["unlocked"].size() >= 1


static func has_unresolved_pending_offer(state: Dictionary) -> bool:
	var offer: Dictionary = state.get("contacts", {}).get("pending_offer", {})
	return not offer.is_empty() and not offer.get("resolved", true)


static func build_available_contact_ids(
	state: Dictionary,
	player_id: String
) -> Array[String]:
	if player_id != GameIds.PLAYER_HUMAN:
		return []
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty() or has_owned_contact(player):
		return []
	var pending_ids: Array = state.get("contacts", {}).get(
		"pending_offer", {}
	).get("contact_offer_ids", [])
	var available: Array[String] = []
	for contact_id: String in ContactIds.ALL:
		if player["contacts"]["unlocked"].has(contact_id):
			continue
		if pending_ids.has(contact_id):
			continue
		available.append(contact_id)
	return available


static func validate_offer_generation(
	state: Dictionary,
	player_id: String,
	count: int,
	source: String
) -> Dictionary:
	if player_id != GameIds.PLAYER_HUMAN:
		return _fail(ValidationErrors.INVALID_TARGET)
	if not ALLOWED_SOURCES.has(source):
		return _fail(ValidationErrors.CONTACT_OFFER_UNAVAILABLE)
	if count <= 0:
		return _fail(ValidationErrors.CONTACT_OFFER_UNAVAILABLE)
	if has_unresolved_pending_offer(state):
		return _fail(ValidationErrors.CONTACT_OFFER_UNAVAILABLE)
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _fail(ValidationErrors.INVALID_PLAYER_ID)
	if has_owned_contact(player):
		return _fail(ValidationErrors.CONTACT_LIMIT_REACHED)
	var available: Array[String] = build_available_contact_ids(
		state, player_id
	)
	if available.size() < count:
		return _fail(ValidationErrors.CONTACT_OFFER_UNAVAILABLE)
	return {"ok": true, "error": ValidationErrors.OK}


static func validate_selection(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var player_id: String = str(payload.get("player_id", ""))
	var contact_id: String = str(payload.get("contact_id", ""))
	var offer: Dictionary = state.get("contacts", {}).get("pending_offer", {})
	if offer.is_empty():
		return _selection_fail(
			ValidationErrors.CONTACT_OFFER_UNAVAILABLE, player_id, contact_id
		)
	if offer.get("resolved", false):
		return _selection_fail(
			ValidationErrors.INVALID_STATE, player_id, contact_id
		)
	if player_id != offer.get("player_id", ""):
		return _selection_fail(
			ValidationErrors.INVALID_TARGET, player_id, contact_id
		)
	if player_id != GameIds.PLAYER_HUMAN:
		return _selection_fail(
			ValidationErrors.INVALID_TARGET, player_id, contact_id
		)
	if not is_valid_contact_id(contact_id):
		return _selection_fail(
			ValidationErrors.INVALID_CONTACT_ID, player_id, contact_id
		)
	if not offer["contact_offer_ids"].has(contact_id):
		return _selection_fail(
			ValidationErrors.CONTACT_LOCKED, player_id, contact_id
		)
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _selection_fail(
			ValidationErrors.INVALID_PLAYER_ID, player_id, contact_id
		)
	if has_owned_contact(player):
		return _selection_fail(
			ValidationErrors.CONTACT_LIMIT_REACHED, player_id, contact_id
		)
	if player["contacts"]["unlocked"].has(contact_id):
		return _selection_fail(
			ValidationErrors.CONTACT_ALREADY_UNLOCKED, player_id, contact_id
		)
	return {"ok": true, "error": ValidationErrors.OK}


static func is_strong_ai_victory_event(event: Dictionary) -> bool:
	if str(event.get("attacker_id", "")) != GameIds.PLAYER_HUMAN:
		return false
	if not bool(event.get("target_is_ai", false)):
		return false
	if not bool(event.get("target_is_strong_ai", false)):
		return false
	if bool(event.get("blocked", true)):
		return false
	if not bool(event.get("success", false)):
		return false
	var destroyed_id: String = str(event.get("destroyed_status_card_id", ""))
	return STATUS_CARD_IDS.has(destroyed_id)


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}


static func _selection_fail(
	error: String,
	player_id: String,
	contact_id: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"contact_id": contact_id,
	}
