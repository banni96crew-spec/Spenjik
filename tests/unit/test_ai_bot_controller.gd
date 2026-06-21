extends GutTest

## M13 §12.2 AI setup: strong AI selection, unique profile assignment,
## determinism, ai_bosses/player flag consistency, and Turf Level 2 VP bonus.


func _fresh_setup_state(seed_value: String, turf_level: int = 0) -> Dictionary:
	return GameStateFactory.create_new_game_state(seed_value, turf_level)


func test_setup_selects_exactly_one_strong_ai() -> void:
	var result: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_1")
	)
	assert_true(result["ok"])
	var strong_count: int = 0
	for boss: Dictionary in result["ai_bosses"]:
		if boss["is_strong"]:
			strong_count += 1
	assert_eq(strong_count, 1)
	assert_true(GameIds.AI_PLAYER_IDS.has(result["strong_ai_player_id"]))


func test_setup_assigns_three_unique_profiles_in_player_order() -> void:
	var result: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_2")
	)
	assert_eq(result["ai_bosses"].size(), 3)
	var assigned_players: Array[String] = []
	var profiles: Array[String] = []
	for boss: Dictionary in result["ai_bosses"]:
		assigned_players.append(boss["assigned_player_id"])
		profiles.append(boss["profile_id"])
		assert_true(AIProfileIds.ALL.has(boss["profile_id"]))
	assert_eq(assigned_players, GameIds.AI_PLAYER_IDS)
	assert_eq(profiles.size(), _unique(profiles).size())


func test_setup_is_deterministic_for_same_seed() -> void:
	var first: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_stable")
	)
	var second: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_stable")
	)
	assert_eq(first["ai_bosses"], second["ai_bosses"])
	assert_eq(first["strong_ai_player_id"], second["strong_ai_player_id"])


func test_setup_can_vary_strong_ai_across_seeds() -> void:
	var seen: Dictionary = {}
	for index: int in 12:
		var result: Dictionary = AIBotController.setup_ai_bosses(
			_fresh_setup_state("ai_seed_variation_%d" % index)
		)
		seen[result["strong_ai_player_id"]] = true
	assert_gt(seen.size(), 1, "Strong AI selection should not be constant")


func test_setup_consumes_exactly_four_random_steps() -> void:
	var state: Dictionary = _fresh_setup_state("ai_setup_seed_steps")
	var result: Dictionary = AIBotController.setup_ai_bosses(state)
	assert_eq(result["state"]["random"]["step"], state["random"]["step"] + 4)


func test_ai_bosses_match_player_strong_flags() -> void:
	var result: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_flags")
	)
	var state: Dictionary = result["state"]
	assert_true(AIStateValidator.validate(state)["ok"])
	for boss: Dictionary in state["ai_bosses"]:
		var player: Dictionary = TestPlayers.find(state, boss["assigned_player_id"])
		assert_eq(player["is_strong_ai"], boss["is_strong"])


func test_turf_level_2_gives_strong_ai_extra_vp_after_selection() -> void:
	var result: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_turf2", 2)
	)
	var state: Dictionary = result["state"]
	var strong: Dictionary = TestPlayers.find(state, result["strong_ai_player_id"])
	assert_eq(strong["vp"], 1)
	for player_id: String in GameIds.AI_PLAYER_IDS:
		if player_id != result["strong_ai_player_id"]:
			assert_eq(TestPlayers.find(state, player_id)["vp"], 0)


func test_repeated_setup_returns_safe_failure_without_mutation() -> void:
	var first: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_double")
	)
	var already_setup: Dictionary = first["state"].duplicate(true)
	var second: Dictionary = AIBotController.setup_ai_bosses(already_setup)
	assert_false(second["ok"])
	assert_eq(second["error"], ValidationErrors.INVALID_AI_STATE)
	assert_eq(second["state"], already_setup)


func test_get_ai_boss_state_and_profile_lookup() -> void:
	var result: Dictionary = AIBotController.setup_ai_bosses(
		_fresh_setup_state("ai_setup_seed_lookup")
	)
	var state: Dictionary = result["state"]
	var boss: Dictionary = AIBotController.get_ai_boss_state(state, GameIds.PLAYER_AI_1)
	assert_eq(boss["assigned_player_id"], GameIds.PLAYER_AI_1)
	var profile: AIProfileDefinition = AIBotController.get_ai_profile(boss["profile_id"])
	assert_not_null(profile)
	assert_eq(profile.id, boss["profile_id"])
	assert_eq(AIBotController.get_ai_boss_state(state, GameIds.PLAYER_HUMAN), {})


func _unique(values: Array) -> Array:
	var seen: Array = []
	for value: Variant in values:
		if not seen.has(value):
			seen.append(value)
	return seen
