class_name TestGameStateFactory


static func setup_state(game_seed: String = "test_seed_001") -> Dictionary:
	return GameStateFactory.create_new_game_state(game_seed, 0)


static func base_state(game_seed: String = "test_seed_001") -> Dictionary:
	return TestStates.committed_state(game_seed)


static func completed_setup_state(
	game_seed: String = "test_seed_setup"
) -> Dictionary:
	var state: Dictionary = base_state(game_seed)
	state["current_phase"] = PhaseIds.SETUP
	return state


static func market_state(
	game_seed: String = "test_seed_market",
	round_number: int = 1
) -> Dictionary:
	var state: Dictionary = base_state(game_seed)
	state["round"] = round_number
	state["current_phase"] = PhaseIds.MARKET
	state["market"] = GameStateFactory.create_market_state()
	state["market"]["round"] = round_number
	return state


static func action_state(
	game_seed: String = "test_seed_action",
	round_number: int = 1
) -> Dictionary:
	var state: Dictionary = market_state(game_seed, round_number)
	state["current_phase"] = PhaseIds.ACTION
	state["action_order"] = GameIds.PLAYER_IDS.duplicate()
	state["active_action_player_id"] = GameIds.PLAYER_HUMAN
	return state


static func completed_action_state(
	round_number: int,
	game_seed: String = "test_seed_action_done"
) -> Dictionary:
	var state: Dictionary = action_state(game_seed, round_number)
	for player: Dictionary in state["players"]:
		player["action_done"] = true
	state["active_action_player_id"] = ""
	return state


static func ready_market_state(
	game_seed: String = "test_seed_market_ready"
) -> Dictionary:
	var state: Dictionary = market_state(game_seed)
	for player: Dictionary in state["players"]:
		player["ready_for_action"] = true
	return state


static func street_deal_state(
	game_seed: String = "test_seed_deal",
	round_number: int = 4
) -> Dictionary:
	var state: Dictionary = market_state(game_seed, round_number)
	state["current_phase"] = PhaseIds.STREET_DEAL
	for player: Dictionary in state["players"]:
		player["action_done"] = true
	state["street_deals"]["offered_this_round"] = true
	state["street_deals"]["current_deal_id"] = StreetDealIds.DIRTY_TIP
	state["street_deals"]["option_availability"] = {
		StreetDealOptionIds.OPTION_A: ValidationErrors.OK,
		StreetDealOptionIds.OPTION_B: ValidationErrors.OK,
	}
	return state
