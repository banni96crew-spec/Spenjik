extends GutTest

## M13 §12.8 AI integration: setup determinism, Market for all three AI, Action
## in player order after the human, and MVP exclusions (no roles/contracts/deals).

const ALWAYS: Array[String] = [
	GameIds.CARD_INFORMANT, GameIds.CARD_STASH,
	GameIds.CARD_THUG, GameIds.CARD_COPS,
]


func _market_state(seed_value: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state(seed_value, 1)
	var rotating: Array = [GameIds.CARD_WORKSHOP, GameIds.CARD_LAUNDRY]
	var all_cards: Array = ALWAYS.duplicate()
	all_cards.append_array(rotating)
	state["market"] = {
		"round": 1,
		"always_available_card_ids": ALWAYS.duplicate(),
		"rotating_card_ids": rotating,
		"all_available_card_ids": all_cards,
	}
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		TestPlayers.find(state, ai_id)["nal"] = 20
	return state


func test_full_setup_is_deterministic_and_valid() -> void:
	var first: Dictionary = AIBotController.setup_ai_bosses(
		GameStateFactory.create_new_game_state("integration_setup", 0)
	)
	var second: Dictionary = AIBotController.setup_ai_bosses(
		GameStateFactory.create_new_game_state("integration_setup", 0)
	)
	assert_true(first["ok"])
	assert_eq(first["ai_bosses"], second["ai_bosses"])
	assert_true(AIStateValidator.validate(first["state"])["ok"])


func test_market_runs_for_all_three_ai() -> void:
	var state: Dictionary = _market_state("integration_market")
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		var result: Dictionary = AIBotController.run_market_for_ai(state, ai_id)
		assert_true(result["ok"], "market ok for %s" % ai_id)
		state = result["state"]
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		assert_true(TestPlayers.find(state, ai_id)["ready_for_action"])
	assert_true(GameStateValidator.validate_game_state(state)["ok"])


func test_action_runs_in_player_order_after_human() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("integration_action", 1)
	var human_end: Dictionary = GamePhaseController.end_action_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	state = human_end["state"]
	state = GamePhaseController.advance_action_player(state)["state"]
	assert_eq(state["active_action_player_id"], GameIds.PLAYER_AI_1)
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		assert_eq(state["active_action_player_id"], ai_id)
		var result: Dictionary = AIBotController.run_action_for_ai(state, ai_id)
		assert_true(result["ok"], "action ok for %s" % ai_id)
		state = result["state"]
		if not state["active_action_player_id"].is_empty():
			state = GamePhaseController.advance_action_player(state)["state"]
	for player_id: String in GameIds.PLAYER_IDS:
		assert_true(TestPlayers.find(state, player_id)["action_done"])


func test_ai_players_have_no_roles_contracts_or_deal_choices() -> void:
	var state: Dictionary = TestStates.committed_state("integration_exclusions")
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		var ai: Dictionary = TestPlayers.find(state, ai_id)
		assert_eq(ai["contracts"], [], "AI receives no contracts in MVP")
		assert_eq(ai["contacts"]["unlocked"], [], "AI receives no contacts in MVP")
	assert_eq(state["selected_role_id"], RoleIds.MERCHANT, "role belongs to the human only")
	assert_false(state["street_deals"]["choices_by_player"].has(GameIds.PLAYER_AI_1))
