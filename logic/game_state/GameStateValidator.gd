class_name GameStateValidator

const ROOT_KEYS: Array[String] = [
	"round", "current_phase", "players", "game_seed", "random", "turf_level",
	"selected_role_id", "selected_contract_id", "contract_offer_ids", "market",
	"street_deals", "contacts", "ai_bosses", "action_order",
	"active_action_player_id", "combat_log", "winner_id", "game_result", "debug",
]


## Validates a complete state that is eligible to become active state.
static func validate_game_state(state: Dictionary) -> Dictionary:
	return _validate_root(state, true)


## Validates the local pre-commit state created before setup gameplay is resolved.
static func validate_setup_working_state(state: Dictionary) -> Dictionary:
	return _validate_root(state, false)


static func validate_player_state(player: Dictionary) -> Dictionary:
	return PlayerStateValidator.validate(player)


static func validate_market_state(market: Dictionary, round_number: int) -> Dictionary:
	return RuntimeStateValidator.validate_market_state(market, round_number)


static func validate_random_state(random_state: Dictionary) -> Dictionary:
	return RuntimeStateValidator.validate_random_state(random_state)


static func validate_contract_runtime(contract: Dictionary) -> Dictionary:
	return ProgressStateValidator.validate_contract(contract)


static func validate_contact_state(contact_state: Dictionary) -> Dictionary:
	return RuntimeStateValidator.validate_contact_state(contact_state)


static func validate_global_contact_state(global_contacts: Dictionary) -> Dictionary:
	return RuntimeStateValidator.validate_global_contact_state(global_contacts)


static func validate_contact_offer_state(contact_offer: Dictionary) -> Dictionary:
	return RuntimeStateValidator.validate_contact_offer_state(contact_offer)


static func validate_street_deal_state(street_deals: Dictionary) -> Dictionary:
	return RuntimeStateValidator.validate_street_deal_state(street_deals)


static func validate_debt_state(debt: Dictionary) -> Dictionary:
	return ProgressStateValidator.validate_debt(debt)


static func validate_temporary_modifier(modifier: Dictionary) -> Dictionary:
	return ProgressStateValidator.validate_modifier(modifier)


static func validate_role_flags(role_flags: Dictionary) -> Dictionary:
	return ProgressStateValidator.validate_role_flags(role_flags)


static func validate_turf_flags(turf_flags: Dictionary) -> Dictionary:
	return ProgressStateValidator.validate_turf_flags(turf_flags)


static func validate_ai_bosses(state: Dictionary) -> Dictionary:
	return AIStateValidator.validate(state)


static func validate_combat_log_entry(
	entry: Dictionary,
	expected_index: int
) -> Dictionary:
	return GameStateLogValidator.validate(entry, expected_index)


static func _validate_root(state: Dictionary, committed: bool) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(state, ROOT_KEYS, "state")
	if not shape["ok"]:
		return shape
	if not StateShapeValidator.is_json_compatible(state):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state", "not_json_compatible"
		)
	if typeof(state["round"]) != TYPE_INT or state["round"] < 1 or state["round"] > 15:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_ROUND, "state.round", "range"
		)
	if not PhaseIds.ALL.has(state["current_phase"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_PHASE, "state.current_phase", "invalid_id"
		)
	if committed and state["current_phase"] == PhaseIds.SETUP:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_PHASE, "state.current_phase", "setup_not_committed"
		)
	if not committed and state["current_phase"] != PhaseIds.SETUP:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_PHASE, "state.current_phase", "working_not_setup"
		)
	var simple: Dictionary = GameStateRootValidator.validate_simple_fields(
		state, committed
	)
	if not simple["ok"]:
		return simple
	var players: Dictionary = GameStateRootValidator.validate_players(state, committed)
	if not players["ok"]:
		return players
	for key: String in ["random", "street_deals", "contacts"]:
		if typeof(state[key]) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "state.%s" % key, "wrong_type"
			)
	if typeof(state["ai_bosses"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_AI_STATE, "state.ai_bosses", "wrong_type"
		)
	if typeof(state["combat_log"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "state.combat_log", "wrong_type"
		)
	for result: Dictionary in [
		RuntimeStateValidator.validate_random_state(state["random"]),
		RuntimeStateValidator.validate_street_deal_state(state["street_deals"]),
		RuntimeStateValidator.validate_global_contact_state(state["contacts"]),
	]:
		if not result["ok"]:
			return result
	var contact_turf: Dictionary = GameStateRootValidator.validate_contact_offer_for_turf(
		state
	)
	if not contact_turf["ok"]:
		return contact_turf
	if state["random"]["seed"] != state["game_seed"]:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_RANDOM_STATE, "state.random.seed", "seed_mismatch"
		)
	var phase_result: Dictionary = GameStateRootValidator.validate_phase_fields(state)
	if not phase_result["ok"]:
		return phase_result
	if committed:
		var ai_result: Dictionary = AIStateValidator.validate(state)
		if not ai_result["ok"]:
			return ai_result
	elif state["ai_bosses"] != []:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_AI_STATE, "state.ai_bosses", "setup_placeholder"
		)
	for index: int in state["combat_log"].size():
		var log_result: Dictionary = GameStateLogValidator.validate(
			state["combat_log"][index], index + 1
		)
		if not log_result["ok"]:
			return log_result
	return GameStateRootValidator.validate_winner_fields(state)
