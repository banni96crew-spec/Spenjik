extends GutTest

const ReplayScenarios = preload("res://tests/fixtures/ReplayScenarios.gd")


func before_each() -> void:
	GameStateManager.reset_game()


func test_same_seed_and_script_produce_identical_successful_game_over() -> void:
	var preview: Dictionary = GameStateManager.generate_contract_offers(
		ReplayScenarios.setup_preview_config(ReplayScenarios.REPLAY_SEED)
	)
	assert_true(preview["ok"], str(preview))
	assert_has(preview["contract_offer_ids"], ReplayScenarios.REPLAY_CONTRACT)
	var script: Array[Dictionary] = ReplayScenarios.full_game_script()
	var first: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED, script
	)
	var second: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED, script
	)
	_assert_successful_game_over(first)
	_assert_successful_game_over(second)
	if not first["ok"] or not second["ok"]:
		return
	var first_state: Dictionary = first["state"]
	var second_state: Dictionary = second["state"]
	assert_eq(
		ReplayScriptRunner.normalize_snapshot(first_state),
		ReplayScriptRunner.normalize_snapshot(second_state)
	)
	assert_eq(first["trace"], second["trace"])
	assert_eq(first_state["winner_id"], second_state["winner_id"])
	assert_eq(first_state["game_result"], second_state["game_result"])
	assert_eq(_final_scores(first_state), _final_scores(second_state))
	assert_eq(
		ReplayAssertions.market_trace(first["trace"]),
		ReplayAssertions.market_trace(second["trace"])
	)
	assert_eq(first_state["ai_bosses"], second_state["ai_bosses"])
	assert_eq(
		first_state["street_deals"]["used_deal_ids"],
		second_state["street_deals"]["used_deal_ids"]
	)
	assert_eq(
		ReplayAssertions.street_deal_trace(first["trace"]),
		ReplayAssertions.street_deal_trace(second["trace"])
	)
	assert_eq(
		ReplayAssertions.contact_offer_trace(first["trace"]),
		ReplayAssertions.contact_offer_trace(second["trace"])
	)
	assert_eq(
		ReplayAssertions.contact_offer_trace(first["trace"]),
		[],
		"full replay does not claim focused contact coverage"
	)
	assert_eq(first_state["contacts"], second_state["contacts"])
	assert_eq(_human(first_state)["contracts"], _human(second_state)["contracts"])
	assert_eq(_debts(first_state), _debts(second_state))
	assert_eq(first_state["combat_log"], second_state["combat_log"])
	assert_eq(first["commands_executed"], second["commands_executed"])


func _assert_successful_game_over(result: Dictionary) -> void:
	assert_true(result["ok"], str(result))
	if not result["ok"]:
		return
	assert_eq(result["state"]["current_phase"], PhaseIds.GAME_OVER)
	assert_eq(result["state"]["round"], 15)
	assert_ne(result["state"]["winner_id"], "")
	assert_false(result["state"]["game_result"].is_empty())


func _final_scores(state: Dictionary) -> Array[Dictionary]:
	return state["game_result"]["final_scores"].duplicate(true)


func _human(state: Dictionary) -> Dictionary:
	for player: Dictionary in state["players"]:
		if player["id"] == GameIds.PLAYER_HUMAN:
			return player
	return {}


func _debts(state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for player: Dictionary in state["players"]:
		result[player["id"]] = player["debts"].duplicate(true)
	return result
