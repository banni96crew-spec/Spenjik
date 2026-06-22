extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func test_ai_market_and_action_complete_through_facade() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	assert_true(GameStateManager.end_market_for_player(
		GameIds.PLAYER_HUMAN
	)["ok"])
	var market_result: Dictionary = GameStateManager.run_all_ai_market()
	assert_true(market_result["ok"], str(market_result))
	assert_true(GameStateManager.advance_phase()["ok"])
	assert_true(GameStateManager.end_action_for_player(
		GameIds.PLAYER_HUMAN
	)["ok"])
	var action_result: Dictionary = GameStateManager.run_all_ai_actions()
	assert_true(action_result["ok"], str(action_result))
	var state: Dictionary = GameStateManager.get_state_snapshot()
	assert_eq(state["active_action_player_id"], "")
	for player: Dictionary in state["players"]:
		assert_true(player["action_done"])
	assert_true(GameStateValidator.validate_game_state(state)["ok"])


func _valid_config() -> Dictionary:
	var game_seed := "ai_turn_integration"
	var preview: Dictionary = GameStateManager.generate_contract_offers({
		"game_seed": game_seed,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
	})
	return {
		"game_seed": game_seed,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	}
