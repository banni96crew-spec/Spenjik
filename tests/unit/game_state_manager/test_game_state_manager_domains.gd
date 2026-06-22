extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_failed_domain_mutators_preserve_complete_active_state() -> void:
	var cases: Array[Callable] = [
		func() -> Dictionary:
			return GameStateManager.buy_card("bad_player", GameIds.CARD_STASH),
		func() -> Dictionary:
			return GameStateManager.rebuild_district_control(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.execute_attack({}),
		func() -> Dictionary:
			return GameStateManager.discard_war_card(
				GameIds.PLAYER_HUMAN, GameIds.CARD_THUG
			),
		func() -> Dictionary:
			return GameStateManager.claim_contract(
				GameIds.PLAYER_HUMAN, ContractIds.SILENT_EXPANSION
			),
		func() -> Dictionary:
			return GameStateManager.select_street_deal({}),
		func() -> Dictionary:
			return GameStateManager.select_contact({}),
		func() -> Dictionary:
			return GameStateManager.activate_contact({
				"player_id": GameIds.PLAYER_HUMAN,
				"contact_id": ContactIds.STREET_MEDIC,
			}),
		func() -> Dictionary:
			return GameStateManager.run_market_for_ai(GameIds.PLAYER_HUMAN),
	]
	GameStateManager.state = TestStates.committed_state("domain_failures")
	for invoke: Callable in cases:
		var before: Dictionary = GameStateManager.get_state_snapshot()
		watch_signals(GameStateManager)
		var result: Dictionary = invoke.call()
		assert_false(result["ok"], str(result))
		assert_eq(GameStateManager.get_state_snapshot(), before)
		assert_signal_not_emitted(GameStateManager, "state_changed")


func test_activate_contact_owner_errors_are_stable_and_read_only() -> void:
	GameStateManager.state = TestStates.committed_state("contact_activate")
	var before: Dictionary = GameStateManager.get_state_snapshot()
	var invalid_player: Dictionary = GameStateManager.activate_contact({
		"player_id": "player_99",
		"contact_id": ContactIds.STREET_MEDIC,
	})
	assert_eq(invalid_player["error"], ValidationErrors.INVALID_PLAYER_ID)
	var invalid_contact: Dictionary = GameStateManager.activate_contact({
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": "missing_contact",
	})
	assert_eq(invalid_contact["error"], ValidationErrors.INVALID_CONTACT_ID)
	var manual: Dictionary = GameStateManager.activate_contact({
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": ContactIds.STREET_MEDIC,
	})
	assert_eq(manual["error"], ValidationErrors.REQUIREMENT_NOT_MET)
	assert_eq(GameStateManager.get_state_snapshot(), before)


func test_phase_transition_commits_and_emits_after_validation() -> void:
	GameStateManager.state = TestGameStateFactory.ready_market_state("phase_facade")
	watch_signals(GameStateManager)
	var result: Dictionary = GameStateManager.advance_phase()
	assert_true(result["ok"], str(result))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.ACTION)
	assert_signal_emitted(GameStateManager, "state_changed")
	assert_signal_emitted(GameStateManager, "phase_changed")


func test_end_action_advances_turn_only_when_next_player_exists() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("action_advance")
	GameStateManager.state = state
	var ended: Dictionary = GameStateManager.end_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(ended["ok"], str(ended))
	assert_eq(
		GameStateManager.get_state_snapshot()["active_action_player_id"],
		GameIds.PLAYER_AI_1
	)
	state = TestGameStateFactory.action_state("action_last")
	for player_id: String in [
		GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_1, GameIds.PLAYER_AI_2,
	]:
		TestPlayers.find(state, player_id)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_3
	GameStateManager.state = state
	ended = GameStateManager.end_action_for_player(GameIds.PLAYER_AI_3)
	assert_true(ended["ok"], str(ended))
	assert_eq(GameStateManager.get_state_snapshot()["active_action_player_id"], "")


func test_skip_action_delegates_to_phase_owner() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("skip_facade")
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["skip_next_action"] = true
	GameStateManager.state = state
	var result: Dictionary = GameStateManager.skip_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	var human: Dictionary = TestPlayers.find(
		GameStateManager.get_state_snapshot(), GameIds.PLAYER_HUMAN
	)
	assert_true(human["action_done"])
	assert_false(human["skip_next_action"])
	assert_eq(
		GameStateManager.get_state_snapshot()["active_action_player_id"],
		GameIds.PLAYER_AI_1
	)
