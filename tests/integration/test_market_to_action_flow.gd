extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func test_market_waits_then_enters_action_in_fixed_order() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	var before: Dictionary = GameStateManager.get_state_snapshot()
	var early: Dictionary = GameStateManager.advance_phase()
	assert_false(early["ok"])
	assert_eq(early["error"], ValidationErrors.PHASE_NOT_READY)
	assert_eq(GameStateManager.get_state_snapshot(), before)
	var completed: Dictionary = GameStateManager.end_market_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(completed["ok"], str(completed))
	var state: Dictionary = GameStateManager.get_state_snapshot()
	assert_eq(state["current_phase"], PhaseIds.ACTION)
	assert_eq(state["action_order"], GameIds.PLAYER_IDS)
	assert_eq(state["active_action_player_id"], GameIds.PLAYER_HUMAN)
	assert_true(GameStateValidator.validate_game_state(state)["ok"])


func _valid_config() -> Dictionary:
	var game_seed := "market_action_integration"
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
