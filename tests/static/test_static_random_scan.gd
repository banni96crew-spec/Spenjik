extends GutTest

const GAMEPLAY_PATHS: Array[String] = [
	"res://logic",
	"res://autoload",
	"res://data",
]
const FORBIDDEN_PATTERNS: Array[String] = [
	"randf(",
	"randi(",
	"randi_range(",
	"randomize(",
	"RandomNumberGenerator",
]


func test_forbidden_pattern_detector_covers_required_apis() -> void:
	for pattern: String in FORBIDDEN_PATTERNS:
		assert_eq(_find_forbidden_pattern("call %s now" % pattern), pattern)
	assert_eq(_find_forbidden_pattern("SeededRandom.next(state)"), "")


func test_gameplay_files_contain_no_forbidden_random_apis() -> void:
	for root_path: String in GAMEPLAY_PATHS:
		for path: String in _source_files_under(root_path):
			var source: String = FileAccess.get_file_as_string(path)
			var pattern: String = _find_forbidden_pattern(source)
			assert_eq(
				pattern,
				"",
				"Forbidden random API %s in %s" % [pattern, path]
			)


func _find_forbidden_pattern(source: String) -> String:
	for pattern: String in FORBIDDEN_PATTERNS:
		if source.contains(pattern):
			return pattern
	return ""


func _source_files_under(root_path: String) -> Array[String]:
	var result: Array[String] = []
	var pending_paths: Array[String] = [root_path]
	while not pending_paths.is_empty():
		var current: String = pending_paths.pop_back()
		var directory: DirAccess = DirAccess.open(current)
		assert_not_null(directory, "Missing gameplay path: %s" % current)
		for directory_name: String in directory.get_directories():
			pending_paths.append("%s/%s" % [current, directory_name])
		for file_name: String in directory.get_files():
			if file_name.ends_with(".gd") or file_name.ends_with(".tres"):
				result.append("%s/%s" % [current, file_name])
	result.sort()
	return result
