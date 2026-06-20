extends GutTest

const EPSILON := 0.000000000001


func test_locked_sample_vectors_match_fix_036() -> void:
	var samples: Array[Dictionary] = [
		{"step": 0, "value": 0.708633181872},
		{"step": 1, "value": 0.749210928567},
		{"step": 2, "value": 0.925818509422},
	]
	for sample: Dictionary in samples:
		var actual: float = SeededRandom.seeded_random(
			"run_12345",
			sample["step"]
		)
		assert_almost_eq(actual, sample["value"], EPSILON)


func test_seeded_random_is_reproducible_distinct_and_in_range() -> void:
	var first: float = SeededRandom.seeded_random("test_seed_001", 7)
	var repeated: float = SeededRandom.seeded_random("test_seed_001", 7)
	var next_step: float = SeededRandom.seeded_random("test_seed_001", 8)
	var other_seed: float = SeededRandom.seeded_random("test_seed_other", 7)
	assert_eq(first, repeated)
	assert_ne(first, next_step)
	assert_ne(first, other_seed)
	for value: float in [first, next_step, other_seed]:
		assert_gte(value, 0.0)
		assert_lt(value, 1.0)


func test_create_random_state_has_exact_initial_shape() -> void:
	assert_eq(
		SeededRandom.create_random_state("test_seed_001"),
		{
			"seed": "test_seed_001",
			"step": 0,
			"last_random_tag": "",
			"random_history_enabled": false,
			"history": [],
		}
	)


func test_next_consumes_one_step_without_mutating_input() -> void:
	var state: Dictionary = SeededRandom.create_random_state("run_12345")
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = SeededRandom.next(state, "first_tag")
	assert_true(result["ok"])
	assert_eq(result["error"], ValidationErrors.OK)
	assert_eq(state, before)
	assert_eq(result["random"]["seed"], "run_12345")
	assert_eq(result["random"]["step"], 1)
	assert_eq(result["random"]["last_random_tag"], "first_tag")
	assert_almost_eq(result["value"], 0.708633181872, EPSILON)


func test_tag_does_not_affect_value() -> void:
	var state: Dictionary = SeededRandom.create_random_state("run_12345")
	var first: Dictionary = SeededRandom.next(state, "tag_a")
	var second: Dictionary = SeededRandom.next(state, "tag_b")
	assert_eq(first["value"], second["value"])


func test_history_disabled_stays_empty() -> void:
	var state: Dictionary = SeededRandom.create_random_state("run_12345")
	var result: Dictionary = SeededRandom.next(state, "history_off")
	assert_eq(result["random"]["history"], [])


func test_history_enabled_appends_exact_canonical_entry() -> void:
	var state: Dictionary = SeededRandom.create_random_state("run_12345", true)
	var result: Dictionary = SeededRandom.next(state, "history_on")
	var history: Array = result["random"]["history"]
	assert_eq(history.size(), 1)
	assert_eq(
		history[0],
		{
			"step_before": 0,
			"step_after": 1,
			"tag": "history_on",
			"value": result["value"],
		}
	)


func test_invalid_random_state_fails_without_mutation_or_step() -> void:
	var state: Dictionary = {"seed": "bad", "step": -1}
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = SeededRandom.next(state, "invalid")
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.REQUIREMENT_NOT_MET)
	assert_eq(result["random"], before)
	assert_eq(state, before)


func test_roll_d6_pair_matches_locked_vector_and_consumes_two_steps() -> void:
	var state: Dictionary = SeededRandom.create_random_state("run_12345")
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = SeededRandom.roll_d6_pair(state, "income")
	assert_true(result["ok"])
	assert_eq(result["dice"], [5, 5])
	assert_eq(result["sum"], 10)
	assert_true(result["is_double"])
	assert_eq(result["steps_used"], 2)
	assert_eq(result["random"]["step"], 2)
	assert_eq(state, before)


func test_roll_d6_pair_is_reproducible_and_dice_are_in_range() -> void:
	var first: Dictionary = SeededRandom.roll_d6_pair(
		SeededRandom.create_random_state("test_seed_income"),
		"income"
	)
	var second: Dictionary = SeededRandom.roll_d6_pair(
		SeededRandom.create_random_state("test_seed_income"),
		"income"
	)
	assert_eq(first, second)
	assert_eq(first["sum"], first["dice"][0] + first["dice"][1])
	assert_eq(first["is_double"], first["dice"][0] == first["dice"][1])
	for die: int in first["dice"]:
		assert_between(die, 1, 6)
