extends GutTest


func test_income_components_and_double_bonus_are_exact() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("run_12345")
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["engine"]["laundries"] = 2
	human["engine"]["informers"] = 1
	human["engine"]["brothel"] = true
	human["contacts"]["unlocked"] = [ContactIds.BLACK_CASH]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = IncomeLogic.resolve_player(state, human["id"])
	assert_true(result["ok"], str(result))
	assert_eq(result["dice"], [5, 5])
	assert_eq(result["laundry_income"], 4)
	assert_eq(result["informant_income"], 1)
	assert_eq(result["brothel_income"], 6)
	assert_eq(result["total_income"], 21)
	assert_eq(result["state"]["random"]["step"], 2)
	assert_eq(
		TestPlayers.find(result["state"], human["id"])["nal"],
		before["players"][0]["nal"] + 21
	)
	assert_eq(state, before)


func test_all_player_income_consumes_exactly_eight_steps() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("income_all")
	var result: Dictionary = IncomeLogic.resolve_all_players(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["player_results"].size(), 4)
	assert_eq(result["state"]["random"]["step"], state["random"]["step"] + 8)
	assert_eq(result["log_entries"].size(), 4)


func test_cops_upkeep_interval_payment_and_deactivation() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("income_cops")
	state["turf_level"] = 5
	for player: Dictionary in state["players"]:
		player["turf_level"] = 5
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["defense"]["cops_active"] = true
	human["defense"]["cops_timer"] = 1
	human["nal"] = 1
	var paid: Dictionary = IncomeLogic.resolve_cops_upkeep(state, human["id"])
	assert_true(paid["cops_upkeep_result"]["paid"])
	var paid_human: Dictionary = TestPlayers.find(paid["state"], human["id"])
	assert_eq(paid_human["nal"], 0)
	assert_true(paid_human["defense"]["cops_active"])
	assert_eq(
		IncomeLogic.get_cops_upkeep_interval(
			state, TestPlayers.find(state, GameIds.PLAYER_AI_1)
		),
		3
	)
	human["nal"] = 0
	var deactivated: Dictionary = IncomeLogic.resolve_cops_upkeep(
		state, human["id"]
	)
	var inactive: Dictionary = TestPlayers.find(
		deactivated["state"], human["id"]
	)
	assert_true(deactivated["cops_upkeep_result"]["deactivated"])
	assert_false(inactive["defense"]["cops_active"])
	assert_eq(inactive["nal"], 0)


func test_future_debt_dependency_blocks_before_random_without_mutation() -> void:
	var debt_state: Dictionary = TestGameStateFactory.base_state("income_debt")
	TestPlayers.find(debt_state, GameIds.PLAYER_HUMAN)["debts"] = [
		GameStateFactory.create_debt_state(
			"loan_shark_round_1_option_a", 12, 3,
			{"lose_all_nal": true, "vp_delta": -1}, 1
		)
	]
	var before: Dictionary = debt_state.duplicate(true)
	var result: Dictionary = IncomeLogic.resolve_all_players(debt_state)
	assert_eq(result["error"], ValidationErrors.PHASE_NOT_READY)
	assert_eq(debt_state, before)
