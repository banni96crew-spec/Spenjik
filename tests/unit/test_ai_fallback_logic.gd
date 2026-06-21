extends GutTest

## M13 §12.7 AI fallbacks: Market end variants, buy_cheapest_valid, action
## attack_best_target (blocked only), discard_action_cards. Never bypass
## validation; never override a failed probability roll (caller-gated).

const ALWAYS: Array[String] = [
	GameIds.CARD_INFORMANT, GameIds.CARD_STASH,
	GameIds.CARD_THUG, GameIds.CARD_COPS,
]


func _market_state(rotating: Array, seed_value: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state(seed_value, 1)
	var all_cards: Array = ALWAYS.duplicate()
	all_cards.append_array(rotating)
	state["market"] = {
		"round": 1,
		"always_available_card_ids": ALWAYS.duplicate(),
		"rotating_card_ids": rotating.duplicate(),
		"all_available_card_ids": all_cards,
	}
	return state


func _action_state_active_ai1(seed_value: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.action_state(seed_value, 1)
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_1
	return state


func _all_opponents_get_cops(state: Dictionary) -> void:
	for player_id: String in [GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_2, GameIds.PLAYER_AI_3]:
		TestPlayers.find(state, player_id)["defense"]["cops_active"] = true


func test_hold_nal_market_fallback_buys_nothing() -> void:
	var state: Dictionary = _market_state([], "fallback_hold")
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = AIFallbackLogic.apply_market_fallback(
		state, GameIds.PLAYER_AI_1, AIProfileCatalog.get_by_id(AIProfileIds.BUILDER)
	)
	assert_false(result["purchased"])
	assert_eq(result["fallback_used"], "")
	assert_eq(result["state"], before)


func test_end_phase_market_fallback_buys_nothing() -> void:
	var state: Dictionary = _market_state([], "fallback_end")
	var result: Dictionary = AIFallbackLogic.apply_market_fallback(
		state, GameIds.PLAYER_AI_1, AIProfileCatalog.get_by_id(AIProfileIds.SCHEMER)
	)
	assert_false(result["purchased"])


func test_buy_cheapest_valid_buys_cheapest_reserve_safe_card() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_LAUNDRY], "fallback_cheap")
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["nal"] = 10
	var result: Dictionary = AIFallbackLogic.apply_market_fallback(
		state, GameIds.PLAYER_AI_2, AIProfileCatalog.get_by_id(AIProfileIds.PARANOID)
	)
	assert_true(result["purchased"])
	assert_eq(result["fallback_used"], "buy_cheapest_valid")
	assert_eq(result["purchase"]["price"], 2, "cheapest valid card costs 2")


func test_buy_cheapest_valid_respects_reserve() -> void:
	var state: Dictionary = _market_state([], "fallback_cheap_reserve")
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["nal"] = 5
	var result: Dictionary = AIFallbackLogic.apply_market_fallback(
		state, GameIds.PLAYER_AI_2, AIProfileCatalog.get_by_id(AIProfileIds.PARANOID)
	)
	assert_false(result["purchased"], "reserve 4 leaves nothing reserve-safe at 5 Nal")


func test_attack_best_target_resolves_one_blocked_attack() -> void:
	var state: Dictionary = _action_state_active_ai1("fallback_attack_blocked")
	_all_opponents_get_cops(state)
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["hand"] = [GameIds.CARD_THUG]
	var result: Dictionary = AIFallbackLogic.apply_action_fallback(
		state, GameIds.PLAYER_AI_1,
		AIProfileCatalog.get_by_id(AIProfileIds.RACKETEER), {}
	)
	assert_eq(result["attacks"].size(), 1)
	assert_true(result["attacks"][0]["blocked"])
	assert_eq(result["fallback_used"], "attack_best_target")


func test_attack_best_target_no_blocked_option_is_no_op() -> void:
	var state: Dictionary = _action_state_active_ai1("fallback_attack_none")
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["hand"] = [GameIds.CARD_THUG]
	var result: Dictionary = AIFallbackLogic.apply_action_fallback(
		state, GameIds.PLAYER_AI_1,
		AIProfileCatalog.get_by_id(AIProfileIds.RACKETEER), {}
	)
	assert_eq(result["attacks"].size(), 0)
	assert_eq(result["fallback_used"], "")


func test_attack_best_target_runs_after_successful_unblocked_attack() -> void:
	var seed_value: String = _seed_for_roll(0.8, true)
	var state: Dictionary = _action_state_active_ai1(seed_value)
	_all_opponents_get_cops(state)
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["hand"] = [
		GameIds.CARD_THUG, GameIds.CARD_INSIDER, GameIds.CARD_THUG,
	]
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["is_strong_ai"] = true
	state["ai_bosses"] = [
		GameStateFactory.create_ai_boss_state(
			AIProfileIds.RACKETEER, true, GameIds.PLAYER_AI_1
		),
		GameStateFactory.create_ai_boss_state(
			AIProfileIds.BUILDER, false, GameIds.PLAYER_AI_2
		),
		GameStateFactory.create_ai_boss_state(
			AIProfileIds.MERCHANT, false, GameIds.PLAYER_AI_3
		),
	]
	var result: Dictionary = AIBotController.run_action_for_ai(
		state, GameIds.PLAYER_AI_1
	)
	assert_true(result["ok"], str(result))
	assert_eq(result["attacks"].size(), 2)
	assert_false(result["attacks"][0]["blocked"])
	assert_true(result["attacks"][1]["blocked"])
	assert_eq(result["fallback_used"], "attack_best_target")


func test_discard_action_cards_discards_unusable_war_cards() -> void:
	var state: Dictionary = _action_state_active_ai1("fallback_discard")
	_all_opponents_get_cops(state)
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["hand"] = [GameIds.CARD_THUG]
	var profile: AIProfileDefinition = _discard_profile()
	var result: Dictionary = AIFallbackLogic.apply_action_fallback(
		state, GameIds.PLAYER_AI_1, profile, {}
	)
	assert_eq(result["discarded"], [GameIds.CARD_THUG])
	assert_eq(result["fallback_used"], "discard_action_cards")
	assert_false(
		TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)["hand"].has(GameIds.CARD_THUG)
	)


func _seed_for_roll(threshold: float, below: bool) -> String:
	for index: int in 1000:
		var candidate: String = "fb_roll_%s_%d" % ["lo" if below else "hi", index]
		var value: float = SeededRandom.seeded_random(candidate, 0)
		if below and value <= threshold:
			return candidate
		if not below and value > threshold:
			return candidate
	return "fallback_after_success"


func _discard_profile() -> AIProfileDefinition:
	var profile: AIProfileDefinition = AIProfileDefinition.new()
	profile.id = "test_discard"
	profile.purchase_scores = {}
	profile.attack_probability = 1.0
	profile.target_weights = {}
	profile.minimum_reserve_nal = 0
	profile.fallback = "discard_action_cards"
	return profile
