extends GutTest


func test_cleaner_steals_up_to_fourteen_with_protection() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_CLEANER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 25
	target["engine"]["accountants"] = 2
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_CLEANER, AttackModes.STEAL_NAL
		)
	)
	assert_eq(result["effect_result"]["stolen_nal"], 14)
	assert_eq(CombatTestHelper.target(result["state"])["nal"], 11)


func test_cleaner_destroy_workshop_applies_all_effects() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_CLEANER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["status_buildings"]["workshop"] = 1
	target["vp"] = 1
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_CLEANER, AttackModes.DESTROY_WORKSHOP
		)
	)
	target = CombatTestHelper.target(result["state"])
	assert_eq(target["status_buildings"]["workshop"], 0)
	assert_eq(target["vp"], 0)
	assert_true(target["skip_next_action"])
	assert_eq(CombatTestHelper.attacker(result["state"])["nal"], 10)


func test_cartel_blocks_cleaner_depletes_and_has_no_fallback() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_CLEANER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 20
	target["vp"] = 4
	target["status_buildings"]["workshop"] = 1
	target["defense"]["cartel_state"] = DefenseStates.ACTIVE
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_CLEANER, AttackModes.DESTROY_WORKSHOP
		)
	)
	target = CombatTestHelper.target(result["state"])
	assert_true(result["blocked"])
	assert_eq(target["defense"]["cartel_state"], DefenseStates.DEPLETED)
	assert_eq(target["status_buildings"]["workshop"], 1)
	assert_eq(target["nal"], 20)
	assert_eq(target["vp"], 4)
	assert_false(target["skip_next_action"])
	assert_eq(CombatTestHelper.attacker(result["state"])["nal"], 5)


func test_saboteur_destroys_each_selected_engine_without_random() -> void:
	var cases: Array[Dictionary] = [
		{"id": GameIds.CARD_INFORMANT, "field": "informers", "value": 1},
		{"id": GameIds.CARD_LAUNDRY, "field": "laundries", "value": 1},
		{"id": GameIds.CARD_ACCOUNTANT, "field": "accountants", "value": 1},
		{"id": GameIds.CARD_BROTHEL, "field": "brothel", "value": true},
	]
	for item: Dictionary in cases:
		var state: Dictionary = CombatTestHelper.state_with_hand(
			[GameIds.CARD_SABOTEUR], "saboteur_%s" % item["id"]
		)
		var target: Dictionary = CombatTestHelper.target(state)
		target["engine"][item["field"]] = item["value"]
		var random_before: Dictionary = state["random"].duplicate(true)
		var result: Dictionary = CombatEngine.resolve_attack(
			state,
			CombatTestHelper.payload(
				GameIds.CARD_SABOTEUR, "", GameIds.PLAYER_AI_1, [],
				item["id"]
			)
		)
		target = CombatTestHelper.target(result["state"])
		if item["id"] == GameIds.CARD_BROTHEL:
			assert_false(target["engine"]["brothel"])
		else:
			assert_eq(target["engine"][item["field"]], 0)
		assert_eq(result["state"]["random"], random_before)


func test_judge_blocks_saboteur_once_and_preserves_engine() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_SABOTEUR]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["engine"]["laundries"] = 1
	target["defense"]["judge_state"] = DefenseStates.ACTIVE
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_SABOTEUR, "", GameIds.PLAYER_AI_1, [],
			GameIds.CARD_LAUNDRY
		)
	)
	target = CombatTestHelper.target(result["state"])
	assert_true(result["blocked"])
	assert_eq(result["blocker"], GameIds.CARD_JUDGE)
	assert_eq(target["engine"]["laundries"], 1)
	assert_eq(target["defense"]["judge_state"], DefenseStates.NONE)
	assert_eq(CombatTestHelper.attacker(result["state"])["hand"], [])


func test_federal_raid_ignores_all_defenses_and_sets_rebuild_flag() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_FEDERAL_RAID]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["status_buildings"]["district_control"] = 1
	target["vp"] = 2
	target["defense"]["cops_active"] = true
	target["defense"]["cartel_state"] = DefenseStates.ACTIVE
	target["defense"]["judge_state"] = DefenseStates.ACTIVE
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_FEDERAL_RAID, AttackModes.DESTROY_DISTRICT
		)
	)
	target = CombatTestHelper.target(result["state"])
	assert_true(result["success"])
	assert_false(result["blocked"])
	assert_eq(target["status_buildings"]["district_control"], 0)
	assert_true(target["status_buildings"]["can_rebuild_district_for_8"])
	assert_eq(target["vp"], 0)
	assert_eq(target["defense"]["cartel_state"], DefenseStates.ACTIVE)
	assert_eq(target["defense"]["judge_state"], DefenseStates.ACTIVE)
