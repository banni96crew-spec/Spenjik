extends GutTest


func test_resources_cover_levels_zero_through_ten_without_duplicates() -> void:
	var seen: Dictionary = {}
	for level: int in TurfLevelIds.ALL:
		var definition: TurfLevelDefinition = TurfLevelCatalog.get_by_level(level)
		assert_not_null(definition)
		assert_false(seen.has(level))
		seen[level] = true
	assert_eq(seen.size(), 11)


func test_turf_level_validation_range() -> void:
	assert_true(TurfLevelLogic.is_valid_turf_level(0))
	assert_true(TurfLevelLogic.is_valid_turf_level(10))
	assert_false(TurfLevelLogic.is_valid_turf_level(-1))
	assert_false(TurfLevelLogic.is_valid_turf_level(11))


func test_apply_setup_modifiers_rejects_invalid_turf_level_without_mutation() -> void:
	var state: Dictionary = _setup_state(3, RoleIds.MERCHANT)
	state["turf_level"] = 11
	for player: Dictionary in state["players"]:
		player["turf_level"] = 11
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = TurfLevelLogic.apply_setup_modifiers(state)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.INVALID_TURF_LEVEL)
	assert_eq(state, before)


func test_level_one_gives_all_ai_extra_nal_only() -> void:
	var state: Dictionary = _setup_state(1, RoleIds.MERCHANT)
	var result: Dictionary = TurfLevelLogic.apply_setup_modifiers(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["effects_applied"], ["ai_starting_nal_bonus"])
	assert_eq(TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)["nal"], 7)
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		assert_eq(TestPlayers.find(result["state"], ai_id)["nal"], 6)


func test_level_two_requires_exactly_one_strong_ai() -> void:
	var missing: Dictionary = _setup_state(2, RoleIds.MERCHANT)
	TestPlayers.find(missing, GameIds.PLAYER_AI_1)["is_strong_ai"] = false
	var missing_before: Dictionary = missing.duplicate(true)
	var missing_result: Dictionary = TurfLevelLogic.apply_setup_modifiers(missing)
	assert_false(missing_result["ok"])
	assert_eq(missing_result["error"], ValidationErrors.INVALID_AI_STATE)
	assert_eq(missing, missing_before)
	var duplicate: Dictionary = _setup_state(2, RoleIds.MERCHANT)
	TestPlayers.find(duplicate, GameIds.PLAYER_AI_2)["is_strong_ai"] = true
	var duplicate_before: Dictionary = duplicate.duplicate(true)
	var duplicate_result: Dictionary = TurfLevelLogic.apply_setup_modifiers(duplicate)
	assert_false(duplicate_result["ok"])
	assert_eq(duplicate_result["error"], ValidationErrors.INVALID_AI_STATE)
	assert_eq(duplicate, duplicate_before)


func test_level_two_and_three_apply_cumulative_setup_modifiers() -> void:
	var state: Dictionary = _setup_state(3, RoleIds.GRAY_CARDINAL)
	var result: Dictionary = TurfLevelLogic.apply_setup_modifiers(state)
	assert_true(result["ok"], str(result))
	assert_eq(
		result["effects_applied"],
		[
			"ai_starting_nal_bonus",
			"strong_ai_starting_vp_bonus",
			"human_starting_nal_penalty",
		]
	)
	assert_eq(TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)["vp"], 1)
	assert_eq(TestPlayers.find(result["state"], GameIds.PLAYER_AI_2)["vp"], 0)
	assert_eq(TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)["nal"], 3)


func test_turf_flags_initialize_and_reset_each_round() -> void:
	var state: Dictionary = _setup_state(6, RoleIds.MERCHANT)
	var setup: Dictionary = TurfLevelLogic.apply_setup_modifiers(state)
	var player: Dictionary = TestPlayers.find(setup["state"], GameIds.PLAYER_AI_1)
	player["turf_flags"]["ai_first_war_discount_used_this_round"] = true
	TurfLevelLogic.reset_round_turf_flags(player)
	assert_false(player["turf_flags"]["ai_first_war_discount_used_this_round"])


func test_runtime_helpers_for_levels_four_through_nine() -> void:
	assert_eq(TurfLevelLogic.get_rotating_market_slot_count(3), 4)
	assert_eq(TurfLevelLogic.get_rotating_market_slot_count(4), 3)
	var state: Dictionary = TestGameStateFactory.base_state("turf_helpers")
	state["turf_level"] = 5
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	assert_eq(TurfLevelLogic.get_cops_upkeep_interval(state, human), 2)
	assert_eq(TurfLevelLogic.get_cops_upkeep_interval(state, ai), 3)
	assert_eq(TurfLevelLogic.get_strong_ai_victory_contact_offer_count(6), 3)
	assert_eq(TurfLevelLogic.get_strong_ai_victory_contact_offer_count(7), 2)
	state["turf_level"] = 8
	human["vp"] = 5
	ai["vp"] = 4
	assert_eq(TurfLevelLogic.get_street_deal_payment_delta(state, human), 1)
	assert_eq(TurfLevelLogic.get_street_deal_payment_delta(state, ai), 0)


func test_level_nine_war_multiplier_requires_strict_human_lead_and_war_card() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("turf_level_9")
	state["turf_level"] = 9
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	human["vp"] = 5
	ai["vp"] = 4
	var war_card: CardDefinition = CardCatalog.get_by_id(GameIds.CARD_THUG)
	var status_card: CardDefinition = CardCatalog.get_by_id(GameIds.CARD_STASH)
	assert_eq(
		TurfLevelLogic.get_ai_war_purchase_weight_multiplier(state, war_card),
		1.2
	)
	assert_eq(
		TurfLevelLogic.get_ai_war_purchase_weight_multiplier(state, status_card),
		1.0
	)
	ai["vp"] = 5
	assert_eq(
		TurfLevelLogic.get_ai_war_purchase_weight_multiplier(state, war_card),
		1.0
	)
	state["turf_level"] = 8
	assert_eq(
		TurfLevelLogic.get_ai_war_purchase_weight_multiplier(state, war_card),
		1.0
	)


func test_level_six_discount_preview_and_consume() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("turf_level_6")
	state["turf_level"] = 6
	state["market"]["all_available_card_ids"] = [GameIds.CARD_THUG]
	state["market"]["always_available_card_ids"] = [GameIds.CARD_THUG]
	state["market"]["rotating_card_ids"] = []
	for player: Dictionary in state["players"]:
		player["turf_level"] = 6
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	ai["nal"] = 10
	var preview: Dictionary = PriceLogic.get_card_price(
		state, ai["id"], GameIds.CARD_THUG
	)
	assert_eq(preview["modifiers"].size(), 1)
	assert_eq(preview["modifiers"][0]["source"], "turf_level")
	var purchase: Dictionary = MarketLogic.buy_card(
		state, ai["id"], GameIds.CARD_THUG
	)
	assert_true(purchase["ok"], str(purchase))
	assert_true(
		TestPlayers.find(purchase["state"], ai["id"])
		["turf_flags"]["ai_first_war_discount_used_this_round"]
	)


func test_level_eight_payment_delta_and_level_ten_tie_break() -> void:
	var state: Dictionary = TestGameStateFactory.street_deal_state("turf_level_8")
	state["turf_level"] = 8
	for player: Dictionary in state["players"]:
		player["turf_level"] = 8
	assert_eq(
		StreetDealLogic.get_payment_amount(
			state,
			StreetDealIds.DIRTY_TIP,
			StreetDealOptionIds.OPTION_A,
			GameIds.PLAYER_HUMAN
		),
		4
	)
	var tie_state: Dictionary = TestGameStateFactory.base_state("turf_level_10")
	tie_state["turf_level"] = 10
	for player: Dictionary in tie_state["players"]:
		player["turf_level"] = 10
		player["vp"] = 8
	TestPlayers.find(tie_state, GameIds.PLAYER_HUMAN)["nal"] = 20
	TestPlayers.find(tie_state, GameIds.PLAYER_AI_1)["nal"] = 5
	TestPlayers.find(tie_state, GameIds.PLAYER_AI_2)["nal"] = 10
	var winner: Dictionary = WinnerResolver.resolve(tie_state)
	assert_true(winner["ok"], str(winner))
	assert_eq(winner["winner_id"], GameIds.PLAYER_AI_2)
	assert_true(winner["game_result"]["turf_level_10_ai_win_applied"])


func test_contact_offer_count_matches_root_validator() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("turf_contact")
	state["turf_level"] = 7
	state["contacts"]["pending_offer"] = GameStateFactory.create_contact_offer_state(
		GameIds.PLAYER_HUMAN, "strong_ai_victory", ["a", "b"], 1
	)
	assert_true(GameStateRootValidator.validate_contact_offer_for_turf(state)["ok"])
	assert_eq(
		ContactOfferLogic.get_strong_ai_offer_count(state),
		TurfLevelLogic.get_strong_ai_victory_contact_offer_count(7)
	)


func test_phase_state_helper_resets_turf_flags_through_turf_logic() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("turf_reset")
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	ai["turf_flags"]["ai_first_war_discount_used_this_round"] = true
	PhaseStateHelper.apply_round_reset(state)
	assert_false(ai["turf_flags"]["ai_first_war_discount_used_this_round"])


func _setup_state(turf_level: int, role_id: String) -> Dictionary:
	var state: Dictionary = GameStateFactory.create_new_game_state(
		"turf_setup_%d_%s" % [turf_level, role_id], turf_level
	)
	var role_result: Dictionary = RoleSetupResolver.apply(state, role_id)
	assert_true(role_result["ok"], str(role_result))
	state = role_result["state"]
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["is_strong_ai"] = true
	return state
