extends GutTest

const ROOT := "res://logic/street_deals"


func test_street_deal_logic_has_no_forbidden_dependencies() -> void:
	var forbidden: Array[String] = [
		"randf(",
		"randi(",
		"randomize(",
		"RandomNumberGenerator",
		"res://scenes/ui/",
		"extends Control",
		"get_node(",
		"advance_phase(",
		"ContactLogic",
		"React",
		"TypeScript",
		"Tailwind",
		"Zustand",
		"Docker",
	]
	for path: String in StaticScanHelper.get_gd_files_under(ROOT):
		var pattern: String = StaticScanHelper.find_pattern(path, forbidden)
		assert_eq(
			pattern, "",
			"Forbidden M10 pattern %s in %s" % [pattern, path]
		)


func test_street_deal_logic_does_not_parse_display_descriptions() -> void:
	var forbidden: Array[String] = [
		"option_a_description",
		"option_b_description",
		".description",
	]
	for path: String in StaticScanHelper.get_gd_files_under(ROOT):
		var pattern: String = StaticScanHelper.find_pattern(path, forbidden)
		assert_eq(
			pattern, "",
			"Display text used as gameplay data in %s" % path
		)
