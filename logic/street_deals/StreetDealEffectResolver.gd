class_name StreetDealEffectResolver


static func apply(
	state: Dictionary,
	player_id: String,
	deal_id: String,
	option_id: String
) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	var definition: StreetDealDefinition = StreetDealCatalog.get_by_id(deal_id)
	var effects: Array[Dictionary] = (
		definition.option_a_effects
		if option_id == StreetDealOptionIds.OPTION_A
		else definition.option_b_effects
	)
	var applied: Array[Dictionary] = []
	var selected_ai_id: String = ""
	var random_steps_used: int = 0
	var created_debts: Array[Dictionary] = []
	var contact_offer: Dictionary = {}
	for effect: Dictionary in effects:
		var resolved: Dictionary = effect.duplicate(true)
		var target_id: String = player_id
		match effect["target"]:
			"random_ai":
				var picked: Dictionary = SeededPicker.pick_one(
					candidate["random"],
					GameIds.AI_PLAYER_IDS,
					"dirty_tip_ai_target_round_%s" % candidate["round"]
				)
				if not picked["ok"]:
					return _failure(state, ValidationErrors.INVALID_RANDOM_STATE)
				candidate["random"] = picked["random"]
				target_id = str(picked["selected"])
				selected_ai_id = target_id
				random_steps_used += int(picked["steps_used"])
			"richest_ai":
				target_id = _richest_ai_id(candidate)
				selected_ai_id = target_id
		var effect_result: Dictionary = _apply_effect(
			candidate, target_id, deal_id, option_id, effect
		)
		if not effect_result["ok"]:
			return _failure(state, effect_result["error"])
		candidate = effect_result["state"]
		resolved["target_player_id"] = target_id
		resolved["applied_amount"] = effect_result["applied_amount"]
		applied.append(resolved)
		if not effect_result["debt"].is_empty():
			created_debts.append(effect_result["debt"])
		if not effect_result["contact_offer"].is_empty():
			contact_offer = effect_result["contact_offer"]
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": candidate,
		"effects_applied": applied,
		"selected_ai_id": selected_ai_id,
		"random_steps_used": random_steps_used,
		"created_debts": created_debts,
		"contact_offer": contact_offer,
	}


static func _apply_effect(
	state: Dictionary,
	target_id: String,
	deal_id: String,
	option_id: String,
	effect: Dictionary
) -> Dictionary:
	var player: Dictionary = _find_player(state, target_id)
	var applied_amount: int = int(effect["amount"])
	var debt: Dictionary = {}
	var contact_offer: Dictionary = {}
	match effect["type"]:
		EffectTypes.ADD_NAL:
			player["nal"] += applied_amount
		EffectTypes.LOSE_NAL:
			applied_amount = StreetDealLogic.get_payment_amount(
				state, deal_id, option_id, target_id
			)
			player["nal"] -= applied_amount
		EffectTypes.ADD_VP:
			player["vp"] += applied_amount
		EffectTypes.ADD_CARD_TO_HAND:
			player["hand"].append(effect["card_id"])
		EffectTypes.ADD_TEMPORARY_MODIFIER:
			var modifier: Dictionary = GameStateFactory.create_temporary_modifier({
				"id": "%s_%s_round_%d" % [
					deal_id, target_id, state["round"]
				],
				"type": effect["modifier_type"],
				"source": deal_id,
				"owner_player_id": target_id,
				"affected_card_id": "",
				"affected_card_type": effect["card_type"],
				"delta": effect["delta"],
				"multiplier": 1.0,
				"min_value": effect["minimum"],
				"expires_at": "next_purchase",
				"consumed": false,
			})
			player["temporary_modifiers"].append(modifier)
		EffectTypes.CREATE_DEBT:
			var debt_id: String = "%s_round_%d_%s" % [
				deal_id, state["round"], option_id
			]
			debt = DebtLogic.create_debt(
				debt_id,
				int(effect["debt_amount_due"]),
				state["round"] + int(effect["deadline_round_delta"]),
				effect["penalty"],
				state["round"]
			)
			player["debts"].append(debt)
		EffectTypes.UNLOCK_CONTACT:
			contact_offer = GameStateFactory.create_contact_offer_state(
				target_id, StreetDealIds.INSIDE_CONTACT, [], state["round"]
			)
			state["contacts"]["pending_offer"] = contact_offer
		_:
			return _failure(state, ValidationErrors.REQUIREMENT_NOT_MET)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": state,
		"applied_amount": applied_amount,
		"debt": debt,
		"contact_offer": contact_offer,
	}


static func _richest_ai_id(state: Dictionary) -> String:
	var selected_id: String = GameIds.PLAYER_AI_1
	var highest_nal: int = -1
	for player_id: String in GameIds.AI_PLAYER_IDS:
		var player: Dictionary = _find_player(state, player_id)
		if player["nal"] > highest_nal:
			highest_nal = player["nal"]
			selected_id = player_id
	return selected_id


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state["players"]:
		if player["id"] == player_id:
			return player
	return {}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"state": state,
		"effects_applied": [],
		"selected_ai_id": "",
		"random_steps_used": 0,
		"created_debts": [],
		"contact_offer": {},
	}
