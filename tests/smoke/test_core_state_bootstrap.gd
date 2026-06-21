extends GutTest


func test_core_state_bootstrap() -> void:
	var state: Dictionary = GameStateFactory.create_new_game_state("smoke", 0)
	assert_true(state.has("players"))
	assert_eq(state["players"].size(), 4)
	assert_eq(state["current_phase"], PhaseIds.SETUP)
	assert_true(GameStateValidator.validate_setup_working_state(state)["ok"])
