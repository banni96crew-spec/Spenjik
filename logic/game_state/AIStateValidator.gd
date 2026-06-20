class_name AIStateValidator

const AI_KEYS: Array[String] = ["profile_id", "is_strong", "assigned_player_id"]


static func validate(state: Dictionary) -> Dictionary:
	if typeof(state.get("ai_bosses")) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_AI_STATE, "ai_bosses", "wrong_type"
		)
	var bosses: Array = state["ai_bosses"]
	if bosses.size() != 3:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_AI_STATE, "ai_bosses", "count"
		)
	var profile_ids: Dictionary = {}
	var player_ids: Dictionary = {}
	var strong_player_id: String = ""
	for boss: Variant in bosses:
		if typeof(boss) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_STATE, "ai_bosses", "entry_type"
			)
		if not StateShapeValidator.exact_keys(boss, AI_KEYS, "ai_bosses[]")["ok"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_STATE, "ai_bosses", "entry_shape"
			)
		if not AIProfileIds.ALL.has(boss["profile_id"]):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_PROFILE_ID,
				"ai_bosses.profile_id", "invalid_id"
			)
		if (
			typeof(boss["is_strong"]) != TYPE_BOOL
			or not GameIds.AI_PLAYER_IDS.has(boss["assigned_player_id"])
			or profile_ids.has(boss["profile_id"])
			or player_ids.has(boss["assigned_player_id"])
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_STATE, "ai_bosses", "entry_contract"
			)
		profile_ids[boss["profile_id"]] = true
		player_ids[boss["assigned_player_id"]] = true
		if boss["is_strong"]:
			if not strong_player_id.is_empty():
				return StateShapeValidator.fail(
					ValidationErrors.INVALID_AI_STATE, "ai_bosses", "multiple_strong"
				)
			strong_player_id = boss["assigned_player_id"]
	if strong_player_id.is_empty():
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_AI_STATE, "ai_bosses", "missing_strong"
		)
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		if not player_ids.has(ai_id):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_STATE, "ai_bosses", "missing_assignment"
			)
		var player: Dictionary = _find_player(state, ai_id)
		if player.is_empty() or player["is_strong_ai"] != (ai_id == strong_player_id):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_STATE, "players.is_strong_ai", "mismatch"
			)
	return StateShapeValidator.ok()


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id", "") == player_id:
			return player
	return {}
