class_name PurchaseValidator


## Validates a card purchase without changing state or random.
static func validate_purchase(
	state: Dictionary,
	player_id: String,
	card_id: String
) -> Dictionary:
	var common: Dictionary = _validate_common(state, player_id)
	if not common["ok"]:
		return common
	if not GameIds.CARD_IDS.has(card_id):
		return _failure(ValidationErrors.INVALID_CARD_ID)
	if not state["market"]["all_available_card_ids"].has(card_id):
		return _failure(ValidationErrors.CARD_NOT_AVAILABLE_IN_MARKET)
	var player: Dictionary = common["player"]
	var price: Dictionary = PriceLogic.get_card_price(state, player_id, card_id)
	if not price["ok"]:
		return _failure(price["error"])
	if player["nal"] < price["final_price"]:
		return _failure(ValidationErrors.NOT_ENOUGH_NAL, price)
	if player["purchased_this_round"].has(card_id):
		return _failure(
			ValidationErrors.CARD_ALREADY_PURCHASED_THIS_ROUND, price
		)
	var requirement_error: String = _requirement_error(state, player, card_id)
	if not requirement_error.is_empty():
		return _failure(requirement_error, price)
	return {
		"ok": true, "error": ValidationErrors.OK,
		"player": player, "definition": CardCatalog.get_by_id(card_id),
		"price_result": price,
	}


## Validates the dedicated District Control rebuild action.
static func validate_rebuild(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var common: Dictionary = _validate_common(state, player_id)
	if not common["ok"]:
		return common
	var player: Dictionary = common["player"]
	var buildings: Dictionary = player["status_buildings"]
	var price: Dictionary = PriceLogic.get_rebuild_price(state, player_id)
	if not buildings["can_rebuild_district_for_8"]:
		return _failure(ValidationErrors.REQUIREMENT_NOT_MET, price)
	if buildings["district_control"] >= buildings["workshop"]:
		return _failure(ValidationErrors.REQUIREMENT_NOT_MET, price)
	if player["nal"] < price["final_rebuild_price"]:
		return _failure(ValidationErrors.NOT_ENOUGH_NAL, price)
	return {
		"ok": true, "error": ValidationErrors.OK,
		"player": player, "price_result": price,
	}


static func _validate_common(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(ValidationErrors.INVALID_STATE)
	if state["current_phase"] != PhaseIds.MARKET:
		return _failure(ValidationErrors.INVALID_PHASE)
	if not GameIds.PLAYER_IDS.has(player_id):
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return {"ok": true, "error": ValidationErrors.OK,
		"player": _find_player(state, player_id)}


static func _requirement_error(
	state: Dictionary,
	player: Dictionary,
	card_id: String
) -> String:
	var engine: Dictionary = player["engine"]
	var status: Dictionary = player["status_buildings"]
	var defense: Dictionary = player["defense"]
	match card_id:
		GameIds.CARD_ACCOUNTANT:
			if (
				player["vp"] < 1
				and not RoleLogic.can_bypass_purchase_requirement(
					state, player, card_id, ""
				)
			):
				return ValidationErrors.REQUIREMENT_NOT_MET
		GameIds.CARD_DISTRICT_CONTROL:
			if status["district_control"] >= status["workshop"]:
				return ValidationErrors.REQUIREMENT_NOT_MET
		GameIds.CARD_BROTHEL:
			if engine["brothel"]:
				return ValidationErrors.CARD_LIMIT_REACHED
		GameIds.CARD_COPS:
			if defense["cops_active"]:
				return ValidationErrors.CARD_LIMIT_REACHED
		GameIds.CARD_CARTEL:
			if defense["cartel_state"] == DefenseStates.ACTIVE:
				return ValidationErrors.CARD_LIMIT_REACHED
		GameIds.CARD_JUDGE:
			if defense["judge_state"] == DefenseStates.ACTIVE:
				return ValidationErrors.CARD_LIMIT_REACHED
	return ValidationErrors.OK


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state["players"]:
		if player["id"] == player_id:
			return player
	return {}


static func _failure(
	error: String,
	price_result: Dictionary = {}
) -> Dictionary:
	return {
		"ok": false, "error": error, "player": {},
		"definition": null, "price_result": price_result,
	}
