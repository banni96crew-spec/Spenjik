extends GutTest

const ReplayScenarios = preload("res://tests/fixtures/ReplayScenarios.gd")


func before_each() -> void:
	GameStateManager.reset_game()


func test_round_one_runs_through_facade_and_starts_round_two() -> void:
	var preview: Dictionary = GameStateManager.generate_contract_offers(
		ReplayScenarios.setup_preview_config(ReplayScenarios.REPLAY_SEED)
	)
	assert_true(preview["ok"], str(preview))
	assert_has(preview["contract_offer_ids"], ReplayScenarios.REPLAY_CONTRACT)
	var result: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED,
		ReplayScenarios.full_round_one_script()
	)
	assert_true(result["ok"], str(result))
	var state: Dictionary = result["state"]
	assert_eq(state["round"], 2)
	assert_eq(state["current_phase"], PhaseIds.INCOME)
	assert_eq(state["active_action_player_id"], "")
	assert_eq(state["winner_id"], "")
	assert_true(state["game_result"].is_empty())
	assert_true(GameStateValidator.validate_game_state(state)["ok"])


func test_runner_stops_at_first_failed_command() -> void:
	var script: Array[Dictionary] = [
		ReplayScenarios.setup_command(),
		{"operation": "advance_phase", "payload": {}},
		{"operation": "advance_phase", "payload": {}},
		{"operation": "run_all_ai_market", "payload": {}},
	]
	var result: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED, script
	)
	assert_false(result["ok"])
	assert_eq(result["failed_command_index"], 2)
	assert_eq(result["failed_command"]["operation"], "advance_phase")
	assert_eq(result["commands_executed"], 2)
	assert_eq(result["trace"].size(), 2)


func test_runner_rejects_invalid_script_with_structured_failure() -> void:
	var result: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED,
		[{"operation": "end_market_for_player", "payload": {}}]
	)
	assert_false(result["ok"])
	assert_eq(result["error"], ReplayScriptRunner.ERROR_INVALID_SCRIPT)
	assert_eq(result["failed_command_index"], 0)
	assert_eq(result["commands_executed"], 0)
	assert_eq(result["trace"], [])
