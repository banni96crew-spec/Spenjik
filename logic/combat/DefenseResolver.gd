class_name DefenseResolver


## Returns defense outcome without mutating state.
static func resolve_defense_preview(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var target: Dictionary = AttackValidator.find_player(
		state, payload["target_id"]
	)
	var result: Dictionary = {
		"blocked": false,
		"blocker": "",
		"side_effects": [],
		"description": "",
	}
	if (
		payload["card_id"] == GameIds.CARD_THUG
		and target["defense"]["cops_active"]
		and not payload["modifiers"].has(GameIds.CARD_INSIDER)
	):
		result["blocked"] = true
		result["blocker"] = GameIds.CARD_COPS
		result["description"] = "cops_block_thug"
	elif (
		payload["mode"] in [
			AttackModes.DESTROY_STASH,
			AttackModes.DESTROY_WORKSHOP,
		]
		and target["defense"]["cartel_state"] == DefenseStates.ACTIVE
	):
		result["blocked"] = true
		result["blocker"] = GameIds.CARD_CARTEL
		result["description"] = "cartel_blocks_status_destruction"
		if payload["card_id"] == GameIds.CARD_CLEANER:
			result["side_effects"] = ["deplete_cartel"]
	elif (
		payload["card_id"] == GameIds.CARD_SABOTEUR
		and target["defense"]["judge_state"] == DefenseStates.ACTIVE
	):
		result["blocked"] = true
		result["blocker"] = GameIds.CARD_JUDGE
		result["description"] = "judge_blocks_saboteur"
		result["side_effects"] = ["remove_judge"]
	return result


## Applies only the side effects declared by a defense preview.
static func apply_block_side_effects(
	state: Dictionary,
	payload: Dictionary,
	defense_result: Dictionary
) -> Dictionary:
	var target: Dictionary = AttackValidator.find_player(
		state, payload["target_id"]
	)
	for side_effect: String in defense_result["side_effects"]:
		if side_effect == "deplete_cartel":
			target["defense"]["cartel_state"] = DefenseStates.DEPLETED
		elif side_effect == "remove_judge":
			target["defense"]["judge_state"] = DefenseStates.NONE
	return state
