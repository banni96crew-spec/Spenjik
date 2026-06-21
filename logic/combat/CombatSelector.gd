class_name CombatSelector


static func get_valid_targets(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var normalized: Dictionary = AttackValidator.normalize_payload(payload)
	var targets: Array[String] = []
	for player_id: String in GameIds.PLAYER_IDS:
		if player_id == normalized["attacker_id"]:
			continue
		var candidate_payload: Dictionary = normalized.duplicate(true)
		candidate_payload["target_id"] = player_id
		if (
			candidate_payload["card_id"] == GameIds.CARD_SABOTEUR
			and candidate_payload["engine_target_card_id"].is_empty()
		):
			var target: Dictionary = AttackValidator.find_player(
				state, player_id
			)
			var engines: Array[String] = (
				AttackValidator.get_owned_engine_targets(target)
			)
			if not engines.is_empty():
				candidate_payload["engine_target_card_id"] = engines[0]
		var validation: Dictionary = AttackValidator.validate_attack(
			state, candidate_payload
		)
		if validation["ok"]:
			targets.append(player_id)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"target_ids": targets,
	}


static func get_valid_engine_targets(
	state: Dictionary,
	attacker_id: String,
	target_id: String
) -> Dictionary:
	if state.get("current_phase") != PhaseIds.ACTION:
		return _failure(ValidationErrors.INVALID_PHASE)
	var attacker: Dictionary = AttackValidator.find_player(state, attacker_id)
	var target: Dictionary = AttackValidator.find_player(state, target_id)
	if (
		attacker.is_empty()
		or target.is_empty()
		or attacker_id == target_id
		or state.get("active_action_player_id") != attacker_id
	):
		return _failure(ValidationErrors.INVALID_TARGET)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"engine_target_card_ids":
			AttackValidator.get_owned_engine_targets(target),
	}


static func _failure(error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"engine_target_card_ids": [],
	}
