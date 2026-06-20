class_name PhaseLogBuilder


static func append_round_started(state: Dictionary) -> void:
	_append(
		state,
		LogEventTypes.ROUND_STARTED,
		"",
		{"round": state["round"]}
	)


static func append_phase_changed(
	state: Dictionary,
	from_phase: String,
	round_before: int
) -> void:
	_append(state, LogEventTypes.PHASE_CHANGED, "", {
		"from_phase": from_phase,
		"to_phase": state["current_phase"],
		"round_before": round_before,
		"round_after": state["round"],
	})


static func append_action_started(
	state: Dictionary,
	active_player_id: String
) -> void:
	_append(state, LogEventTypes.ACTION_STARTED, "", {
		"action_order": state["action_order"].duplicate(),
		"active_player_id": active_player_id,
	})


static func append_action_skipped(
	state: Dictionary,
	player_id: String
) -> void:
	_append(
		state,
		LogEventTypes.ACTION_SKIPPED,
		player_id,
		{"player_id": player_id}
	)


static func append_game_over(state: Dictionary) -> void:
	_append(
		state,
		LogEventTypes.GAME_OVER_REACHED,
		"",
		{"round": state["round"]}
	)


static func append_winner(state: Dictionary) -> void:
	var result: Dictionary = state["game_result"]
	_append(state, LogEventTypes.WINNER_RESOLVED, "", {
		"winner_id": result["winner_id"],
		"final_scores": result["final_scores"].duplicate(true),
		"tie_break_used": result["tie_break_used"],
		"tie_break_steps": result["tie_break_steps"].duplicate(true),
		"turf_level_10_ai_win_applied":
			result["turf_level_10_ai_win_applied"],
	})


static func _append(
	state: Dictionary,
	event_type: String,
	actor_id: String,
	details: Dictionary
) -> void:
	var entry: Dictionary = GameStateFactory.create_combat_log_entry(
		event_type,
		{
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"],
			"phase": state["current_phase"],
			"actor_id": actor_id,
			"summary": event_type,
			"details": details,
		}
	)
	state["combat_log"].append(entry)
