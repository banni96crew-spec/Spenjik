extends GutTest

const UI_ROOTS: Array[String] = [
	"res://scenes/main",
	"res://scenes/game",
	"res://scenes/ui",
]
const RUNTIME_UI_EXTENSIONS: Array[String] = [".gd", ".tscn", ".tres"]
const FORBIDDEN_UI_PATTERNS: Array[String] = [
	"GameStateManager.state[",
	"[\"nal\"] +=", "[\"nal\"] -=",
	"[\"vp\"] +=", "[\"vp\"] -=",
	"[\"hand\"].append", "[\"hand\"].erase",
	"[\"combat_log\"].append",
	"[\"purchased_this_round\"].append",
	"SeededRandom", "SeededPicker",
	"randf(", "randi(", "randomize(", "RandomNumberGenerator",
	"MarketLogic.buy_card", "CombatEngine.resolve_attack",
	"StreetDealLogic.select_street_deal", "ContactLogic.select_contact",
	"ContractLogic.claim_contract", "AIBotController.run_action_for_ai",
	"PriceLogic.calculate",
	"FileAccess", "user://", "SaveManager", "SaveLoad",
]
const FORBIDDEN_RUNTIME_REFERENCE_PATTERNS: Array[String] = [
	"CARD_STYLE_REFERENCE", "C:\\Users\\", "http://", "https://",
]
const FORBIDDEN_CARD_VIEW_PATTERNS: Array[String] = [
	"CARD_STYLE_REFERENCE", "CARD_LAUNDRY", "CARD_STASH",
	"CARD_THUG", "CARD_COPS", "GameStateManager.state",
	"MarketLogic", "CombatEngine", "PriceLogic",
	"full_card_png", "card_png",
]
const FORBIDDEN_CARD_VIEW_WORDS: Array[String] = [
	"laundry", "stash", "thug", "cops",
]
const AUDIO_API_PATTERNS: Array[String] = [
	"AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D",
	"AudioServer",
]
const FORBIDDEN_PERSISTENCE_PATTERNS: Array[String] = [
	"SaveManager", "save_game", "load_game", "user://", "FileAccess",
	"ConfigFile",
]
const FORBIDDEN_WEB_STACK_PATTERNS: Array[String] = [
	"React", "TypeScript", "Zustand", "Tailwind", "Docker", "WebSocket",
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


func test_runtime_ui_files_do_not_reference_external_design_assets() -> void:
	var paths: Array[String] = _get_runtime_files_under_roots(UI_ROOTS)
	assert_gt(paths.size(), 0, "Runtime UI files must exist")
	for path: String in paths:
		var pattern: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_RUNTIME_REFERENCE_PATTERNS
		)
		assert_eq(pattern, "", "Forbidden runtime reference %s in %s" % [pattern, path])


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
	for word: String in FORBIDDEN_CARD_VIEW_WORDS:
		assert_false(
			_contains_whole_word(source, word),
			"CardView must not hardcode card ID word: %s" % word
		)
	assert_false(source.contains("TextureRect"))


func test_audio_apis_stay_out_of_gameplay_layers() -> void:
	for root: String in ["res://logic", "res://data", "res://autoload"]:
		for path: String in StaticScanHelper.get_gd_files_under(root):
			if path == "res://autoload/AudioManager.gd":
				continue
			var pattern: String = StaticScanHelper.find_pattern(path, AUDIO_API_PATTERNS)
			assert_eq(pattern, "", "Forbidden audio API %s in %s" % [pattern, path])


func test_ui_polish_does_not_add_persistence_or_web_stack() -> void:
	var paths: Array[String] = _get_runtime_files_under_roots(UI_ROOTS)
	for path: String in paths:
		var persistence: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_PERSISTENCE_PATTERNS
		)
		assert_eq(persistence, "", "Forbidden persistence %s in %s" % [persistence, path])
		var web_stack: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_WEB_STACK_PATTERNS
		)
		assert_eq(web_stack, "", "Forbidden web stack %s in %s" % [web_stack, path])


func test_logic_has_no_ui_scene_dependency() -> void:
	for path: String in StaticScanHelper.get_gd_files_under("res://logic"):
		assert_false(
			FileAccess.get_file_as_string(path).contains("res://scenes/ui/"),
			"Logic imports UI: %s" % path
		)


func _get_runtime_files_under_roots(root_paths: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for root: String in root_paths:
		result.append_array(_get_runtime_files_under(root))
	result.sort()
	return result


func _get_runtime_files_under(root_path: String) -> Array[String]:
	var result: Array[String] = []
	var pending: Array[String] = [root_path]
	while not pending.is_empty():
		var current: String = pending.pop_back()
		var directory: DirAccess = DirAccess.open(current)
		if directory == null:
			continue
		for child: String in directory.get_directories():
			pending.append("%s/%s" % [current, child])
		for file_name: String in directory.get_files():
			if _has_runtime_extension(file_name):
				result.append("%s/%s" % [current, file_name])
	return result


func _has_runtime_extension(file_name: String) -> bool:
	for extension: String in RUNTIME_UI_EXTENSIONS:
		if file_name.ends_with(extension):
			return true
	return false


func _contains_whole_word(source: String, word: String) -> bool:
	var expression := RegEx.new()
	assert_eq(expression.compile("\\b%s\\b" % word), OK)
	return expression.search(source) != null
