extends GutTest


func test_successful_combat_boundary_applies_contract_hook_and_valid_state() -> void:
	var state: Dictionary = TestStates.with_contract(
		TestGameStateFactory.action_state("combat_hook_integration"),
		ContractIds.BLOODY_TURF_WAR
	)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	var target: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	human["hand"] = [GameIds.CARD_BRUISER]
	target["status_buildings"]["stash"] = 1
	target["vp"] = 1
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	assert_true(result["ok"], str(result))
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)["contracts"][0]["progress"],
		1
	)
	assert_true(GameStateValidator.validate_game_state(result["state"])["ok"])
