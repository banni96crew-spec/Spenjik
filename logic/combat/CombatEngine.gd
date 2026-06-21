class_name CombatEngine


## Validates an attack without mutating state or payload.
static func validate_attack(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return AttackValidator.validate_attack(state, payload)


## Resolves one attack on a deep candidate state.
static func resolve_attack(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var validation: Dictionary = validate_attack(state, payload)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	var normalized: Dictionary = validation["payload"]
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	var attacker: Dictionary = AttackValidator.find_player(
		candidate, normalized["attacker_id"]
	)
	var target: Dictionary = AttackValidator.find_player(
		candidate, normalized["target_id"]
	)
	var defense: Dictionary = DefenseResolver.resolve_defense_preview(
		candidate, normalized
	)
	var effect: Dictionary = CombatEffectResolver.preview_effect(
		candidate, normalized, true
	)
	if defense["blocked"]:
		DefenseResolver.apply_block_side_effects(
			candidate, normalized, defense
		)
	else:
		effect = CombatEffectResolver.resolve_effect(candidate, normalized)
	var cards: Array[String] = CombatHandMutator.cards_for_attack(normalized)
	CombatHandMutator.consume_cards(attacker, cards)
	target["last_attacked_by"] = attacker["id"]
	var result: Dictionary = _result(
		candidate, normalized, defense, effect, cards
	)
	result["resolved_attack_event"] = (
		CombatHookBuilder.build_resolved_attack_event(
			candidate, normalized, effect, defense["blocked"]
		)
	)
	var contract_result: Dictionary = ContractLogic.on_attack_resolved(
		candidate, result["resolved_attack_event"]
	)
	if not contract_result["ok"]:
		return _failure(state, contract_result["error"])
	candidate = contract_result["state"]
	result["contract_results"] = [contract_result]
	result["contract_hook_events"] = [
		result["resolved_attack_event"].duplicate(true)
	]
	if not defense["blocked"]:
		result["contact_hook_events"] = [
			CombatHookBuilder.build_contact_event(
				candidate, normalized, effect
			)
		]
		var contact_result: Dictionary = ContactLogic.on_attack_resolved(
			candidate, result["resolved_attack_event"]
		)
		if not contact_result["ok"]:
			return _failure(state, contact_result["error"])
		candidate = contact_result["state"]
		result["contact_results"] = (
			[contact_result]
			if contact_result["contact_offer_ids"].size() > 0
			else []
		)
	result["state"] = candidate
	candidate["combat_log"].append(
		CombatLogBuilder.build_attack_log(result)
	)
	result["log_entries"] = candidate["combat_log"].slice(log_start)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _failure(state, final_validation["error"])
	return result


## Discards exactly one owned War card during the active player's turn.
static func discard_war_card(
	state: Dictionary,
	player_id: String,
	card_id: String
) -> Dictionary:
	var validation: Dictionary = _validate_discard(
		state, player_id, card_id
	)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = AttackValidator.find_player(
		candidate, player_id
	)
	CombatHandMutator.consume_one(player, card_id)
	var log_entry: Dictionary = CombatLogBuilder.build_discard_log(
		candidate, player_id, card_id
	)
	candidate["combat_log"].append(log_entry)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _failure(state, final_validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"card_id": card_id,
		"cards_consumed": [card_id],
		"contract_results": [],
		"contact_results": [],
		"contract_hook_events": [],
		"contact_hook_events": [],
		"resolved_attack_event": {},
		"log_entries": [log_entry],
		"state": candidate,
	}


## Returns an immutable combat preview.
static func get_combat_preview(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return CombatPreviewBuilder.build(state, payload)


## Returns opponents that satisfy the selected card and mode requirements.
static func get_valid_targets(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return CombatSelector.get_valid_targets(state, payload)


## Returns owned Engine cards available to Saboteur.
static func get_valid_engine_targets(
	state: Dictionary,
	attacker_id: String,
	target_id: String
) -> Dictionary:
	return CombatSelector.get_valid_engine_targets(
		state, attacker_id, target_id
	)


static func _validate_discard(
	state: Dictionary,
	player_id: String,
	card_id: String
) -> Dictionary:
	if state.get("current_phase") != PhaseIds.ACTION:
		return {"ok": false, "error": ValidationErrors.INVALID_PHASE}
	var player: Dictionary = AttackValidator.find_player(state, player_id)
	if (
		player.is_empty()
		or state.get("active_action_player_id") != player_id
	):
		return {"ok": false, "error": ValidationErrors.INVALID_TARGET}
	var definition: CardDefinition = CardCatalog.get_by_id(card_id)
	if (
		definition == null
		or definition.type != CardTypes.WAR
		or not player["hand"].has(card_id)
	):
		return {
			"ok": false,
			"error": ValidationErrors.INVALID_ACTION_CARD,
		}
	return {"ok": true, "error": ValidationErrors.OK}


static func _result(
	state: Dictionary,
	payload: Dictionary,
	defense: Dictionary,
	effect: Dictionary,
	cards: Array[String]
) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"attacker_id": payload["attacker_id"],
		"target_id": payload["target_id"],
		"card_id": payload["card_id"],
		"mode": payload["mode"],
		"modifiers": payload["modifiers"].duplicate(),
		"engine_target_card_id": payload["engine_target_card_id"],
		"blocked": defense["blocked"],
		"blocker": defense["blocker"],
		"success": not defense["blocked"],
		"effect_result": effect,
		"cards_consumed": cards,
		"contract_results": [],
		"contact_results": [],
		"contract_hook_events": [],
		"contact_hook_events": [],
		"resolved_attack_event": {},
		"log_entries": [],
		"state": state,
	}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"attacker_id": "",
		"target_id": "",
		"card_id": "",
		"mode": "",
		"modifiers": [],
		"engine_target_card_id": "",
		"blocked": false,
		"blocker": "",
		"success": false,
		"effect_result": {},
		"cards_consumed": [],
		"contract_results": [],
		"contact_results": [],
		"contract_hook_events": [],
		"contact_hook_events": [],
		"resolved_attack_event": {},
		"log_entries": [],
		"state": state,
	}
