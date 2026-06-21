extends GutTest


func test_thug_steals_up_to_six_and_respects_protected_nal() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 12
	target["engine"]["accountants"] = 2
	var result: Dictionary = CombatEngine.resolve_attack(
		state, CombatTestHelper.payload(GameIds.CARD_THUG)
	)
	assert_true(result["ok"], str(result))
	assert_eq(result["effect_result"]["protected_nal"], 6)
	assert_eq(result["effect_result"]["stolen_nal"], 6)
	assert_eq(CombatTestHelper.target(result["state"])["nal"], 6)
	assert_eq(CombatTestHelper.attacker(result["state"])["nal"], 11)
	assert_eq(result["cards_consumed"], [GameIds.CARD_THUG])


func test_thug_can_steal_zero_and_still_resolves_and_consumes() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 4
	target["engine"]["accountants"] = 1
	var result: Dictionary = CombatEngine.resolve_attack(
		state, CombatTestHelper.payload(GameIds.CARD_THUG)
	)
	assert_true(result["success"])
	assert_eq(result["effect_result"]["stolen_nal"], 0)
	assert_eq(CombatTestHelper.attacker(result["state"])["hand"], [])
	assert_eq(
		CombatTestHelper.target(result["state"])["last_attacked_by"],
		GameIds.PLAYER_HUMAN
	)


func test_cops_block_thug_without_consuming_cops() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG, GameIds.CARD_THUG]
	)
	CombatTestHelper.target(state)["defense"]["cops_active"] = true
	var result: Dictionary = CombatEngine.resolve_attack(
		state, CombatTestHelper.payload(GameIds.CARD_THUG)
	)
	var target: Dictionary = CombatTestHelper.target(result["state"])
	assert_true(result["blocked"])
	assert_eq(result["blocker"], GameIds.CARD_COPS)
	assert_true(target["defense"]["cops_active"])
	assert_eq(
		CombatTestHelper.attacker(result["state"])["hand"],
		[GameIds.CARD_THUG]
	)
	assert_eq(result["contract_hook_events"].size(), 1)
	assert_true(result["contract_hook_events"][0]["blocked"])
	assert_false(result["contract_results"][0]["changed"])
	assert_eq(result["contact_hook_events"], [])


func test_valid_insider_bypasses_cops_and_consumes_one_of_each() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand([
		GameIds.CARD_THUG, GameIds.CARD_INSIDER, GameIds.CARD_INSIDER,
	])
	var target: Dictionary = CombatTestHelper.target(state)
	target["defense"]["cops_active"] = true
	target["nal"] = 10
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_THUG, "", GameIds.PLAYER_AI_1,
			[GameIds.CARD_INSIDER]
		)
	)
	assert_true(result["success"])
	assert_false(result["blocked"])
	assert_eq(
		result["cards_consumed"],
		[GameIds.CARD_THUG, GameIds.CARD_INSIDER]
	)
	assert_eq(
		CombatTestHelper.attacker(result["state"])["hand"],
		[GameIds.CARD_INSIDER]
	)


func test_bruiser_steal_respects_protection_and_max_eight() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 20
	target["engine"]["accountants"] = 1
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.STEAL_NAL
		)
	)
	assert_eq(result["effect_result"]["protected_nal"], 4)
	assert_eq(result["effect_result"]["stolen_nal"], 8)
	assert_eq(CombatTestHelper.target(result["state"])["nal"], 12)


func test_bruiser_destroy_stash_applies_effect_and_vp_clamp() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["status_buildings"]["stash"] = 1
	target["vp"] = 0
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	target = CombatTestHelper.target(result["state"])
	assert_eq(target["status_buildings"]["stash"], 0)
	assert_eq(target["vp"], 0)
	assert_eq(CombatTestHelper.attacker(result["state"])["nal"], 8)
	assert_eq(
		result["effect_result"]["destroyed_status_card_id"],
		GameIds.CARD_STASH
	)


func test_cartel_blocks_bruiser_without_fallback_or_depletion() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER]
	)
	var attacker_before: int = CombatTestHelper.attacker(state)["nal"]
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 30
	target["vp"] = 3
	target["status_buildings"]["stash"] = 1
	target["defense"]["cartel_state"] = DefenseStates.ACTIVE
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	target = CombatTestHelper.target(result["state"])
	assert_true(result["blocked"])
	assert_eq(target["nal"], 30)
	assert_eq(target["vp"], 3)
	assert_eq(target["status_buildings"]["stash"], 1)
	assert_eq(target["defense"]["cartel_state"], DefenseStates.ACTIVE)
	assert_eq(CombatTestHelper.attacker(result["state"])["nal"], attacker_before)
