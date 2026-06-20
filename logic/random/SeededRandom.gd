class_name SeededRandom

const UINT32_MASK := 0xFFFFFFFF
const UINT32_RANGE := 4294967296.0
const CYRB53_H1 := 0xDEADBEEF
const CYRB53_H2 := 0x41C6CE57
const MULBERRY_INCREMENT := 0x6D2B79F5


## Returns the replay-stable random value for one seed and step.
@warning_ignore("shadowed_global_identifier")
static func seeded_random(seed: String, step: int) -> float:
	var hash_input: String = seed + "::step::" + str(step)
	var hash53: int = _cyrb53(hash_input, 0)
	var low32: int = hash53 & UINT32_MASK
	var high32: int = (hash53 >> 21) & UINT32_MASK
	var state32: int = (low32 ^ high32) & UINT32_MASK
	var output32: int = _mulberry32_next(state32)
	return float(output32) / UINT32_RANGE


## Creates the canonical RandomState at step zero.
@warning_ignore("shadowed_global_identifier")
static func create_random_state(
	seed: String,
	history_enabled: bool = false
) -> Dictionary:
	return {
		"seed": seed,
		"step": 0,
		"last_random_tag": "",
		"random_history_enabled": history_enabled,
		"history": [],
	}


## Consumes exactly one step and returns a new RandomState.
static func next(random_state: Dictionary, tag: String = "") -> Dictionary:
	if not _is_valid_random_state(random_state):
		return _failed_draw(random_state)

	var updated: Dictionary = random_state.duplicate(true)
	var step_before: int = updated["step"]
	var value: float = seeded_random(updated["seed"], step_before)
	updated["step"] = step_before + 1
	updated["last_random_tag"] = tag
	if updated["random_history_enabled"]:
		updated["history"].append({
			"step_before": step_before,
			"step_after": updated["step"],
			"tag": tag,
			"value": value,
		})
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"value": value,
		"random": updated,
	}


## Rolls two deterministic d6 values and consumes exactly two steps.
static func roll_d6_pair(
	random_state: Dictionary,
	tag: String = ""
) -> Dictionary:
	var first_result: Dictionary = next(random_state, "%s_die_1" % tag)
	if not first_result["ok"]:
		return _failed_dice(random_state)
	var second_result: Dictionary = next(
		first_result["random"],
		"%s_die_2" % tag
	)
	if not second_result["ok"]:
		return _failed_dice(random_state)

	var first: int = clampi(int(floor(first_result["value"] * 6.0)) + 1, 1, 6)
	var second: int = clampi(int(floor(second_result["value"] * 6.0)) + 1, 1, 6)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"dice": [first, second],
		"sum": first + second,
		"is_double": first == second,
		"steps_used": 2,
		"random": second_result["random"],
	}


static func _cyrb53(text: String, seed_value: int) -> int:
	var h1: int = (CYRB53_H1 ^ seed_value) & UINT32_MASK
	var h2: int = (CYRB53_H2 ^ seed_value) & UINT32_MASK
	for index: int in text.length():
		var character: int = text.unicode_at(index)
		h1 = _imul32(h1 ^ character, 2654435761)
		h2 = _imul32(h2 ^ character, 1597334677)
	h1 = (
		_imul32(h1 ^ _urshift32(h1, 16), 2246822507)
		^ _imul32(h2 ^ _urshift32(h2, 13), 3266489909)
	) & UINT32_MASK
	h2 = (
		_imul32(h2 ^ _urshift32(h2, 16), 2246822507)
		^ _imul32(h1 ^ _urshift32(h1, 13), 3266489909)
	) & UINT32_MASK
	return 4294967296 * (h2 & 0x1FFFFF) + h1


static func _mulberry32_next(state32: int) -> int:
	var value: int = (state32 + MULBERRY_INCREMENT) & UINT32_MASK
	var mixed: int = value
	mixed = _imul32(
		mixed ^ _urshift32(mixed, 15),
		mixed | 1
	)
	mixed = (
		mixed
		^ (
			mixed
			+ _imul32(
				mixed ^ _urshift32(mixed, 7),
				mixed | 61
			)
		)
	) & UINT32_MASK
	return (mixed ^ _urshift32(mixed, 14)) & UINT32_MASK


static func _imul32(left: int, right: int) -> int:
	var left_low: int = left & 0xFFFF
	var left_high: int = (left >> 16) & 0xFFFF
	var right_low: int = right & 0xFFFF
	var right_high: int = (right >> 16) & 0xFFFF
	return (
		left_low * right_low
		+ ((left_high * right_low + left_low * right_high) << 16)
	) & UINT32_MASK


static func _urshift32(value: int, bits: int) -> int:
	return (value & UINT32_MASK) >> bits


static func _is_valid_random_state(random_state: Dictionary) -> bool:
	return (
		random_state.has("seed")
		and typeof(random_state["seed"]) == TYPE_STRING
		and random_state.has("step")
		and typeof(random_state["step"]) == TYPE_INT
		and random_state["step"] >= 0
		and random_state.has("last_random_tag")
		and typeof(random_state["last_random_tag"]) == TYPE_STRING
		and random_state.has("random_history_enabled")
		and typeof(random_state["random_history_enabled"]) == TYPE_BOOL
		and random_state.has("history")
		and typeof(random_state["history"]) == TYPE_ARRAY
	)


static func _failed_draw(random_state: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"error": ValidationErrors.REQUIREMENT_NOT_MET,
		"value": 0.0,
		"random": random_state,
	}


static func _failed_dice(random_state: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"error": ValidationErrors.REQUIREMENT_NOT_MET,
		"dice": [],
		"sum": 0,
		"is_double": false,
		"steps_used": 0,
		"random": random_state,
	}
