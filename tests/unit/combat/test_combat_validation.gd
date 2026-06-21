extends GutTest


func test_validation_order_starts_with_phase_and_required_fields() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG]
	)
	state["current_phase"] = PhaseIds.MARKET
	state["action_order"] = []
	state["active_action_player_id"] = ""
	assert_eq(
		CombatEngine.validate_attack(state, {})["error"],
		ValidationErrors.INVALID_PHASE
	)
	state = CombatTestHelper.state_with_hand([GameIds.CARD_THUG])
	assert_eq(
		CombatEngine.validate_attack(state, {})["error"],
		ValidationErrors.INVALID_TARGET
	)
	assert_eq(
		CombatEngine.validate_attack(state, {
			"attacker_id": GameIds.PLAYER_HUMAN,
			"target_id": GameIds.PLAYER_AI_1,
		})["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)


func test_attacker_target_active_player_and_hand_validation_order() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand([])
	var payload: Dictionary = CombatTestHelper.payload(GameIds.CARD_THUG)
	payload["attacker_id"] = "bad_player"
	assert_eq(
		CombatEngine.validate_attack(state, payload)["error"],
		ValidationErrors.INVALID_TARGET
	)
	payload = CombatTestHelper.payload(GameIds.CARD_THUG)
	payload["target_id"] = "bad_player"
	assert_eq(
		CombatEngine.validate_attack(state, payload)["error"],
		ValidationErrors.INVALID_TARGET
	)
	payload["target_id"] = GameIds.PLAYER_HUMAN
	assert_eq(
		CombatEngine.validate_attack(state, payload)["error"],
		ValidationErrors.INVALID_TARGET
	)
	payload = CombatTestHelper.payload(GameIds.CARD_THUG)
	state["active_action_player_id"] = GameIds.PLAYER_AI_1
	assert_eq(
		CombatEngine.validate_attack(state, payload)["error"],
		ValidationErrors.INVALID_TARGET
	)
	state["active_action_player_id"] = GameIds.PLAYER_HUMAN
	assert_eq(
		CombatEngine.validate_attack(state, payload)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)


func test_primary_cards_modes_and_target_requirements() -> void:
	var cases: Array[Dictionary] = [
		{
			"card": GameIds.CARD_BRUISER,
			"mode": "",
			"error": ValidationErrors.ATTACK_MODE_REQUIRED,
		},
		{
			"card": GameIds.CARD_BRUISER,
			"mode": AttackModes.DESTROY_WORKSHOP,
			"error": ValidationErrors.INVALID_ATTACK_MODE,
		},
		{
			"card": GameIds.CARD_THUG,
			"mode": AttackModes.STEAL_NAL,
			"error": ValidationErrors.INVALID_ATTACK_MODE,
		},
		{
			"card": GameIds.CARD_CLEANER,
			"mode": "",
			"error": ValidationErrors.ATTACK_MODE_REQUIRED,
		},
		{
			"card": GameIds.CARD_FEDERAL_RAID,
			"mode": "",
			"error": ValidationErrors.ATTACK_MODE_REQUIRED,
		},
		{
			"card": GameIds.CARD_FEDERAL_RAID,
			"mode": AttackModes.STEAL_NAL,
			"error": ValidationErrors.INVALID_ATTACK_MODE,
		},
		{
			"card": GameIds.CARD_SABOTEUR,
			"mode": AttackModes.STEAL_NAL,
			"error": ValidationErrors.INVALID_ATTACK_MODE,
		},
	]
	for item: Dictionary in cases:
		var state: Dictionary = CombatTestHelper.state_with_hand([item["card"]])
		var result: Dictionary = CombatEngine.validate_attack(
			state, CombatTestHelper.payload(item["card"], item["mode"])
		)
		assert_eq(result["error"], item["error"], str(item))
	for item: Dictionary in [
		{
			"card": GameIds.CARD_BRUISER,
			"mode": AttackModes.DESTROY_STASH,
		},
		{
			"card": GameIds.CARD_CLEANER,
			"mode": AttackModes.DESTROY_WORKSHOP,
		},
		{
			"card": GameIds.CARD_FEDERAL_RAID,
			"mode": AttackModes.DESTROY_DISTRICT,
		},
	]:
		var state: Dictionary = CombatTestHelper.state_with_hand([item["card"]])
		assert_eq(
			CombatEngine.validate_attack(
				state, CombatTestHelper.payload(item["card"], item["mode"])
			)["error"],
			ValidationErrors.INVALID_TARGET
		)


func test_insider_is_modifier_only_and_requires_thug_cops_and_hand() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_INSIDER]
	)
	assert_eq(
		CombatEngine.validate_attack(
			state, CombatTestHelper.payload(GameIds.CARD_INSIDER)
		)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)
	state = CombatTestHelper.state_with_hand([
		GameIds.CARD_BRUISER, GameIds.CARD_INSIDER,
	])
	assert_eq(
		CombatEngine.validate_attack(
			state,
			CombatTestHelper.payload(
				GameIds.CARD_BRUISER,
				AttackModes.STEAL_NAL,
				GameIds.PLAYER_AI_1,
				[GameIds.CARD_INSIDER]
			)
		)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)
	state = CombatTestHelper.state_with_hand([GameIds.CARD_THUG])
	CombatTestHelper.target(state)["defense"]["cops_active"] = true
	assert_eq(
		CombatEngine.validate_attack(
			state,
			CombatTestHelper.payload(
				GameIds.CARD_THUG, "", GameIds.PLAYER_AI_1,
				[GameIds.CARD_INSIDER]
			)
		)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)
	state = CombatTestHelper.state_with_hand([
		GameIds.CARD_THUG, GameIds.CARD_INSIDER,
	])
	assert_eq(
		CombatEngine.validate_attack(
			state,
			CombatTestHelper.payload(
				GameIds.CARD_THUG, "", GameIds.PLAYER_AI_1,
				[GameIds.CARD_INSIDER]
			)
		)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)
	CombatTestHelper.target(state)["defense"]["cops_active"] = true
	assert_eq(
		CombatEngine.validate_attack(
			state,
			CombatTestHelper.payload(
				GameIds.CARD_THUG, "", GameIds.PLAYER_AI_1,
				[GameIds.CARD_INSIDER, GameIds.CARD_INSIDER]
			)
		)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)


func test_saboteur_requires_explicit_owned_engine_target() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_SABOTEUR]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["engine"]["informers"] = 1
	assert_eq(
		CombatEngine.validate_attack(
			state, CombatTestHelper.payload(GameIds.CARD_SABOTEUR)
		)["error"],
		ValidationErrors.INVALID_TARGET
	)
	assert_eq(
		CombatEngine.validate_attack(
			state,
			CombatTestHelper.payload(
				GameIds.CARD_SABOTEUR, "", GameIds.PLAYER_AI_1, [],
				GameIds.CARD_LAUNDRY
			)
		)["error"],
		ValidationErrors.INVALID_TARGET
	)
	assert_true(CombatEngine.validate_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_SABOTEUR, "", GameIds.PLAYER_AI_1, [],
			GameIds.CARD_INFORMANT
		)
	)["ok"])


func test_failed_validation_is_fully_read_only() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER]
	)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	assert_false(result["ok"])
	assert_eq(state, before)
	assert_eq(result["cards_consumed"], [])
	assert_eq(result["contract_hook_events"], [])
	assert_eq(result["contact_hook_events"], [])
