extends GutTest


func test_committed_fixture_validates() -> void:
	var result: Dictionary = GameStateValidator.validate_game_state(
		TestStates.committed_state()
	)
	assert_true(result["ok"], str(result["details"]))
	assert_eq(result["error"], ValidationErrors.OK)


func test_missing_root_key_wrong_round_and_invalid_player_id_fail() -> void:
	var missing: Dictionary = TestStates.without_key(
		TestStates.committed_state(), "market"
	)
	assert_false(GameStateValidator.validate_game_state(missing)["ok"])
	var wrong_round: Dictionary = TestStates.committed_state()
	wrong_round["round"] = 16
	assert_eq(
		GameStateValidator.validate_game_state(wrong_round)["error"],
		ValidationErrors.INVALID_ROUND
	)
	var invalid_player: Dictionary = TestStates.committed_state()
	invalid_player["players"][0]["id"] = "human"
	assert_eq(
		GameStateValidator.validate_game_state(invalid_player)["error"],
		ValidationErrors.INVALID_PLAYER_ID
	)


func test_duplicate_players_and_invalid_nested_states_fail() -> void:
	var duplicate_players: Dictionary = TestStates.committed_state()
	duplicate_players["players"][1]["id"] = GameIds.PLAYER_HUMAN
	assert_false(GameStateValidator.validate_game_state(duplicate_players)["ok"])
	var bad_random: Dictionary = TestStates.committed_state()
	bad_random["random"]["step"] = -1
	assert_eq(
		GameStateValidator.validate_game_state(bad_random)["error"],
		ValidationErrors.INVALID_RANDOM_STATE
	)
	var wrong_nested_type: Dictionary = TestStates.committed_state()
	wrong_nested_type["contacts"] = []
	assert_false(
		GameStateValidator.validate_game_state(wrong_nested_type)["ok"]
	)
	var bad_contact: Dictionary = TestStates.committed_state()
	bad_contact["players"][0]["contacts"]["unlocked"] = [
		ContactIds.BLACK_CASH, ContactIds.CORRUPT_CLERK
	]
	assert_false(GameStateValidator.validate_game_state(bad_contact)["ok"])


func test_contract_debt_and_street_deal_invariants_fail() -> void:
	var contract: Dictionary = GameStateFactory.create_contract_runtime(
		ContractIds.SILENT_EXPANSION, 6
	)
	contract["completed"] = true
	contract["failed"] = true
	assert_false(GameStateValidator.validate_contract_runtime(contract)["ok"])
	var debt: Dictionary = GameStateFactory.create_debt_state(
		"loan_shark_round_4_option_a", 12, 6,
		{"lose_all_nal": true, "vp_delta": -1}, 4
	)
	debt["repaid_round"] = 5
	assert_false(GameStateValidator.validate_debt_state(debt)["ok"])
	var deals: Dictionary = GameStateFactory.create_street_deal_state()
	deals["choices_by_player"][GameIds.PLAYER_AI_1] = StreetDealOptionIds.OPTION_A
	assert_false(GameStateValidator.validate_street_deal_state(deals)["ok"])


func test_populated_ai_metadata_requires_unique_profiles_and_one_strong_ai() -> void:
	var state: Dictionary = TestStates.committed_state()
	state["ai_bosses"][1]["profile_id"] = state["ai_bosses"][0]["profile_id"]
	assert_eq(
		GameStateValidator.validate_ai_bosses(state)["error"],
		ValidationErrors.INVALID_AI_STATE
	)
	state = TestStates.committed_state()
	state["ai_bosses"][0]["is_strong"] = false
	assert_false(GameStateValidator.validate_ai_bosses(state)["ok"])


func test_winner_result_consistency_and_validation_no_mutation() -> void:
	var state: Dictionary = TestStates.committed_state()
	state["winner_id"] = GameIds.PLAYER_HUMAN
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = GameStateValidator.validate_game_state(state)
	assert_false(result["ok"])
	TestStates.assert_no_mutation(self, before, state)
