extends GutTest

## M13 replay: same seed and state produce identical AI setup, Market, and
## Action results, including identical final random step (§7.4, FIX-021).

const ALWAYS: Array[String] = [
	GameIds.CARD_INFORMANT, GameIds.CARD_STASH,
	GameIds.CARD_THUG, GameIds.CARD_COPS,
]


func test_setup_replay_is_identical() -> void:
	var first: Dictionary = AIBotController.setup_ai_bosses(
		GameStateFactory.create_new_game_state("replay_setup_seed", 0)
	)
	var second: Dictionary = AIBotController.setup_ai_bosses(
		GameStateFactory.create_new_game_state("replay_setup_seed", 0)
	)
	assert_eq(first["ai_bosses"], second["ai_bosses"])
	assert_eq(first["strong_ai_player_id"], second["strong_ai_player_id"])
	assert_eq(first["state"]["random"]["step"], second["state"]["random"]["step"])


func test_market_replay_is_identical() -> void:
	var first: Dictionary = AIBotController.run_market_for_ai(
		_market_state(), GameIds.PLAYER_AI_1
	)
	var second: Dictionary = AIBotController.run_market_for_ai(
		_market_state(), GameIds.PLAYER_AI_1
	)
	assert_eq(first["purchases"], second["purchases"])
	assert_eq(
		first["state"]["random"]["step"], second["state"]["random"]["step"]
	)


func test_action_replay_is_identical() -> void:
	var first: Dictionary = AIBotController.run_action_for_ai(
		_action_state(), GameIds.PLAYER_AI_1
	)
	var second: Dictionary = AIBotController.run_action_for_ai(
		_action_state(), GameIds.PLAYER_AI_1
	)
	assert_eq(first["attacks"], second["attacks"])
	assert_almost_eq(float(first["attack_roll"]), float(second["attack_roll"]), 0.0001)
	assert_eq(
		first["state"]["random"]["step"], second["state"]["random"]["step"]
	)


func _market_state() -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state("replay_market_seed", 1)
	var rotating: Array = [GameIds.CARD_WORKSHOP, GameIds.CARD_LAUNDRY]
	var all_cards: Array = ALWAYS.duplicate()
	all_cards.append_array(rotating)
	state["market"] = {
		"round": 1,
		"always_available_card_ids": ALWAYS.duplicate(),
		"rotating_card_ids": rotating,
		"all_available_card_ids": all_cards,
	}
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 20
	return state


func _action_state() -> Dictionary:
	var state: Dictionary = TestGameStateFactory.action_state("replay_action_seed", 1)
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_1
	state["ai_bosses"] = [
		GameStateFactory.create_ai_boss_state(AIProfileIds.RACKETEER, true, GameIds.PLAYER_AI_1),
		GameStateFactory.create_ai_boss_state(AIProfileIds.BUILDER, false, GameIds.PLAYER_AI_2),
		GameStateFactory.create_ai_boss_state(AIProfileIds.MERCHANT, false, GameIds.PLAYER_AI_3),
	]
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["hand"] = [GameIds.CARD_THUG]
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["nal"] = 10
	return state
