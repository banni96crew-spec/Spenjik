class_name UICommandPayloads
extends RefCounted


static func setup_config(
	seed_value: String,
	turf_level: int,
	role_id: String,
	contract_id: String
) -> Dictionary:
	return {
		"game_seed": seed_value,
		"turf_level": turf_level,
		"selected_role_id": role_id,
		"selected_contract_id": contract_id,
	}


static func setup_preview_config(
	seed_value: String,
	turf_level: int,
	role_id: String
) -> Dictionary:
	return {
		"game_seed": seed_value,
		"turf_level": turf_level,
		"selected_role_id": role_id,
	}


static func is_setup_complete(config: Dictionary) -> bool:
	return (
		not str(config.get("game_seed", "")).is_empty()
		and typeof(config.get("turf_level")) == TYPE_INT
		and not str(config.get("selected_role_id", "")).is_empty()
		and not str(config.get("selected_contract_id", "")).is_empty()
	)


static func attack_payload(
	card_id: String,
	target_id: String,
	mode: String,
	modifiers: Array[String],
	engine_target_card_id: String
) -> Dictionary:
	return {
		"attacker_id": GameIds.PLAYER_HUMAN,
		"target_id": target_id,
		"card_id": card_id,
		"mode": mode,
		"modifiers": modifiers.duplicate(),
		"engine_target_card_id": engine_target_card_id,
	}


static func is_attack_complete(payload: Dictionary) -> bool:
	if (
		str(payload.get("card_id", "")).is_empty()
		or str(payload.get("target_id", "")).is_empty()
	):
		return false
	var card_id: String = payload["card_id"]
	var mode: String = str(payload.get("mode", ""))
	if card_id in [GameIds.CARD_BRUISER, GameIds.CARD_CLEANER]:
		if mode.is_empty():
			return false
	if card_id == GameIds.CARD_FEDERAL_RAID:
		if mode != AttackModes.DESTROY_DISTRICT:
			return false
	if (
		card_id == GameIds.CARD_SABOTEUR
		and str(payload.get("engine_target_card_id", "")).is_empty()
	):
		return false
	var modifiers: Array = payload.get("modifiers", [])
	return (
		modifiers.is_empty()
		or (
			modifiers == [GameIds.CARD_INSIDER]
			and card_id == GameIds.CARD_THUG
		)
	)


static func street_deal_payload(
	deal_id: String,
	option_id: String
) -> Dictionary:
	return {
		"player_id": GameIds.PLAYER_HUMAN,
		"deal_id": deal_id,
		"option_id": option_id,
	}


static func contact_payload(contact_id: String) -> Dictionary:
	return {
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": contact_id,
	}
