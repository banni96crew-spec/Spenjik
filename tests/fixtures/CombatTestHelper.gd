class_name CombatTestHelper


static func state_with_hand(
	card_ids: Array[String],
	game_seed: String = "test_seed_combat"
) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.action_state(game_seed)
	TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)["hand"] = card_ids.duplicate()
	return state


static func payload(
	card_id: String,
	mode: String = "",
	target_id: String = GameIds.PLAYER_AI_1,
	modifiers: Array[String] = [],
	engine_target_card_id: String = ""
) -> Dictionary:
	return {
		"attacker_id": GameIds.PLAYER_HUMAN,
		"target_id": target_id,
		"card_id": card_id,
		"mode": mode,
		"modifiers": modifiers.duplicate(),
		"engine_target_card_id": engine_target_card_id,
	}


static func player(state: Dictionary, player_id: String) -> Dictionary:
	return TestPlayers.find(state, player_id)


static func target(state: Dictionary) -> Dictionary:
	return player(state, GameIds.PLAYER_AI_1)


static func attacker(state: Dictionary) -> Dictionary:
	return player(state, GameIds.PLAYER_HUMAN)
