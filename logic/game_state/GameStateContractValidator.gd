class_name GameStateContractValidator


static func validate_root_fields(
	state: Dictionary,
	committed: bool
) -> Dictionary:
	if typeof(state["selected_contract_id"]) != TYPE_STRING:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"state.selected_contract_id", "wrong_type"
		)
	if typeof(state["contract_offer_ids"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"state.contract_offer_ids", "wrong_type"
		)
	if committed:
		return _validate_committed(state)
	return _validate_setup(state)


static func human_contract_count(
	state: Dictionary,
	committed: bool,
	player_index: int
) -> int:
	if player_index != 0:
		return 0
	return 1 if committed or not state["selected_contract_id"].is_empty() else 0


static func selection_matches_runtime(state: Dictionary) -> Dictionary:
	if state["selected_contract_id"].is_empty():
		return StateShapeValidator.ok()
	var contract: Dictionary = state["players"][0]["contracts"][0]
	if contract["contract_id"] != state["selected_contract_id"]:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"player.contracts", "selection_mismatch"
		)
	return StateShapeValidator.ok()


static func _validate_committed(state: Dictionary) -> Dictionary:
	var offers: Dictionary = StateShapeValidator.unique_strings(
		state["contract_offer_ids"], ContractIds.ALL,
		"state.contract_offer_ids", ValidationErrors.INVALID_CONTRACT_ID
	)
	if not offers["ok"] or state["contract_offer_ids"].size() != 3:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"state.contract_offer_ids", "committed_offer_contract"
		)
	if (
		not ContractIds.ALL.has(state["selected_contract_id"])
		or not state["contract_offer_ids"].has(state["selected_contract_id"])
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"state.selected_contract_id", "not_offered"
		)
	return StateShapeValidator.ok()


static func _validate_setup(state: Dictionary) -> Dictionary:
	if state["contract_offer_ids"].is_empty():
		if not state["selected_contract_id"].is_empty():
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_CONTRACT_ID,
				"state.selected_contract_id", "selection_without_offers"
			)
		return StateShapeValidator.ok()
	var offers: Dictionary = StateShapeValidator.unique_strings(
		state["contract_offer_ids"], ContractIds.ALL,
		"state.contract_offer_ids", ValidationErrors.INVALID_CONTRACT_ID
	)
	if not offers["ok"] or state["contract_offer_ids"].size() != 3:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"state.contract_offer_ids", "setup_offer_contract"
		)
	if (
		not state["selected_contract_id"].is_empty()
		and not state["contract_offer_ids"].has(
			state["selected_contract_id"]
		)
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID,
			"state.selected_contract_id", "not_offered"
		)
	return StateShapeValidator.ok()
