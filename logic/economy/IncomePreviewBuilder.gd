class_name IncomePreviewBuilder


## Returns deterministic income components without rolling active random.
static func get_income_preview(state: Dictionary, player_id: String) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	var laundry_income: int = int(player["engine"]["laundries"]) * 2
	var informant_income: int = int(player["engine"]["informers"])
	var brothel_bonus: int = 0
	if player["engine"]["brothel"]:
		brothel_bonus = (
			6
			if ContactLogic.has_contact(player, ContactIds.BLACK_CASH)
			else 5
		)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"dice_min": 2,
		"dice_max": 12,
		"laundry_income": laundry_income,
		"informant_income": informant_income,
		"brothel_bonus_on_doubles": brothel_bonus,
		"total_min": 2 + laundry_income + informant_income,
		"total_max": 12 + laundry_income + informant_income + brothel_bonus,
	}


## Resolves upkeep only on an isolated candidate and returns its preview data.
static func get_cops_upkeep_preview(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var result: Dictionary = IncomeLogic.resolve_cops_upkeep(
		state.duplicate(true), player_id
	)
	if not result["ok"]:
		return _failure(result["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"cops_upkeep": result["cops_upkeep_result"].duplicate(true),
	}


static func get_protected_nal_preview(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _failure(ValidationErrors.INVALID_PLAYER_ID)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"protected_nal": PriceLogic.get_protected_nal(
			int(player["engine"]["accountants"])
		),
	}


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}
