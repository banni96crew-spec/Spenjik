class_name AttackValidator

const PRIMARY_CARDS: Array[String] = [
	GameIds.CARD_THUG,
	GameIds.CARD_BRUISER,
	GameIds.CARD_CLEANER,
	GameIds.CARD_SABOTEUR,
	GameIds.CARD_FEDERAL_RAID,
]
const ENGINE_TARGETS: Array[String] = [
	GameIds.CARD_INFORMANT,
	GameIds.CARD_LAUNDRY,
	GameIds.CARD_ACCOUNTANT,
	GameIds.CARD_BROTHEL,
]


## Returns the canonical attack payload without mutating the input.
static func normalize_payload(payload: Dictionary) -> Dictionary:
	return {
		"attacker_id": payload.get("attacker_id", ""),
		"target_id": payload.get("target_id", ""),
		"card_id": payload.get("card_id", ""),
		"mode": payload.get("mode", ""),
		"modifiers": payload.get("modifiers", []).duplicate(),
		"engine_target_card_id": payload.get("engine_target_card_id", ""),
	}


## Validates an attack in the canonical M7 order.
static func validate_attack(state: Dictionary, payload: Dictionary) -> Dictionary:
	if state.get("current_phase") != PhaseIds.ACTION:
		return _failure(ValidationErrors.INVALID_PHASE)
	var shape: Dictionary = validate_payload_shape(payload)
	if not shape["ok"]:
		return shape
	var normalized: Dictionary = normalize_payload(payload)
	var attacker: Dictionary = find_player(state, normalized["attacker_id"])
	if attacker.is_empty():
		return _failure(ValidationErrors.INVALID_TARGET)
	var target: Dictionary = find_player(state, normalized["target_id"])
	if target.is_empty() or attacker["id"] == target["id"]:
		return _failure(ValidationErrors.INVALID_TARGET)
	if state.get("active_action_player_id") != attacker["id"]:
		return _failure(ValidationErrors.INVALID_TARGET)
	if not PRIMARY_CARDS.has(normalized["card_id"]):
		return _failure(ValidationErrors.INVALID_ACTION_CARD)
	var hand: Dictionary = validate_card_in_hand(attacker, normalized["card_id"])
	if not hand["ok"]:
		return hand
	var modifiers: Dictionary = validate_modifiers(
		attacker, target, normalized
	)
	if not modifiers["ok"]:
		return modifiers
	var mode: Dictionary = validate_mode(
		normalized["card_id"], normalized["mode"]
	)
	if not mode["ok"]:
		return mode
	var requirement: Dictionary = validate_target_requirement(
		target, normalized
	)
	if not requirement["ok"]:
		return requirement
	if normalized["card_id"] == GameIds.CARD_SABOTEUR:
		var engine: Dictionary = validate_engine_target(
			target, normalized["engine_target_card_id"]
		)
		if not engine["ok"]:
			return engine
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"payload": normalized,
	}


static func validate_payload_shape(payload: Dictionary) -> Dictionary:
	if (
		not payload.has("attacker_id")
		or typeof(payload["attacker_id"]) != TYPE_STRING
		or str(payload["attacker_id"]).is_empty()
		or not payload.has("target_id")
		or typeof(payload["target_id"]) != TYPE_STRING
		or str(payload["target_id"]).is_empty()
	):
		return _failure(ValidationErrors.INVALID_TARGET)
	if (
		not payload.has("card_id")
		or typeof(payload["card_id"]) != TYPE_STRING
		or str(payload["card_id"]).is_empty()
	):
		return _failure(ValidationErrors.INVALID_ACTION_CARD)
	if payload.has("mode") and typeof(payload["mode"]) != TYPE_STRING:
		return _failure(ValidationErrors.INVALID_ATTACK_MODE)
	if payload.has("modifiers") and typeof(payload["modifiers"]) != TYPE_ARRAY:
		return _failure(ValidationErrors.INVALID_ACTION_CARD)
	if (
		payload.has("engine_target_card_id")
		and typeof(payload["engine_target_card_id"]) != TYPE_STRING
	):
		return _failure(ValidationErrors.INVALID_TARGET)
	return {"ok": true, "error": ValidationErrors.OK}


static func validate_card_in_hand(
	attacker: Dictionary,
	card_id: String
) -> Dictionary:
	if not attacker["hand"].has(card_id):
		return _failure(ValidationErrors.INVALID_ACTION_CARD)
	return {"ok": true, "error": ValidationErrors.OK}


static func validate_modifiers(
	attacker: Dictionary,
	target: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var modifiers: Array = payload["modifiers"]
	if modifiers.size() > 1:
		return _failure(ValidationErrors.INVALID_ACTION_CARD)
	for modifier: Variant in modifiers:
		if (
			typeof(modifier) != TYPE_STRING
			or modifier != GameIds.CARD_INSIDER
		):
			return _failure(ValidationErrors.INVALID_ACTION_CARD)
	if modifiers.is_empty():
		return {"ok": true, "error": ValidationErrors.OK}
	if (
		payload["card_id"] != GameIds.CARD_THUG
		or not attacker["hand"].has(GameIds.CARD_INSIDER)
		or not target["defense"]["cops_active"]
	):
		return _failure(ValidationErrors.INVALID_ACTION_CARD)
	return {"ok": true, "error": ValidationErrors.OK}


static func validate_mode(card_id: String, mode: String) -> Dictionary:
	var required: bool = card_id in [
		GameIds.CARD_BRUISER,
		GameIds.CARD_CLEANER,
		GameIds.CARD_FEDERAL_RAID,
	]
	if required and mode.is_empty():
		return _failure(ValidationErrors.ATTACK_MODE_REQUIRED)
	var allowed: Array[String] = []
	match card_id:
		GameIds.CARD_THUG, GameIds.CARD_SABOTEUR:
			allowed = [""]
		GameIds.CARD_BRUISER:
			allowed = [AttackModes.STEAL_NAL, AttackModes.DESTROY_STASH]
		GameIds.CARD_CLEANER:
			allowed = [AttackModes.STEAL_NAL, AttackModes.DESTROY_WORKSHOP]
		GameIds.CARD_FEDERAL_RAID:
			allowed = [AttackModes.DESTROY_DISTRICT]
	if not allowed.has(mode):
		return _failure(ValidationErrors.INVALID_ATTACK_MODE)
	return {"ok": true, "error": ValidationErrors.OK}


static func validate_target_requirement(
	target: Dictionary,
	payload: Dictionary
) -> Dictionary:
	match payload["card_id"]:
		GameIds.CARD_BRUISER:
			if (
				payload["mode"] == AttackModes.DESTROY_STASH
				and target["status_buildings"]["stash"] <= 0
			):
				return _failure(ValidationErrors.INVALID_TARGET)
		GameIds.CARD_CLEANER:
			if (
				payload["mode"] == AttackModes.DESTROY_WORKSHOP
				and target["status_buildings"]["workshop"] <= 0
			):
				return _failure(ValidationErrors.INVALID_TARGET)
		GameIds.CARD_FEDERAL_RAID:
			if target["status_buildings"]["district_control"] <= 0:
				return _failure(ValidationErrors.INVALID_TARGET)
	return {"ok": true, "error": ValidationErrors.OK}


static func validate_engine_target(
	target: Dictionary,
	engine_target_card_id: String
) -> Dictionary:
	if not ENGINE_TARGETS.has(engine_target_card_id):
		return _failure(ValidationErrors.INVALID_TARGET)
	if not get_owned_engine_targets(target).has(engine_target_card_id):
		return _failure(ValidationErrors.INVALID_TARGET)
	return {"ok": true, "error": ValidationErrors.OK}


static func get_owned_engine_targets(target: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if target["engine"]["informers"] > 0:
		result.append(GameIds.CARD_INFORMANT)
	if target["engine"]["laundries"] > 0:
		result.append(GameIds.CARD_LAUNDRY)
	if target["engine"]["accountants"] > 0:
		result.append(GameIds.CARD_ACCOUNTANT)
	if target["engine"]["brothel"]:
		result.append(GameIds.CARD_BROTHEL)
	return result


static func find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}
