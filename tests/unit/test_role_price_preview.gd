extends GutTest


func test_price_preview_contains_role_first_and_clamps_without_mutation() -> void:
	var state: Dictionary = _market_state(
		RoleIds.DISTRICT_BOSS, [GameIds.CARD_STASH]
	)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["contacts"]["unlocked"] = [ContactIds.CORRUPT_CLERK]
	human["temporary_modifiers"] = [
		GameStateFactory.create_temporary_modifier({
			"id": "cheap_player_1_round_1",
			"type": ModifierTypes.CARD_PRICE_DELTA,
			"source": "test", "owner_player_id": human["id"],
			"affected_card_id": GameIds.CARD_STASH, "delta": -20,
			"multiplier": 1.0, "min_value": 1,
			"expires_at": "next_purchase",
		}),
	]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = PriceLogic.get_card_price(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_eq(result["modifiers"][0]["source"], "role")
	assert_eq(result["modifiers"][1]["source"], "contact")
	assert_eq(result["modifiers"][2]["source"], "test")
	assert_eq(result["final_price"], 1)
	assert_eq(state, before)
	assert_eq(state["random"], before["random"])


func test_ai_never_receives_human_role_price_or_flag_consumption() -> void:
	var state: Dictionary = _market_state(
		RoleIds.ENFORCER, [GameIds.CARD_LAUNDRY]
	)
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	ai["nal"] = 20
	var result: Dictionary = PriceLogic.get_card_price(
		state, ai["id"], GameIds.CARD_LAUNDRY
	)
	assert_eq(result["final_price"], 8)
	assert_true(result["modifiers"].is_empty())
	var before_flags: Dictionary = ai["role_flags"].duplicate(true)
	var bought: Dictionary = MarketLogic.buy_card(
		state, ai["id"], GameIds.CARD_LAUNDRY
	)
	assert_true(bought["ok"])
	assert_eq(
		TestPlayers.find(bought["state"], ai["id"])["role_flags"],
		before_flags
	)


func _market_state(role_id: String, card_ids: Array[String]) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state(
		"role_preview_%s" % role_id
	)
	state["selected_role_id"] = role_id
	state["market"]["always_available_card_ids"] = card_ids.duplicate()
	state["market"]["rotating_card_ids"] = []
	state["market"]["all_available_card_ids"] = card_ids.duplicate()
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 50
	return state
