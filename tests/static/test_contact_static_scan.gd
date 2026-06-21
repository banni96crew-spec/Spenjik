extends GutTest

const ROOT := "res://logic/contacts"


func test_contact_logic_has_no_forbidden_dependencies() -> void:
	var forbidden: Array[String] = [
		"randf(",
		"randi(",
		"randi_range(",
		"randomize(",
		"RandomNumberGenerator",
		"res://scenes/ui/",
		"extends Control",
		"get_node(",
		"advance_phase(",
		"MarketLogic.buy_card",
		"IncomeLogic.resolve",
		"CombatEngine.resolve_attack",
		"DebtLogic.apply_debt_penalty",
		"ContractLogic.",
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
			"Forbidden M11 pattern %s in %s" % [pattern, path]
		)


func test_contact_logic_does_not_parse_display_descriptions() -> void:
	var forbidden: Array[String] = [".description"]
	for path: String in StaticScanHelper.get_gd_files_under(ROOT):
		var pattern: String = StaticScanHelper.find_pattern(path, forbidden)
		assert_eq(
			pattern, "",
			"Display text used as gameplay data in %s" % path
		)


func test_contact_source_files_stay_under_250_lines() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(ROOT):
		assert_lt(
			StaticScanHelper.count_lines(path),
			250,
			"Source file must stay under 250 lines: %s" % path
		)
