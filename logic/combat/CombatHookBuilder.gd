class_name CombatHookBuilder


## Builds the M9 resolved-attack event without calling future modules.
static func build_resolved_attack_event(
	state: Dictionary,
	payload: Dictionary,
	effect: Dictionary,
	blocked: bool
) -> Dictionary:
	var target: Dictionary = AttackValidator.find_player(
		state, payload["target_id"]
	)
	return {
		"attacker_id": payload["attacker_id"],
		"target_id": payload["target_id"],
		"target_is_ai": target["is_ai"],
		"card_id": payload["card_id"],
		"mode": payload["mode"],
		"engine_target_card_id": payload["engine_target_card_id"],
		"blocked": blocked,
		"success": not blocked,
		"valid_attack": true,
		"destroyed_status_card_id": effect["destroyed_status_card_id"],
		"destroyed_engine_card_id": effect["destroyed_engine_card_id"],
	}


## Builds the M11 contact event without calling future modules.
static func build_contact_event(
	state: Dictionary,
	payload: Dictionary,
	effect: Dictionary
) -> Dictionary:
	var target: Dictionary = AttackValidator.find_player(
		state, payload["target_id"]
	)
	return {
		"attacker_id": payload["attacker_id"],
		"target_id": payload["target_id"],
		"target_is_ai": target["is_ai"],
		"target_is_strong_ai": target["is_strong_ai"],
		"card_id": payload["card_id"],
		"mode": payload["mode"],
		"blocked": false,
		"success": true,
		"destroyed_status_card_id": effect["destroyed_status_card_id"],
	}
