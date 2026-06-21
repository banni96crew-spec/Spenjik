class_name StreetDealLogic


static func create_empty_state() -> Dictionary:
	return GameStateFactory.create_street_deal_state()


static func generate_street_deal(state: Dictionary) -> Dictionary:
	var validation: Dictionary = StreetDealValidator.validate_generation(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	var candidate: Dictionary = reset_for_new_street_deal_phase(state)
	var eligible_ids: Array[String] = get_eligible_deal_ids(
		candidate, GameIds.PLAYER_HUMAN
	)
	var weighted: Array[Dictionary] = []
	for deal_id: String in eligible_ids:
		var definition: StreetDealDefinition = StreetDealCatalog.get_by_id(deal_id)
		weighted.append({"id": deal_id, "weight": definition.weight})
	if weighted.is_empty():
		return _failure(state, ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE)
	var picked: Dictionary = SeededPicker.pick_weighted(
		candidate["random"],
		weighted,
		"street_deal_round_%s" % candidate["round"]
	)
	if not picked["ok"]:
		return _failure(state, ValidationErrors.INVALID_RANDOM_STATE)
	var deal_id: String = str(picked["selected"]["id"])
	candidate["random"] = picked["random"]
	candidate["street_deals"]["offered_this_round"] = true
	candidate["street_deals"]["current_deal_id"] = deal_id
	var available: Array[String] = []
	for option_id: String in StreetDealOptionIds.ALL:
		var error: String = StreetDealValidator.option_error(
			candidate, deal_id, option_id, GameIds.PLAYER_HUMAN
		)
		candidate["street_deals"]["option_availability"][option_id] = error
		if error == ValidationErrors.OK:
			available.append(option_id)
	StreetDealLogBuilder.append_offered(candidate, deal_id, available)
	return _validated_generation(state, candidate, deal_id, picked["steps_used"])


static func get_eligible_deal_ids(
	state: Dictionary,
	player_id: String
) -> Array[String]:
	if player_id != GameIds.PLAYER_HUMAN:
		return []
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return []
	var used: Array = state.get("street_deals", {}).get("used_deal_ids", [])
	var eligible: Array[String] = []
	for definition: StreetDealDefinition in StreetDealCatalog.get_all():
		if definition.min_round > int(state.get("round", 0)):
			continue
		if used.count(definition.id) >= definition.max_uses_per_run:
			continue
		if (
			definition.id == StreetDealIds.LOAN_SHARK
			and DebtLogic.has_active_debt(player)
		):
			continue
		eligible.append(definition.id)
	return eligible


static func validate_street_deal_choice(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	return StreetDealValidator.validate_choice(state, payload)


static func select_street_deal(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var validation: Dictionary = validate_street_deal_choice(state, payload)
	if not validation["ok"]:
		return _choice_failure(state, payload, validation["error"])
	var player_id: String = payload["player_id"]
	var deal_id: String = payload["deal_id"]
	var option_id: String = payload["option_id"]
	var effect_result: Dictionary = apply_option_effects(
		state, player_id, deal_id, option_id
	)
	if not effect_result["ok"]:
		return _choice_failure(state, payload, effect_result["error"])
	var candidate: Dictionary = effect_result["state"]
	candidate["street_deals"]["choices_by_player"][player_id] = option_id
	candidate["street_deals"]["used_deal_ids"].append(deal_id)
	candidate["street_deals"]["current_deal_id"] = ""
	candidate["street_deals"]["option_availability"] = {}
	var contract_result: Dictionary = ContractLogic.on_state_changed(
		candidate,
		{
			"source": "street_deal",
			"source_event_type": LogEventTypes.STREET_DEAL_RESOLVED,
			"player_id": player_id,
		}
	)
	if not contract_result["ok"]:
		return _choice_failure(state, payload, contract_result["error"])
	candidate = contract_result["state"]
	StreetDealLogBuilder.append_resolved(
		candidate, player_id, deal_id, option_id
	)
	for debt: Dictionary in effect_result["created_debts"]:
		StreetDealLogBuilder.append_debt_created(candidate, player_id, debt)
	if not effect_result["contact_offer"].is_empty():
		StreetDealLogBuilder.append_contact_handoff(
			candidate, player_id, effect_result["contact_offer"]
		)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _choice_failure(state, payload, final_validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"deal_id": deal_id,
		"option_id": option_id,
		"effects_applied": effect_result["effects_applied"],
		"selected_ai_id": effect_result["selected_ai_id"],
		"random_steps_used": effect_result["random_steps_used"],
		"contact_offer": effect_result["contact_offer"],
		"contract_results": [contract_result],
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(
			state["combat_log"].size()
		),
	}


static func get_payment_amount(
	state: Dictionary,
	deal_id: String,
	option_id: String,
	player_id: String
) -> int:
	if player_id != GameIds.PLAYER_HUMAN:
		return 0
	var payment: int = 0
	if deal_id == StreetDealIds.DIRTY_TIP and option_id == StreetDealOptionIds.OPTION_A:
		payment = 3
	elif (
		deal_id == StreetDealIds.BLACK_MARKET_CACHE
		and option_id == StreetDealOptionIds.OPTION_B
	):
		payment = 6
	elif (
		deal_id == StreetDealIds.RISKY_CONTRACT
		and option_id == StreetDealOptionIds.OPTION_A
	):
		payment = 3
	if payment > 0 and int(state.get("turf_level", 0)) >= 8:
		payment += 1
	return payment


static func apply_option_effects(
	state: Dictionary,
	player_id: String,
	deal_id: String,
	option_id: String
) -> Dictionary:
	return StreetDealEffectResolver.apply(
		state, player_id, deal_id, option_id
	)


static func reset_for_new_street_deal_phase(
	state: Dictionary
) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	candidate["street_deals"]["offered_this_round"] = false
	candidate["street_deals"]["current_deal_id"] = ""
	candidate["street_deals"]["choices_by_player"] = {}
	candidate["street_deals"]["option_availability"] = {}
	return candidate


static func _validated_generation(
	original: Dictionary,
	candidate: Dictionary,
	deal_id: String,
	steps_used: int
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failure(original, validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"current_deal_id": deal_id,
		"steps_used": steps_used,
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(
			original["combat_log"].size()
		),
	}


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _choice_failure(
	state: Dictionary,
	payload: Dictionary,
	error: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": str(payload.get("player_id", "")),
		"deal_id": str(payload.get("deal_id", "")),
		"option_id": str(payload.get("option_id", "")),
		"effects_applied": [],
		"selected_ai_id": "",
		"random_steps_used": 0,
		"contact_offer": {},
		"state": state,
		"log_entries": [],
	}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"current_deal_id": "",
		"steps_used": 0,
		"state": state,
		"log_entries": [],
	}
