extends GutTest


func test_generation_is_deterministic_and_consumes_one_step() -> void:
	var first: Dictionary = _empty_deal_state("deal_generation", 4)
	var second: Dictionary = first.duplicate(true)
	var first_result: Dictionary = StreetDealLogic.generate_street_deal(first)
	var second_result: Dictionary = StreetDealLogic.generate_street_deal(second)
	assert_true(first_result["ok"], str(first_result))
	assert_eq(
		first_result["current_deal_id"],
		second_result["current_deal_id"]
	)
	assert_eq(first_result["steps_used"], 1)
	assert_eq(
		first_result["state"]["random"]["step"],
		first["random"]["step"] + 1
	)
	assert_eq(first, second)
	assert_eq(
		first_result["log_entries"][0]["event_type"],
		LogEventTypes.STREET_DEAL_OFFERED
	)


func test_generation_validates_phase_round_and_no_eligible_pool() -> void:
	var wrong_phase: Dictionary = TestGameStateFactory.market_state(
		"deal_wrong_phase", 4
	)
	var before: Dictionary = wrong_phase.duplicate(true)
	var result: Dictionary = StreetDealLogic.generate_street_deal(
		wrong_phase
	)
	assert_eq(result["error"], ValidationErrors.INVALID_PHASE)
	assert_eq(wrong_phase, before)
	var wrong_round: Dictionary = _empty_deal_state("deal_wrong_round", 5)
	before = wrong_round.duplicate(true)
	result = StreetDealLogic.generate_street_deal(wrong_round)
	assert_eq(
		result["error"],
		ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE
	)
	assert_eq(wrong_round, before)
	var exhausted: Dictionary = _empty_deal_state("deal_exhausted", 12)
	exhausted["street_deals"]["used_deal_ids"] = (
		StreetDealIds.ALL.duplicate()
	)
	before = exhausted.duplicate(true)
	result = StreetDealLogic.generate_street_deal(exhausted)
	assert_eq(
		result["error"],
		ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE
	)
	assert_eq(exhausted, before)


func test_eligibility_filters_min_round_used_and_only_blocked_loan() -> void:
	var state: Dictionary = _empty_deal_state("deal_filters", 8)
	state["street_deals"]["used_deal_ids"] = [
		StreetDealIds.DIRTY_TIP
	]
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["debts"] = [DebtLogic.create_debt(
		"loan_shark_round_8_option_a", 12, 10,
		{"lose_all_nal": true, "vp_delta": -1}, 8
	)]
	var ids: Array[String] = StreetDealLogic.get_eligible_deal_ids(
		state, GameIds.PLAYER_HUMAN
	)
	assert_does_not_have(ids, StreetDealIds.LOAN_SHARK)
	assert_does_not_have(ids, StreetDealIds.DIRTY_TIP)
	assert_has(ids, StreetDealIds.CHEAP_PROTECTION)
	assert_has(ids, StreetDealIds.BLACK_MARKET_CACHE)
	assert_has(ids, StreetDealIds.INSIDE_CONTACT)
	assert_does_not_have(ids, StreetDealIds.RISKY_CONTRACT)


func test_only_human_can_choose_and_failure_is_deeply_read_only() -> void:
	var state: Dictionary = _offered_state(
		StreetDealIds.DIRTY_TIP, 4, "deal_human_only"
	)
	var before: Dictionary = state.duplicate(true)
	var ai_result: Dictionary = StreetDealLogic.select_street_deal(
		state,
		_payload(
			GameIds.PLAYER_AI_1,
			StreetDealIds.DIRTY_TIP,
			StreetDealOptionIds.OPTION_B
		)
	)
	assert_eq(ai_result["error"], ValidationErrors.INVALID_TARGET)
	assert_eq(state, before)
	var invalid: Dictionary = StreetDealLogic.select_street_deal(
		state,
		_payload(GameIds.PLAYER_HUMAN, StreetDealIds.DIRTY_TIP, "A")
	)
	assert_eq(
		invalid["error"],
		ValidationErrors.INVALID_STREET_DEAL_OPTION
	)
	assert_eq(state, before)


func test_success_records_choice_used_id_and_contract_hook() -> void:
	var state: Dictionary = _offered_state(
		StreetDealIds.BLACK_MARKET_CACHE, 4, "deal_success"
	)
	var result: Dictionary = StreetDealLogic.select_street_deal(
		state,
		_payload(
			GameIds.PLAYER_HUMAN,
			StreetDealIds.BLACK_MARKET_CACHE,
			StreetDealOptionIds.OPTION_A
		)
	)
	assert_true(result["ok"], str(result))
	assert_eq(
		result["state"]["street_deals"]["choices_by_player"][
			GameIds.PLAYER_HUMAN
		],
		StreetDealOptionIds.OPTION_A
	)
	assert_has(
		result["state"]["street_deals"]["used_deal_ids"],
		StreetDealIds.BLACK_MARKET_CACHE
	)
	assert_eq(result["state"]["street_deals"]["current_deal_id"], "")
	assert_eq(result["contract_results"].size(), 1)
	assert_eq(
		result["log_entries"][-1]["event_type"],
		LogEventTypes.STREET_DEAL_RESOLVED
	)


func test_payment_and_duplicate_modifier_fail_without_mutation() -> void:
	var payment: Dictionary = _offered_state(
		StreetDealIds.DIRTY_TIP, 4, "deal_payment_failure"
	)
	TestPlayers.find(
		payment, GameIds.PLAYER_HUMAN
	)["nal"] = 2
	var before: Dictionary = payment.duplicate(true)
	var result: Dictionary = StreetDealLogic.select_street_deal(
		payment,
		_payload(
			GameIds.PLAYER_HUMAN,
			StreetDealIds.DIRTY_TIP,
			StreetDealOptionIds.OPTION_A
		)
	)
	assert_eq(result["error"], ValidationErrors.NOT_ENOUGH_NAL)
	assert_eq(payment, before)
	var duplicate_state: Dictionary = _offered_state(
		StreetDealIds.CHEAP_PROTECTION, 4, "deal_modifier_failure"
	)
	TestPlayers.find(
		duplicate_state, GameIds.PLAYER_HUMAN
	)["temporary_modifiers"] = [
		GameStateFactory.create_temporary_modifier({
			"id": "cheap_protection_player_1_round_4",
			"type": ModifierTypes.NEXT_DEFENSE_CARD_PRICE_DELTA,
			"source": StreetDealIds.CHEAP_PROTECTION,
			"owner_player_id": GameIds.PLAYER_HUMAN,
			"affected_card_type": CardTypes.DEFENSE,
			"delta": -2,
			"multiplier": 1.0,
			"min_value": 1,
			"expires_at": "next_purchase",
		})
	]
	before = duplicate_state.duplicate(true)
	result = StreetDealLogic.select_street_deal(
		duplicate_state,
		_payload(
			GameIds.PLAYER_HUMAN,
			StreetDealIds.CHEAP_PROTECTION,
			StreetDealOptionIds.OPTION_A
		)
	)
	assert_eq(result["error"], ValidationErrors.INVALID_MODIFIER_STATE)
	assert_eq(duplicate_state, before)


func _empty_deal_state(game_seed: String, round_number: int) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		game_seed, round_number
	)
	state["street_deals"] = StreetDealLogic.create_empty_state()
	return state


func _offered_state(
	deal_id: String,
	round_number: int,
	game_seed: String
) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		game_seed, round_number
	)
	state["street_deals"]["current_deal_id"] = deal_id
	return state


func _payload(
	player_id: String,
	deal_id: String,
	option_id: String
) -> Dictionary:
	return {
		"player_id": player_id,
		"deal_id": deal_id,
		"option_id": option_id,
	}
