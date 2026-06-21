extends GutTest

const CONTRACT_PATH := "res://logic/contracts"
const FORBIDDEN_PATTERNS: Array[String] = [
	"randf(",
	"randi(",
	"randi_range(",
	"randomize(",
	"RandomNumberGenerator",
	"res://scenes/",
	"extends Control",
	"get_node(",
	"description",
	"effect_summary",
	"base_price",
	"final_price",
	"_place_card",
	"resolve_attack(",
	"advance_phase(",
	"AIBotController",
	"React",
	"TypeScript",
	"Tailwind",
	"Zustand",
	"Docker",
	"WebSocket",
]


func test_contract_source_has_no_forbidden_dependencies_or_behavior() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(CONTRACT_PATH):
		var pattern: String = StaticScanHelper.find_pattern(
			path, FORBIDDEN_PATTERNS
		)
		assert_eq(
			pattern, "",
			"Forbidden contract pattern %s in %s" % [pattern, path]
		)


func test_contract_source_uses_only_seeded_picker_for_offer_random() -> void:
	var setup_source: String = FileAccess.get_file_as_string(
		"res://logic/contracts/ContractSetupLogic.gd"
	)
	assert_true(setup_source.contains("SeededPicker.pick_unique("))
	assert_true(setup_source.contains("\"contract_offers_setup\""))
	for path: String in StaticScanHelper.get_gd_files_under(CONTRACT_PATH):
		if path.ends_with("ContractSetupLogic.gd"):
			continue
		assert_false(
			FileAccess.get_file_as_string(path).contains("SeededPicker.")
		)


func test_contract_claim_is_not_called_by_owner_integrations() -> void:
	for root: String in [
		"res://logic/economy",
		"res://logic/combat",
		"res://logic/game_state",
	]:
		for path: String in StaticScanHelper.get_gd_files_under(root):
			assert_false(
				FileAccess.get_file_as_string(path).contains(
					"claim_contract("
				),
				"Automatic contract claim in %s" % path
			)


func test_contract_files_stay_under_250_lines() -> void:
	for path: String in StaticScanHelper.get_gd_files_under(CONTRACT_PATH):
		assert_lt(
			StaticScanHelper.count_lines(path),
			250,
			"Contract source must stay under 250 lines: %s" % path
		)
