extends GutTest

## M13 §12.3 AI Market: scoring, reserve rule, multi-buy, tie-break, missing
## score = 0, Turf Level 9 War multiplier, and phase-safe Market end.

const ALWAYS: Array[String] = [
	GameIds.CARD_INFORMANT, GameIds.CARD_STASH,
	GameIds.CARD_THUG, GameIds.CARD_COPS,
]


func _market_state(
	rotating: Array,
	seed_value: String = "ai_market_seed"
) -> Dictionary:
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


func _builder() -> AIProfileDefinition:
	return AIProfileCatalog.get_by_id(AIProfileIds.BUILDER)


func test_run_market_buys_highest_score_then_stops_on_reserve() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_WORKSHOP])
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 11
	var result: Dictionary = AIBotController.run_market_for_ai(state, GameIds.PLAYER_AI_1)
	assert_true(result["ok"])
	assert_eq(result["purchases"].size(), 1)
	assert_eq(result["purchases"][0]["card_id"], GameIds.CARD_STASH)
	assert_eq(result["purchases"][0]["score"], 100)
	var ai: Dictionary = TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)
	assert_true(ai["ready_for_action"])
	assert_eq(ai["nal"], 3)


func test_run_market_buys_multiple_and_avoids_duplicates() -> void:
	var state: Dictionary = _market_state(
		[GameIds.CARD_WORKSHOP, GameIds.CARD_LAUNDRY, GameIds.CARD_CARTEL]
	)
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 40
	var result: Dictionary = AIBotController.run_market_for_ai(state, GameIds.PLAYER_AI_1)
	var bought: Array[String] = []
	for purchase: Dictionary in result["purchases"]:
		bought.append(purchase["card_id"])
	assert_true(bought.has(GameIds.CARD_STASH))
	assert_true(bought.has(GameIds.CARD_WORKSHOP))
	assert_eq(bought.size(), _unique(bought).size(), "no duplicate purchases")


func test_build_candidates_respects_reserve_rule() -> void:
	var state: Dictionary = _market_state([])
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 10
	var built: Dictionary = AIPurchaseLogic.build_purchase_candidates(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	var ids: Array[String] = _candidate_ids(built["candidates"])
	assert_false(ids.has(GameIds.CARD_STASH), "stash drops nal below reserve 3")
	assert_true(ids.has(GameIds.CARD_COPS), "cops keeps reserve")


func test_build_candidates_excludes_missing_score_cards() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_BROTHEL])
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 40
	var built: Dictionary = AIPurchaseLogic.build_purchase_candidates(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	var ids: Array[String] = _candidate_ids(built["candidates"])
	assert_false(ids.has(GameIds.CARD_BROTHEL), "missing score counts as 0")
	assert_true(ids.has(GameIds.CARD_STASH))


func test_run_market_does_not_buy_when_unaffordable() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_WORKSHOP])
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 1
	var result: Dictionary = AIBotController.run_market_for_ai(state, GameIds.PLAYER_AI_1)
	assert_eq(result["purchases"].size(), 0)
	var ai: Dictionary = TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)
	assert_eq(ai["nal"], 1)
	assert_true(ai["ready_for_action"])


func test_choose_candidate_tiebreak_consumes_one_step() -> void:
	var random_state: Dictionary = SeededRandom.create_random_state("ai_tie_seed")
	var state: Dictionary = {"random": random_state}
	var candidates: Array[Dictionary] = [
		_candidate(GameIds.CARD_STASH, 100.0),
		_candidate(GameIds.CARD_WORKSHOP, 100.0),
	]
	var first: Dictionary = AIPurchaseLogic.choose_purchase_candidate(state, candidates)
	assert_true(first["ok"])
	assert_eq(first["random"]["step"], 1)
	var second: Dictionary = AIPurchaseLogic.choose_purchase_candidate(state, candidates)
	assert_eq(first["candidate"]["card_id"], second["candidate"]["card_id"])


func test_choose_single_candidate_consumes_no_random() -> void:
	var random_state: Dictionary = SeededRandom.create_random_state("ai_single_seed")
	var state: Dictionary = {"random": random_state}
	var result: Dictionary = AIPurchaseLogic.choose_purchase_candidate(
		state, [_candidate(GameIds.CARD_STASH, 100.0)]
	)
	assert_true(result["ok"])
	assert_eq(result["random"]["step"], 0)


func test_turf_level_9_multiplies_war_score_only_when_human_leads() -> void:
	var leading: Dictionary = _turf9_state(5, 0)
	var racketeer: AIProfileDefinition = AIProfileCatalog.get_by_id(AIProfileIds.RACKETEER)
	var ai: Dictionary = TestPlayers.find(leading, GameIds.PLAYER_AI_2)
	var scored: Dictionary = AIPurchaseLogic.score_purchase_candidate(
		leading, ai, GameIds.CARD_THUG, racketeer
	)
	assert_almost_eq(float(scored["final_score"]), 120.0, 0.001)
	var tied: Dictionary = _turf9_state(0, 0)
	var ai_tied: Dictionary = TestPlayers.find(tied, GameIds.PLAYER_AI_2)
	var scored_tied: Dictionary = AIPurchaseLogic.score_purchase_candidate(
		tied, ai_tied, GameIds.CARD_THUG, racketeer
	)
	assert_almost_eq(float(scored_tied["final_score"]), 100.0, 0.001)


func test_run_market_wrong_phase_is_safe_failure() -> void:
	var state: Dictionary = TestGameStateFactory.action_state("ai_market_phase", 1)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = AIBotController.run_market_for_ai(state, GameIds.PLAYER_AI_1)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.INVALID_PHASE)
	assert_eq(state, before)


func test_failed_owner_buy_does_not_commit_tiebreak_random() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_WORKSHOP])
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["nal"] = 40
	state["random"] = SeededRandom.create_random_state("ai_buy_fail_seed")
	var candidates: Array[Dictionary] = [
		_candidate(GameIds.CARD_STASH, 100.0),
		_candidate(GameIds.CARD_WORKSHOP, 100.0),
	]
	var choice: Dictionary = AIPurchaseLogic.choose_purchase_candidate(
		state, candidates
	)
	assert_true(choice["ok"])
	assert_eq(int(choice["random"]["step"]), 1)
	var trial: Dictionary = state.duplicate(true)
	trial["random"] = choice["random"]
	trial["current_phase"] = PhaseIds.ACTION
	var bought: Dictionary = MarketLogic.buy_card(
		trial, GameIds.PLAYER_AI_1, choice["candidate"]["card_id"]
	)
	assert_false(bought["ok"])
	assert_eq(int(state["random"]["step"]), 0)


func _turf9_state(human_vp: int, ai_vp: int) -> Dictionary:
	var state: Dictionary = TestStates.committed_state("ai_turf9_seed")
	state["turf_level"] = 9
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["vp"] = human_vp
	for ai_id: String in GameIds.AI_PLAYER_IDS:
		TestPlayers.find(state, ai_id)["vp"] = ai_vp
	return state


func _candidate(card_id: String, final_score: float) -> Dictionary:
	return {
		"player_id": GameIds.PLAYER_AI_1, "card_id": card_id,
		"base_score": int(final_score), "final_score": final_score,
		"price": 5, "reserve_after_purchase": 10, "modifiers": [],
	}


func _candidate_ids(candidates: Array) -> Array[String]:
	var ids: Array[String] = []
	for candidate: Dictionary in candidates:
		ids.append(candidate["card_id"])
	return ids


func _unique(values: Array) -> Array:
	var seen: Array = []
	for value: Variant in values:
		if not seen.has(value):
			seen.append(value)
	return seen
