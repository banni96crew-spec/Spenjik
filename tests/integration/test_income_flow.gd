extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func test_facade_income_resolves_all_players_and_enters_market_atomically() -> void:
	var started: Dictionary = GameStateManager.start_new_game(
		_valid_config("income_integration")
	)
	assert_true(started["ok"], str(started))
	var before: Dictionary = GameStateManager.get_state_snapshot()
	var advanced: Dictionary = GameStateManager.advance_phase()
	assert_true(advanced["ok"], str(advanced))
	var after: Dictionary = GameStateManager.get_state_snapshot()
	assert_eq(after["current_phase"], PhaseIds.MARKET)
	assert_eq(after["random"]["step"], before["random"]["step"] + 12)
	assert_true(GameStateValidator.validate_game_state(after)["ok"])
	for player: Dictionary in after["players"]:
		assert_gt(player["nal"], 0)
		assert_false(player["ready_for_action"])


func _valid_config(seed_value: String) -> Dictionary:
	var preview: Dictionary = GameStateManager.generate_contract_offers({
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
	})
	return {
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	}
