extends GutTest


func test_completed_setup_transitions_to_income() -> void:
	var state: Dictionary = TestGameStateFactory.completed_setup_state()
	var random_before: Dictionary = state["random"].duplicate(true)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.INCOME)
	assert_eq(result["state"]["round"], 1)
	assert_eq(result["state"]["random"], random_before)
	assert_eq(
		result["state"]["combat_log"][-1]["event_type"],
		LogEventTypes.PHASE_CHANGED
	)
	assert_true(GameStateValidator.validate_game_state(result["state"])["ok"])


func test_income_enters_market_atomically_with_exact_random_steps() -> void:
	for turf_level: int in [0, 4]:
		var state: Dictionary = TestGameStateFactory.base_state(
			"phase_income_%d" % turf_level
		)
		state["turf_level"] = turf_level
		for player: Dictionary in state["players"]:
			player["turf_level"] = turf_level
		var before: Dictionary = state.duplicate(true)
		var result: Dictionary = GamePhaseController.advance_phase(state)
		var market_steps: int = 3 if turf_level >= 4 else 4
		assert_true(result["ok"], str(result))
		assert_eq(result["state"]["current_phase"], PhaseIds.MARKET)
		assert_eq(result["state"]["random"]["step"], 8 + market_steps)
		assert_eq(
			result["state"]["combat_log"][-2]["event_type"],
			LogEventTypes.MARKET_STARTED
		)
		assert_eq(
			result["state"]["combat_log"][-1]["event_type"],
			LogEventTypes.PHASE_CHANGED
		)
		assert_eq(state, before)


func test_unresolved_street_deal_is_deferred() -> void:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		"phase_deal_deferred"
	)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.PHASE_NOT_READY)
	assert_eq(state, before)


func test_income_with_debt_enters_market_atomically() -> void:
	var state: Dictionary = TestGameStateFactory.base_state(
		"phase_income_debt"
	)
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["debts"] = [
		GameStateFactory.create_debt_state(
			"loan_shark_round_1_option_a", 100, 3,
			{"lose_all_nal": true, "vp_delta": -1}, 1
		),
	]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.MARKET)
	assert_eq(result["state"]["random"]["step"], 12)
	assert_eq(state, before)


func test_market_waits_until_all_players_are_ready() -> void:
	var state: Dictionary = TestGameStateFactory.market_state()
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.PHASE_NOT_READY)
	assert_eq(state, before)


func test_ready_market_enters_action_with_fixed_order() -> void:
	var state: Dictionary = TestGameStateFactory.ready_market_state()
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.ACTION)
	assert_eq(result["state"]["action_order"], GameIds.PLAYER_IDS)
	assert_eq(
		result["state"]["active_action_player_id"],
		GameIds.PLAYER_HUMAN
	)


func test_action_player_advances_and_consumes_skip() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("phase_skip")
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["action_done"] = true
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["skip_next_action"] = true
	var hand_before: Array = TestPlayers.find(
		state, GameIds.PLAYER_AI_1
	)["hand"].duplicate()
	var random_before: Dictionary = state["random"].duplicate(true)
	var result: Dictionary = GamePhaseController.advance_action_player(state)
	assert_true(result["ok"], str(result))
	var skipped: Dictionary = TestPlayers.find(
		result["state"], GameIds.PLAYER_AI_1
	)
	assert_true(skipped["action_done"])
	assert_false(skipped["skip_next_action"])
	assert_eq(skipped["hand"], hand_before)
	assert_eq(result["state"]["random"], random_before)
	assert_eq(
		result["state"]["active_action_player_id"],
		GameIds.PLAYER_AI_2
	)


func test_last_action_player_clears_active_player() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("phase_last_player")
	for player_id: String in [
		GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_1, GameIds.PLAYER_AI_2,
	]:
		TestPlayers.find(state, player_id)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_3
	TestPlayers.find(state, GameIds.PLAYER_AI_3)["action_done"] = true
	var result: Dictionary = GamePhaseController.advance_action_player(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["active_action_player_id"], "")


func test_incomplete_action_does_not_transition() -> void:
	var state: Dictionary = TestGameStateFactory.action_state()
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.PHASE_NOT_READY)
	assert_eq(state, before)


func test_completed_normal_action_starts_next_round() -> void:
	var state: Dictionary = TestGameStateFactory.completed_action_state(
		3, "phase_next_round"
	)
	state["players"][0]["purchased_this_round"] = [GameIds.CARD_STASH]
	state["players"][0]["contacts"]["unlocked"] = [ContactIds.BLACK_CASH]
	state["players"][0]["contacts"]["used_this_round"] = [ContactIds.BLACK_CASH]
	for key: String in state["players"][0]["role_flags"]:
		state["players"][0]["role_flags"][key] = true
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.INCOME)
	assert_eq(result["state"]["round"], 4)
	assert_eq(result["state"]["random"], state["random"])
	assert_eq(result["state"]["market"], {})
	assert_eq(result["state"]["players"][0]["purchased_this_round"], [])
	assert_eq(result["state"]["players"][0]["contacts"]["unlocked"], [ContactIds.BLACK_CASH])
	assert_eq(result["state"]["players"][0]["contacts"]["used_this_round"], [])
	assert_false(result["state"]["players"][0]["role_flags"][
		"merchant_first_war_tax_applied_this_round"
	])
	for key: String in result["state"]["players"][0]["role_flags"]:
		if key != "merchant_first_war_tax_applied_this_round":
			assert_true(result["state"]["players"][0]["role_flags"][key], key)
	assert_eq(
		result["state"]["combat_log"][-1]["event_type"],
		LogEventTypes.PHASE_CHANGED
	)


func test_round_15_enters_game_over_without_round_16() -> void:
	var state: Dictionary = TestGameStateFactory.completed_action_state(
		15, "phase_game_over"
	)
	TestPlayers.find(state, GameIds.PLAYER_AI_3)["vp"] = 5
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.GAME_OVER)
	assert_eq(result["state"]["round"], 15)
	assert_eq(result["state"]["winner_id"], GameIds.PLAYER_AI_3)
	assert_true(GameStateValidator.validate_game_state(result["state"])["ok"])
	var before: Dictionary = result["state"].duplicate(true)
	var blocked: Dictionary = GamePhaseController.advance_phase(result["state"])
	assert_eq(blocked["error"], ValidationErrors.GAME_ALREADY_OVER)
	assert_eq(result["state"], before)


func test_turf_10_game_over_resolves_ai_favored_winner() -> void:
	var state: Dictionary = TestGameStateFactory.completed_action_state(
		15, "phase_turf_10"
	)
	state["turf_level"] = 10
	for player: Dictionary in state["players"]:
		player["turf_level"] = 10
		player["vp"] = 6
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 20
	TestPlayers.find(state, GameIds.PLAYER_AI_3)["nal"] = 12
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.GAME_OVER)
	assert_eq(result["state"]["winner_id"], GameIds.PLAYER_AI_3)
	assert_true(
		result["state"]["game_result"]["turf_level_10_ai_win_applied"]
	)
	assert_eq(state, before)


func test_invalid_round_and_active_player_fail_without_mutation() -> void:
	var invalid_round: Dictionary = TestGameStateFactory.base_state()
	invalid_round["round"] = 16
	var round_before: Dictionary = invalid_round.duplicate(true)
	var round_result: Dictionary = GamePhaseController.advance_phase(invalid_round)
	assert_eq(round_result["error"], ValidationErrors.INVALID_ROUND)
	assert_eq(invalid_round, round_before)
	var invalid_active: Dictionary = TestGameStateFactory.action_state()
	invalid_active["active_action_player_id"] = "bad_player"
	var active_before: Dictionary = invalid_active.duplicate(true)
	var active_result: Dictionary = GamePhaseController.advance_action_player(
		invalid_active
	)
	assert_eq(
		active_result["error"],
		ValidationErrors.INVALID_ACTIVE_ACTION_PLAYER
	)
	assert_eq(invalid_active, active_before)


func test_can_advance_is_read_only_and_empty_game_is_rejected() -> void:
	var state: Dictionary = TestGameStateFactory.ready_market_state(
		"phase_can_advance"
	)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GamePhaseController.can_advance_phase(state)
	assert_true(result["ok"])
	assert_eq(state, before)
	assert_eq(result["state"]["random"], before["random"])
	var empty_result: Dictionary = GamePhaseController.can_advance_phase({})
	assert_eq(empty_result["error"], ValidationErrors.GAME_NOT_STARTED)
