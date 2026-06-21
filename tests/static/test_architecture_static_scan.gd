extends GutTest

const LOGIC_ROOT: Array[String] = ["res://logic"]
const PROJECT_GDSCRIPT_PATHS: Array[String] = [
	"res://logic",
	"res://tests/fixtures",
	"res://tests/unit",
	"res://tests/integration",
	"res://tests/replay",
	"res://tests/static",
	"res://tests/smoke",
]
const FORBIDDEN_UNTIL_FUTURE_MILESTONES: Array[String] = [
	"res://autoload/GameStateManager.gd",
]
const FORBIDDEN_LOGIC_PATTERNS: Array[String] = [
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
	"randi_range(",
	"randomize(",
]
const FORBIDDEN_WEB_STACK_PATTERNS: Array[String] = [
	"React",
	"TypeScript",
	"Zustand",
	"Tailwind",
	"Docker",
	"WebSocket",
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


func test_logic_has_no_ui_dependency_or_forbidden_runtime_apis() -> void:
	for root_path: String in LOGIC_ROOT:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			var pattern: String = StaticScanHelper.find_pattern(path, FORBIDDEN_LOGIC_PATTERNS)
			assert_eq(pattern, "", "Forbidden pattern %s in %s" % [pattern, path])


func test_logic_source_has_no_web_stack_artifacts() -> void:
	for root_path: String in LOGIC_ROOT:
		for path: String in StaticScanHelper.get_gd_files_under(root_path):
			var pattern: String = StaticScanHelper.find_pattern(path, FORBIDDEN_WEB_STACK_PATTERNS)
			assert_eq(pattern, "", "Forbidden stack term %s in %s" % [pattern, path])


func test_premature_future_modules_not_created() -> void:
	for path: String in FORBIDDEN_UNTIL_FUTURE_MILESTONES:
		assert_false(
			FileAccess.file_exists(path),
			"Future milestone file created prematurely: %s" % path
		)


func test_project_gdscript_files_stay_under_250_lines() -> void:
	for root_path: String in PROJECT_GDSCRIPT_PATHS:
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
