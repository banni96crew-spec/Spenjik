extends GutTest

const FORBIDDEN_UI_PATTERNS: Array[String] = [
	"GameStateManager.state[",
	"[\"nal\"] +=",
	"[\"nal\"] -=",
	"[\"vp\"] +=",
	"[\"vp\"] -=",
	"[\"hand\"].append",
	"[\"hand\"].erase",
	"[\"combat_log\"].append",
]


func test_ui_scripts_do_not_mutate_gameplay_state() -> void:
	var paths: Array[String] = StaticScanHelper.get_gd_files_under(
		"res://scenes/ui"
	)
	if paths.is_empty():
		assert_eq(paths, [], "M16 UI is not implemented during M15")
	for path: String in paths:
		var pattern: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_UI_PATTERNS
		)
		assert_eq(pattern, "", "Forbidden UI mutation %s in %s" % [pattern, path])
