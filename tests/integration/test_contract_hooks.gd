extends GutTest


func test_market_purchase_hook_completes_silent_expansion() -> void:
	var state: Dictionary = TestStates.with_contract(
		TestGameStateFactory.market_state("contract_market"),
		ContractIds.SILENT_EXPANSION
	)
	state["market"]["always_available_card_ids"] = [
		GameIds.CARD_STASH, GameIds.CARD_WORKSHOP,
	]
	state["market"]["all_available_card_ids"] = [
		GameIds.CARD_STASH, GameIds.CARD_WORKSHOP,
	]
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 50
	var first: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_STASH
	)
	var second: Dictionary = MarketLogic.buy_card(
		first["state"], human["id"], GameIds.CARD_WORKSHOP
	)
	assert_true(second["ok"], str(second))
	assert_true(_contract(second["state"])["completed"])
	assert_false(_contract(second["state"])["claimed"])


func test_income_hook_completes_gray_capital_after_income_and_upkeep() -> void:
	var state: Dictionary = TestStates.with_contract(
		TestGameStateFactory.base_state("contract_income"),
		ContractIds.GRAY_CAPITAL
	)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 29
	var result: Dictionary = IncomeLogic.resolve_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	assert_true(_contract(result["state"])["completed"])
	assert_false(_contract(result["state"])["claimed"])


func test_blocked_valid_combat_event_fails_only_silent_expansion() -> void:
	var silent: Dictionary = _combat_state(
		ContractIds.SILENT_EXPANSION, GameIds.CARD_THUG
	)
	TestPlayers.find(
		silent, GameIds.PLAYER_AI_1
	)["defense"]["cops_active"] = true
	var blocked: Dictionary = CombatEngine.resolve_attack(
		silent, CombatTestHelper.payload(GameIds.CARD_THUG)
	)
	assert_true(blocked["ok"], str(blocked))
	assert_true(blocked["blocked"])
	assert_true(_contract(blocked["state"])["failed"])
	assert_true(blocked["contract_results"][0]["failed_now"])
	assert_eq(blocked["contract_hook_events"].size(), 1)
	assert_eq(
		blocked["log_entries"][-1]["event_type"],
		LogEventTypes.ATTACK_BLOCKED
	)
	var proxy: Dictionary = _combat_state(
		ContractIds.PROXY_WAR, GameIds.CARD_SABOTEUR
	)
	var target: Dictionary = TestPlayers.find(proxy, GameIds.PLAYER_AI_1)
	target["engine"]["informers"] = 1
	target["defense"]["judge_state"] = DefenseStates.ACTIVE
	blocked = CombatEngine.resolve_attack(
		proxy,
		CombatTestHelper.payload(
			GameIds.CARD_SABOTEUR, "", GameIds.PLAYER_AI_1,
			[], GameIds.CARD_INFORMANT
		)
	)
	assert_true(blocked["blocked"])
	assert_false(_contract(blocked["state"])["completed"])
	assert_eq(_contract(blocked["state"])["progress"], 0)


func test_successful_combat_hooks_progress_bloody_turf_war_and_proxy_war() -> void:
	var bloody: Dictionary = _combat_state(
		ContractIds.BLOODY_TURF_WAR, GameIds.CARD_BRUISER
	)
	var target: Dictionary = TestPlayers.find(
		bloody, GameIds.PLAYER_AI_1
	)
	target["status_buildings"]["stash"] = 1
	target["vp"] = 1
	var result: Dictionary = CombatEngine.resolve_attack(
		bloody,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	assert_eq(_contract(result["state"])["progress"], 1)
	var proxy: Dictionary = _combat_state(
		ContractIds.PROXY_WAR, GameIds.CARD_SABOTEUR
	)
	target = TestPlayers.find(proxy, GameIds.PLAYER_AI_1)
	target["engine"]["informers"] = 1
	result = CombatEngine.resolve_attack(
		proxy,
		CombatTestHelper.payload(
			GameIds.CARD_SABOTEUR, "", GameIds.PLAYER_AI_1,
			[], GameIds.CARD_INFORMANT
		)
	)
	assert_true(_contract(result["state"])["completed"])


func test_round_start_deadline_hook_preserves_phase_event_order() -> void:
	var state: Dictionary = TestStates.with_contract(
		TestGameStateFactory.completed_action_state(
			9, "contract_deadline_phase"
		),
		ContractIds.IRON_ROOF
	)
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["round"], 10)
	assert_true(_contract(result["state"])["failed"])
	assert_eq(
		result["state"]["combat_log"][-2]["event_type"],
		LogEventTypes.CONTRACT_FAILED
	)
	assert_eq(
		result["state"]["combat_log"][-1]["event_type"],
		LogEventTypes.PHASE_CHANGED
	)


func test_hooks_without_selected_contract_are_safe_and_read_only() -> void:
	var state: Dictionary = TestGameStateFactory.setup_state(
		"contract_no_selection"
	)
	var before: Dictionary = state.duplicate(true)
	var results: Array[Dictionary] = [
		ContractLogic.on_card_purchased(
			state,
			{
				"player_id": GameIds.PLAYER_HUMAN,
				"card_id": GameIds.CARD_STASH,
				"card_type": CardTypes.STATUS,
			}
		),
		ContractLogic.on_income_resolved(
			state, {"player_id": GameIds.PLAYER_HUMAN}
		),
		ContractLogic.on_attack_resolved(
			state,
			{
				"attacker_id": GameIds.PLAYER_HUMAN,
				"valid_attack": true,
			}
		),
		ContractLogic.process_deadlines(state),
	]
	for result: Dictionary in results:
		assert_true(result["ok"])
		assert_false(result["changed"])
	assert_eq(state, before)


func _combat_state(
	contract_id: String,
	card_id: String
) -> Dictionary:
	var state: Dictionary = TestStates.with_contract(
		TestGameStateFactory.action_state("combat_%s" % contract_id),
		contract_id
	)
	TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)["hand"] = [card_id]
	return state


func _contract(state: Dictionary) -> Dictionary:
	return TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)["contracts"][0]
