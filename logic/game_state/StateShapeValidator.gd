class_name StateShapeValidator


static func ok() -> Dictionary:
	return {"ok": true, "error": ValidationErrors.OK, "details": {}}


static func fail(error: String, path: String, condition: String) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"details": {"path": path, "condition": condition},
	}


static func exact_keys(
	value: Dictionary,
	required: Array[String],
	path: String
) -> Dictionary:
	if value.size() != required.size():
		return fail(ValidationErrors.INVALID_STATE, path, "exact_keys")
	for key: String in required:
		if not value.has(key):
			return fail(ValidationErrors.INVALID_STATE, "%s.%s" % [path, key], "missing")
	for key: Variant in value.keys():
		if typeof(key) != TYPE_STRING or not required.has(key):
			return fail(ValidationErrors.INVALID_STATE, path, "extra_or_non_string_key")
	return ok()


static func require_type(
	value: Variant,
	expected_type: int,
	path: String,
	error: String = ValidationErrors.INVALID_STATE
) -> Dictionary:
	if typeof(value) != expected_type:
		return fail(error, path, "wrong_type")
	return ok()


static func unique_strings(
	values: Array,
	allowed: Array,
	path: String,
	error: String = ValidationErrors.INVALID_STATE
) -> Dictionary:
	var seen: Dictionary = {}
	for value: Variant in values:
		if typeof(value) != TYPE_STRING or not allowed.has(value):
			return fail(error, path, "invalid_id")
		if seen.has(value):
			return fail(error, path, "duplicate")
		seen[value] = true
	return ok()


static func is_json_compatible(value: Variant) -> bool:
	match typeof(value):
		TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return true
		TYPE_ARRAY:
			for item: Variant in value:
				if not is_json_compatible(item):
					return false
			return true
		TYPE_DICTIONARY:
			for key: Variant in value.keys():
				if typeof(key) != TYPE_STRING:
					return false
				if not is_json_compatible(value[key]):
					return false
			return true
		_:
			return false
