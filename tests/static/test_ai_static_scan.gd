extends GutTest

## M13 §13 AI static scan. Allows owner-API calls and result dictionaries, but
## forbids forbidden RNG, UI/scene dependencies, and the M14 GameStateManager.

const AI_ROOT: String = "res://logic/ai"
const FORBIDDEN_PATTERNS: Array[String] = [
	"GameStateManager",
	"res://scenes",
	"extends Control",
	"get_node(",
	"randf(",
	"randi(",
	"randi_range(",
	"randomize(",
	"RandomNumberGenerator",
]


func test_ai_files_exist() -> void:
	var files: Array[String] = StaticScanHelper.get_gd_files_under(AI_ROOT)
	assert_gt(files.size(), 0, "AI logic files must exist")


func test_ai_files_have_no_forbidden_references() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(AI_ROOT):
		var pattern: String = StaticScanHelper.find_pattern(path, FORBIDDEN_PATTERNS)
		assert_eq(pattern, "", "Forbidden pattern %s in %s" % [pattern, path])


func test_ai_files_stay_under_250_lines() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(AI_ROOT):
		assert_lt(
			StaticScanHelper.count_lines(path),
			250,
			"AI source must stay under 250 lines: %s" % path
		)
