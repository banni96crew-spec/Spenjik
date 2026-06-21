extends GutTest


func test_role_ids_and_full_flag_shape_are_valid() -> void:
	for role_id: String in RoleIds.ALL:
		assert_true(RoleLogic.is_valid_role_id(role_id))
	assert_false(RoleLogic.is_valid_role_id(""))
	assert_false(RoleLogic.is_valid_role_id("unknown_role"))
	var flags: Dictionary = RoleLogic.create_empty_role_flags()
	assert_true(GameStateValidator.validate_role_flags(flags)["ok"])
	assert_true(flags.has("gray_cardinal_first_stash_tax_used"))
	assert_true(flags.has("district_boss_first_laundry_tax_used"))
	assert_eq(flags.size(), 12)


func test_setup_applies_starting_effects_only_to_human() -> void:
	var expected_nal: Dictionary = {
		RoleIds.MERCHANT: 7,
		RoleIds.ENFORCER: 5,
		RoleIds.GRAY_CARDINAL: 4,
		RoleIds.DISTRICT_BOSS: 5,
	}
	for role_id: String in RoleIds.ALL:
		var state: Dictionary = TestGameStateFactory.setup_state(
			"role_setup_%s" % role_id
		)
		var ai_before: Array[Dictionary] = []
		for ai_id: String in GameIds.AI_PLAYER_IDS:
			ai_before.append(TestPlayers.find(state, ai_id).duplicate(true))
		var result: Dictionary = RoleLogic.apply_role_setup(state, role_id)
		assert_true(result["ok"], "%s: %s" % [role_id, result])
		assert_eq(result["state"]["selected_role_id"], role_id)
		var human: Dictionary = TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)
		assert_eq(human["nal"], expected_nal[role_id])
		assert_eq(
			human["defense"]["cops_active"],
			role_id == RoleIds.ENFORCER
		)
		assert_eq(human["defense"]["cops_timer"], 0)
		for index: int in GameIds.AI_PLAYER_IDS.size():
			assert_eq(
				TestPlayers.find(
					result["state"], GameIds.AI_PLAYER_IDS[index]
				),
				ai_before[index]
			)


func test_failed_setup_is_read_only_and_uses_canonical_errors() -> void:
	var state: Dictionary = TestGameStateFactory.setup_state("role_invalid")
	var before: Dictionary = state.duplicate(true)
	var invalid: Dictionary = RoleLogic.apply_role_setup(state, "")
	assert_eq(invalid["error"], ValidationErrors.INVALID_ROLE_ID)
	assert_eq(state, before)
	var missing_human: Dictionary = state.duplicate(true)
	missing_human["players"].remove_at(0)
	var missing_before: Dictionary = missing_human.duplicate(true)
	var missing: Dictionary = RoleLogic.apply_role_setup(
		missing_human, RoleIds.MERCHANT
	)
	assert_eq(missing["error"], ValidationErrors.INVALID_TARGET)
	assert_eq(missing_human, missing_before)
	var incomplete: Dictionary = state.duplicate(true)
	TestPlayers.find(incomplete, GameIds.PLAYER_HUMAN)["role_flags"].erase(
		"gray_cardinal_first_stash_tax_used"
	)
	var incomplete_before: Dictionary = incomplete.duplicate(true)
	var rejected: Dictionary = RoleLogic.apply_role_setup(
		incomplete, RoleIds.GRAY_CARDINAL
	)
	assert_eq(rejected["error"], ValidationErrors.REQUIREMENT_NOT_MET)
	assert_eq(incomplete, incomplete_before)


func test_all_card_price_modifiers_match_role_rules() -> void:
	var cases: Array[Dictionary] = [
		{"role": RoleIds.MERCHANT, "card": GameIds.CARD_INFORMANT, "delta": -1},
		{"role": RoleIds.MERCHANT, "card": GameIds.CARD_THUG, "delta": 1},
		{"role": RoleIds.ENFORCER, "card": GameIds.CARD_THUG, "delta": -1},
		{"role": RoleIds.ENFORCER, "card": GameIds.CARD_LAUNDRY, "delta": 1},
		{"role": RoleIds.GRAY_CARDINAL, "card": GameIds.CARD_SABOTEUR, "delta": -1},
		{"role": RoleIds.GRAY_CARDINAL, "card": GameIds.CARD_STASH, "delta": 1},
		{"role": RoleIds.DISTRICT_BOSS, "card": GameIds.CARD_STASH, "delta": -2},
		{"role": RoleIds.DISTRICT_BOSS, "card": GameIds.CARD_LAUNDRY, "delta": 1},
	]
	for item: Dictionary in cases:
		var state: Dictionary = _committed_role_state(item["role"])
		var player: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
		var before: Dictionary = state.duplicate(true)
		var modifiers: Array[Dictionary] = RoleLogic.get_role_price_modifiers(
			state, player, CardCatalog.get_by_id(item["card"])
		)
		assert_eq(modifiers.size(), 1, str(item))
		assert_eq(modifiers[0]["source"], "role")
		assert_eq(modifiers[0]["role_id"], item["role"])
		assert_eq(modifiers[0]["delta"], item["delta"])
		assert_eq(state, before)


func test_used_once_flags_disable_modifiers_but_laundry_tax_recurs() -> void:
	var merchant: Dictionary = _committed_role_state(RoleIds.MERCHANT)
	var human: Dictionary = TestPlayers.find(merchant, GameIds.PLAYER_HUMAN)
	human["role_flags"]["merchant_first_engine_discount_used"] = true
	assert_true(RoleLogic.get_role_price_modifiers(
		merchant, human, CardCatalog.get_by_id(GameIds.CARD_INFORMANT)
	).is_empty())
	var enforcer: Dictionary = _committed_role_state(RoleIds.ENFORCER)
	human = TestPlayers.find(enforcer, GameIds.PLAYER_HUMAN)
	human["engine"]["laundries"] = 3
	assert_eq(RoleLogic.get_role_price_modifiers(
		enforcer, human, CardCatalog.get_by_id(GameIds.CARD_LAUNDRY)
	)[0]["delta"], 1)
	var ai: Dictionary = TestPlayers.find(enforcer, GameIds.PLAYER_AI_1)
	assert_true(RoleLogic.get_role_price_modifiers(
		enforcer, ai, CardCatalog.get_by_id(GameIds.CARD_LAUNDRY)
	).is_empty())


func test_accountant_bypass_requires_gray_cardinal_zero_vp_and_unused_flag() -> void:
	var state: Dictionary = _committed_role_state(RoleIds.GRAY_CARDINAL)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	assert_true(RoleLogic.can_bypass_purchase_requirement(
		state, human, GameIds.CARD_ACCOUNTANT, ""
	))
	human["vp"] = 1
	assert_false(RoleLogic.can_bypass_purchase_requirement(
		state, human, GameIds.CARD_ACCOUNTANT, ""
	))
	human["vp"] = 0
	human["role_flags"]["gray_cardinal_first_accountant_bypass_used"] = true
	assert_false(RoleLogic.can_bypass_purchase_requirement(
		state, human, GameIds.CARD_ACCOUNTANT, ""
	))
	state["selected_role_id"] = RoleIds.MERCHANT
	assert_false(RoleLogic.can_bypass_purchase_requirement(
		state, human, GameIds.CARD_ACCOUNTANT, ""
	))


func test_round_reset_changes_only_merchant_round_flag() -> void:
	var player: Dictionary = TestPlayers.player(GameIds.PLAYER_HUMAN)
	for key: String in player["role_flags"]:
		player["role_flags"][key] = true
	var reset: Dictionary = RoleLogic.reset_round_role_flags(
		player, RoleIds.MERCHANT
	)
	assert_false(
		reset["role_flags"]["merchant_first_war_tax_applied_this_round"]
	)
	for key: String in reset["role_flags"]:
		if key != "merchant_first_war_tax_applied_this_round":
			assert_true(reset["role_flags"][key], key)
	assert_true(
		player["role_flags"]["merchant_first_war_tax_applied_this_round"]
	)


func _committed_role_state(role_id: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.base_state(
		"role_%s" % role_id
	)
	state["selected_role_id"] = role_id
	return state
