class_name StreetDealPhaseFlow


static func is_complete(state: Dictionary) -> bool:
	return (
		state["street_deals"]["current_deal_id"].is_empty()
		and state["street_deals"]["choices_by_player"].has(
			GameIds.PLAYER_HUMAN
		)
	)


static func enter(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if (
		state["current_phase"] != PhaseIds.ACTION
		or not PhaseStateHelper.all_players_flag(
			state, StateKeys.ACTION_DONE
		)
		or not GamePhaseController.STREET_DEAL_ROUNDS.has(state["round"])
	):
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	candidate["current_phase"] = PhaseIds.STREET_DEAL
	candidate["action_order"] = []
	candidate["active_action_player_id"] = ""
	PhaseLogBuilder.append_phase_changed(
		candidate, PhaseIds.ACTION, candidate["round"]
	)
	var generated: Dictionary = StreetDealLogic.generate_street_deal(
		candidate
	)
	if not generated["ok"]:
		return _failure(state, generated["error"])
	candidate = generated["state"]
	var final_validation: Dictionary = GameStateValidator.validate_game_state(
		candidate
	)
	if not final_validation["ok"]:
		return _failure(state, final_validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(log_start),
	}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"state": state,
		"log_entries": [],
	}
