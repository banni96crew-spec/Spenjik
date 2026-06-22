extends GutTest

const ReplayScenarios = preload("res://tests/fixtures/ReplayScenarios.gd")


func before_each() -> void:
	GameStateManager.reset_game()


func test_full_facade_flow_reaches_game_over_without_round_sixteen() -> void:
	var preview: Dictionary = GameStateManager.generate_contract_offers(
		ReplayScenarios.setup_preview_config(ReplayScenarios.REPLAY_SEED)
	)
	assert_true(preview["ok"], str(preview))
	assert_has(preview["contract_offer_ids"], ReplayScenarios.REPLAY_CONTRACT)
	var result: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED,
		ReplayScenarios.full_game_script()
	)
	assert_true(result["ok"], str(result))
	if not result["ok"]:
		return
	var state: Dictionary = result["state"]
	assert_eq(state["current_phase"], PhaseIds.GAME_OVER)
	assert_eq(state["round"], 15)
	assert_ne(state["winner_id"], "")
	assert_false(state["game_result"].is_empty())
	assert_eq(state["winner_id"], state["game_result"]["winner_id"])
	assert_true(GameStateValidator.validate_game_state(state)["ok"])
	for checkpoint: Dictionary in result["trace"]:
		assert_lte(checkpoint["round"], 15)
