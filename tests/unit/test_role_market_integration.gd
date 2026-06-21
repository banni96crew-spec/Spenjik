extends GutTest


func test_merchant_purchase_consumes_flags_only_after_success() -> void:
	var state: Dictionary = _market_state(
		RoleIds.MERCHANT,
		[GameIds.CARD_INFORMANT, GameIds.CARD_THUG, GameIds.CARD_BRUISER]
	)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 0
	var before: Dictionary = state.duplicate(true)
	var failed: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_INFORMANT
	)
	assert_eq(failed["error"], ValidationErrors.NOT_ENOUGH_NAL)
	assert_eq(state, before)
	human["nal"] = 50
	var engine: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_INFORMANT
	)
	assert_eq(engine["price"], 4)
	assert_true(_human(engine)["role_flags"]["merchant_first_engine_discount_used"])
	var war: Dictionary = MarketLogic.buy_card(
		engine["state"], human["id"], GameIds.CARD_THUG
	)
	assert_eq(war["price"], 3)
	assert_true(
		_human(war)["role_flags"]["merchant_first_war_tax_applied_this_round"]
	)
	var second_war: Dictionary = MarketLogic.buy_card(
		war["state"], human["id"], GameIds.CARD_BRUISER
	)
	assert_eq(second_war["price"], 5)


func test_once_per_run_role_modifiers_consume_and_do_not_reapply() -> void:
	var cases: Array[Dictionary] = [
		{
			"role": RoleIds.ENFORCER,
			"first": GameIds.CARD_THUG,
			"second": GameIds.CARD_BRUISER,
			"first_price": 1,
			"second_price": 5,
			"flag": "enforcer_first_war_discount_used",
		},
		{
			"role": RoleIds.GRAY_CARDINAL,
			"first": GameIds.CARD_SABOTEUR,
			"second": GameIds.CARD_SABOTEUR,
			"first_price": 5,
			"second_price": 6,
			"flag": "gray_cardinal_first_saboteur_discount_used",
		},
		{
			"role": RoleIds.GRAY_CARDINAL,
			"first": GameIds.CARD_STASH,
			"second": GameIds.CARD_STASH,
			"first_price": 9,
			"second_price": 8,
			"flag": "gray_cardinal_first_stash_tax_used",
		},
		{
			"role": RoleIds.DISTRICT_BOSS,
			"first": GameIds.CARD_STASH,
			"second": GameIds.CARD_STASH,
			"first_price": 6,
			"second_price": 8,
			"flag": "district_boss_first_stash_discount_used",
		},
		{
			"role": RoleIds.DISTRICT_BOSS,
			"first": GameIds.CARD_LAUNDRY,
			"second": GameIds.CARD_LAUNDRY,
			"first_price": 9,
			"second_price": 10,
			"flag": "district_boss_first_laundry_tax_used",
		},
	]
	for item: Dictionary in cases:
		var state: Dictionary = _market_state(
			item["role"], [item["first"], item["second"]]
		)
		var first: Dictionary = MarketLogic.buy_card(
			state, GameIds.PLAYER_HUMAN, item["first"]
		)
		assert_true(first["ok"], str(item))
		assert_eq(first["price"], item["first_price"], str(item))
		assert_true(_human(first)["role_flags"][item["flag"]], str(item))
		_human(first)["purchased_this_round"] = []
		var second: Dictionary = MarketLogic.buy_card(
			first["state"], GameIds.PLAYER_HUMAN, item["second"]
		)
		assert_true(second["ok"], str(item))
		assert_eq(second["price"], item["second_price"], str(item))


func test_enforcer_laundry_tax_applies_to_every_purchase() -> void:
	var state: Dictionary = _market_state(
		RoleIds.ENFORCER, [GameIds.CARD_LAUNDRY]
	)
	var first: Dictionary = MarketLogic.buy_card(
		state, GameIds.PLAYER_HUMAN, GameIds.CARD_LAUNDRY
	)
	assert_eq(first["price"], 9)
	_human(first)["purchased_this_round"] = []
	var second: Dictionary = MarketLogic.buy_card(
		first["state"], GameIds.PLAYER_HUMAN, GameIds.CARD_LAUNDRY
	)
	assert_eq(second["price"], 11)


func test_accountant_requirement_and_gray_cardinal_bypass_cases() -> void:
	var merchant: Dictionary = _market_state(
		RoleIds.MERCHANT, [GameIds.CARD_ACCOUNTANT]
	)
	assert_eq(
		MarketLogic.buy_card(
			merchant, GameIds.PLAYER_HUMAN, GameIds.CARD_ACCOUNTANT
		)["error"],
		ValidationErrors.REQUIREMENT_NOT_MET
	)
	var gray: Dictionary = _market_state(
		RoleIds.GRAY_CARDINAL, [GameIds.CARD_ACCOUNTANT]
	)
	TestPlayers.find(gray, GameIds.PLAYER_HUMAN)["nal"] = 0
	var gray_before: Dictionary = gray.duplicate(true)
	var failed_gray: Dictionary = MarketLogic.buy_card(
		gray, GameIds.PLAYER_HUMAN, GameIds.CARD_ACCOUNTANT
	)
	assert_eq(failed_gray["error"], ValidationErrors.NOT_ENOUGH_NAL)
	assert_false(TestPlayers.find(
		gray, GameIds.PLAYER_HUMAN
	)["role_flags"]["gray_cardinal_first_accountant_bypass_used"])
	assert_eq(gray, gray_before)
	TestPlayers.find(gray, GameIds.PLAYER_HUMAN)["nal"] = 50
	var bought: Dictionary = MarketLogic.buy_card(
		gray, GameIds.PLAYER_HUMAN, GameIds.CARD_ACCOUNTANT
	)
	assert_true(bought["ok"], str(bought))
	assert_true(
		_human(bought)["role_flags"]["gray_cardinal_first_accountant_bypass_used"]
	)
	var second_state: Dictionary = bought["state"]
	_human(bought)["purchased_this_round"] = []
	var second: Dictionary = MarketLogic.buy_card(
		second_state, GameIds.PLAYER_HUMAN, GameIds.CARD_ACCOUNTANT
	)
	assert_eq(second["error"], ValidationErrors.REQUIREMENT_NOT_MET)
	var normal: Dictionary = _market_state(
		RoleIds.GRAY_CARDINAL, [GameIds.CARD_ACCOUNTANT]
	)
	TestPlayers.find(normal, GameIds.PLAYER_HUMAN)["vp"] = 1
	var normal_buy: Dictionary = MarketLogic.buy_card(
		normal, GameIds.PLAYER_HUMAN, GameIds.CARD_ACCOUNTANT
	)
	assert_true(normal_buy["ok"])
	assert_false(
		_human(normal_buy)["role_flags"]["gray_cardinal_first_accountant_bypass_used"]
	)


func test_district_boss_rebuild_discount_is_once_per_run() -> void:
	var state: Dictionary = _market_state(RoleIds.DISTRICT_BOSS, [])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 6
	human["status_buildings"]["workshop"] = 2
	human["status_buildings"]["can_rebuild_district_for_8"] = true
	var before: Dictionary = state.duplicate(true)
	var preview: Dictionary = PriceLogic.get_rebuild_price(
		state, GameIds.PLAYER_HUMAN
	)
	assert_eq(preview["final_rebuild_price"], 7)
	assert_eq(state, before)
	var failed: Dictionary = MarketLogic.rebuild_district_control(
		state, GameIds.PLAYER_HUMAN
	)
	assert_eq(failed["error"], ValidationErrors.NOT_ENOUGH_NAL)
	assert_false(
		human["role_flags"]["district_boss_rebuild_discount_used"]
	)
	assert_eq(state, before)
	human["nal"] = 20
	var first: Dictionary = MarketLogic.rebuild_district_control(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(first["ok"], str(first))
	assert_eq(first["price"], 7)
	assert_true(
		_human(first)["role_flags"]["district_boss_rebuild_discount_used"]
	)
	var next_state: Dictionary = first["state"]
	var next_human: Dictionary = _human(first)
	next_human["status_buildings"]["can_rebuild_district_for_8"] = true
	var second: Dictionary = MarketLogic.rebuild_district_control(
		next_state, GameIds.PLAYER_HUMAN
	)
	assert_true(second["ok"], str(second))
	assert_eq(second["price"], 8)


func _market_state(role_id: String, card_ids: Array[String]) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state(
		"role_market_%s" % role_id
	)
	state["selected_role_id"] = role_id
	var unique_ids: Array[String] = []
	for card_id: String in card_ids:
		if not unique_ids.has(card_id):
			unique_ids.append(card_id)
	state["market"]["always_available_card_ids"] = unique_ids.duplicate()
	state["market"]["rotating_card_ids"] = []
	state["market"]["all_available_card_ids"] = unique_ids.duplicate()
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 50
	return state


func _human(result: Dictionary) -> Dictionary:
	return TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
