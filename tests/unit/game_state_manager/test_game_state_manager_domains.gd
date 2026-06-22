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


func test_human_end_action_completes_ai_turns_and_advances_phase() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("action_advance")
	GameStateManager.state = state
	var ended: Dictionary = GameStateManager.end_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(ended["ok"], str(ended))
	var snapshot: Dictionary = GameStateManager.get_state_snapshot()
	assert_eq(snapshot["active_action_player_id"], "")
	assert_eq(snapshot["current_phase"], PhaseIds.INCOME)
	assert_eq(ended.get("results", []).size(), 3)


func test_ai_end_action_advances_turn_only_when_next_player_exists() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("action_last")
	for player_id: String in [
		GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_1, GameIds.PLAYER_AI_2,
	]:
		TestPlayers.find(state, player_id)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_3
	GameStateManager.state = state
	var ended: Dictionary = GameStateManager.end_action_for_player(
		GameIds.PLAYER_AI_3
	)
	assert_true(ended["ok"], str(ended))
	assert_eq(GameStateManager.get_state_snapshot()["active_action_player_id"], "")


func test_skip_action_ends_active_player_and_advances_turn() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("skip_facade")
	GameStateManager.state = state
	watch_signals(GameStateManager)
	var result: Dictionary = GameStateManager.skip_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	var snapshot: Dictionary = GameStateManager.get_state_snapshot()
	var human: Dictionary = TestPlayers.find(
		snapshot, GameIds.PLAYER_HUMAN
	)
	assert_true(human["action_done"])
	assert_false(human["skip_next_action"])
	assert_eq(snapshot["active_action_player_id"], GameIds.PLAYER_AI_1)
	assert_true(GameStateValidator.validate_game_state(snapshot)["ok"])
	assert_signal_emitted(GameStateManager, "state_changed")


func test_skip_action_invalid_or_non_active_player_is_read_only() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("skip_invalid")
	GameStateManager.state = state
	var before: Dictionary = GameStateManager.get_state_snapshot()
	watch_signals(GameStateManager)
	var non_active: Dictionary = GameStateManager.skip_action_for_player(
		GameIds.PLAYER_AI_1
	)
	assert_false(non_active["ok"])
	assert_eq(non_active["error"], ValidationErrors.NOT_ACTIVE_PLAYER)
	assert_eq(GameStateManager.get_state_snapshot(), before)
	assert_signal_not_emitted(GameStateManager, "state_changed")
	GameStateManager.state = TestGameStateFactory.market_state("skip_phase")
	before = GameStateManager.get_state_snapshot()
	var wrong_phase: Dictionary = GameStateManager.skip_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_false(wrong_phase["ok"])
	assert_eq(wrong_phase["error"], ValidationErrors.INVALID_PHASE)
	assert_eq(GameStateManager.get_state_snapshot(), before)
	assert_signal_not_emitted(GameStateManager, "state_changed")


func test_skip_then_all_ai_actions_completes_action_phase_flow() -> void:
	GameStateManager.state = TestGameStateFactory.action_state("skip_ai_flow")
	var skipped: Dictionary = GameStateManager.skip_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(skipped["ok"], str(skipped))
	assert_eq(
		GameStateManager.get_state_snapshot()["active_action_player_id"],
		GameIds.PLAYER_AI_1
	)
	var ai_result: Dictionary = GameStateManager.run_all_ai_actions()
	assert_true(ai_result["ok"], str(ai_result))
	var completed: Dictionary = GameStateManager.get_state_snapshot()
	for player: Dictionary in completed["players"]:
		assert_true(player["action_done"], str(player))
	assert_eq(completed["active_action_player_id"], "")
	assert_true(GameStateValidator.validate_game_state(completed)["ok"])
	var advanced: Dictionary = GameStateManager.advance_phase()
	assert_true(advanced["ok"], str(advanced))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)
