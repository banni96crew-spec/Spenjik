extends GutTest

const ReplayScenarios = preload("res://tests/fixtures/ReplayScenarios.gd")


func before_each() -> void:
	GameStateManager.reset_game()


func test_setup_connects_role_contract_ai_and_turf() -> void:
	var config: Dictionary = ReplayScenarios.setup_preview_config(
		ReplayScenarios.REPLAY_SEED
	)
	var preview: Dictionary = GameStateManager.generate_contract_offers(config)
	assert_true(preview["ok"], str(preview))
	assert_has(preview["contract_offer_ids"], ReplayScenarios.REPLAY_CONTRACT)
	var started: Dictionary = GameStateManager.start_new_game({
		"game_seed": ReplayScenarios.REPLAY_SEED,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": ReplayScenarios.REPLAY_ROLE,
		"selected_contract_id": ReplayScenarios.REPLAY_CONTRACT,
	})
	assert_true(started["ok"], str(started))
	var state: Dictionary = GameStateManager.get_state_snapshot()
	assert_true(GameStateValidator.validate_game_state(state)["ok"])
	assert_eq(state["selected_role_id"], ReplayScenarios.REPLAY_ROLE)
	assert_eq(state["selected_contract_id"], ReplayScenarios.REPLAY_CONTRACT)
	assert_eq(state["contract_offer_ids"], preview["contract_offer_ids"])
	assert_eq(state["ai_bosses"].size(), 3)
	assert_eq(state["random"]["step"], 7)


func test_locked_contract_must_remain_in_preview() -> void:
	var config: Dictionary = ReplayScenarios.setup_preview_config(
		ReplayScenarios.REPLAY_SEED
	)
	var preview: Dictionary = GameStateManager.generate_contract_offers(config)
	assert_true(preview["ok"], str(preview))
	assert_has(preview["contract_offer_ids"], ReplayScenarios.REPLAY_CONTRACT)
