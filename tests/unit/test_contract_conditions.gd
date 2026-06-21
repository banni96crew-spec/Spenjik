extends GutTest
func test_silent_expansion_counts_status_purchases_and_does_not_auto_claim() -> void:
	var state: Dictionary = _state(ContractIds.SILENT_EXPANSION)
	var vp_before: int = _human(state)["vp"]
	var first: Dictionary = ContractLogic.on_card_purchased(
		state, _purchase_event(GameIds.CARD_STASH, CardTypes.STATUS)
	)
	assert_eq(first["progress_after"], 1)
	var completed: Dictionary = ContractLogic.on_card_purchased(
		first["state"],
		_purchase_event(GameIds.CARD_WORKSHOP, CardTypes.STATUS)
	)
	assert_true(completed["completed_now"])
	assert_false(_contract(completed["state"])["claimed"])
	assert_eq(_human(completed["state"])["vp"], vp_before)
	var bought_war: Dictionary = ContractLogic.on_card_purchased(
		state, _purchase_event(GameIds.CARD_THUG, CardTypes.WAR)
	)
	assert_false(bought_war["changed"])

func test_silent_expansion_valid_blocked_attack_fails_but_invalid_does_not() -> void:
	var state: Dictionary = _state(ContractIds.SILENT_EXPANSION)
	var blocked: Dictionary = _attack_event(
		GameIds.CARD_THUG, "", true, false
	)
	var result: Dictionary = ContractLogic.on_attack_resolved(
		state, blocked
	)
	assert_true(result["failed_now"])
	assert_eq(_contract(result["state"])["failed_reason"], "war_played")
	var invalid: Dictionary = blocked.duplicate(true)
	invalid["valid_attack"] = false
	var before: Dictionary = state.duplicate(true)
	result = ContractLogic.on_attack_resolved(state, invalid)
	assert_false(result["changed"])
	assert_eq(state, before)


func test_completed_silent_expansion_is_irreversible() -> void:
	var state: Dictionary = _state(ContractIds.SILENT_EXPANSION)
	var contract: Dictionary = _contract(state)
	contract["progress"] = 2
	contract["completed"] = true
	contract["completed_round"] = 1
	var result: Dictionary = ContractLogic.on_attack_resolved(
		state, _attack_event(GameIds.CARD_THUG, "", true, false)
	)
	assert_false(result["changed"])
	assert_true(_contract(result["state"])["completed"])
	assert_false(_contract(result["state"])["failed"])


func test_bloody_turf_war_counts_only_matching_unblocked_ai_destruction() -> void:
	var state: Dictionary = _state(ContractIds.BLOODY_TURF_WAR)
	var first: Dictionary = ContractLogic.on_attack_resolved(
		state,
		_status_attack(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH,
			GameIds.CARD_STASH
		)
	)
	assert_eq(first["progress_after"], 1)
	var blocked: Dictionary = _status_attack(
		GameIds.CARD_CLEANER, AttackModes.DESTROY_WORKSHOP,
		GameIds.CARD_WORKSHOP
	)
	blocked["blocked"] = true
	blocked["success"] = false
	var unchanged: Dictionary = ContractLogic.on_attack_resolved(
		first["state"], blocked
	)
	assert_eq(unchanged["progress_after"], 1)
	var human_target: Dictionary = _status_attack(
		GameIds.CARD_FEDERAL_RAID, AttackModes.DESTROY_DISTRICT,
		GameIds.CARD_DISTRICT_CONTROL
	)
	human_target["target_is_ai"] = false
	unchanged = ContractLogic.on_attack_resolved(
		first["state"], human_target
	)
	assert_eq(unchanged["progress_after"], 1)
	var completed: Dictionary = ContractLogic.on_attack_resolved(
		first["state"],
		_status_attack(
			GameIds.CARD_CLEANER, AttackModes.DESTROY_WORKSHOP,
			GameIds.CARD_WORKSHOP
		)
	)
	assert_true(completed["completed_now"])


func test_gray_capital_progresses_to_thirty_and_stays_completed() -> void:
	var state: Dictionary = _state(ContractIds.GRAY_CAPITAL)
	_human(state)["nal"] = 29
	var result: Dictionary = ContractLogic.on_state_changed(
		state, _state_event()
	)
	assert_eq(result["progress_after"], 29)
	assert_false(result["completed_now"])
	_human(result["state"])["nal"] = 30
	result = ContractLogic.on_state_changed(result["state"], _state_event())
	assert_true(result["completed_now"])
	_human(result["state"])["nal"] = 0
	var lost: Dictionary = ContractLogic.on_state_changed(
		result["state"], _state_event()
	)
	assert_true(_contract(lost["state"])["completed"])


func test_iron_roof_requires_all_three_active_defenses() -> void:
	var state: Dictionary = _state(ContractIds.IRON_ROOF)
	var human: Dictionary = _human(state)
	human["defense"]["cops_active"] = true
	human["defense"]["cartel_state"] = DefenseStates.ACTIVE
	var result: Dictionary = ContractLogic.on_state_changed(
		state, _state_event()
	)
	assert_eq(result["progress_after"], 2)
	human = _human(result["state"])
	human["defense"]["judge_state"] = DefenseStates.ACTIVE
	result = ContractLogic.on_state_changed(result["state"], _state_event())
	assert_true(result["completed_now"])
	var depleted: Dictionary = _state(ContractIds.IRON_ROOF)
	_human(depleted)["defense"]["cartel_state"] = DefenseStates.DEPLETED
	assert_eq(
		ContractLogic.on_state_changed(
			depleted, _state_event()
		)["progress_after"],
		0
	)


func test_district_under_control_requires_district_and_active_protection() -> void:
	for defense_key: String in ["cops_active", "cartel_state", "judge_state"]:
		var state: Dictionary = _state(ContractIds.DISTRICT_UNDER_CONTROL)
		var human: Dictionary = _human(state)
		human["status_buildings"]["district_control"] = 1
		var partial: Dictionary = ContractLogic.on_state_changed(
			state, _state_event()
		)
		assert_eq(partial["progress_after"], 1)
		human = _human(partial["state"])
		if defense_key == "cops_active":
			human["defense"][defense_key] = true
		else:
			human["defense"][defense_key] = DefenseStates.ACTIVE
		var completed: Dictionary = ContractLogic.on_state_changed(
			partial["state"], _state_event()
		)
		assert_true(completed["completed_now"], defense_key)


func test_proxy_war_requires_successful_unblocked_saboteur() -> void:
	for blocked: bool in [true, false]:
		var state: Dictionary = _state(ContractIds.PROXY_WAR)
		var event: Dictionary = _attack_event(
			GameIds.CARD_SABOTEUR, "", blocked, not blocked
		)
		var result: Dictionary = ContractLogic.on_attack_resolved(
			state, event
		)
		assert_eq(result["completed_now"], not blocked)
	var bought: Dictionary = ContractLogic.on_card_purchased(
		_state(ContractIds.PROXY_WAR),
		_purchase_event(GameIds.CARD_SABOTEUR, CardTypes.WAR)
	)
	assert_false(bought["changed"])


func test_big_cashbox_counts_three_simultaneous_subconditions() -> void:
	var state: Dictionary = _state(ContractIds.BIG_CASHBOX)
	var human: Dictionary = _human(state)
	human["engine"]["laundries"] = 2
	human["engine"]["accountants"] = 1
	human["nal"] = 19
	var result: Dictionary = ContractLogic.on_state_changed(
		state, _state_event()
	)
	assert_eq(result["progress_after"], 2)
	_human(result["state"])["nal"] = 20
	result = ContractLogic.on_state_changed(result["state"], _state_event())
	assert_true(result["completed_now"])


func _state(contract_id: String) -> Dictionary:
	return TestStates.with_contract(
		TestGameStateFactory.base_state("condition_%s" % contract_id),
		contract_id
	)


func _human(state: Dictionary) -> Dictionary:
	return TestPlayers.find(state, GameIds.PLAYER_HUMAN)


func _contract(state: Dictionary) -> Dictionary:
	return _human(state)["contracts"][0]


func _purchase_event(card_id: String, card_type: String) -> Dictionary:
	return {
		"player_id": GameIds.PLAYER_HUMAN,
		"card_id": card_id,
		"card_type": card_type,
		"destination": (
			CardDestinations.HAND
			if card_type == CardTypes.WAR else CardDestinations.TABLE
		),
	}


func _attack_event(
	card_id: String,
	mode: String,
	blocked: bool,
	success: bool
) -> Dictionary:
	return {
		"attacker_id": GameIds.PLAYER_HUMAN,
		"target_id": GameIds.PLAYER_AI_1,
		"target_is_ai": true,
		"card_id": card_id,
		"mode": mode,
		"engine_target_card_id": "",
		"blocked": blocked,
		"success": success,
		"valid_attack": true,
		"destroyed_status_card_id": "",
		"destroyed_engine_card_id": "",
	}


func _status_attack(
	card_id: String,
	mode: String,
	destroyed_id: String
) -> Dictionary:
	var event: Dictionary = _attack_event(card_id, mode, false, true)
	event["destroyed_status_card_id"] = destroyed_id
	return event


func _state_event() -> Dictionary:
	return {
		"source": "test",
		"source_event_type": LogEventTypes.STREET_DEAL_RESOLVED,
		"player_id": GameIds.PLAYER_HUMAN,
	}
