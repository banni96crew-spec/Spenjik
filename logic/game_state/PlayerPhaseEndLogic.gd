class_name PlayerPhaseEndLogic


## Marks one player ready for Action through a pure phase-safe mutation.
static func end_market_for_player(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	if state.get("current_phase") != PhaseIds.MARKET:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _failure(state, ValidationErrors.INVALID_PLAYER_ID)
	if player["ready_for_action"]:
		return _failure(state, ValidationErrors.PLAYER_ALREADY_READY)
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	_find_player(candidate, player_id)["ready_for_action"] = true
	_append_player_event(
		candidate, LogEventTypes.MARKET_ENDED_FOR_PLAYER, player_id
	)
	return _validated(state, candidate, log_start)


## Marks the active player's Action complete through a pure phase-safe mutation.
static func end_action_for_player(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	if state.get("current_phase") != PhaseIds.ACTION:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _failure(state, ValidationErrors.INVALID_PLAYER_ID)
	if state.get("active_action_player_id") != player_id:
		return _failure(state, ValidationErrors.NOT_ACTIVE_PLAYER)
	if player["action_done"]:
		return _failure(state, ValidationErrors.PLAYER_ALREADY_ACTION_DONE)
	var candidate: Dictionary = state.duplicate(true)
	var log_start: int = candidate["combat_log"].size()
	_find_player(candidate, player_id)["action_done"] = true
	_append_player_event(
		candidate, LogEventTypes.ACTION_ENDED_FOR_PLAYER, player_id
	)
	if PhaseStateHelper.all_players_flag(candidate, StateKeys.ACTION_DONE):
		candidate["active_action_player_id"] = ""
	return _validated(state, candidate, log_start)


static func _append_player_event(
	state: Dictionary,
	event_type: String,
	player_id: String
) -> void:
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		event_type, {
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"],
			"phase": state["current_phase"],
			"actor_id": player_id,
			"summary": event_type,
			"details": {"player_id": player_id},
		}
	))


static func _validated(
	original: Dictionary,
	candidate: Dictionary,
	log_start: int
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failure(original, validation["error"])
	return _success(candidate, log_start)


static func _success(candidate: Dictionary, log_start: int) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(log_start),
	}


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"state": state,
		"log_entries": [],
	}
