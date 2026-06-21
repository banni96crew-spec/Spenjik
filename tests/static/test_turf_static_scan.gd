extends GutTest


const FORBIDDEN_TURF_THRESHOLDS: Array[String] = [
	'turf_level"] >= 4',
	'turf_level"] >= 5',
	'turf_level"] >= 6',
	'turf_level"] >= 7',
	'turf_level"] >= 8',
	'turf_level"] >= 10',
	'turf_level", 0)) >= 4',
	'turf_level", 0)) >= 5',
	'turf_level", 0)) >= 6',
	'turf_level", 0)) >= 7',
	'turf_level", 0)) >= 8',
	'turf_level", 0)) >= 10',
	"turf_level\"] >= 4",
	"turf_level\"] >= 5",
	"turf_level\"] >= 6",
	"turf_level\"] >= 7",
	"turf_level\"] >= 8",
	"turf_level\"] >= 10",
]
const ALLOWED_THRESHOLD_PATHS: Array[String] = [
	"res://logic/turf_levels/TurfLevelLogic.gd",
]


func test_production_logic_has_no_hardcoded_turf_thresholds() -> void:
	for path: String in StaticScanHelper.get_gd_files_under("res://logic"):
		if ALLOWED_THRESHOLD_PATHS.has(path):
			continue
		var source: String = FileAccess.get_file_as_string(path)
		for pattern: String in FORBIDDEN_TURF_THRESHOLDS:
			assert_false(
				source.contains(pattern),
				"Hardcoded Turf threshold %s in %s" % [pattern, path]
			)


func test_turf_level_logic_has_no_forbidden_random_or_ui_patterns() -> void:
	var forbidden: Array[String] = [
		"RandomNumberGenerator",
		"randf(",
		"randi(",
		"randomize(",
		"res://scenes/ui/",
		"effect_summary",
	]
	for path: String in [
		"res://logic/turf_levels/TurfLevelLogic.gd",
		"res://logic/turf_levels/TurfWinnerRules.gd",
	]:
		for pattern: String in forbidden:
			assert_eq(
				StaticScanHelper.find_pattern(path, [pattern]),
				"",
				"Forbidden pattern %s in %s" % [pattern, path]
			)
