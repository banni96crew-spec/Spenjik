extends GutTest


func test_black_market_option_b_pays_and_adds_vp() -> void:
	var state: Dictionary = _state(
		StreetDealIds.BLACK_MARKET_CACHE, 4
	)
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 10
	var result: Dictionary = _select(
		state, StreetDealIds.BLACK_MARKET_CACHE,
		StreetDealOptionIds.OPTION_B
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["nal"], 4)
	assert_eq(human["vp"], 1)


func test_inside_contact_options_create_handoff_or_cash() -> void:
	var contact: Dictionary = _state(StreetDealIds.INSIDE_CONTACT, 8)
	var result: Dictionary = _select(
		contact, StreetDealIds.INSIDE_CONTACT,
		StreetDealOptionIds.OPTION_A
	)
	var offer: Dictionary = result["state"]["contacts"]["pending_offer"]
	assert_eq(offer["source"], StreetDealIds.INSIDE_CONTACT)
	assert_eq(offer["contact_offer_ids"], [])
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)["contacts"]["unlocked"],
		[]
	)
	var cash: Dictionary = _state(StreetDealIds.INSIDE_CONTACT, 8)
	var before: int = TestPlayers.find(
		cash, GameIds.PLAYER_HUMAN
	)["nal"]
	result = _select(
		cash, StreetDealIds.INSIDE_CONTACT,
		StreetDealOptionIds.OPTION_B
	)
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)["nal"],
		before + 4
	)
	assert_eq(result["state"]["contacts"]["pending_offer"], {})


func test_risky_contract_options_pay_vp_or_reward_stable_richest_ai() -> void:
	var paid: Dictionary = _state(StreetDealIds.RISKY_CONTRACT, 12)
	var human: Dictionary = TestPlayers.find(
		paid, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 10
	var result: Dictionary = _select(
		paid, StreetDealIds.RISKY_CONTRACT,
		StreetDealOptionIds.OPTION_A
	)
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["nal"], 7)
	assert_eq(human["vp"], 1)
	var reward: Dictionary = _state(StreetDealIds.RISKY_CONTRACT, 12)
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		TestPlayers.find(reward, ai_id)["nal"] = 7
	var random_before: Dictionary = reward["random"].duplicate(true)
	result = _select(
		reward, StreetDealIds.RISKY_CONTRACT,
		StreetDealOptionIds.OPTION_B
	)
	assert_eq(result["selected_ai_id"], GameIds.PLAYER_AI_1)
	assert_eq(result["state"]["random"], random_before)
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_AI_1
		)["nal"],
		8
	)
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)["nal"],
		25
	)


func test_turf_eight_changes_paid_effects_but_not_loan_debt() -> void:
	for pair: Array in [
		[StreetDealIds.DIRTY_TIP, StreetDealOptionIds.OPTION_A],
		[StreetDealIds.BLACK_MARKET_CACHE, StreetDealOptionIds.OPTION_B],
		[StreetDealIds.RISKY_CONTRACT, StreetDealOptionIds.OPTION_A],
	]:
		var state: Dictionary = _state(pair[0], 12)
		state["turf_level"] = 8
		for player: Dictionary in state["players"]:
			player["turf_level"] = 8
		var human_before: int = TestPlayers.find(
			state, GameIds.PLAYER_HUMAN
		)["nal"]
		var payment: int = StreetDealLogic.get_payment_amount(
			state, pair[0], pair[1], GameIds.PLAYER_HUMAN
		)
		var result: Dictionary = _select(state, pair[0], pair[1])
		assert_eq(
			TestPlayers.find(
				result["state"], GameIds.PLAYER_HUMAN
			)["nal"],
			human_before - payment
		)
	var loan: Dictionary = _state(StreetDealIds.LOAN_SHARK, 8)
	loan["turf_level"] = 8
	for player: Dictionary in loan["players"]:
		player["turf_level"] = 8
	var loan_result: Dictionary = _select(
		loan, StreetDealIds.LOAN_SHARK,
		StreetDealOptionIds.OPTION_A
	)
	assert_eq(
		TestPlayers.find(
			loan_result["state"], GameIds.PLAYER_HUMAN
		)["debts"][0]["amount_due"],
		12
	)


func _state(deal_id: String, round_number: int) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		"progression_%s" % deal_id, round_number
	)
	state["street_deals"]["current_deal_id"] = deal_id
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
