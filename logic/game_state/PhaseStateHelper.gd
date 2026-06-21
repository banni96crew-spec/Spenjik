class_name PhaseStateHelper


static func all_players_flag(state: Dictionary, key: String) -> bool:
	for player: Dictionary in state.get("players", []):
		if not player.get(key, false):
			return false
	return state.get("players", []).size() == GameIds.PLAYER_IDS.size()


static func apply_round_reset(state: Dictionary) -> void:
	state["market"] = {}
	state["action_order"] = []
	state["active_action_player_id"] = ""
	for player: Dictionary in state["players"]:
		player["ready_for_action"] = false
		player["action_done"] = false
		player["purchased_this_round"] = []
		var reset_player: Dictionary = RoleLogic.reset_round_role_flags(
			player, state["selected_role_id"]
		)
		player["role_flags"] = reset_player["role_flags"]
		player["turf_flags"]["ai_first_war_discount_used_this_round"] = false
		ContactLogic.reset_round_contact_usage(player)
		var modifiers: Array = []
		for modifier: Dictionary in player["temporary_modifiers"]:
			if modifier["expires_at"] != "end_of_round":
				modifiers.append(modifier)
		player["temporary_modifiers"] = modifiers


static func apply_market_reset(state: Dictionary) -> void:
	for player: Dictionary in state.get("players", []):
		player["purchased_this_round"] = []
		player["ready_for_action"] = false


static func apply_action_reset(state: Dictionary) -> void:
	for player: Dictionary in state["players"]:
		player["action_done"] = false
	state["action_order"] = GameIds.PLAYER_IDS.duplicate()
	state["active_action_player_id"] = GameIds.PLAYER_HUMAN


static func validate_action_advancement_input(state: Dictionary) -> Dictionary:
	if (
		state.get("current_phase") == PhaseIds.ACTION
		and state.get("action_order", []).has(
			state.get("active_action_player_id", "")
		)
		and all_players_flag(state, StateKeys.ACTION_DONE)
	):
		var normalized: Dictionary = state.duplicate(true)
		normalized["active_action_player_id"] = ""
		return GameStateValidator.validate_game_state(normalized)
	return GameStateValidator.validate_game_state(state)


static func advance_after_active(state: Dictionary) -> Dictionary:
	var active_id: String = state["active_action_player_id"]
	var active: Dictionary = find_player(state, active_id)
	if not active["action_done"] and not active["skip_next_action"]:
		return {"ok": false, "error": ValidationErrors.PHASE_NOT_READY}
	consume_skip(state, active_id)
	set_next_active(state, state["action_order"].find(active_id) + 1)
	consume_active_skips(state)
	return {"ok": true, "error": ValidationErrors.OK}


static func consume_active_skips(state: Dictionary) -> void:
	while not state["active_action_player_id"].is_empty():
		var active_id: String = state["active_action_player_id"]
		var player: Dictionary = find_player(state, active_id)
		if not player["skip_next_action"]:
			return
		consume_skip(state, active_id)
		set_next_active(state, state["action_order"].find(active_id) + 1)


static func consume_skip(state: Dictionary, player_id: String) -> void:
	var player: Dictionary = find_player(state, player_id)
	if player["skip_next_action"]:
		player["skip_next_action"] = false
		player["action_done"] = true
		PhaseLogBuilder.append_action_skipped(state, player_id)


static func set_next_active(state: Dictionary, start_index: int) -> void:
	state["active_action_player_id"] = ""
	for index: int in range(start_index, state["action_order"].size()):
		var player_id: String = state["action_order"][index]
		if not find_player(state, player_id)["action_done"]:
			state["active_action_player_id"] = player_id
			return


static func find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state["players"]:
		if player["id"] == player_id:
			return player
	return {}
