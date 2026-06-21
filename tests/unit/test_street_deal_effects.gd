extends GutTest


func test_loan_shark_options_create_exact_player_debts() -> void:
	for option: String in StreetDealOptionIds.ALL:
		var state: Dictionary = _state(
			StreetDealIds.LOAN_SHARK, option, 8
		)
		var human_before: int = TestPlayers.find(
			state, GameIds.PLAYER_HUMAN
		)["nal"]
		var result: Dictionary = _select(state, StreetDealIds.LOAN_SHARK, option)
		assert_true(result["ok"], str(result))
		var human: Dictionary = TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)
		var expected_gain: int = (
			10 if option == StreetDealOptionIds.OPTION_A else 5
		)
		var expected_due: int = (
			12 if option == StreetDealOptionIds.OPTION_A else 6
		)
		assert_eq(human["nal"], human_before + expected_gain)
		assert_eq(human["debts"].size(), 1)
		assert_eq(human["debts"][0]["amount_due"], expected_due)
		assert_eq(human["debts"][0]["deadline_round"], 10)
		assert_eq(
			human["debts"][0]["id"],
			"loan_shark_round_8_%s" % option
		)
		assert_false(result["state"].has("active_debts"))


func test_dirty_tip_options_apply_payment_and_deterministic_ai_target() -> void:
	var paid: Dictionary = _state(
		StreetDealIds.DIRTY_TIP, StreetDealOptionIds.OPTION_A, 4
	)
	var human_before: int = TestPlayers.find(
		paid, GameIds.PLAYER_HUMAN
	)["nal"]
	var result: Dictionary = _select(
		paid, StreetDealIds.DIRTY_TIP, StreetDealOptionIds.OPTION_A
	)
	var human: Dictionary = TestPlayers.find(
		result["state"], GameIds.PLAYER_HUMAN
	)
	assert_eq(human["nal"], human_before - 3)
	assert_has(human["hand"], GameIds.CARD_BRUISER)
	var random_state: Dictionary = _state(
		StreetDealIds.DIRTY_TIP, StreetDealOptionIds.OPTION_B, 4,
		"dirty_random"
	)
	var repeated: Dictionary = random_state.duplicate(true)
	result = _select(
		random_state, StreetDealIds.DIRTY_TIP,
		StreetDealOptionIds.OPTION_B
	)
	var again: Dictionary = _select(
		repeated, StreetDealIds.DIRTY_TIP,
		StreetDealOptionIds.OPTION_B
	)
	assert_eq(result["selected_ai_id"], again["selected_ai_id"])
	assert_eq(result["random_steps_used"], 1)
	assert_eq(
		result["state"]["random"]["step"],
		random_state["random"]["step"] + 1
	)
	assert_has(
		TestPlayers.find(
			result["state"], result["selected_ai_id"]
		)["hand"],
		GameIds.CARD_THUG
	)


func test_cheap_protection_options_create_consumable_modifiers() -> void:
	var defense: Dictionary = _state(
		StreetDealIds.CHEAP_PROTECTION,
		StreetDealOptionIds.OPTION_A, 4
	)
	var result: Dictionary = _select(
		defense, StreetDealIds.CHEAP_PROTECTION,
		StreetDealOptionIds.OPTION_A
	)
	var modifier: Dictionary = TestPlayers.find(
		result["state"], GameIds.PLAYER_HUMAN
	)["temporary_modifiers"][0]
	assert_eq(
		modifier["type"],
		ModifierTypes.NEXT_DEFENSE_CARD_PRICE_DELTA
	)
	assert_eq(modifier["delta"], -2)
	assert_eq(modifier["min_value"], 1)
	assert_false(modifier["consumed"])
	var market: Dictionary = result["state"]
	market["current_phase"] = PhaseIds.MARKET
	market["market"]["always_available_card_ids"] = [GameIds.CARD_COPS]
	market["market"]["all_available_card_ids"] = [GameIds.CARD_COPS]
	var purchase: Dictionary = MarketLogic.buy_card(
		market, GameIds.PLAYER_HUMAN, GameIds.CARD_COPS
	)
	assert_true(purchase["ok"], str(purchase))
	assert_true(
		TestPlayers.find(
			purchase["state"], GameIds.PLAYER_HUMAN
		)["temporary_modifiers"][0]["consumed"]
	)
	var war: Dictionary = _state(
		StreetDealIds.CHEAP_PROTECTION,
		StreetDealOptionIds.OPTION_B, 4
	)
	result = _select(
		war, StreetDealIds.CHEAP_PROTECTION,
		StreetDealOptionIds.OPTION_B
	)
	modifier = TestPlayers.find(
		result["state"], GameIds.PLAYER_HUMAN
	)["temporary_modifiers"][0]
	assert_eq(modifier["type"], ModifierTypes.NEXT_WAR_CARD_PRICE_DELTA)
	assert_eq(modifier["delta"], 1)


func test_cash_vp_and_turf_eight_payments_are_exact() -> void:
	var state: Dictionary = _state(
		StreetDealIds.BLACK_MARKET_CACHE,
		StreetDealOptionIds.OPTION_A, 4
	)
	var before: int = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)["nal"]
	var result: Dictionary = _select(
		state, StreetDealIds.BLACK_MARKET_CACHE,
		StreetDealOptionIds.OPTION_A
	)
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)["nal"],
		before + 6
	)
	for pair: Array in [
		[StreetDealIds.DIRTY_TIP, StreetDealOptionIds.OPTION_A, 3],
		[StreetDealIds.BLACK_MARKET_CACHE, StreetDealOptionIds.OPTION_B, 6],
		[StreetDealIds.RISKY_CONTRACT, StreetDealOptionIds.OPTION_A, 3],
	]:
		state = _state(pair[0], pair[1], 12)
		assert_eq(
			StreetDealLogic.get_payment_amount(
				state, pair[0], pair[1], GameIds.PLAYER_HUMAN
			),
			pair[2]
		)
		state["turf_level"] = 8
		for player: Dictionary in state["players"]:
			player["turf_level"] = 8
		assert_eq(
			StreetDealLogic.get_payment_amount(
				state, pair[0], pair[1], GameIds.PLAYER_HUMAN
			),
			pair[2] + 1
		)


func _state(
	deal_id: String,
	_option_id: String,
	round_number: int,
	game_seed: String = "deal_effect"
) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		game_seed, round_number
	)
	state["street_deals"]["current_deal_id"] = deal_id
	state["street_deals"]["option_availability"] = {
		StreetDealOptionIds.OPTION_A: ValidationErrors.OK,
		StreetDealOptionIds.OPTION_B: ValidationErrors.OK,
	}
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 20
	return state


func _select(
	state: Dictionary,
	deal_id: String,
	option_id: String
) -> Dictionary:
	return StreetDealLogic.select_street_deal(state, {
		"player_id": GameIds.PLAYER_HUMAN,
		"deal_id": deal_id,
		"option_id": option_id,
	})
