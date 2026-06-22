class_name GameViewBuilder


static func build_view(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return _failure()
	return _success(state.duplicate(true))


static func get_available_roles() -> Dictionary:
	var roles: Array[Dictionary] = []
	for definition: RoleDefinition in RoleCatalog.get_all():
		roles.append({
			"id": definition.id,
			"title": definition.title,
			"starting_nal": definition.starting_nal,
			"effect_summary": definition.effect_summary,
			"limitation_summary": definition.limitation_summary,
		})
	return _success({"roles": roles})


static func get_available_turf_levels() -> Dictionary:
	var levels: Array[Dictionary] = []
	for definition: TurfLevelDefinition in TurfLevelCatalog.get_all():
		levels.append({
			"level": definition.level,
			"title": definition.title,
			"effect_summary": definition.effect_summary,
		})
	return _success({"turf_levels": levels})


static func get_contract_offers(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return _failure()
	return _success({
		"contract_offer_ids": state["contract_offer_ids"].duplicate(),
		"selected_contract_id": state["selected_contract_id"],
	})


static func get_market_view(state: Dictionary, player_id: String) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if state.is_empty():
		return _failure()
	if player.is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return _success({
		"market": state["market"].duplicate(true),
		"player_id": player_id,
		"nal": player["nal"],
		"purchased_this_round": player["purchased_this_round"].duplicate(),
		"ready_for_action": player["ready_for_action"],
	})


static func get_contract_state(state: Dictionary, player_id: String) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if state.is_empty():
		return _failure()
	if player.is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return _success({"contracts": player["contracts"].duplicate(true)})


static func get_street_deal_view(state: Dictionary, player_id: String) -> Dictionary:
	if state.is_empty():
		return _failure()
	if _find_player(state, player_id).is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return _success({
		"player_id": player_id,
		"street_deal": state["street_deals"].duplicate(true),
	})


static func get_debt_status(state: Dictionary, player_id: String) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if state.is_empty():
		return _failure()
	if player.is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return _success({"player_id": player_id, "debts": player["debts"].duplicate(true)})


static func get_contact_offer(state: Dictionary, player_id: String) -> Dictionary:
	if state.is_empty():
		return _failure()
	if _find_player(state, player_id).is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	var offer: Dictionary = state["contacts"]["pending_offer"]
	if not offer.is_empty() and offer["player_id"] != player_id:
		return _failure(ValidationErrors.CONTACT_OFFER_UNAVAILABLE)
	return _success({"pending_offer": offer.duplicate(true)})


static func get_contact_state(state: Dictionary, player_id: String) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if state.is_empty():
		return _failure()
	if player.is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return _success(player["contacts"].duplicate(true))


static func get_ai_state(state: Dictionary, player_id: String) -> Dictionary:
	if state.is_empty():
		return _failure()
	if not GameIds.AI_PLAYER_IDS.has(player_id):
		return _failure(ValidationErrors.INVALID_AI_STATE)
	var boss: Dictionary = AIBotController.get_ai_boss_state(state, player_id)
	return (
		_success(boss.duplicate(true))
		if not boss.is_empty()
		else _failure(ValidationErrors.INVALID_AI_STATE)
	)


static func get_ai_profiles_view(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return _failure()
	var profiles: Array[Dictionary] = []
	for boss: Dictionary in state["ai_bosses"]:
		profiles.append({
			"assigned_player_id": boss["assigned_player_id"],
			"profile_id": boss["profile_id"],
			"is_strong": boss["is_strong"],
		})
	return _success({"profiles": profiles})


static func get_turf_level_view(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return _failure()
	var level: int = state["turf_level"]
	var definition: TurfLevelDefinition = TurfLevelCatalog.get_by_level(level)
	return _success({
		"level": level,
		"title": definition.title if definition != null else "",
		"effect_summary": definition.effect_summary if definition != null else "",
	})


static func find_player(state: Dictionary, player_id: String) -> Dictionary:
	return _find_player(state, player_id).duplicate(true)


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _success(view: Dictionary) -> Dictionary:
	return {
		"ok": true, "error": ValidationErrors.OK,
		"view": view.duplicate(true),
	}


static func _failure(error: String = ValidationErrors.GAME_NOT_STARTED) -> Dictionary:
	return {"ok": false, "error": error, "view": {}}
