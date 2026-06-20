extends GutTest


func test_pick_one_selects_item_consumes_one_step_and_preserves_input() -> void:
	var state: Dictionary = SeededRandom.create_random_state("run_12345")
	var items: Array = ["a", "b", "c"]
	var before: Array = items.duplicate(true)
	var result: Dictionary = SeededPicker.pick_one(state, items, "one")
	assert_true(result["ok"])
	assert_has(items, result["selected"])
	assert_eq(result["steps_used"], 1)
	assert_eq(result["random"]["step"], 1)
	assert_eq(items, before)


func test_pick_one_empty_fails_without_consuming_random() -> void:
	var state: Dictionary = SeededRandom.create_random_state("test_seed_001")
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = SeededPicker.pick_one(state, [], "empty")
	_assert_failure_without_random_change(result, before)


func test_pick_unique_returns_unique_items_and_exact_steps() -> void:
	var state: Dictionary = SeededRandom.create_random_state("test_seed_001")
	var items: Array = ["a", "b", "c", "d"]
	var before: Array = items.duplicate(true)
	var result: Dictionary = SeededPicker.pick_unique(state, items, 3, "unique")
	assert_true(result["ok"])
	assert_eq(result["selected_items"].size(), 3)
	assert_eq(_unique_count(result["selected_items"]), 3)
	assert_eq(result["steps_used"], 3)
	assert_eq(result["random"]["step"], 3)
	assert_eq(items, before)


func test_pick_unique_non_positive_count_consumes_zero_steps() -> void:
	var state: Dictionary = SeededRandom.create_random_state("test_seed_001")
	var result: Dictionary = SeededPicker.pick_unique(
		state,
		["a", "b"],
		0,
		"zero"
	)
	assert_true(result["ok"])
	assert_eq(result["error"], ValidationErrors.OK)
	assert_eq(result["selected_items"], [])
	assert_eq(result["steps_used"], 0)
	assert_eq(result["random"], state)


func test_pick_unique_count_above_pool_returns_every_item_once() -> void:
	var items: Array = ["a", "b", "c"]
	var result: Dictionary = SeededPicker.pick_unique(
		SeededRandom.create_random_state("test_seed_001"),
		items,
		10,
		"all"
	)
	assert_true(result["ok"])
	assert_eq(result["selected_items"].size(), 3)
	assert_eq(_unique_count(result["selected_items"]), 3)
	assert_eq(result["steps_used"], 3)
	assert_eq(result["random"]["step"], 3)


func test_pick_weighted_ignores_non_positive_weights_and_preserves_input() -> void:
	var weighted: Array[Dictionary] = [
		{"id": "never_zero", "weight": 0},
		{"id": "never_negative", "weight": -10},
		{"id": "always", "weight": 5},
	]
	var before: Array[Dictionary] = weighted.duplicate(true)
	var result: Dictionary = SeededPicker.pick_weighted(
		SeededRandom.create_random_state("test_seed_001"),
		weighted,
		"weighted"
	)
	assert_true(result["ok"])
	assert_eq(result["selected"], weighted[2])
	assert_eq(result["steps_used"], 1)
	assert_eq(result["random"]["step"], 1)
	assert_eq(weighted, before)


func test_pick_weighted_without_positive_weight_fails_without_step() -> void:
	var state: Dictionary = SeededRandom.create_random_state("test_seed_001")
	var before: Dictionary = state.duplicate(true)
	var weighted: Array[Dictionary] = [
		{"id": "zero", "weight": 0},
		{"id": "negative", "weight": -1},
	]
	var result: Dictionary = SeededPicker.pick_weighted(
		state,
		weighted,
		"invalid_weight"
	)
	_assert_failure_without_random_change(result, before)


func test_pick_best_tie_empty_fails_without_step() -> void:
	var state: Dictionary = SeededRandom.create_random_state("test_seed_001")
	var result: Dictionary = SeededPicker.pick_best_tie(state, [], "empty_tie")
	_assert_failure_without_random_change(result, state)


func test_pick_best_tie_single_item_is_deterministic_without_step() -> void:
	var state: Dictionary = SeededRandom.create_random_state("test_seed_001")
	var items: Array = ["only"]
	var before: Array = items.duplicate(true)
	var result: Dictionary = SeededPicker.pick_best_tie(state, items, "single")
	assert_true(result["ok"])
	assert_eq(result["selected"], "only")
	assert_eq(result["steps_used"], 0)
	assert_eq(result["random"], state)
	assert_eq(items, before)


func test_pick_best_tie_real_tie_consumes_one_step() -> void:
	var result: Dictionary = SeededPicker.pick_best_tie(
		SeededRandom.create_random_state("test_seed_ai"),
		["ai_1", "ai_2", "ai_3"],
		"real_tie"
	)
	assert_true(result["ok"])
	assert_has(["ai_1", "ai_2", "ai_3"], result["selected"])
	assert_eq(result["steps_used"], 1)
	assert_eq(result["random"]["step"], 1)


func _assert_failure_without_random_change(
	result: Dictionary,
	before: Dictionary
) -> void:
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.REQUIREMENT_NOT_MET)
	assert_null(result["selected"])
	assert_eq(result["selected_items"], [])
	assert_eq(result["steps_used"], 0)
	assert_eq(result["random"], before)


func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value: Variant in values:
		unique[value] = true
	return unique.size()
