extends GutTest

const UI_ROOTS: Array[String] = [
	"res://scenes/main",
	"res://scenes/game",
	"res://scenes/ui",
]
const FORBIDDEN_UI_PATTERNS: Array[String] = [
	"GameStateManager.state[",
	"[\"nal\"] +=", "[\"nal\"] -=",
	"[\"vp\"] +=", "[\"vp\"] -=",
	"[\"hand\"].append", "[\"hand\"].erase",
	"[\"combat_log\"].append",
	"[\"purchased_this_round\"].append",
	"randf(", "randi(", "randomize(", "RandomNumberGenerator",
	"MarketLogic.buy_card", "CombatEngine.resolve_attack",
	"StreetDealLogic.select_street_deal", "ContactLogic.select_contact",
	"ContractLogic.claim_contract", "AIBotController.run_action_for_ai",
	"PriceLogic.calculate",
]
const FORBIDDEN_CARD_VIEW_PATTERNS: Array[String] = [
	"CARD_STYLE_REFERENCE", "CARD_LAUNDRY", "CARD_STASH",
	"CARD_THUG", "CARD_COPS", "GameStateManager.state",
	"MarketLogic", "CombatEngine", "PriceLogic",
]


func test_ui_scripts_obey_gameplay_boundaries() -> void:
	var paths: Array[String] = []
	for root: String in UI_ROOTS:
		var root_paths: Array[String] = StaticScanHelper.get_gd_files_under(root)
		assert_gt(root_paths.size(), 0, "UI root must contain scripts: %s" % root)
		paths.append_array(root_paths)
	assert_gt(paths.size(), 0, "M16 UI scripts must exist")
	for path: String in paths:
		var pattern: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_UI_PATTERNS
		)
		assert_eq(pattern, "", "Forbidden UI pattern %s in %s" % [pattern, path])
		assert_lt(
			StaticScanHelper.count_lines(path), 250,
			"UI script must stay below 250 lines: %s" % path
		)


func test_card_view_is_template_based_and_type_driven() -> void:
	var path := "res://scenes/ui/widgets/CardView.gd"
	assert_true(FileAccess.file_exists(path))
	var source: String = FileAccess.get_file_as_string(path)
	for card_type: String in CardTypes.ALL:
		assert_string_contains(source, card_type)
	var pattern: String = StaticScanHelper.find_pattern(
		path, FORBIDDEN_CARD_VIEW_PATTERNS
	)
	assert_eq(pattern, "", "CardView forbidden special case: %s" % pattern)
	assert_false(source.contains("TextureRect"))


func test_logic_has_no_ui_scene_dependency() -> void:
	for path: String in StaticScanHelper.get_gd_files_under("res://logic"):
		assert_false(
			FileAccess.get_file_as_string(path).contains("res://scenes/ui/"),
			"Logic imports UI: %s" % path
		)
