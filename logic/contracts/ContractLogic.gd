class_name ContractLogic


static func create_contract_runtime(
	contract_id: String,
	deadline: int
) -> Dictionary:
	return GameStateFactory.create_contract_runtime(contract_id, deadline)


static func generate_contract_offers(state: Dictionary) -> Dictionary:
	return ContractSetupLogic.generate_offers(state)


static func validate_contract_selection(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	return ContractSetupLogic.validate_selection(
		state, player_id, contract_id
	)


static func select_contract(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	return ContractSetupLogic.select(state, player_id, contract_id)


static func get_player_contract(
	player: Dictionary,
	contract_id: String = ""
) -> Dictionary:
	var contract: Dictionary = ContractStateHelper.contract_ref(
		player, contract_id
	)
	return contract.duplicate(true)


static func on_card_purchased(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	return ContractProgressLogic.on_card_purchased(state, event)


static func on_income_resolved(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	return ContractProgressLogic.on_income_resolved(state, event)


static func on_attack_resolved(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	return ContractProgressLogic.on_attack_resolved(state, event)


static func on_state_changed(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	return ContractProgressLogic.on_state_changed(state, event)


static func check_contract_completion(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	return ContractProgressLogic.check_completion(
		state, player_id, LogEventTypes.CONTRACT_PROGRESS_UPDATED
	)


static func process_deadlines(state: Dictionary) -> Dictionary:
	return ContractProgressLogic.process_deadlines(state)


static func claim_contract(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	return ContractClaimLogic.claim(state, player_id, contract_id)


static func validate_contract_claim(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	return ContractClaimLogic.validate_claim(state, player_id, contract_id)
