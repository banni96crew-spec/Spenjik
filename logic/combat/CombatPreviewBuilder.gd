class_name CombatPreviewBuilder


static func build(state: Dictionary, payload: Dictionary) -> Dictionary:
	var validation: Dictionary = AttackValidator.validate_attack(state, payload)
	if not validation["ok"]:
		return _failure(validation["error"])
	var normalized: Dictionary = validation["payload"]
	var defense: Dictionary = DefenseResolver.resolve_defense_preview(
		state, normalized
	)
	var effect: Dictionary = CombatEffectResolver.preview_effect(
		state, normalized, defense["blocked"]
	)
	var cards: Array[String] = CombatHandMutator.cards_for_attack(normalized)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"attacker_id": normalized["attacker_id"],
		"target_id": normalized["target_id"],
		"card_id": normalized["card_id"],
		"mode": normalized["mode"],
		"modifiers": normalized["modifiers"].duplicate(),
		"engine_target_card_id": normalized["engine_target_card_id"],
		"would_be_blocked": defense["blocked"],
		"blocker": defense["blocker"],
		"stealable_nal": effect["stolen_nal"],
		"protected_nal": effect["protected_nal"],
		"max_steal": effect["max_steal"],
		"vp_loss": effect["vp_loss"],
		"nal_gain": effect["nal_gain"],
		"would_set_skip_next_action": effect["skip_next_action_set"],
		"would_deplete_cartel": defense["side_effects"].has(
			"deplete_cartel"
		),
		"would_remove_judge": defense["side_effects"].has("remove_judge"),
		"would_destroy": (
			effect["destroyed_status_card_id"]
			if not effect["destroyed_status_card_id"].is_empty()
			else effect["destroyed_engine_card_id"]
		),
		"cards_that_would_be_consumed": cards,
	}


static func _failure(error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"attacker_id": "",
		"target_id": "",
		"card_id": "",
		"mode": "",
		"modifiers": [],
		"engine_target_card_id": "",
		"would_be_blocked": false,
		"blocker": "",
		"stealable_nal": 0,
		"protected_nal": 0,
		"max_steal": 0,
		"vp_loss": 0,
		"nal_gain": 0,
		"would_set_skip_next_action": false,
		"would_deplete_cartel": false,
		"would_remove_judge": false,
		"would_destroy": "",
		"cards_that_would_be_consumed": [],
	}
