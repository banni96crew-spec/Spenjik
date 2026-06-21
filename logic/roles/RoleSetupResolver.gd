class_name RoleSetupResolver


## Applies one valid role to the human setup player without mutating input.
static func apply(state: Dictionary, selected_role_id: String) -> Dictionary:
	if not RoleIds.ALL.has(selected_role_id):
		return _failure(state, ValidationErrors.INVALID_ROLE_ID)
	var human: Dictionary = _find_human(state)
	if human.is_empty():
		return _failure(state, ValidationErrors.INVALID_TARGET)
	var flags: Dictionary = GameStateValidator.validate_role_flags(
		human.get("role_flags", {})
	)
	if not flags["ok"]:
		return _failure(state, ValidationErrors.REQUIREMENT_NOT_MET)
	var candidate: Dictionary = state.duplicate(true)
	human = _find_human(candidate)
	human["role_flags"] = GameStateFactory.create_role_flags()
	human["nal"] = get_starting_nal(selected_role_id)
	if selected_role_id == RoleIds.ENFORCER:
		human["defense"]["cops_active"] = true
		human["defense"]["cops_timer"] = 0
	candidate["selected_role_id"] = selected_role_id
	var validation: Dictionary = GameStateValidator.validate_setup_working_state(
		candidate
	)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"selected_role_id": selected_role_id,
		"player_id": GameIds.PLAYER_HUMAN,
		"state": candidate,
		"log_entries": [],
	}


static func get_starting_nal(role_id: String) -> int:
	var definition: RoleDefinition = RoleCatalog.get_by_id(role_id)
	return definition.starting_nal if definition != null else 5


static func _find_human(state: Dictionary) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == GameIds.PLAYER_HUMAN:
			return player
	return {}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"selected_role_id": "",
		"player_id": GameIds.PLAYER_HUMAN,
		"state": state,
		"log_entries": [],
	}
