extends GutTest

## Pure phase-safe per-player Market/Action end (PRD 13 §8.6/§8.7). These set the
## owner flag and log the canonical event only; they never advance the phase.


func test_end_market_sets_ready_and_logs_canonical_event() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("phase_end_market", 1)
	var log_before: int = state["combat_log"].size()
	var result: Dictionary = PlayerPhaseEndLogic.end_market_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_true(result["ok"])
	assert_true(TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)["ready_for_action"])
	assert_eq(result["state"]["current_phase"], PhaseIds.MARKET, "no phase advancement")
	assert_eq(result["log_entries"].size(), 1)
	assert_eq(result["log_entries"][0]["event_type"], LogEventTypes.MARKET_ENDED_FOR_PLAYER)
	assert_eq(result["log_entries"][0]["details"], {"player_id": GameIds.PLAYER_AI_1})
	assert_eq(result["state"]["combat_log"].size(), log_before + 1)


func test_end_market_wrong_phase_is_safe_failure() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("phase_end_market_bad", 1)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = PlayerPhaseEndLogic.end_market_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.INVALID_PHASE)
	assert_eq(state, before)


func test_end_market_already_ready_is_safe_failure() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("phase_end_ready", 1)
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["ready_for_action"] = true
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = PlayerPhaseEndLogic.end_market_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.PLAYER_ALREADY_READY)
	assert_eq(state, before)


func test_end_market_unknown_player_is_safe_failure() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("phase_end_unknown", 1)
	var result: Dictionary = PlayerPhaseEndLogic.end_market_for_player(state, "ai_99")
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.INVALID_PLAYER_ID)


func _action_state_active(player_id: String, seed_value: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.action_state(seed_value, 1)
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["action_done"] = true
	state["active_action_player_id"] = player_id
	return state


func test_end_action_sets_done_and_logs_without_advancing() -> void:
	var state: Dictionary = _action_state_active(GameIds.PLAYER_AI_1, "phase_end_action")
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_true(result["ok"])
	assert_true(TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)["action_done"])
	assert_eq(result["state"]["active_action_player_id"], GameIds.PLAYER_AI_1,
		"no phase/turn advancement")
	assert_eq(result["log_entries"].size(), 1)
	assert_eq(result["log_entries"][0]["event_type"], LogEventTypes.ACTION_ENDED_FOR_PLAYER)
	assert_eq(result["log_entries"][0]["details"], {"player_id": GameIds.PLAYER_AI_1})


func test_end_action_requires_active_player() -> void:
	var state: Dictionary = _action_state_active(GameIds.PLAYER_AI_1, "phase_end_active")
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_2
	)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.NOT_ACTIVE_PLAYER)
	assert_eq(state, before)


func test_end_action_wrong_phase_is_safe_failure() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("phase_end_action_bad", 1)
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.INVALID_PHASE)


func test_end_action_already_done_is_safe_failure() -> void:
	var state: Dictionary = _action_state_active(GameIds.PLAYER_AI_1, "phase_end_done")
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["action_done"] = true
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.PLAYER_ALREADY_ACTION_DONE)


func _last_active_action_state(seed_value: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.action_state(seed_value, 1)
	for player_id: String in [GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_1, GameIds.PLAYER_AI_2]:
		TestPlayers.find(state, player_id)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_3
	return state


func test_last_active_player_end_action_returns_valid_state() -> void:
	var state: Dictionary = _last_active_action_state("phase_last_active")
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_3
	)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["active_action_player_id"], "")
	assert_true(
		GameStateValidator.validate_game_state(result["state"])["ok"],
		"last end_action state must validate"
	)


func test_last_action_end_allows_advance_phase() -> void:
	var state: Dictionary = _last_active_action_state("phase_last_advance")
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_3
	)
	assert_true(result["ok"])
	var advanced: Dictionary = GamePhaseController.advance_phase(result["state"])
	assert_true(advanced["ok"], str(advanced))
	assert_eq(advanced["state"]["current_phase"], PhaseIds.INCOME)


func test_non_last_action_end_keeps_active_player() -> void:
	var state: Dictionary = _action_state_active(GameIds.PLAYER_AI_1, "phase_non_last")
	var result: Dictionary = PlayerPhaseEndLogic.end_action_for_player(
		state, GameIds.PLAYER_AI_1
	)
	assert_true(result["ok"])
	assert_eq(result["state"]["active_action_player_id"], GameIds.PLAYER_AI_1)
