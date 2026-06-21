class_name CombatLogBuilder


## Builds the canonical attack log without appending it.
static func build_attack_log(result: Dictionary) -> Dictionary:
	var state: Dictionary = result["state"]
	var event_type: String = (
		LogEventTypes.ATTACK_BLOCKED
		if result["blocked"] else LogEventTypes.ATTACK_EXECUTED
	)
	var details: Dictionary = {
		"attacker_id": result["attacker_id"],
		"target_id": result["target_id"],
		"card_id": result["card_id"],
		"mode": result["mode"],
		"modifiers": result["modifiers"].duplicate(),
		"engine_target_card_id": result["engine_target_card_id"],
		"cards_consumed": result["cards_consumed"].duplicate(),
	}
	if result["blocked"]:
		details["block_source"] = result["blocker"]
	return GameStateFactory.create_combat_log_entry(event_type, {
		"id": "log_%06d" % (state["combat_log"].size() + 1),
		"round": state["round"],
		"phase": state["current_phase"],
		"actor_id": result["attacker_id"],
		"target_id": result["target_id"],
		"card_id": result["card_id"],
		"summary": event_type,
		"details": details,
	})


## Builds the canonical discard log without appending it.
static func build_discard_log(
	state: Dictionary,
	player_id: String,
	card_id: String
) -> Dictionary:
	return GameStateFactory.create_combat_log_entry(
		LogEventTypes.CARD_DISCARDED,
		{
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"],
			"phase": state["current_phase"],
			"actor_id": player_id,
			"card_id": card_id,
			"summary": LogEventTypes.CARD_DISCARDED,
			"details": {"player_id": player_id, "card_id": card_id},
		}
	)
