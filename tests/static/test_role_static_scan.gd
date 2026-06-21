extends GutTest

const ROLE_PATH := "res://logic/roles"
const FORBIDDEN_PATTERNS: Array[String] = [
	"res://scenes/",
	"extends Control",
	"get_node(",
	"randf(",
	"randi(",
	"randi_range(",
	"randomize(",
	"RandomNumberGenerator",
	"effect_summary",
	"limitation_summary",
	"CombatEngine",
	"advance_phase",
	"AIBotController",
	"React",
	"TypeScript",
	"Tailwind",
	"Zustand",
	"Docker",
	"WebSocket",
]


func test_role_logic_has_no_forbidden_dependencies_or_behavior() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(ROLE_PATH):
		var pattern: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_PATTERNS
		)
		assert_eq(pattern, "", "Forbidden role pattern %s in %s" % [
			pattern, path,
		])


func test_role_logic_files_stay_under_250_lines() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(ROLE_PATH):
		assert_lt(
			StaticScanHelper.count_lines(path),
			250,
			"Role source must stay under 250 lines: %s" % path
		)
