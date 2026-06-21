class_name GameStateRootValidator


static func validate_simple_fields(
	state: Dictionary,
	committed: bool
) -> Dictionary:
	if typeof(state["game_seed"]) != TYPE_STRING or (committed and state["game_seed"].is_empty()):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.game_seed", "empty_or_type"
		)
	if typeof(state["turf_level"]) != TYPE_INT or not TurfLevelIds.ALL.has(state["turf_level"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_TURF_LEVEL, "state.turf_level", "invalid"
		)
	if typeof(state["selected_role_id"]) != TYPE_STRING:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ROLE_ID, "state.selected_role_id", "wrong_type"
		)
	if committed and not RoleIds.ALL.has(state["selected_role_id"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ROLE_ID, "state.selected_role_id", "invalid_id"
		)
	if (
		not committed
		and state["selected_role_id"] != ""
		and not RoleIds.ALL.has(state["selected_role_id"])
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ROLE_ID, "state.selected_role_id", "invalid_id"
		)
	if typeof(state["selected_contract_id"]) != TYPE_STRING:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID, "state.selected_contract_id", "wrong_type"
		)
	if typeof(state["contract_offer_ids"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID, "state.contract_offer_ids", "wrong_type"
		)
	if committed:
		var offers: Dictionary = StateShapeValidator.unique_strings(
			state["contract_offer_ids"], ContractIds.ALL, "state.contract_offer_ids",
			ValidationErrors.INVALID_CONTRACT_ID
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
	elif state["selected_contract_id"] != "" or not state["contract_offer_ids"].is_empty():
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_CONTRACT_ID, "state.contracts", "setup_placeholder"
		)
	if typeof(state["debug"]) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.debug", "wrong_type"
		)
	var debug_shape: Dictionary = StateShapeValidator.exact_keys(
		state["debug"], ["schema_version", "last_validation_error"], "state.debug"
	)
	if (
		not debug_shape["ok"]
		or state["debug"]["schema_version"] != "1.0.0"
		or state["debug"]["last_validation_error"] != ""
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.debug", "contract"
		)
	return StateShapeValidator.ok()


static func validate_players(state: Dictionary, committed: bool) -> Dictionary:
	if typeof(state["players"]) != TYPE_ARRAY or state["players"].size() != 4:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.players", "count"
		)
	for index: int in state["players"].size():
		var player: Variant = state["players"][index]
		if typeof(player) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "state.players", "entry_type"
			)
		var result: Dictionary = PlayerStateValidator.validate(player)
		if not result["ok"]:
			return result
		if player["id"] != GameIds.PLAYER_IDS[index]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_PLAYER_ID, "state.players", "order_or_duplicate"
			)
		if player["turf_level"] != state["turf_level"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_TURF_LEVEL, "player.turf_level", "root_mismatch"
			)
		var expected_contracts: int = 1 if committed and index == 0 else 0
		if player["contracts"].size() != expected_contracts:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "player.contracts", "ownership_count"
			)
		if index == 0 and player["is_strong_ai"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_AI_STATE, "player.is_strong_ai", "human_strong"
			)
		for modifier: Dictionary in player["temporary_modifiers"]:
			if modifier["owner_player_id"] != player["id"]:
				return StateShapeValidator.fail(
					ValidationErrors.INVALID_MODIFIER_STATE,
					"player.temporary_modifiers.owner_player_id", "owner_mismatch"
				)
	if committed:
		var contract: Dictionary = state["players"][0]["contracts"][0]
		if contract["contract_id"] != state["selected_contract_id"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_CONTRACT_ID, "player.contracts", "selection_mismatch"
			)
	return StateShapeValidator.ok()


static func validate_phase_fields(state: Dictionary) -> Dictionary:
	if typeof(state["market"]) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.market", "wrong_type"
		)
	if state["current_phase"] in [PhaseIds.SETUP, PhaseIds.INCOME]:
		if state["market"] != {}:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "state.market", "must_be_empty"
			)
	else:
		var market: Dictionary = RuntimeStateValidator.validate_market_state(
			state["market"], state["round"]
		)
		if not market["ok"]:
			return market
	if typeof(state["action_order"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ACTION_ORDER, "state.action_order", "wrong_type"
		)
	if not state["action_order"].is_empty() and state["action_order"] != GameIds.PLAYER_IDS:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ACTION_ORDER, "state.action_order", "invalid_order"
		)
	if (
		typeof(state["active_action_player_id"]) != TYPE_STRING
		or (
			state["active_action_player_id"] != ""
			and not state["action_order"].has(state["active_action_player_id"])
		)
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ACTIVE_ACTION_PLAYER,
			"state.active_action_player_id", "invalid"
		)
	if state["current_phase"] == PhaseIds.ACTION:
		if state["action_order"] != GameIds.PLAYER_IDS:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_ACTION_ORDER,
				"state.action_order", "action_requires_order"
			)
		var all_done: bool = true
		for player: Dictionary in state["players"]:
			if not player["action_done"]:
				all_done = false
		if all_done != state["active_action_player_id"].is_empty():
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_ACTIVE_ACTION_PLAYER,
				"state.active_action_player_id", "action_completion_mismatch"
			)
	elif (
		not state["action_order"].is_empty()
		or not state["active_action_player_id"].is_empty()
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ACTION_ORDER,
			"state.action_order", "outside_action"
		)
	if state["current_phase"] == PhaseIds.STREET_DEAL:
		if state["round"] not in [4, 8, 12]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_ROUND, "state.round", "street_deal_round"
			)
		for player: Dictionary in state["players"]:
			if not player["action_done"]:
				return StateShapeValidator.fail(
					ValidationErrors.INVALID_STATE, "player.action_done", "street_deal"
				)
	return StateShapeValidator.ok()


static func validate_contact_offer_for_turf(state: Dictionary) -> Dictionary:
	var offer: Dictionary = state["contacts"]["pending_offer"]
	if offer.is_empty() or offer["source"] != "strong_ai_victory":
		return StateShapeValidator.ok()
	var expected_count: int = 2 if state["turf_level"] >= 7 else 3
	if offer["contact_offer_ids"].size() != expected_count:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE,
			"state.contacts.pending_offer.contact_offer_ids",
			"turf_offer_count"
		)
	return StateShapeValidator.ok()


static func validate_winner_fields(state: Dictionary) -> Dictionary:
	if typeof(state["winner_id"]) != TYPE_STRING or typeof(state["game_result"]) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.winner", "wrong_type"
		)
	if state["current_phase"] != PhaseIds.GAME_OVER:
		if state["winner_id"] != "" or state["game_result"] != {}:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "state.winner", "premature_result"
			)
		return StateShapeValidator.ok()
	if state["round"] != 15 or not GameIds.PLAYER_IDS.has(state["winner_id"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.winner_id", "game_over_contract"
		)
	var result: Dictionary = GameResultValidator.validate(state["game_result"])
	if not result["ok"]:
		return result
	if state["game_result"]["winner_id"] != state["winner_id"]:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.game_result.winner_id", "mismatch"
		)
	return StateShapeValidator.ok()
