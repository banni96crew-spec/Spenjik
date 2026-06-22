extends Node

signal state_changed(state: Dictionary)
signal action_failed(error: String, result: Dictionary)
signal phase_changed(phase_id: String)
signal game_started(state: Dictionary)
signal game_ended(result: Dictionary)

var state: Dictionary = {}

func has_active_game() -> bool:
	return not state.is_empty()
func get_state_snapshot() -> Dictionary:
	return state.duplicate(true)
func get_view() -> Dictionary:
	return GameViewBuilder.build_view(state)
func reset_game() -> Dictionary:
	state = {}
	state_changed.emit({})
	return {"ok": true, "error": ValidationErrors.OK, "state": {}}
func start_new_game(config: Dictionary) -> Dictionary:
	var result: Dictionary = GameSetupCoordinator.start(config)
	if not result["ok"]:
		return _failed(result)
	state = result["state"].duplicate(true)
	var safe: Dictionary = _safe_result(result)
	game_started.emit(state.duplicate(true))
	state_changed.emit(state.duplicate(true))
	return safe
func get_available_roles() -> Dictionary:
	return GameViewBuilder.get_available_roles()
func get_available_turf_levels() -> Dictionary:
	return GameViewBuilder.get_available_turf_levels()
func generate_contract_offers(config: Dictionary) -> Dictionary:
	return GameSetupCoordinator.preview_contract_offers(config).duplicate(true)
func get_contract_offers() -> Dictionary:
	return GameViewBuilder.get_contract_offers(state)
func advance_phase() -> Dictionary:
	return _commit(GamePhaseController.advance_phase(_working()), get_current_phase())
func end_market_for_player(player_id: String) -> Dictionary:
	return _commit(GamePhaseController.end_market_for_player(_working(), player_id))
func end_action_for_player(player_id: String) -> Dictionary:
	var result: Dictionary = GamePhaseController.end_action_for_player(
		_working(), player_id
	)
	if result["ok"] and not result["state"]["active_action_player_id"].is_empty():
		result = _combine_with_advance(result)
	return _commit(result)
func skip_action_for_player(player_id: String) -> Dictionary:
	var result: Dictionary = PlayerPhaseEndLogic.skip_action_for_player(
		_working(), player_id
	)
	if result["ok"] and not result["state"]["active_action_player_id"].is_empty():
		result = _combine_with_advance(result)
	return _commit(result)
func get_current_phase() -> String:
	return str(state.get("current_phase", ""))
func get_round() -> int:
	return int(state.get("round", 0))
func buy_card(player_id: String, card_id: String) -> Dictionary:
	return _commit(MarketLogic.buy_card(_working(), player_id, card_id))
func rebuild_district_control(player_id: String) -> Dictionary:
	return _commit(MarketLogic.rebuild_district_control(_working(), player_id))
func get_market_view(player_id: String) -> Dictionary:
	return GameViewBuilder.get_market_view(state, player_id)
func get_card_price_preview(player_id: String, card_id: String) -> Dictionary:
	return _select(PriceLogic.get_card_price(state, player_id, card_id))
func get_purchase_disabled_reason(player_id: String, card_id: String) -> String:
	if state.is_empty():
		return ValidationErrors.GAME_NOT_STARTED
	return str(MarketLogic.can_buy_card(state, player_id, card_id)["error"])
func get_income_preview(player_id: String) -> Dictionary:
	return _select(IncomePreviewBuilder.get_income_preview(state, player_id))
func get_cops_upkeep_preview(player_id: String) -> Dictionary:
	return _select(IncomePreviewBuilder.get_cops_upkeep_preview(state, player_id))
func get_protected_nal_preview(player_id: String) -> Dictionary:
	return _select(IncomePreviewBuilder.get_protected_nal_preview(state, player_id))
func execute_attack(payload: Dictionary) -> Dictionary:
	return _commit(CombatEngine.resolve_attack(_working(), payload))
func discard_war_card(player_id: String, card_id: String) -> Dictionary:
	return _commit(CombatEngine.discard_war_card(_working(), player_id, card_id))
func get_combat_preview(payload: Dictionary) -> Dictionary:
	return _select(CombatEngine.get_combat_preview(state, payload))
func get_valid_targets(action_payload: Dictionary) -> Dictionary:
	return _select(CombatEngine.get_valid_targets(state, action_payload))
func get_valid_engine_targets(attacker_id: String, target_id: String) -> Dictionary:
	return _select(CombatEngine.get_valid_engine_targets(state, attacker_id, target_id))
func get_action_disabled_reason(action_payload: Dictionary) -> String:
	if state.is_empty():
		return ValidationErrors.GAME_NOT_STARTED
	return str(CombatEngine.validate_attack(state, action_payload)["error"])
func claim_contract(player_id: String, contract_id: String) -> Dictionary:
	return _commit(ContractLogic.claim_contract(_working(), player_id, contract_id))
func get_contract_state(player_id: String) -> Dictionary:
	return GameViewBuilder.get_contract_state(state, player_id)
func get_contract_claim_disabled_reason(player_id: String, contract_id: String) -> String:
	if state.is_empty():
		return ValidationErrors.GAME_NOT_STARTED
	return str(ContractLogic.validate_contract_claim(state, player_id, contract_id)["error"])
func select_street_deal(payload: Dictionary) -> Dictionary:
	return _commit(StreetDealLogic.select_street_deal(_working(), payload))
func get_street_deal_view(player_id: String) -> Dictionary:
	return GameViewBuilder.get_street_deal_view(state, player_id)
func get_street_deal_disabled_reason(payload: Dictionary) -> String:
	if state.is_empty():
		return ValidationErrors.GAME_NOT_STARTED
	return str(StreetDealLogic.validate_street_deal_choice(state, payload)["error"])
func get_debt_status(player_id: String) -> Dictionary:
	return GameViewBuilder.get_debt_status(state, player_id)
func select_contact(payload: Dictionary) -> Dictionary:
	return _commit(ContactLogic.select_contact(_working(), payload))
func activate_contact(payload: Dictionary) -> Dictionary:
	return _commit(ContactLogic.activate_contact(_working(), payload))
func get_contact_offer(player_id: String) -> Dictionary:
	return GameViewBuilder.get_contact_offer(state, player_id)
func get_contact_state(player_id: String) -> Dictionary:
	return GameViewBuilder.get_contact_state(state, player_id)
func get_contact_disabled_reason(payload: Dictionary) -> String:
	if state.is_empty():
		return ValidationErrors.GAME_NOT_STARTED
	return str(ContactLogic.validate_contact_selection(state, payload)["error"])
func run_market_for_ai(player_id: String) -> Dictionary:
	return _commit(AIBotController.run_market_for_ai(_working(), player_id))
func run_action_for_ai(player_id: String) -> Dictionary:
	return _commit(AIPhaseCoordinator.run_action_and_advance(_working(), player_id))
func run_all_ai_market() -> Dictionary:
	return _commit(AIPhaseCoordinator.run_all_market(_working()))
func run_all_ai_actions() -> Dictionary:
	return _commit(AIPhaseCoordinator.run_all_actions(_working()))
func get_ai_state(player_id: String) -> Dictionary:
	return GameViewBuilder.get_ai_state(state, player_id)
func get_ai_profiles_view() -> Dictionary:
	return GameViewBuilder.get_ai_profiles_view(state)
func get_turf_level() -> int:
	return TurfLevelIds.BASE if state.is_empty() else int(state["turf_level"])
func get_turf_level_view() -> Dictionary:
	return GameViewBuilder.get_turf_level_view(state)
func _working() -> Dictionary:
	return state.duplicate(true)
func _select(result: Dictionary) -> Dictionary:
	if state.is_empty():
		return _selector_failure()
	return result.duplicate(true)
func _commit(result: Dictionary, previous_phase: String = "") -> Dictionary:
	if state.is_empty():
		return _failed(_failure(ValidationErrors.GAME_NOT_STARTED))
	if not result.get("ok", false):
		return _failed(result)
	var candidate: Dictionary = result.get("state", {})
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failed(_failure(validation["error"]))
	var old_phase: String = get_current_phase() if previous_phase.is_empty() else previous_phase
	state = candidate.duplicate(true)
	var safe: Dictionary = _safe_result(result)
	state_changed.emit(state.duplicate(true))
	if old_phase != get_current_phase():
		phase_changed.emit(get_current_phase())
	if old_phase != PhaseIds.GAME_OVER and get_current_phase() == PhaseIds.GAME_OVER:
		game_ended.emit(state["game_result"].duplicate(true))
	return safe
func _combine_with_advance(result: Dictionary) -> Dictionary:
	var advanced: Dictionary = GamePhaseController.advance_action_player(result["state"])
	if not advanced["ok"]:
		return advanced
	var combined: Dictionary = result.duplicate(true)
	combined["state"] = advanced["state"]
	combined["log_entries"].append_array(advanced["log_entries"])
	return combined
func _failed(result: Dictionary) -> Dictionary:
	var safe: Dictionary = result.duplicate(true)
	safe["state"] = state.duplicate(true)
	if not safe.has("log_entries"):
		safe["log_entries"] = []
	action_failed.emit(str(safe.get("error", ValidationErrors.INVALID_STATE)), safe.duplicate(true))
	return safe
func _safe_result(result: Dictionary) -> Dictionary:
	var safe: Dictionary = result.duplicate(true)
	safe["state"] = state.duplicate(true)
	return safe
func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error, "state": {}, "log_entries": []}
func _selector_failure() -> Dictionary:
	return {"ok": false, "error": ValidationErrors.GAME_NOT_STARTED}
