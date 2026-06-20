class_name GameResultValidator

const RESULT_KEYS: Array[String] = [
	"winner_id", "final_scores", "tie_break_used", "tie_break_steps",
	"turf_level_10_ai_win_applied",
]
const SCORE_KEYS: Array[String] = [
	"player_id", "vp", "nal", "status_building_vp_value",
	"status_building_count",
]
const TIE_KEYS: Array[String] = [
	"tie_break_id", "candidates_before", "candidates_after", "explanation",
]


static func validate(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, RESULT_KEYS, "game_result"
	)
	if not shape["ok"]:
		return shape
	if (
		not GameIds.PLAYER_IDS.has(value["winner_id"])
		or typeof(value["final_scores"]) != TYPE_ARRAY
		or value["final_scores"].size() != 4
		or typeof(value["tie_break_used"]) != TYPE_BOOL
		or typeof(value["tie_break_steps"]) != TYPE_ARRAY
		or typeof(value["turf_level_10_ai_win_applied"]) != TYPE_BOOL
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "game_result", "field_contract"
		)
	var score_players: Dictionary = {}
	for score: Variant in value["final_scores"]:
		if typeof(score) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "game_result.final_scores", "entry_type"
			)
		if not StateShapeValidator.exact_keys(score, SCORE_KEYS, "final_score")["ok"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "game_result.final_scores", "entry_shape"
			)
		if (
			not GameIds.PLAYER_IDS.has(score["player_id"])
			or score_players.has(score["player_id"])
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "game_result.final_scores", "player_id"
			)
		for key: String in SCORE_KEYS.slice(1):
			if typeof(score[key]) != TYPE_INT or score[key] < 0:
				return StateShapeValidator.fail(
					ValidationErrors.INVALID_STATE, "final_score.%s" % key, "range"
				)
		score_players[score["player_id"]] = true
	for step: Variant in value["tie_break_steps"]:
		if typeof(step) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "game_result.tie_break_steps", "entry_type"
			)
		if not StateShapeValidator.exact_keys(step, TIE_KEYS, "tie_break_step")["ok"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "game_result.tie_break_steps", "entry_shape"
			)
		if (
			not TieBreakIds.ALL.has(step["tie_break_id"])
			or typeof(step["candidates_before"]) != TYPE_ARRAY
			or typeof(step["candidates_after"]) != TYPE_ARRAY
			or typeof(step["explanation"]) != TYPE_STRING
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "game_result.tie_break_steps", "contract"
			)
		for key: String in ["candidates_before", "candidates_after"]:
			var candidates: Dictionary = StateShapeValidator.unique_strings(
				step[key], GameIds.PLAYER_IDS, "tie_break_step.%s" % key
			)
			if not candidates["ok"]:
				return candidates
	return StateShapeValidator.ok()
