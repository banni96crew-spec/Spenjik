class_name AISetupLogic

## Owns deterministic strong-AI selection and unique AI profile assignment.
## Consumes random in this exact order: strong AI (1 step), profiles (3 steps).


static func setup(state: Dictionary) -> Dictionary:
	if not state.get("ai_bosses", []).is_empty():
		return _failure(state, ValidationErrors.INVALID_AI_STATE)
	var strong: Dictionary = SeededPicker.pick_one(
		state["random"],
		GameIds.AI_PLAYER_IDS.duplicate(),
		"ai_strong_selection"
	)
	if not strong["ok"]:
		return _failure(state, ValidationErrors.INVALID_AI_STATE)
	var strong_id: String = str(strong["selected"])
	var profiles: Dictionary = SeededPicker.pick_unique(
		strong["random"],
		AIProfileIds.ALL.duplicate(),
		GameIds.AI_PLAYER_IDS.size(),
		"ai_profile_assignment"
	)
	if not profiles["ok"] or profiles["selected_items"].size() != GameIds.AI_PLAYER_IDS.size():
		return _failure(state, ValidationErrors.INVALID_AI_STATE)
	var candidate: Dictionary = state.duplicate(true)
	candidate["random"] = profiles["random"]
	candidate["ai_bosses"] = _build_bosses(candidate, strong_id, profiles["selected_items"])
	var turf: Dictionary = TurfLevelLogic.apply_setup_modifiers(candidate)
	if not turf["ok"]:
		return _failure(state, turf["error"])
	candidate = turf["state"]
	var validation: Dictionary = AIStateValidator.validate(candidate)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"ai_bosses": _bosses_copy(candidate["ai_bosses"]),
		"strong_ai_player_id": strong_id,
		"random": candidate["random"].duplicate(true),
		"state": candidate,
	}


static func _build_bosses(
	candidate: Dictionary,
	strong_id: String,
	profile_ids: Array
) -> Array:
	var bosses: Array = []
	for index: int in GameIds.AI_PLAYER_IDS.size():
		var ai_id: String = GameIds.AI_PLAYER_IDS[index]
		var is_strong: bool = ai_id == strong_id
		_find_player(candidate, ai_id)["is_strong_ai"] = is_strong
		bosses.append(GameStateFactory.create_ai_boss_state(
			str(profile_ids[index]), is_strong, ai_id
		))
	return bosses


static func _bosses_copy(bosses: Array) -> Array:
	var copy: Array = []
	for boss: Dictionary in bosses:
		copy.append(boss.duplicate(true))
	return copy


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"ai_bosses": [],
		"strong_ai_player_id": "",
		"random": state.get("random", {}).duplicate(true),
		"state": state,
	}
