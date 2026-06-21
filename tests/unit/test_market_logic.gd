extends GutTest


func test_market_generation_is_deterministic_unique_and_uses_exact_steps() -> void:
	for turf_level: int in [0, 4]:
		var state: Dictionary = _income_state("market_%d" % turf_level, turf_level)
		var before: Dictionary = state.duplicate(true)
		var first: Dictionary = MarketLogic.generate_market(state)
		var second: Dictionary = MarketLogic.generate_market(state)
		var slots: int = 3 if turf_level >= 4 else 4
		assert_true(first["ok"], str(first))
		assert_eq(first["market"], second["market"])
		assert_eq(first["steps_used"], slots)
		assert_eq(first["random"]["step"], before["random"]["step"] + slots)
		assert_eq(
			first["market"]["always_available_card_ids"],
			MarketLogic.ALWAYS_AVAILABLE_CARD_IDS
		)
		assert_eq(first["market"]["rotating_card_ids"].size(), slots)
		assert_eq(
			first["market"]["all_available_card_ids"].size(),
			MarketLogic.ALWAYS_AVAILABLE_CARD_IDS.size() + slots
		)
		for card_id: String in first["market"]["all_available_card_ids"]:
			assert_true(GameIds.CARD_IDS.has(card_id))
		for card_id: String in MarketLogic.ALWAYS_AVAILABLE_CARD_IDS:
			assert_false(MarketLogic.ROTATING_MARKET_POOL.has(card_id))
		assert_eq(state, before)


func test_purchase_validation_errors_do_not_mutate_state() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_STASH])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 0
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_eq(result["error"], ValidationErrors.NOT_ENOUGH_NAL)
	assert_eq(state, before)
	human["nal"] = 20
	human["purchased_this_round"] = [GameIds.CARD_STASH]
	before = state.duplicate(true)
	result = MarketLogic.buy_card(state, human["id"], GameIds.CARD_STASH)
	assert_eq(
		result["error"],
		ValidationErrors.CARD_ALREADY_PURCHASED_THIS_ROUND
	)
	assert_eq(state, before)
	result = MarketLogic.buy_card(state, human["id"], GameIds.CARD_THUG)
	assert_eq(
		result["error"],
		ValidationErrors.CARD_NOT_AVAILABLE_IN_MARKET
	)


func test_purchase_places_each_card_category_and_validates_requirements() -> void:
	var cases: Array[Dictionary] = [
		{"id": GameIds.CARD_INFORMANT, "path": "informers", "value": 1},
		{"id": GameIds.CARD_STASH, "path": "stash", "value": 1},
		{"id": GameIds.CARD_COPS, "path": "cops_active", "value": true},
		{"id": GameIds.CARD_THUG, "path": "hand", "value": GameIds.CARD_THUG},
	]
	for item: Dictionary in cases:
		var state: Dictionary = _market_state([item["id"]])
		var result: Dictionary = MarketLogic.buy_card(
			state, GameIds.PLAYER_HUMAN, item["id"]
		)
		assert_true(result["ok"], "%s: %s" % [item["id"], result])
		var player: Dictionary = TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)
		if item["path"] == "informers":
			assert_eq(player["engine"][item["path"]], item["value"])
		elif item["path"] == "stash":
			assert_eq(player["status_buildings"][item["path"]], item["value"])
			assert_eq(player["vp"], 1)
		elif item["path"] == "cops_active":
			assert_eq(player["defense"][item["path"]], item["value"])
		else:
			assert_true(player["hand"].has(item["value"]))
	var accountant: Dictionary = _market_state([GameIds.CARD_ACCOUNTANT])
	assert_eq(
		MarketLogic.can_buy_card(
			accountant, GameIds.PLAYER_HUMAN, GameIds.CARD_ACCOUNTANT
		)["error"],
		ValidationErrors.REQUIREMENT_NOT_MET
	)


func test_depleted_cartel_reactivates_and_active_limits_fail() -> void:
	var state: Dictionary = _market_state([
		GameIds.CARD_CARTEL, GameIds.CARD_BROTHEL,
	])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["defense"]["cartel_state"] = DefenseStates.DEPLETED
	var result: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_CARTEL
	)
	assert_true(result["ok"])
	assert_eq(
		TestPlayers.find(result["state"], human["id"])["defense"]["cartel_state"],
		DefenseStates.ACTIVE
	)
	human["engine"]["brothel"] = true
	var before: Dictionary = state.duplicate(true)
	result = MarketLogic.buy_card(state, human["id"], GameIds.CARD_BROTHEL)
	assert_eq(result["error"], ValidationErrors.CARD_LIMIT_REACHED)
	assert_eq(state, before)


func test_corrupt_clerk_consumes_only_after_successful_status_purchase() -> void:
	var state: Dictionary = _market_state([
		GameIds.CARD_STASH, GameIds.CARD_THUG,
	])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["contacts"]["unlocked"] = [ContactIds.CORRUPT_CLERK]
	human["nal"] = 0
	var failed: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_false(failed["ok"])
	assert_false(human["role_flags"]["used_one_time_contact_bonus"])
	human["nal"] = 20
	var war: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_THUG
	)
	assert_false(
		TestPlayers.find(
			war["state"], human["id"]
		)["role_flags"]["used_one_time_contact_bonus"]
	)
	var bought: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_true(
		TestPlayers.find(
			bought["state"], human["id"]
		)["role_flags"]["used_one_time_contact_bonus"]
	)


func test_successful_matching_purchase_consumes_temporary_and_turf_flags() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_THUG])
	state["turf_level"] = 6
	for player: Dictionary in state["players"]:
		player["turf_level"] = 6
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	ai["temporary_modifiers"] = [
		GameStateFactory.create_temporary_modifier({
			"id": "cheap_ai_1_round_1",
			"type": ModifierTypes.NEXT_WAR_CARD_PRICE_DELTA,
			"source": "test", "owner_player_id": ai["id"],
			"affected_card_type": CardTypes.WAR, "delta": -1,
			"multiplier": 1.0, "min_value": 1,
			"expires_at": "next_purchase",
		}),
	]
	var result: Dictionary = MarketLogic.buy_card(
		state, ai["id"], GameIds.CARD_THUG
	)
	assert_true(result["ok"], str(result))
	var updated: Dictionary = TestPlayers.find(result["state"], ai["id"])
	assert_true(updated["turf_flags"]["ai_first_war_discount_used_this_round"])
	assert_true(updated["temporary_modifiers"][0]["consumed"])


func test_rebuild_is_dedicated_atomic_action() -> void:
	var state: Dictionary = _market_state([])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 8
	human["status_buildings"]["workshop"] = 1
	human["status_buildings"]["can_rebuild_district_for_8"] = true
	var result: Dictionary = MarketLogic.rebuild_district_control(
		state, human["id"]
	)
	assert_true(result["ok"], str(result))
	var rebuilt: Dictionary = TestPlayers.find(result["state"], human["id"])
	assert_eq(rebuilt["nal"], 0)
	assert_eq(rebuilt["vp"], 3)
	assert_eq(rebuilt["status_buildings"]["district_control"], 1)
	assert_false(rebuilt["status_buildings"]["can_rebuild_district_for_8"])
	human["status_buildings"]["can_rebuild_district_for_8"] = false
	var before: Dictionary = state.duplicate(true)
	var failed: Dictionary = MarketLogic.rebuild_district_control(
		state, human["id"]
	)
	assert_eq(failed["error"], ValidationErrors.REQUIREMENT_NOT_MET)
	assert_eq(state, before)
	human["status_buildings"]["can_rebuild_district_for_8"] = true
	human["nal"] = 7
	before = state.duplicate(true)
	failed = MarketLogic.rebuild_district_control(state, human["id"])
	assert_eq(failed["error"], ValidationErrors.NOT_ENOUGH_NAL)
	assert_eq(state, before)


func _market_state(card_ids: Array[String]) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state("purchase_state")
	state["market"]["always_available_card_ids"] = card_ids.duplicate()
	state["market"]["rotating_card_ids"] = []
	state["market"]["all_available_card_ids"] = card_ids.duplicate()
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 50
	return state


func _income_state(game_seed: String, turf_level: int) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.base_state(game_seed)
	state["turf_level"] = turf_level
	for player: Dictionary in state["players"]:
		player["turf_level"] = turf_level
	return state
