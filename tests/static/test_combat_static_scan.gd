extends GutTest

const COMBAT_PATH := "res://logic/combat"
const FORBIDDEN: Array[String] = [
	"randf(",
	"randi(",
	"randi_range(",
	"randomize(",
	"RandomNumberGenerator",
	"res://scenes/ui/",
	"extends Control",
	"Button",
	"Label",
	"TextureRect",
	"Panel",
	"get_node(",
	"advance_phase",
	"ContactLogic",
	"React",
	"TypeScript",
	"Zustand",
	"Tailwind",
	"Docker",
	"WebSocket",
]


func test_combat_source_has_no_forbidden_dependencies_or_apis() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(COMBAT_PATH):
		var pattern: String = StaticScanHelper.find_pattern(path, FORBIDDEN)
		assert_eq(pattern, "", "Forbidden pattern %s in %s" % [pattern, path])


func test_combat_uses_m6_protected_nal_api() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://logic/combat/CombatEffectResolver.gd"
	)
	assert_true(source.contains("PriceLogic.get_protected_nal("))


func test_combat_files_stay_under_250_lines() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(COMBAT_PATH):
		assert_lt(
			StaticScanHelper.count_lines(path),
			250,
			"Combat source must stay under 250 lines: %s" % path
		)
