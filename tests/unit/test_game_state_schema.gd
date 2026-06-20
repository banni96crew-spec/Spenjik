extends GutTest


func test_setup_and_committed_validation_modes_are_distinct() -> void:
	var setup: Dictionary = TestGameStateFactory.setup_state()
	var committed: Dictionary = TestStates.committed_state()
	assert_true(GameStateValidator.validate_setup_working_state(setup)["ok"])
	assert_false(GameStateValidator.validate_game_state(setup)["ok"])
	assert_true(GameStateValidator.validate_game_state(committed)["ok"])


func test_runtime_state_is_json_compatible_and_round_trips() -> void:
	var state: Dictionary = TestStates.committed_state()
	assert_true(StateShapeValidator.is_json_compatible(state))
	var encoded: String = JSON.stringify(state)
	var decoded: Variant = JSON.parse_string(encoded)
	assert_false(encoded.is_empty())
	assert_typeof(decoded, TYPE_DICTIONARY)
	assert_true(StateShapeValidator.is_json_compatible(decoded))


func test_reusable_phase_fixtures_remain_valid_committed_states() -> void:
	for state: Dictionary in [
		TestGameStateFactory.market_state(),
		TestGameStateFactory.action_state(),
		TestGameStateFactory.street_deal_state(),
	]:
		var result: Dictionary = GameStateValidator.validate_game_state(state)
		assert_true(result["ok"], str(result["details"]))
