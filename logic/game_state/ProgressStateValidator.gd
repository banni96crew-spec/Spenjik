class_name ProgressStateValidator

const CONTRACT_KEYS: Array[String] = [
	"contract_id", "progress", "completed", "failed", "claimed", "deadline",
	"failed_reason", "completed_round", "claimed_round",
]
const DEBT_KEYS: Array[String] = [
	"id", "source", "amount_due", "deadline_round", "penalty", "repaid",
	"created_round", "repaid_round", "penalty_applied_round",
]
const MODIFIER_KEYS: Array[String] = [
	"id", "type", "source", "owner_player_id", "affected_card_id",
	"affected_card_type", "delta", "multiplier", "min_value", "expires_at",
	"consumed",
]
const ROLE_FLAG_KEYS: Array[String] = [
	"merchant_first_engine_discount_used",
	"merchant_first_war_tax_applied_this_round",
	"enforcer_first_war_discount_used",
	"gray_cardinal_first_accountant_bypass_used",
	"gray_cardinal_first_saboteur_discount_used",
	"gray_cardinal_first_stash_tax_used",
	"district_boss_first_stash_discount_used",
	"district_boss_first_laundry_tax_used",
	"district_boss_rebuild_discount_used",
	"used_first_card_discount",
	"used_emergency_protection",
	"used_one_time_contact_bonus",
]


static func validate_contract(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, CONTRACT_KEYS, "contract"
	)
	if not shape["ok"]:
		return shape
	if (
		typeof(value["contract_id"]) != TYPE_STRING
		or not ContractIds.ALL.has(value["contract_id"])
		or typeof(value["progress"]) != TYPE_INT
		or value["progress"] < 0
		or typeof(value["completed"]) != TYPE_BOOL
		or typeof(value["failed"]) != TYPE_BOOL
		or typeof(value["claimed"]) != TYPE_BOOL
		or typeof(value["deadline"]) != TYPE_INT
		or value["deadline"] < 1
		or value["deadline"] > 15
		or typeof(value["failed_reason"]) != TYPE_STRING
		or typeof(value["completed_round"]) != TYPE_INT
		or typeof(value["claimed_round"]) != TYPE_INT
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contract", "field_contract"
		)
	if value["completed"] and value["failed"]:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contract", "completed_and_failed"
		)
	if value["claimed"] and not value["completed"]:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contract.claimed", "without_completion"
		)
	if (
		value["failed_reason"] != ""
		and value["failed_reason"] not in ["war_played", "deadline_exceeded"]
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contract.failed_reason", "invalid_value"
		)
	for key: String in ["completed_round", "claimed_round"]:
		if value[key] < 0 or value[key] > 15:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "contract.%s" % key, "range"
			)
	return StateShapeValidator.ok()


static func validate_debt(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(value, DEBT_KEYS, "debt")
	if not shape["ok"]:
		return shape
	if (
		typeof(value["id"]) != TYPE_STRING
		or not _valid_debt_id(value["id"], value["created_round"])
		or value["source"] != StreetDealIds.LOAN_SHARK
		or typeof(value["amount_due"]) != TYPE_INT
		or value["amount_due"] <= 0
		or not _round(value["deadline_round"])
		or typeof(value["penalty"]) != TYPE_DICTIONARY
		or typeof(value["repaid"]) != TYPE_BOOL
		or not _round(value["created_round"])
		or value["created_round"] > value["deadline_round"]
		or typeof(value["repaid_round"]) != TYPE_INT
		or typeof(value["penalty_applied_round"]) != TYPE_INT
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_DEBT_STATE, "debt", "field_contract"
		)
	var penalty_shape: Dictionary = StateShapeValidator.exact_keys(
		value["penalty"], ["lose_all_nal", "vp_delta"], "debt.penalty"
	)
	if (
		not penalty_shape["ok"]
		or typeof(value["penalty"]["lose_all_nal"]) != TYPE_BOOL
		or typeof(value["penalty"]["vp_delta"]) != TYPE_INT
		or value["penalty"]["vp_delta"] not in [0, -1]
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_DEBT_STATE, "debt.penalty", "contract"
		)
	var repayment: int = value["repaid_round"]
	var penalty_round: int = value["penalty_applied_round"]
	if not value["repaid"] and (repayment != 0 or penalty_round != 0):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_DEBT_STATE, "debt", "unresolved_rounds"
		)
	if (
		value["repaid"]
		and (
			((repayment > 0) == (penalty_round > 0))
			or repayment > 15
			or penalty_round > 15
		)
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_DEBT_STATE, "debt", "resolution_round"
		)
	return StateShapeValidator.ok()


static func validate_modifier(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, MODIFIER_KEYS, "temporary_modifier"
	)
	if not shape["ok"]:
		return shape
	if (
		typeof(value["id"]) != TYPE_STRING
		or not _valid_modifier_id(value["id"], value["owner_player_id"])
		or typeof(value["type"]) != TYPE_STRING
		or not ModifierTypes.ALL.has(value["type"])
		or typeof(value["source"]) != TYPE_STRING
		or value["source"].is_empty()
		or not GameIds.PLAYER_IDS.has(value["owner_player_id"])
		or typeof(value["affected_card_id"]) != TYPE_STRING
		or (value["affected_card_id"] != "" and not GameIds.CARD_IDS.has(value["affected_card_id"]))
		or typeof(value["affected_card_type"]) != TYPE_STRING
		or (value["affected_card_type"] != "" and not CardTypes.ALL.has(value["affected_card_type"]))
		or typeof(value["delta"]) != TYPE_INT
		or typeof(value["multiplier"]) != TYPE_FLOAT
		or typeof(value["min_value"]) != TYPE_INT
		or value["expires_at"] not in [
			"next_purchase", "end_of_round", "end_of_market",
			"end_of_action", "never",
		]
		or typeof(value["consumed"]) != TYPE_BOOL
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_MODIFIER_STATE, "temporary_modifier", "contract"
		)
	return StateShapeValidator.ok()


static func validate_role_flags(value: Dictionary) -> Dictionary:
	return _validate_boolean_shape(value, ROLE_FLAG_KEYS, "role_flags")


static func validate_turf_flags(value: Dictionary) -> Dictionary:
	return _validate_boolean_shape(
		value, ["ai_first_war_discount_used_this_round"], "turf_flags"
	)


static func _validate_boolean_shape(
	value: Dictionary,
	keys: Array[String],
	path: String
) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(value, keys, path)
	if not shape["ok"]:
		return shape
	for key: String in keys:
		if typeof(value[key]) != TYPE_BOOL:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "%s.%s" % [path, key], "wrong_type"
			)
	return StateShapeValidator.ok()


static func _round(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 1 and value <= 15


static func _valid_debt_id(value: String, created_round: Variant) -> bool:
	if typeof(created_round) != TYPE_INT:
		return false
	var expression: RegEx = RegEx.new()
	expression.compile("^loan_shark_round_([1-9]|1[0-5])_option_[ab]$")
	var found: RegExMatch = expression.search(value)
	return found != null and int(found.get_string(1)) == created_round


static func _valid_modifier_id(value: String, owner_player_id: Variant) -> bool:
	if typeof(owner_player_id) != TYPE_STRING:
		return false
	var expression: RegEx = RegEx.new()
	expression.compile(
		"^[a-z][a-z0-9_]*_(player_1|ai_1|ai_2|ai_3)_round_([1-9]|1[0-5])$"
	)
	var found: RegExMatch = expression.search(value)
	return found != null and found.get_string(1) == owner_player_id
