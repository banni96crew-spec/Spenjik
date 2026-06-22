extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func test_canonical_mvp_smoke_reaches_valid_market() -> void:
	var preview: Dictionary = GameStateManager.generate_contract_offers({
		"game_seed": "test_seed_smoke",
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
	})
	assert_true(preview["ok"], str(preview))
	assert_eq(preview["contract_offer_ids"].size(), 3)
	var started: Dictionary = GameStateManager.start_new_game({
		"game_seed": "test_seed_smoke",
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	})
	assert_true(started["ok"], str(started))
	var setup_state: Dictionary = GameStateManager.get_state_snapshot()
	assert_true(GameStateValidator.validate_game_state(setup_state)["ok"])
	assert_eq(setup_state["current_phase"], PhaseIds.INCOME)
	assert_eq(setup_state["players"].size(), 4)
	assert_eq(
		_player_ids(setup_state),
		["player_1", "ai_1", "ai_2", "ai_3"]
	)
	var advanced: Dictionary = GameStateManager.advance_phase()
	assert_true(advanced["ok"], str(advanced))
	var market_state: Dictionary = GameStateManager.get_state_snapshot()
	assert_true(GameStateValidator.validate_game_state(market_state)["ok"])
	assert_true(
		GameStateValidator.validate_market_state(
			market_state["market"], market_state["round"]
		)["ok"]
	)
	assert_eq(market_state["current_phase"], PhaseIds.MARKET)
	assert_eq(market_state["random"]["step"], setup_state["random"]["step"] + 12)
	assert_has(
		_event_types(market_state),
		LogEventTypes.INCOME_RESOLVED
	)
	assert_eq(
		market_state["combat_log"][-1]["event_type"],
		LogEventTypes.PHASE_CHANGED
	)


func _event_types(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in state["combat_log"]:
		result.append(entry["event_type"])
	return result


func _player_ids(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for player: Dictionary in state["players"]:
		result.append(player["id"])
	return result
