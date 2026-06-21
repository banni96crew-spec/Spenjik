class_name StreetDealValidator

const STREET_DEAL_ROUNDS: Array[int] = [4, 8, 12]


static func validate_generation(state: Dictionary) -> Dictionary:
	if state.get("current_phase") != PhaseIds.STREET_DEAL:
		return _failure(ValidationErrors.INVALID_PHASE)
	if not STREET_DEAL_ROUNDS.has(int(state.get("round", 0))):
		return _failure(ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE)
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(validation["error"])
	return _success()


static func validate_choice(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(validation["error"])
	if state["current_phase"] != PhaseIds.STREET_DEAL:
		return _failure(ValidationErrors.INVALID_PHASE)
	if not STREET_DEAL_ROUNDS.has(state["round"]):
		return _failure(ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE)
	var player_id: String = str(payload.get("player_id", ""))
	var deal_id: String = str(payload.get("deal_id", ""))
	var option_id: String = str(payload.get("option_id", ""))
	if player_id != GameIds.PLAYER_HUMAN:
		return _failure(ValidationErrors.INVALID_TARGET)
	if not StreetDealIds.ALL.has(deal_id):
		return _failure(ValidationErrors.INVALID_STREET_DEAL_ID)
	if not StreetDealOptionIds.ALL.has(option_id):
		return _failure(ValidationErrors.INVALID_STREET_DEAL_OPTION)
	var deals: Dictionary = state["street_deals"]
	if (
		not deals["offered_this_round"]
		or deals["current_deal_id"].is_empty()
		or deals["current_deal_id"] != deal_id
		or deals["choices_by_player"].has(player_id)
	):
		return _failure(ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE)
	var availability: String = str(
		deals["option_availability"].get(
			option_id, ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE
		)
	)
	if availability != ValidationErrors.OK:
		return _failure(availability)
	var player: Dictionary = _find_player(state, player_id)
	if (
		deal_id == StreetDealIds.LOAN_SHARK
		and DebtLogic.has_active_debt(player)
	):
		return _failure(ValidationErrors.ACTIVE_DEBT_EXISTS)
	var payment: int = StreetDealLogic.get_payment_amount(
		state, deal_id, option_id, player_id
	)
	if player["nal"] < payment:
		return _failure(ValidationErrors.NOT_ENOUGH_NAL)
	if _has_duplicate_modifier(state, deal_id, option_id, player_id):
		return _failure(ValidationErrors.INVALID_MODIFIER_STATE)
	if (
		deal_id == StreetDealIds.INSIDE_CONTACT
		and option_id == StreetDealOptionIds.OPTION_A
		and not state["contacts"]["pending_offer"].is_empty()
	):
		return _failure(ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE)
	return _success()


static func option_error(
	state: Dictionary,
	deal_id: String,
	option_id: String,
	player_id: String
) -> String:
	var player: Dictionary = _find_player(state, player_id)
	var payment: int = StreetDealLogic.get_payment_amount(
		state, deal_id, option_id, player_id
	)
	if player["nal"] < payment:
		return ValidationErrors.NOT_ENOUGH_NAL
	if _has_duplicate_modifier(state, deal_id, option_id, player_id):
		return ValidationErrors.INVALID_MODIFIER_STATE
	if (
		deal_id == StreetDealIds.INSIDE_CONTACT
		and option_id == StreetDealOptionIds.OPTION_A
		and not state["contacts"]["pending_offer"].is_empty()
	):
		return ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE
	return ValidationErrors.OK


static func _has_duplicate_modifier(
	state: Dictionary,
	deal_id: String,
	option_id: String,
	player_id: String
) -> bool:
	if deal_id != StreetDealIds.CHEAP_PROTECTION:
		return false
	var definition: StreetDealDefinition = StreetDealCatalog.get_by_id(deal_id)
	var effects: Array[Dictionary] = (
		definition.option_a_effects
		if option_id == StreetDealOptionIds.OPTION_A
		else definition.option_b_effects
	)
	var creates_modifier: bool = false
	for effect: Dictionary in effects:
		if effect["type"] == EffectTypes.ADD_TEMPORARY_MODIFIER:
			creates_modifier = true
	if not creates_modifier:
		return false
	var player: Dictionary = _find_player(state, player_id)
	for modifier: Dictionary in player["temporary_modifiers"]:
		if (
			modifier["source"] == deal_id
			and modifier["owner_player_id"] == player_id
			and modifier["id"].ends_with("_round_%d" % state["round"])
			and not modifier["consumed"]
		):
			return true
	return false


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _success() -> Dictionary:
	return {"ok": true, "error": ValidationErrors.OK}


static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}
