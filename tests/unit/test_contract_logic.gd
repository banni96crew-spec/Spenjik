extends GutTest


func test_runtime_schema_and_resources_match_all_contract_ids() -> void:
	for contract_id: String in ContractIds.ALL:
		var definition: ContractDefinition = ContractCatalog.get_by_id(
			contract_id
		)
		assert_not_null(definition)
		var runtime: Dictionary = ContractLogic.create_contract_runtime(
			contract_id, definition.deadline_round
		)
		assert_eq(runtime.keys().size(), 9)
		assert_eq(runtime["contract_id"], contract_id)
		assert_eq(runtime["deadline"], definition.deadline_round)
		assert_true(GameStateValidator.validate_contract_runtime(runtime)["ok"])


func test_offers_are_deterministic_unique_and_consume_three_steps() -> void:
	var state: Dictionary = TestGameStateFactory.setup_state("contract_offers")
	var before: Dictionary = state.duplicate(true)
	var first: Dictionary = ContractLogic.generate_contract_offers(state)
	var second: Dictionary = ContractLogic.generate_contract_offers(state)
	assert_true(first["ok"], str(first))
	assert_eq(first["contract_offer_ids"], second["contract_offer_ids"])
	assert_eq(first["contract_offer_ids"].size(), 3)
	assert_eq(_unique_count(first["contract_offer_ids"]), 3)
	assert_eq(first["steps_used"], 3)
	assert_eq(first["state"]["random"]["step"], 3)
	assert_eq(
		first["state"]["random"]["last_random_tag"],
		"contract_offers_setup_pick_2"
	)
	for contract_id: String in first["contract_offer_ids"]:
		assert_true(ContractIds.ALL.has(contract_id))
	assert_eq(state, before)


func test_failed_offer_generation_does_not_mutate_input_or_random() -> void:
	var state: Dictionary = TestGameStateFactory.setup_state("bad_offers")
	state["random"]["step"] = -1
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = ContractLogic.generate_contract_offers(state)
	assert_false(result["ok"])
	assert_eq(state, before)
	assert_eq(result["random"], before["random"])


func test_setup_validator_accepts_exactly_three_contract_stages() -> void:
	var empty: Dictionary = TestGameStateFactory.setup_state()
	var offered: Dictionary = TestGameStateFactory.setup_with_offers()
	var selected: Dictionary = TestGameStateFactory.setup_with_contract(
		ContractIds.SILENT_EXPANSION
	)
	assert_true(GameStateValidator.validate_setup_working_state(empty)["ok"])
	assert_true(GameStateValidator.validate_setup_working_state(offered)["ok"])
	assert_true(GameStateValidator.validate_setup_working_state(selected)["ok"])
	offered["contract_offer_ids"].pop_back()
	assert_false(GameStateValidator.validate_setup_working_state(offered)["ok"])


func test_human_selects_offered_contract_and_ai_contracts_stay_empty() -> void:
	var state: Dictionary = TestGameStateFactory.setup_with_offers()
	var selected_id: String = state["contract_offer_ids"][1]
	var before_random: Dictionary = state["random"].duplicate(true)
	var result: Dictionary = ContractLogic.select_contract(
		state, GameIds.PLAYER_HUMAN, selected_id
	)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["selected_contract_id"], selected_id)
	assert_eq(result["contract"]["contract_id"], selected_id)
	assert_eq(result["state"]["random"], before_random)
	assert_eq(
		TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)["contracts"].size(),
		1
	)
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		assert_eq(TestPlayers.find(result["state"], ai_id)["contracts"], [])


func test_invalid_second_outside_offer_and_ai_selection_are_read_only() -> void:
	var state: Dictionary = TestGameStateFactory.setup_with_offers()
	var before: Dictionary = state.duplicate(true)
	var outside: String = ContractIds.ALL[4]
	assert_false(state["contract_offer_ids"].has(outside))
	var result: Dictionary = ContractLogic.select_contract(
		state, GameIds.PLAYER_HUMAN, outside
	)
	assert_eq(result["error"], ValidationErrors.CONTRACT_OFFER_UNAVAILABLE)
	assert_eq(state, before)
	result = ContractLogic.select_contract(
		state, GameIds.PLAYER_AI_1, state["contract_offer_ids"][0]
	)
	assert_eq(result["error"], ValidationErrors.INVALID_TARGET)
	assert_eq(state, before)
	var selected: Dictionary = ContractLogic.select_contract(
		state, GameIds.PLAYER_HUMAN, state["contract_offer_ids"][0]
	)["state"]
	var selected_before: Dictionary = selected.duplicate(true)
	result = ContractLogic.select_contract(
		selected, GameIds.PLAYER_HUMAN, state["contract_offer_ids"][1]
	)
	assert_eq(result["error"], ValidationErrors.CONTRACT_ALREADY_SELECTED)
	assert_eq(selected, selected_before)


func test_deadline_is_inclusive_and_failure_starts_after_deadline() -> void:
	var state: Dictionary = _contract_state(ContractIds.SILENT_EXPANSION)
	var contract: Dictionary = _contract(state)
	state["round"] = contract["deadline"]
	var result: Dictionary = ContractLogic.process_deadlines(state)
	assert_false(result["changed"])
	assert_false(_contract(result["state"])["failed"])
	state["round"] = contract["deadline"] + 1
	result = ContractLogic.process_deadlines(state)
	assert_true(result["failed_now"])
	assert_eq(
		_contract(result["state"])["failed_reason"],
		"deadline_exceeded"
	)
	assert_eq(
		result["log_entries"][0]["event_type"],
		LogEventTypes.CONTRACT_FAILED
	)


func test_vp_and_nal_rewards_claim_once_and_failed_claims_are_read_only() -> void:
	for contract_id: String in [
		ContractIds.GRAY_CAPITAL, ContractIds.BLOODY_TURF_WAR,
	]:
		var state: Dictionary = _completed_state(contract_id)
		var human: Dictionary = TestPlayers.find(
			state, GameIds.PLAYER_HUMAN
		)
		var before_vp: int = human["vp"]
		var before_nal: int = human["nal"]
		var result: Dictionary = ContractLogic.claim_contract(
			state, GameIds.PLAYER_HUMAN, contract_id
		)
		assert_true(result["ok"], str(result))
		var claimed: Dictionary = TestPlayers.find(
			result["state"], GameIds.PLAYER_HUMAN
		)
		var definition: ContractDefinition = ContractCatalog.get_by_id(
			contract_id
		)
		assert_eq(
			claimed["vp"],
			before_vp + (
				definition.reward_amount
				if definition.reward_type == RewardTypes.VP else 0
			)
		)
		assert_eq(
			claimed["nal"],
			before_nal + (
				definition.reward_amount
				if definition.reward_type == RewardTypes.NAL else 0
			)
		)
		var claimed_before: Dictionary = result["state"].duplicate(true)
		var repeated: Dictionary = ContractLogic.claim_contract(
			result["state"], GameIds.PLAYER_HUMAN, contract_id
		)
		assert_eq(
			repeated["error"], ValidationErrors.CONTRACT_ALREADY_CLAIMED
		)
		assert_eq(result["state"], claimed_before)


func test_completed_on_time_contract_can_claim_after_deadline() -> void:
	var state: Dictionary = _completed_state(ContractIds.GRAY_CAPITAL)
	state["round"] = 11
	var result: Dictionary = ContractLogic.claim_contract(
		state, GameIds.PLAYER_HUMAN, ContractIds.GRAY_CAPITAL
	)
	assert_true(result["ok"], str(result))
	assert_true(_contract(result["state"])["claimed"])


func test_claim_before_completion_and_after_failure_do_not_mutate() -> void:
	var active: Dictionary = _contract_state(ContractIds.GRAY_CAPITAL)
	var before: Dictionary = active.duplicate(true)
	var result: Dictionary = ContractLogic.claim_contract(
		active, GameIds.PLAYER_HUMAN, ContractIds.GRAY_CAPITAL
	)
	assert_eq(result["error"], ValidationErrors.CONTRACT_NOT_COMPLETED)
	assert_eq(active, before)
	var failed: Dictionary = _contract_state(ContractIds.GRAY_CAPITAL)
	_contract(failed)["failed"] = true
	_contract(failed)["failed_reason"] = "deadline_exceeded"
	before = failed.duplicate(true)
	result = ContractLogic.claim_contract(
		failed, GameIds.PLAYER_HUMAN, ContractIds.GRAY_CAPITAL
	)
	assert_eq(result["error"], ValidationErrors.CONTRACT_ALREADY_FAILED)
	assert_eq(failed, before)


func _contract_state(contract_id: String) -> Dictionary:
	return TestStates.with_contract(
		TestGameStateFactory.base_state("contract_%s" % contract_id),
		contract_id
	)


func _completed_state(contract_id: String) -> Dictionary:
	var state: Dictionary = _contract_state(contract_id)
	var contract: Dictionary = _contract(state)
	contract["progress"] = ContractCatalog.get_by_id(
		contract_id
	).progress_required
	contract["completed"] = true
	contract["completed_round"] = mini(state["round"], contract["deadline"])
	return state


func _contract(state: Dictionary) -> Dictionary:
	return TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)["contracts"][0]


func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value: Variant in values:
		unique[value] = true
	return unique.size()
