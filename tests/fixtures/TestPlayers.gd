class_name TestPlayers


static func player(player_id: String, turf_level: int = 0) -> Dictionary:
	return GameStateFactory.create_player_state(
		player_id,
		GameIds.AI_PLAYER_IDS.has(player_id),
		turf_level
	)


static func with_hand(base: Dictionary, card_ids: Array[String]) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	result["hand"] = card_ids.duplicate()
	return result


static func find(state: Dictionary, player_id: String) -> Dictionary:
	for candidate: Dictionary in state["players"]:
		if candidate["id"] == player_id:
			return candidate
	return {}
