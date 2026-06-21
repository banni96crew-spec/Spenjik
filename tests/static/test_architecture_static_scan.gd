extends GutTest

const M8_PATHS: Array[String] = [
	"res://logic/game_state",
	"res://logic/economy",
	"res://logic/combat",
	"res://logic/roles",
	"res://logic/contracts",
	"res://tests/fixtures",
	"res://tests/unit",
	"res://tests/integration",
]
const LOGIC_PATHS: Array[String] = [
	"res://logic/game_state",
	"res://logic/economy",
	"res://logic/combat",
	"res://logic/roles",
	"res://logic/contracts",
]
const FORBIDDEN_FUTURE_GAMEPLAY_FILES: Array[String] = [
	"res://logic/street_deals/StreetDealLogic.gd",
	"res://logic/turf_levels/TurfLevelLogic.gd",
	"res://logic/ai/AIBotController.gd",
	"res://autoload/GameStateManager.gd",
]


func test_runtime_states_are_json_compatible_without_objects() -> void:
	var states: Array[Dictionary] = [
		TestGameStateFactory.setup_state(),
		TestStates.committed_state(),
		TestGameStateFactory.market_state(),
		TestGameStateFactory.action_state(),
		TestGameStateFactory.street_deal_state(),
	]
	for state: Dictionary in states:
		assert_true(StateShapeValidator.is_json_compatible(state))
		assert_false(_contains_forbidden_runtime_type(state))


func test_game_state_logic_has_no_ui_dependency_or_forbidden_runtime_apis() -> void:
	var forbidden: Array[String] = [
		"res://scenes/ui/",
		"extends Control",
		"Button",
		"Label",
		"TextureRect",
		"Panel",
		"get_node(",
		"RandomNumberGenerator",
		"randf(",
		"randi(",
		"randomize(",
	]
	for root_path: String in LOGIC_PATHS:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			var pattern: String = StaticScanHelper.find_pattern(path, forbidden)
			assert_eq(pattern, "", "Forbidden pattern %s in %s" % [pattern, path])


func test_game_state_source_has_no_web_stack_artifacts() -> void:
	var forbidden: Array[String] = [
		"React", "TypeScript", "Zustand", "Tailwind", "Docker", "WebSocket",
	]
	for root_path: String in LOGIC_PATHS:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			var pattern: String = StaticScanHelper.find_pattern(path, forbidden)
			assert_eq(pattern, "", "Forbidden stack term %s in %s" % [pattern, path])


func test_m8_does_not_create_future_gameplay_modules() -> void:
	for path: String in FORBIDDEN_FUTURE_GAMEPLAY_FILES:
		assert_false(FileAccess.file_exists(path), "M9+ file created: %s" % path)


func test_project_gdscript_files_stay_under_250_lines() -> void:
	for root_path: String in M8_PATHS:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			assert_lt(
				StaticScanHelper.count_lines(path),
				250,
				"Source file must stay under 250 lines: %s" % path
			)


func _contains_forbidden_runtime_type(value: Variant) -> bool:
	var value_type: int = typeof(value)
	if value_type == TYPE_OBJECT or value_type in [
		TYPE_CALLABLE, TYPE_SIGNAL, TYPE_NIL,
	]:
		return true
	if value_type == TYPE_ARRAY:
		for item: Variant in value:
			if _contains_forbidden_runtime_type(item):
				return true
	elif value_type == TYPE_DICTIONARY:
		for item: Variant in value.values():
			if _contains_forbidden_runtime_type(item):
				return true
	return false
