class_name PlayerStateValidator

const PLAYER_KEYS: Array[String] = [
	"id", "is_ai", "nal", "vp", "turf_level", "engine", "status_buildings",
	"defense", "hand", "purchased_this_round", "ready_for_action", "action_done",
	"skip_next_action", "contracts", "contacts", "debts", "role_flags",
	"turf_flags", "temporary_modifiers", "is_strong_ai", "last_attacked_by",
]


static func validate(player: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		player, PLAYER_KEYS, "player"
	)
	if not shape["ok"]:
		return shape
	if not GameIds.PLAYER_IDS.has(player["id"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_PLAYER_ID, "player.id", "invalid_id"
		)
	var expected_ai: bool = GameIds.AI_PLAYER_IDS.has(player["id"])
	if typeof(player["is_ai"]) != TYPE_BOOL or player["is_ai"] != expected_ai:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.is_ai", "id_mismatch"
		)
	if not _non_negative_int(player["nal"]) or not _non_negative_int(player["vp"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.resources", "range"
		)
	if typeof(player["turf_level"]) != TYPE_INT or not TurfLevelIds.ALL.has(player["turf_level"]):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_TURF_LEVEL, "player.turf_level", "invalid"
		)
	for key: String in [
		"ready_for_action", "action_done", "skip_next_action", "is_strong_ai",
	]:
		if typeof(player[key]) != TYPE_BOOL:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "player.%s" % key, "wrong_type"
			)
	for key: String in ["contacts", "role_flags", "turf_flags"]:
		if typeof(player[key]) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "player.%s" % key, "wrong_type"
			)
	for result: Dictionary in [
		_validate_engine(player["engine"]),
		_validate_status(player["status_buildings"]),
		_validate_defense(player["defense"]),
		RuntimeStateValidator.validate_contact_state(player["contacts"]),
		ProgressStateValidator.validate_role_flags(player["role_flags"]),
		ProgressStateValidator.validate_turf_flags(player["turf_flags"]),
	]:
		if not result["ok"]:
			return result
	if typeof(player["hand"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.hand", "wrong_type"
		)
	for card_id: Variant in player["hand"]:
		var definition: CardDefinition = CardCatalog.get_by_id(str(card_id))
		if typeof(card_id) != TYPE_STRING or definition == null or definition.type != CardTypes.WAR:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_CARD_ID, "player.hand", "non_war_card"
			)
	if typeof(player["purchased_this_round"]) != TYPE_ARRAY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.purchased_this_round", "wrong_type"
		)
	var purchased: Dictionary = StateShapeValidator.unique_strings(
		player["purchased_this_round"], GameIds.CARD_IDS, "player.purchased_this_round"
	)
	if not purchased["ok"]:
		return purchased
	for key: String in ["contracts", "debts", "temporary_modifiers"]:
		if typeof(player[key]) != TYPE_ARRAY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "player.%s" % key, "wrong_type"
			)
	for contract: Variant in player["contracts"]:
		if typeof(contract) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "player.contracts", "entry_type"
			)
		var contract_result: Dictionary = ProgressStateValidator.validate_contract(contract)
		if not contract_result["ok"]:
			return contract_result
	var debt_ids: Dictionary = {}
	for debt: Variant in player["debts"]:
		if typeof(debt) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_DEBT_STATE, "player.debts", "entry_type"
			)
		var debt_result: Dictionary = ProgressStateValidator.validate_debt(debt)
		if not debt_result["ok"]:
			return debt_result
		if debt_ids.has(debt["id"]):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_DEBT_STATE, "player.debts", "duplicate_id"
			)
		debt_ids[debt["id"]] = true
	var modifier_ids: Dictionary = {}
	for modifier: Variant in player["temporary_modifiers"]:
		if typeof(modifier) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_MODIFIER_STATE,
				"player.temporary_modifiers", "entry_type"
			)
		var modifier_result: Dictionary = ProgressStateValidator.validate_modifier(modifier)
		if not modifier_result["ok"]:
			return modifier_result
		if modifier_ids.has(modifier["id"]):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_MODIFIER_STATE,
				"player.temporary_modifiers", "duplicate_id"
			)
		modifier_ids[modifier["id"]] = true
	if (
		typeof(player["last_attacked_by"]) != TYPE_STRING
		or (
			player["last_attacked_by"] != ""
			and (
				not GameIds.PLAYER_IDS.has(player["last_attacked_by"])
				or player["last_attacked_by"] == player["id"]
			)
		)
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_PLAYER_ID, "player.last_attacked_by", "invalid"
		)
	return StateShapeValidator.ok()


static func _validate_engine(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.engine", "wrong_type"
		)
	var keys: Array[String] = ["informers", "laundries", "accountants", "brothel"]
	var shape: Dictionary = StateShapeValidator.exact_keys(value, keys, "player.engine")
	if not shape["ok"]:
		return shape
	for key: String in keys.slice(0, 3):
		if not _non_negative_int(value[key]):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "player.engine.%s" % key, "range"
			)
	if typeof(value["brothel"]) != TYPE_BOOL:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.engine.brothel", "wrong_type"
		)
	return StateShapeValidator.ok()


static func _validate_status(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.status_buildings", "wrong_type"
		)
	var keys: Array[String] = [
		"stash", "workshop", "district_control", "can_rebuild_district_for_8",
	]
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, keys, "player.status_buildings"
	)
	if not shape["ok"]:
		return shape
	for key: String in keys.slice(0, 3):
		if not _non_negative_int(value[key]):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE,
				"player.status_buildings.%s" % key, "range"
			)
	if typeof(value["can_rebuild_district_for_8"]) != TYPE_BOOL:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE,
			"player.status_buildings.can_rebuild_district_for_8", "wrong_type"
		)
	return StateShapeValidator.ok()


static func _validate_defense(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.defense", "wrong_type"
		)
	var keys: Array[String] = [
		"cops_active", "cops_timer", "cartel_state", "judge_state",
	]
	var shape: Dictionary = StateShapeValidator.exact_keys(value, keys, "player.defense")
	if not shape["ok"]:
		return shape
	if (
		typeof(value["cops_active"]) != TYPE_BOOL
		or not _non_negative_int(value["cops_timer"])
		or not DefenseStates.ALL_CARTEL.has(value["cartel_state"])
		or not DefenseStates.ALL_JUDGE.has(value["judge_state"])
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "player.defense", "field_contract"
		)
	return StateShapeValidator.ok()


static func _non_negative_int(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 0
