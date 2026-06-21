extends GutTest

## M13 §12.5/§12.6 AI Action: combat option construction (modes, Saboteur
## priority, Insider), option tie-break, probability gating, multi-card loop.


func _action_state(hand: Array[String], seed_value: String = "ai_action_seed") -> Dictionary:
	var state: Dictionary = TestGameStateFactory.action_state(seed_value, 1)
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["action_done"] = true
	state["active_action_player_id"] = GameIds.PLAYER_AI_1
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["hand"] = hand.duplicate()
	return state


func _builder() -> AIProfileDefinition:
	return AIProfileCatalog.get_by_id(AIProfileIds.BUILDER)


func _all_opponents_get_cops(state: Dictionary) -> void:
	for player_id: String in [GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_2, GameIds.PLAYER_AI_3]:
		TestPlayers.find(state, player_id)["defense"]["cops_active"] = true


func _seed_for_roll(threshold: float, below: bool) -> String:
	for index: int in 1000:
		var candidate: String = "ai_roll_%s_%d" % ["lo" if below else "hi", index]
		var value: float = SeededRandom.seeded_random(candidate, 0)
		if below and value <= threshold:
			return candidate
		if not below and value > threshold:
			return candidate
	return ""


func _has_option(options: Array, card_id: String, mode: String) -> bool:
	for option: Dictionary in options:
		if option["card_id"] == card_id and option["mode"] == mode:
			return true
	return false


func test_builds_unblocked_thug_option() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_THUG])
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	assert_true(_has_option(built["options"], GameIds.CARD_THUG, ""))
	assert_false(built["options"].is_empty())


func test_avoids_blocked_thug_when_all_targets_have_cops() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_THUG])
	_all_opponents_get_cops(state)
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	assert_true(built["options"].is_empty(), "no unblocked option exists")
	assert_false(built["blocked_options"].is_empty(), "blocked options recorded")


func test_uses_insider_with_thug_against_cops() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_THUG, GameIds.CARD_INSIDER])
	_all_opponents_get_cops(state)
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	var has_insider_option: bool = false
	for option: Dictionary in built["options"]:
		if option["card_id"] == GameIds.CARD_THUG and option["modifiers"] == [GameIds.CARD_INSIDER]:
			has_insider_option = true
	assert_true(has_insider_option, "thug+insider unblocks active Cops")


func test_never_builds_insider_as_primary() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_INSIDER, GameIds.CARD_THUG])
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	for option: Dictionary in built["options"] + built["blocked_options"]:
		assert_ne(option["card_id"], GameIds.CARD_INSIDER)


func test_bruiser_prefers_destroy_then_falls_back_to_steal() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_BRUISER])
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["status_buildings"]["stash"] = 1
	var blocked_target: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_3)
	blocked_target["status_buildings"]["stash"] = 1
	blocked_target["defense"]["cartel_state"] = DefenseStates.ACTIVE
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	assert_true(
		_target_has(built["options"], GameIds.PLAYER_AI_2,
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH),
		"unblocked destroy_stash preferred"
	)
	assert_true(
		_target_has(built["blocked_options"], GameIds.PLAYER_AI_3,
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH),
		"cartel-blocked destroy stays in blocked_options"
	)
	assert_true(
		_target_has(built["options"], GameIds.PLAYER_AI_3,
			GameIds.CARD_BRUISER, AttackModes.STEAL_NAL),
		"steal_nal remains the unblocked fallback"
	)


func test_federal_raid_only_targets_district_owner() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_FEDERAL_RAID])
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["status_buildings"]["district_control"] = 1
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	for option: Dictionary in built["options"] + built["blocked_options"]:
		assert_eq(option["target_id"], GameIds.PLAYER_AI_2)
		assert_eq(option["mode"], AttackModes.DESTROY_DISTRICT)


func test_saboteur_uses_priority_brothel_first() -> void:
	var state: Dictionary = _action_state([GameIds.CARD_SABOTEUR])
	var victim: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_2)
	victim["engine"]["brothel"] = true
	victim["engine"]["laundries"] = 1
	victim["engine"]["accountants"] = 1
	victim["engine"]["informers"] = 1
	var built: Dictionary = AIActionLogic.build_attack_options(
		state, GameIds.PLAYER_AI_1, _builder()
	)
	var saboteur_option: Dictionary = _first_for_target(
		built["options"] + built["blocked_options"], GameIds.PLAYER_AI_2
	)
	assert_eq(saboteur_option["engine_target_card_id"], GameIds.CARD_BROTHEL)


func test_choose_attack_option_tiebreak_consumes_one_step() -> void:
	var random_state: Dictionary = SeededRandom.create_random_state("ai_option_tie")
	var state: Dictionary = {"random": random_state}
	var options: Array[Dictionary] = [_option("a", 10.0), _option("b", 10.0)]
	var first: Dictionary = AIActionLogic.choose_attack_option(state, options)
	assert_true(first["ok"])
	assert_eq(first["random"]["step"], 1)
	var second: Dictionary = AIActionLogic.choose_attack_option(state, options)
	assert_eq(first["option"]["target_id"], second["option"]["target_id"])


func test_no_war_cards_ends_action_without_roll() -> void:
	var state: Dictionary = _action_state([])
	var result: Dictionary = AIBotController.run_action_for_ai(state, GameIds.PLAYER_AI_1)
	assert_true(result["ok"])
	assert_eq(result["attack_roll"], -1.0)
	assert_eq(result["attacks"].size(), 0)
	assert_true(TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)["action_done"])


func test_failed_probability_ends_action_and_keeps_cards() -> void:
	var seed_value: String = _seed_for_roll(0.25, false)
	var state: Dictionary = _action_state([GameIds.CARD_THUG], seed_value)
	TestPlayers.find(state, GameIds.PLAYER_AI_2)["nal"] = 10
	var result: Dictionary = AIBotController.run_action_for_ai(state, GameIds.PLAYER_AI_1)
	assert_gt(result["attack_roll"], 0.25)
	assert_eq(result["attacks"].size(), 0)
	assert_eq(result["fallback_used"], "")
	var ai: Dictionary = TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)
	assert_true(ai["action_done"])
	assert_true(ai["hand"].has(GameIds.CARD_THUG), "unused War card remains")


func test_passed_probability_plays_multiple_war_cards() -> void:
	var seed_value: String = _seed_for_roll(0.25, true)
	var state: Dictionary = _action_state([GameIds.CARD_THUG, GameIds.CARD_BRUISER], seed_value)
	var victim: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_2)
	victim["nal"] = 12
	victim["status_buildings"]["stash"] = 1
	var result: Dictionary = AIBotController.run_action_for_ai(state, GameIds.PLAYER_AI_1)
	assert_lte(result["attack_roll"], 0.25)
	assert_eq(result["attacks"].size(), 2)
	assert_eq(TestPlayers.find(result["state"], GameIds.PLAYER_AI_1)["hand"].size(), 0)


func _target_has(options: Array, target_id: String, card_id: String, mode: String) -> bool:
	for option: Dictionary in options:
		if (
			option["target_id"] == target_id
			and option["card_id"] == card_id
			and option["mode"] == mode
		):
			return true
	return false


func _first_for_target(options: Array, target_id: String) -> Dictionary:
	for option: Dictionary in options:
		if option["target_id"] == target_id:
			return option
	return {}


func _option(target_id: String, final_score: float) -> Dictionary:
	return {
		"attacker_id": GameIds.PLAYER_AI_1, "target_id": target_id,
		"card_id": GameIds.CARD_THUG, "mode": "", "modifiers": [],
		"engine_target_card_id": "", "card_preference_score": 0,
		"target_score": final_score, "blocked": false, "final_score": final_score,
	}
