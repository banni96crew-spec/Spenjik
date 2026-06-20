extends GutTest

const REQUIRED_FILES: Array[String] = [
	"GameIds.gd",
	"PhaseIds.gd",
	"AttackModes.gd",
	"ValidationErrors.gd",
	"RoleIds.gd",
	"ContractIds.gd",
	"ContactIds.gd",
	"StreetDealIds.gd",
	"AIProfileIds.gd",
	"CardTypes.gd",
	"CardDestinations.gd",
	"DefenseStates.gd",
	"RewardTypes.gd",
	"EffectTypes.gd",
	"ModifierTypes.gd",
	"LogEventTypes.gd",
	"TieBreakIds.gd",
	"TurfLevelIds.gd",
	"StreetDealOptionIds.gd",
	"StateKeys.gd",
]


func test_all_required_constant_files_exist() -> void:
	for file_name: String in REQUIRED_FILES:
		assert_true(
			FileAccess.file_exists("res://data/ids/%s" % file_name),
			"Missing constants file: %s" % file_name
		)


func test_player_and_card_ids_match_owner_prds() -> void:
	assert_eq(
		GameIds.PLAYER_IDS,
		["player_1", "ai_1", "ai_2", "ai_3"]
	)
	assert_eq(GameIds.AI_PLAYER_IDS, ["ai_1", "ai_2", "ai_3"])
	assert_eq(GameIds.CARD_IDS.size(), 16)
	assert_eq(
		GameIds.CARD_IDS,
		[
			"informant", "laundry", "accountant", "brothel",
			"stash", "workshop", "district_control", "cops",
			"cartel", "judge", "thug", "bruiser", "cleaner",
			"insider", "saboteur", "federal_raid",
		]
	)
	_assert_no_duplicates(GameIds.PLAYER_IDS)
	_assert_no_duplicates(GameIds.CARD_IDS)


func test_core_ids_match_owner_prds() -> void:
	assert_eq(
		PhaseIds.ALL,
		["setup", "income", "market", "action", "street_deal", "game_over"]
	)
	assert_eq(
		AttackModes.ALL,
		["steal_nal", "destroy_stash", "destroy_workshop", "destroy_district"]
	)
	assert_eq(CardTypes.ALL, ["engine", "status", "defense", "war"])
	assert_eq(CardDestinations.ALL, ["table", "hand"])
	_assert_no_duplicates(PhaseIds.ALL)
	_assert_no_duplicates(AttackModes.ALL)
	_assert_no_duplicates(CardTypes.ALL)
	_assert_no_duplicates(CardDestinations.ALL)


func test_domain_ids_match_owner_prds() -> void:
	assert_eq(
		RoleIds.ALL,
		["merchant", "enforcer", "gray_cardinal", "district_boss"]
	)
	assert_eq(
		ContractIds.ALL,
		[
			"silent_expansion", "bloody_turf_war", "gray_capital",
			"iron_roof", "district_under_control", "proxy_war",
			"big_cashbox",
		]
	)
	assert_eq(ContactIds.ALL, ["black_cash", "corrupt_clerk", "street_medic"])
	assert_eq(
		StreetDealIds.ALL,
		[
			"loan_shark", "dirty_tip", "cheap_protection",
			"black_market_cache", "inside_contact", "risky_contract",
		]
	)
	assert_eq(
		AIProfileIds.ALL,
		["builder", "racketeer", "merchant", "paranoid", "schemer", "avenger"]
	)
	for values: Array in [
		RoleIds.ALL,
		ContractIds.ALL,
		ContactIds.ALL,
		StreetDealIds.ALL,
		AIProfileIds.ALL,
	]:
		_assert_no_duplicates(values)


func test_supporting_constant_groups_are_complete_and_unique() -> void:
	assert_eq(DefenseStates.ALL_CARTEL, ["none", "active", "depleted"])
	assert_eq(DefenseStates.ALL_JUDGE, ["none", "active"])
	assert_eq(StreetDealOptionIds.ALL, ["option_a", "option_b"])
	assert_eq(RewardTypes.ALL.size(), 7)
	assert_eq(EffectTypes.ALL.size(), 15)
	assert_eq(ModifierTypes.ALL.size(), 6)
	assert_eq(LogEventTypes.ALL.size(), 29)
	assert_eq(TieBreakIds.ALL.size(), 6)
	for values: Array in [
		DefenseStates.ALL_CARTEL,
		DefenseStates.ALL_JUDGE,
		StreetDealOptionIds.ALL,
		RewardTypes.ALL,
		EffectTypes.ALL,
		ModifierTypes.ALL,
		LogEventTypes.ALL,
		TieBreakIds.ALL,
	]:
		_assert_no_duplicates(values)


func test_turf_levels_are_exact_integers_zero_through_ten() -> void:
	assert_eq(TurfLevelIds.MIN, 0)
	assert_eq(TurfLevelIds.MAX, 10)
	assert_eq(TurfLevelIds.ALL, range(0, 11))
	for level: Variant in TurfLevelIds.ALL:
		assert_typeof(level, TYPE_INT)
	_assert_no_duplicates(TurfLevelIds.ALL)


func test_state_keys_match_the_canonical_schema_names() -> void:
	var expected: Dictionary = {
		"ROUND": "round",
		"CURRENT_PHASE": "current_phase",
		"PLAYERS": "players",
		"GAME_SEED": "game_seed",
		"RANDOM": "random",
		"TURF_LEVEL": "turf_level",
		"SELECTED_ROLE_ID": "selected_role_id",
		"SELECTED_CONTRACT_ID": "selected_contract_id",
		"CONTRACT_OFFER_IDS": "contract_offer_ids",
		"MARKET": "market",
		"STREET_DEALS": "street_deals",
		"CONTACTS": "contacts",
		"AI_BOSSES": "ai_bosses",
		"ACTION_ORDER": "action_order",
		"ACTIVE_ACTION_PLAYER_ID": "active_action_player_id",
		"COMBAT_LOG": "combat_log",
		"WINNER_ID": "winner_id",
		"GAME_RESULT": "game_result",
		"ID": "id",
		"IS_AI": "is_ai",
		"NAL": "nal",
		"VP": "vp",
		"ENGINE": "engine",
		"STATUS_BUILDINGS": "status_buildings",
		"DEFENSE": "defense",
		"HAND": "hand",
		"PURCHASED_THIS_ROUND": "purchased_this_round",
		"READY_FOR_ACTION": "ready_for_action",
		"ACTION_DONE": "action_done",
		"SKIP_NEXT_ACTION": "skip_next_action",
		"CONTRACTS": "contracts",
		"DEBTS": "debts",
		"ROLE_FLAGS": "role_flags",
		"TURF_FLAGS": "turf_flags",
		"TEMPORARY_MODIFIERS": "temporary_modifiers",
		"IS_STRONG_AI": "is_strong_ai",
		"LAST_ATTACKED_BY": "last_attacked_by",
	}
	var actual: Dictionary = StateKeys.new().get_script().get_script_constant_map()
	assert_eq(actual, expected)


func test_all_arrays_cover_each_declared_value() -> void:
	var scripts: Array[GDScript] = [
		preload("res://data/ids/PhaseIds.gd"),
		preload("res://data/ids/AttackModes.gd"),
		preload("res://data/ids/RoleIds.gd"),
		preload("res://data/ids/ContractIds.gd"),
		preload("res://data/ids/ContactIds.gd"),
		preload("res://data/ids/StreetDealIds.gd"),
		preload("res://data/ids/AIProfileIds.gd"),
		preload("res://data/ids/CardTypes.gd"),
		preload("res://data/ids/CardDestinations.gd"),
		preload("res://data/ids/RewardTypes.gd"),
		preload("res://data/ids/EffectTypes.gd"),
		preload("res://data/ids/ModifierTypes.gd"),
		preload("res://data/ids/LogEventTypes.gd"),
		preload("res://data/ids/TieBreakIds.gd"),
		preload("res://data/ids/StreetDealOptionIds.gd"),
	]
	for script: GDScript in scripts:
		var constants: Dictionary = script.get_script_constant_map()
		var all_values: Array = constants["ALL"]
		constants.erase("ALL")
		assert_eq(all_values.size(), constants.size())
		for value: Variant in constants.values():
			assert_has(all_values, value)


func _assert_no_duplicates(values: Array) -> void:
	var seen: Dictionary = {}
	for value: Variant in values:
		assert_false(seen.has(value), "Duplicate value: %s" % value)
		seen[value] = true
