class_name ContractSetupLogic


static func generate_offers(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_setup_working_state(
		state
	)
	if not validation["ok"]:
		return _offer_failure(state, validation["error"])
	if not state["contract_offer_ids"].is_empty():
		return _offer_failure(
			state, ValidationErrors.CONTRACT_OFFER_UNAVAILABLE
		)
	var picked: Dictionary = SeededPicker.pick_unique(
		state["random"],
		ContractIds.ALL,
		3,
		"contract_offers_setup"
	)
	if (
		not picked["ok"]
		or picked["selected_items"].size() != 3
		or picked["steps_used"] != 3
	):
		return _offer_failure(
			state, ValidationErrors.CONTRACT_OFFER_UNAVAILABLE
		)
	var candidate: Dictionary = state.duplicate(true)
	candidate["random"] = picked["random"]
	candidate["contract_offer_ids"] = picked["selected_items"].duplicate()
	var final_validation: Dictionary = (
		GameStateValidator.validate_setup_working_state(candidate)
	)
	if not final_validation["ok"]:
		return _offer_failure(state, final_validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"contract_offer_ids": candidate["contract_offer_ids"].duplicate(),
		"steps_used": 3,
		"random": candidate["random"].duplicate(true),
		"state": candidate,
		"log_entries": [],
	}


static func validate_selection(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	var state_validation: Dictionary = (
		GameStateValidator.validate_setup_working_state(state)
	)
	if not state_validation["ok"]:
		return _validation_failure(state_validation["error"])
	if player_id != GameIds.PLAYER_HUMAN:
		return _validation_failure(ValidationErrors.INVALID_TARGET)
	if not ContractIds.ALL.has(contract_id):
		return _validation_failure(ValidationErrors.INVALID_CONTRACT_ID)
	if not state["contract_offer_ids"].has(contract_id):
		return _validation_failure(
			ValidationErrors.CONTRACT_OFFER_UNAVAILABLE
		)
	var human: Dictionary = _find_player(state, GameIds.PLAYER_HUMAN)
	if (
		not state["selected_contract_id"].is_empty()
		or not human["contracts"].is_empty()
	):
		return _validation_failure(
			ValidationErrors.CONTRACT_ALREADY_SELECTED
		)
	return {"ok": true, "error": ValidationErrors.OK}


static func select(
	state: Dictionary,
	player_id: String,
	contract_id: String
) -> Dictionary:
	var validation: Dictionary = validate_selection(
		state, player_id, contract_id
	)
	if not validation["ok"]:
		return _selection_failure(
			state, validation["error"], player_id, contract_id
		)
	var definition: ContractDefinition = ContractCatalog.get_by_id(contract_id)
	if definition == null:
		return _selection_failure(
			state, ValidationErrors.INVALID_CONTRACT_ID,
			player_id, contract_id
		)
	var candidate: Dictionary = state.duplicate(true)
	var human: Dictionary = _find_player(candidate, GameIds.PLAYER_HUMAN)
	var runtime: Dictionary = GameStateFactory.create_contract_runtime(
		contract_id, definition.deadline_round
	)
	human["contracts"] = [runtime]
	candidate["selected_contract_id"] = contract_id
	var final_validation: Dictionary = (
		GameStateValidator.validate_setup_working_state(candidate)
	)
	if not final_validation["ok"]:
		return _selection_failure(
			state, final_validation["error"], player_id, contract_id
		)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"selected_contract_id": contract_id,
		"contract": runtime.duplicate(true),
		"state": candidate,
		"log_entries": [],
	}


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state["players"]:
		if player["id"] == player_id:
			return player
	return {}


static func _validation_failure(error: String) -> Dictionary:
	return {"ok": false, "error": error}


static func _offer_failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"contract_offer_ids": [],
		"steps_used": 0,
		"random": state.get("random", {}).duplicate(true),
		"state": state,
		"log_entries": [],
	}


static func _selection_failure(
	state: Dictionary,
	error: String,
	player_id: String,
	contract_id: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"selected_contract_id": contract_id,
		"contract": {},
		"state": state,
		"log_entries": [],
	}
