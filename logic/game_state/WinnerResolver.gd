class_name WinnerResolver

const STATUS_VALUES := {
	GameIds.CARD_STASH: 1,
	GameIds.CARD_WORKSHOP: 2,
	GameIds.CARD_DISTRICT_CONTROL: 3,
}


## Resolves the normal Turf Level 0-9 winner without mutating the input state.
static func resolve(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if state["turf_level"] >= 10:
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	var scores: Array[Dictionary] = _build_scores(state["players"])
	var candidates: Array = GameIds.PLAYER_IDS.duplicate()
	var steps: Array = []
	candidates = _filter_max(
		candidates, scores, "vp", TieBreakIds.VICTORY_POINTS, steps
	)
	var tie_break_used: bool = candidates.size() > 1
	if candidates.size() > 1:
		candidates = _filter_max(
			candidates, scores, "nal", TieBreakIds.NAL, steps
		)
	if candidates.size() > 1:
		candidates = _filter_max(
			candidates,
			scores,
			"status_building_vp_value",
			TieBreakIds.STATUS_BUILDING_VP_VALUE,
			steps
		)
	if candidates.size() > 1:
		candidates = _filter_max(
			candidates,
			scores,
			"status_building_count",
			TieBreakIds.STATUS_BUILDING_COUNT,
			steps
		)
	if candidates.size() > 1:
		var before: Array = candidates.duplicate()
		candidates = [_first_in_stable_order(candidates)]
		steps.append(_step(
			TieBreakIds.FIXED_PLAYER_ORDER, before, candidates
		))
	var winner_id: String = candidates[0]
	var game_result: Dictionary = {
		"winner_id": winner_id,
		"final_scores": scores,
		"tie_break_used": tie_break_used,
		"tie_break_steps": steps,
		"turf_level_10_ai_win_applied": false,
	}
	var result_validation: Dictionary = GameResultValidator.validate(game_result)
	if not result_validation["ok"]:
		return _failure(state, result_validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": state,
		"log_entries": [],
		"winner_id": winner_id,
		"game_result": game_result,
	}


static func _build_scores(players: Array) -> Array[Dictionary]:
	var scores: Array[Dictionary] = []
	for player_id: String in GameIds.PLAYER_IDS:
		var player: Dictionary = _find_player(players, player_id)
		var status: Dictionary = player["status_buildings"]
		var status_value: int = (
			status[GameIds.CARD_STASH] * STATUS_VALUES[GameIds.CARD_STASH]
			+ status[GameIds.CARD_WORKSHOP] * STATUS_VALUES[GameIds.CARD_WORKSHOP]
			+ status[GameIds.CARD_DISTRICT_CONTROL]
			* STATUS_VALUES[GameIds.CARD_DISTRICT_CONTROL]
		)
		var status_count: int = (
			status[GameIds.CARD_STASH]
			+ status[GameIds.CARD_WORKSHOP]
			+ status[GameIds.CARD_DISTRICT_CONTROL]
		)
		scores.append({
			"player_id": player_id,
			"vp": player["vp"],
			"nal": player["nal"],
			"status_building_vp_value": status_value,
			"status_building_count": status_count,
		})
	return scores


static func _filter_max(
	candidates: Array,
	scores: Array,
	field: String,
	tie_break_id: String,
	steps: Array
) -> Array:
	if candidates.is_empty():
		return []
	var maximum: int = -1
	var values: Dictionary = {}
	for score: Dictionary in scores:
		var player_id: String = score["player_id"]
		if not candidates.has(player_id):
			continue
		var value: int = int(score[field])
		values[player_id] = value
		if value > maximum:
			maximum = value
	var filtered: Array = []
	for player_id: String in candidates:
		if values[player_id] == maximum:
			filtered.append(player_id)
	var step: Dictionary = _step(tie_break_id, candidates, filtered)
	steps.push_back(step)
	return filtered


static func _step(
	tie_break_id: String,
	before: Array,
	after: Array
) -> Dictionary:
	return {
		"tie_break_id": tie_break_id,
		"candidates_before": before.duplicate(),
		"candidates_after": after.duplicate(),
		"explanation": tie_break_id,
	}


static func _find_player(players: Array, player_id: String) -> Dictionary:
	for player: Dictionary in players:
		if player["id"] == player_id:
			return player
	return {}


static func _first_in_stable_order(candidates: Array) -> String:
	for player_id: String in GameIds.PLAYER_IDS:
		if candidates.has(player_id):
			return player_id
	return ""


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"state": state,
		"log_entries": [],
		"winner_id": "",
		"game_result": {},
	}
