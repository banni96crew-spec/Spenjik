class_name GamePhaseController

const STREET_DEAL_ROUNDS: Array[int] = [4, 8, 12]
## Reports whether exactly one M5-owned phase transition can run.
static func can_advance_phase(state: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate_transition_input(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	match state["current_phase"]:
		PhaseIds.SETUP:
			return _success(state)
		PhaseIds.INCOME, PhaseIds.STREET_DEAL:
			return _failure(state, ValidationErrors.PHASE_NOT_READY)
		PhaseIds.MARKET:
			return (
				_success(state)
				if PhaseStateHelper.all_players_flag(
					state, StateKeys.READY_FOR_ACTION
				)
				else _failure(state, ValidationErrors.PHASE_NOT_READY)
			)
		PhaseIds.ACTION:
			return (
				_success(state)
				if PhaseStateHelper.all_players_flag(
					state, StateKeys.ACTION_DONE
				)
				else _failure(state, ValidationErrors.PHASE_NOT_READY)
			)
		PhaseIds.GAME_OVER:
			return _failure(state, ValidationErrors.GAME_ALREADY_OVER)
	return _failure(state, ValidationErrors.INVALID_PHASE)

## Performs one legal transition and returns a validated candidate snapshot.
static func advance_phase(state: Dictionary) -> Dictionary:
	var readiness: Dictionary = can_advance_phase(state)
	if not readiness["ok"]:
		return readiness
	match state["current_phase"]:
		PhaseIds.SETUP:
			return enter_income_phase(state)
		PhaseIds.MARKET:
			return enter_action_phase(state)
		PhaseIds.ACTION:
			if state["round"] == 15:
				return enter_game_over_phase(state)
			if STREET_DEAL_ROUNDS.has(state["round"]):
				return enter_street_deal_phase(state)
			return enter_income_phase(state)
	return _failure(state, ValidationErrors.PHASE_NOT_READY)


static func enter_income_phase(state: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate_transition_input(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	var from_phase: String = state["current_phase"]
	if from_phase == PhaseIds.STREET_DEAL:
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	if from_phase == PhaseIds.ACTION:
		if (
			not PhaseStateHelper.all_players_flag(
				state, StateKeys.ACTION_DONE
			)
			or state["round"] >= 15
			or STREET_DEAL_ROUNDS.has(state["round"])
		):
			return _failure(state, ValidationErrors.PHASE_NOT_READY)
	elif from_phase != PhaseIds.SETUP:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	var round_before: int = candidate["round"]
	if from_phase == PhaseIds.ACTION:
		candidate["round"] += 1
	else:
		candidate["round"] = 1
	candidate["current_phase"] = PhaseIds.INCOME
	PhaseStateHelper.apply_round_reset(candidate)
	if candidate["round"] != round_before:
		PhaseLogBuilder.append_round_started(candidate)
	PhaseLogBuilder.append_phase_changed(candidate, from_phase, round_before)
	return _validated_result(state, candidate, log_start)


static func enter_market_phase(state: Dictionary) -> Dictionary:
	var validation: Dictionary = _validate_transition_input(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if state["current_phase"] != PhaseIds.INCOME:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	return _failure(state, ValidationErrors.PHASE_NOT_READY)


static func enter_action_phase(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if state["current_phase"] != PhaseIds.MARKET:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	if not PhaseStateHelper.all_players_flag(
		state, StateKeys.READY_FOR_ACTION
	):
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	candidate["current_phase"] = PhaseIds.ACTION
	PhaseStateHelper.apply_action_reset(candidate)
	PhaseLogBuilder.append_action_started(
		candidate, candidate["active_action_player_id"]
	)
	PhaseStateHelper.consume_active_skips(candidate)
	PhaseLogBuilder.append_phase_changed(
		candidate, PhaseIds.MARKET, candidate["round"]
	)
	return _validated_result(state, candidate, log_start)


static func advance_action_player(state: Dictionary) -> Dictionary:
	var validation: Dictionary = PhaseStateHelper.validate_action_advancement_input(
		state
	)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if state["current_phase"] != PhaseIds.ACTION:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	var active_id: String = state["active_action_player_id"]
	if active_id.is_empty():
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	var active: Dictionary = PhaseStateHelper.find_player(state, active_id)
	if not active["action_done"] and not active["skip_next_action"]:
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	var advancement: Dictionary = PhaseStateHelper.advance_after_active(candidate)
	if not advancement["ok"]:
		return _failure(state, advancement["error"])
	return _validated_result(state, candidate, log_start)


static func enter_street_deal_phase(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if (
		state["current_phase"] != PhaseIds.ACTION
		or not PhaseStateHelper.all_players_flag(
			state, StateKeys.ACTION_DONE
		)
		or not STREET_DEAL_ROUNDS.has(state["round"])
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
	return _validated_result(state, candidate, log_start)


static func enter_game_over_phase(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if (
		state["current_phase"] != PhaseIds.ACTION
		or state["round"] != 15
		or not PhaseStateHelper.all_players_flag(
			state, StateKeys.ACTION_DONE
		)
	):
		return _failure(state, ValidationErrors.PHASE_NOT_READY)
	var winner: Dictionary = WinnerResolver.resolve(state)
	if not winner["ok"]:
		return _failure(state, winner["error"])
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	candidate["current_phase"] = PhaseIds.GAME_OVER
	candidate["action_order"] = []
	candidate["active_action_player_id"] = ""
	candidate["winner_id"] = winner["winner_id"]
	candidate["game_result"] = winner["game_result"].duplicate(true)
	PhaseLogBuilder.append_game_over(candidate)
	PhaseLogBuilder.append_winner(candidate)
	PhaseLogBuilder.append_phase_changed(
		candidate, PhaseIds.ACTION, candidate["round"]
	)
	return _validated_result(state, candidate, log_start)


static func reset_round_flags(state: Dictionary) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	PhaseStateHelper.apply_round_reset(candidate)
	return _validated_result(state, candidate)


static func reset_market_flags(state: Dictionary) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	PhaseStateHelper.apply_market_reset(candidate)
	return _validated_result(state, candidate)


static func reset_action_flags(state: Dictionary) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	PhaseStateHelper.apply_action_reset(candidate)
	return _validated_result(state, candidate)


static func _validate_transition_input(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return {"ok": false, "error": ValidationErrors.GAME_NOT_STARTED}
	if state.get("current_phase") == PhaseIds.SETUP:
		var candidate: Dictionary = state.duplicate(true)
		candidate["current_phase"] = PhaseIds.INCOME
		candidate["round"] = 1
		PhaseStateHelper.apply_round_reset(candidate)
		return GameStateValidator.validate_game_state(candidate)
	return GameStateValidator.validate_game_state(state)


static func _validated_result(
	original: Dictionary,
	candidate: Dictionary,
	log_start: int = -1
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failure(original, validation["error"])
	var start: int = candidate["combat_log"].size() if log_start < 0 else log_start
	return _success(candidate, candidate["combat_log"].slice(start))


static func _success(
	state: Dictionary,
	log_entries: Array = []
) -> Dictionary:
	return {"ok": true, "error": ValidationErrors.OK,
		"state": state, "log_entries": log_entries}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {"ok": false, "error": error, "state": state, "log_entries": []}
