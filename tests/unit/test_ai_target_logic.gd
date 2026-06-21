extends GutTest

## M13 §12.4 AI target scoring: feature formula, protected Nal, no self-target,
## deterministic tie-break. Read-only: no state mutation.


func _state() -> Dictionary:
	return TestStates.committed_state("ai_target_seed")


func _avenger() -> AIProfileDefinition:
	return AIProfileCatalog.get_by_id(AIProfileIds.AVENGER)


func test_score_target_combines_all_weighted_features() -> void:
	var state: Dictionary = _state()
	var attacker: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	attacker["vp"] = 0
	attacker["last_attacked_by"] = GameIds.PLAYER_HUMAN
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["vp"] = 5
	human["nal"] = 10
	human["engine"]["accountants"] = 1
	human["status_buildings"]["stash"] = 1
	human["status_buildings"]["workshop"] = 1
	var result: Dictionary = AITargetLogic.score_target(
		state, GameIds.PLAYER_AI_1, GameIds.PLAYER_HUMAN, _avenger()
	)
	assert_true(result["ok"])
	assert_eq(result["features"]["vpLead"], 5)
	assert_eq(result["features"]["availableNal"], 6, "protected Nal 4 from 1 accountant")
	assert_eq(result["features"]["lowDefense"], 3)
	assert_eq(result["features"]["destructibleBuildings"], 2)
	assert_eq(result["features"]["revenge"], 1)
	assert_eq(result["features"]["humanBias"], 1)
	# 5*3 + 6*2 + 3*2 + 2*4 + 1*6 + 1*1 = 48
	assert_almost_eq(float(result["score"]), 48.0, 0.001)


func test_score_target_does_not_mutate_state() -> void:
	var state: Dictionary = _state()
	var before: Dictionary = state.duplicate(true)
	AITargetLogic.score_target(state, GameIds.PLAYER_AI_1, GameIds.PLAYER_HUMAN, _avenger())
	assert_eq(state, before)


func test_valid_targets_exclude_self() -> void:
	var state: Dictionary = _state()
	var targets: Array[String] = AITargetLogic.get_valid_targets_for_ai(
		state, GameIds.PLAYER_AI_1
	)
	assert_false(targets.has(GameIds.PLAYER_AI_1))
	assert_eq(targets.size(), 3)


func test_target_tiebreak_uses_seeded_picker() -> void:
	var state: Dictionary = _state()
	for player_id: String in GameIds.AI_PLAYER_IDS + [GameIds.PLAYER_HUMAN]:
		var player: Dictionary = TestPlayers.find(state, player_id)
		player["nal"] = 0
		player["vp"] = 0
	# ai_3 gets all defenses active -> lowest score, breaking it out of the tie.
	var ai_3: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_3)
	ai_3["defense"]["cops_active"] = true
	ai_3["defense"]["cartel_state"] = DefenseStates.ACTIVE
	ai_3["defense"]["judge_state"] = DefenseStates.ACTIVE
	var merchant: AIProfileDefinition = AIProfileCatalog.get_by_id(AIProfileIds.MERCHANT)
	var targets: Array[String] = [
		GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_2, GameIds.PLAYER_AI_3
	]
	var first: Dictionary = AITargetLogic.choose_target(
		state, GameIds.PLAYER_AI_1, targets, merchant
	)
	assert_true(first["ok"])
	assert_eq(first["random"]["step"], 1, "real tie consumes one step")
	var second: Dictionary = AITargetLogic.choose_target(
		state, GameIds.PLAYER_AI_1, targets, merchant
	)
	assert_eq(first["target_id"], second["target_id"], "deterministic for same seed")
	assert_true(first["target_id"] in [GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_2])
