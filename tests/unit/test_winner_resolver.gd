extends GutTest


func test_highest_vp_wins_and_result_shape_validates() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("winner_vp")
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["vp"] = 4
	var result: Dictionary = WinnerResolver.resolve(state)
	assert_true(result["ok"])
	assert_eq(result["winner_id"], GameIds.PLAYER_AI_2)
	assert_false(result["game_result"]["tie_break_used"])
	assert_true(GameResultValidator.validate(result["game_result"])["ok"])


func test_normal_tie_breaks_follow_nal_status_value_and_count() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("winner_ties")
	for player: Dictionary in state["players"]:
		player["vp"] = 5
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 8
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["nal"] = 8
	TestPlayers.find(state, GameIds.PLAYER_AI_3)["nal"] = 7
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["status_buildings"]["stash"] = 2
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["status_buildings"]["workshop"] = 1
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["status_buildings"]["stash"] = 1
	var result: Dictionary = WinnerResolver.resolve(state)
	assert_eq(result["winner_id"], GameIds.PLAYER_AI_2)
	assert_eq(
		_tie_ids(result["game_result"]),
		[
			TieBreakIds.VICTORY_POINTS,
			TieBreakIds.NAL,
			TieBreakIds.STATUS_BUILDING_VP_VALUE,
		]
	)


func test_status_count_then_stable_order_break_remaining_ties() -> void:
	var count_state: Dictionary = TestGameStateFactory.base_state("winner_count")
	for player: Dictionary in count_state["players"]:
		player["vp"] = 3
		player["nal"] = 5
	TestPlayers.find(
		count_state, GameIds.PLAYER_AI_1
	)["status_buildings"]["workshop"] = 1
	TestPlayers.find(
		count_state, GameIds.PLAYER_AI_2
	)["status_buildings"]["stash"] = 2
	var count_result: Dictionary = WinnerResolver.resolve(count_state)
	assert_eq(count_result["winner_id"], GameIds.PLAYER_AI_2)
	assert_true(
		_tie_ids(count_result["game_result"]).has(
			TieBreakIds.STATUS_BUILDING_COUNT
		)
	)
	var stable_state: Dictionary = TestGameStateFactory.base_state("winner_stable")
	for player: Dictionary in stable_state["players"]:
		player["vp"] = 2
		player["nal"] = 4
	var stable_result: Dictionary = WinnerResolver.resolve(stable_state)
	assert_eq(stable_result["winner_id"], GameIds.PLAYER_HUMAN)
	assert_eq(
		_tie_ids(stable_result["game_result"])[-1],
		TieBreakIds.FIXED_PLAYER_ORDER
	)


func test_resolve_does_not_mutate_state_or_random() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("winner_no_mutate")
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["vp"] = 3
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = WinnerResolver.resolve(state)
	assert_true(result["ok"])
	assert_eq(state, before)
	assert_eq(state["random"], before["random"])
	assert_eq(TestPlayers.find(state, GameIds.PLAYER_AI_1)["vp"], 3)


func test_human_sole_vp_leader_wins_at_level_ten() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("winner_turf_human")
	state["turf_level"] = 10
	for player: Dictionary in state["players"]:
		player["turf_level"] = 10
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["vp"] = 9
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = WinnerResolver.resolve(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["winner_id"], GameIds.PLAYER_HUMAN)
	assert_false(result["game_result"]["turf_level_10_ai_win_applied"])
	assert_eq(state, before)


func test_level_ten_human_ai_vp_tie_favors_ai_by_nal_and_stable_order() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("winner_turf_ai")
	state["turf_level"] = 10
	for player: Dictionary in state["players"]:
		player["turf_level"] = 10
		player["vp"] = 8
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 20
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 5
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["nal"] = 10
	TestPlayers.find(state, GameIds.PLAYER_AI_3)["nal"] = 30
	var result: Dictionary = WinnerResolver.resolve(state)
	assert_eq(result["winner_id"], GameIds.PLAYER_AI_3)
	assert_true(result["game_result"]["turf_level_10_ai_win_applied"])
	var tied_nal: Dictionary = TestGameStateFactory.base_state("winner_turf_ai_nal")
	tied_nal["turf_level"] = 10
	for player: Dictionary in tied_nal["players"]:
		player["turf_level"] = 10
		player["vp"] = 4
		player["nal"] = 5
	var stable: Dictionary = WinnerResolver.resolve(tied_nal)
	assert_eq(stable["winner_id"], GameIds.PLAYER_AI_1)


func test_below_level_ten_uses_normal_tie_break() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("winner_turf_normal")
	for player: Dictionary in state["players"]:
		player["vp"] = 5
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 1
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 9
	var result: Dictionary = WinnerResolver.resolve(state)
	assert_eq(result["winner_id"], GameIds.PLAYER_AI_1)
	assert_false(result["game_result"]["turf_level_10_ai_win_applied"])


func _tie_ids(game_result: Dictionary) -> Array:
	var ids: Array = []
	for step: Dictionary in game_result["tie_break_steps"]:
		ids.append(step["tie_break_id"])
	return ids
