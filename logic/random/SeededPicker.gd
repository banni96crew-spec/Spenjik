class_name SeededPicker


## Selects one item and consumes exactly one random step.
static func pick_one(
	random_state: Dictionary,
	items: Array,
	tag: String = ""
) -> Dictionary:
	if items.is_empty():
		return _failure(random_state)
	var draw: Dictionary = SeededRandom.next(random_state, tag)
	if not draw["ok"]:
		return _failure(random_state)
	var index: int = int(floor(draw["value"] * items.size()))
	index = clampi(index, 0, items.size() - 1)
	return _success(items[index], [], 1, draw["random"])


## Selects up to count unique items without mutating the input array.
static func pick_unique(
	random_state: Dictionary,
	items: Array,
	count: int,
	tag: String = ""
) -> Dictionary:
	if count <= 0:
		return _success(null, [], 0, random_state)
	var pool: Array = []
	for item: Variant in items:
		if not pool.has(item):
			pool.append(item)
	var selected_items: Array = []
	var updated_random: Dictionary = random_state
	var pick_count: int = mini(count, pool.size())
	for pick_index: int in pick_count:
		var result: Dictionary = pick_one(
			updated_random,
			pool,
			"%s_pick_%d" % [tag, pick_index]
		)
		if not result["ok"]:
			return _failure(random_state)
		var selected: Variant = result["selected"]
		selected_items.append(selected)
		pool.erase(selected)
		updated_random = result["random"]
	return _success(
		null,
		selected_items,
		selected_items.size(),
		updated_random
	)


## Selects the first item whose positive cumulative weight exceeds the draw.
static func pick_weighted(
	random_state: Dictionary,
	weighted_items: Array[Dictionary],
	tag: String = ""
) -> Dictionary:
	var positive_items: Array[Dictionary] = []
	var total_weight: float = 0.0
	for item: Dictionary in weighted_items:
		var weight_value: Variant = item.get("weight", 0)
		if typeof(weight_value) not in [TYPE_INT, TYPE_FLOAT]:
			continue
		var weight: float = float(weight_value)
		if weight > 0.0:
			positive_items.append(item)
			total_weight += weight
	if positive_items.is_empty():
		return _failure(random_state)

	var draw: Dictionary = SeededRandom.next(random_state, tag)
	if not draw["ok"]:
		return _failure(random_state)
	var threshold: float = draw["value"] * total_weight
	var cumulative: float = 0.0
	for item: Dictionary in positive_items:
		cumulative += float(item["weight"])
		if cumulative > threshold:
			return _success(item, [], 1, draw["random"])
	return _success(
		positive_items[positive_items.size() - 1],
		[],
		1,
		draw["random"]
	)


## Resolves no-item and single-item ties without consuming random.
static func pick_best_tie(
	random_state: Dictionary,
	tied_items: Array,
	tag: String = ""
) -> Dictionary:
	if tied_items.is_empty():
		return _failure(random_state)
	if tied_items.size() == 1:
		return _success(tied_items[0], [], 0, random_state)
	return pick_one(random_state, tied_items, tag)


static func _success(
	selected: Variant,
	selected_items: Array,
	steps_used: int,
	random_state: Dictionary
) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"selected": selected,
		"selected_items": selected_items,
		"steps_used": steps_used,
		"random": random_state,
	}


static func _failure(random_state: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"error": ValidationErrors.REQUIREMENT_NOT_MET,
		"selected": null,
		"selected_items": [],
		"steps_used": 0,
		"random": random_state,
	}
