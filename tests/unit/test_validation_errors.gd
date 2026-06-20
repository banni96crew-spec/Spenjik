extends GutTest

const REQUIRED_ERRORS: Array[String] = [
	"CARD_NOT_AVAILABLE_IN_MARKET",
	"NOT_ENOUGH_NAL",
	"CARD_ALREADY_PURCHASED_THIS_ROUND",
	"REQUIREMENT_NOT_MET",
	"CARD_LIMIT_REACHED",
	"INVALID_TARGET",
	"INVALID_PHASE",
	"PHASE_NOT_READY",
	"INVALID_ACTION_CARD",
	"TARGET_PROTECTED",
	"ATTACK_MODE_REQUIRED",
	"INVALID_ATTACK_MODE",
	"STREET_DEAL_CHOICE_UNAVAILABLE",
	"INVALID_STREET_DEAL_OPTION",
	"CONTACT_LOCKED",
	"CONTACT_ON_COOLDOWN",
	"CONTACT_LIMIT_REACHED",
	"CONTACT_OFFER_UNAVAILABLE",
	"CONTACT_ALREADY_UNLOCKED",
	"CONTACT_ALREADY_USED",
	"ACTIVE_DEBT_EXISTS",
	"INVALID_DEBT_STATE",
	"INVALID_MODIFIER_STATE",
	"CONTRACT_OFFER_UNAVAILABLE",
	"CONTRACT_NOT_SELECTED",
	"CONTRACT_ALREADY_SELECTED",
	"CONTRACT_ALREADY_COMPLETED",
	"CONTRACT_ALREADY_FAILED",
	"CONTRACT_ALREADY_CLAIMED",
	"CONTRACT_NOT_COMPLETED",
	"CONTRACT_NOT_CLAIMABLE",
	"INVALID_PLAYER_ID",
	"INVALID_CARD_ID",
	"INVALID_ROLE_ID",
	"INVALID_CONTRACT_ID",
	"INVALID_CONTACT_ID",
	"INVALID_STREET_DEAL_ID",
	"INVALID_AI_PROFILE_ID",
	"INVALID_STATE",
	"INVALID_ROUND",
	"INVALID_TURF_LEVEL",
	"INVALID_RANDOM_STATE",
	"INVALID_ACTION_ORDER",
	"INVALID_ACTIVE_ACTION_PLAYER",
	"INVALID_AI_STATE",
	"NO_VALID_AI_ACTION",
	"NO_VALID_AI_PURCHASE",
	"NOT_ACTIVE_PLAYER",
	"PLAYER_ALREADY_READY",
	"PLAYER_ALREADY_ACTION_DONE",
	"GAME_ALREADY_OVER",
	"GAME_NOT_STARTED",
	"FORBIDDEN_RANDOM_API",
]


func test_ok_is_the_only_empty_error_code() -> void:
	assert_eq(ValidationErrors.OK, "")
	var constants: Dictionary = _error_constants()
	for value: Variant in constants.values():
		assert_ne(value, "")


func test_all_required_validation_errors_exist_with_exact_values() -> void:
	var constants: Dictionary = _error_constants()
	assert_eq(constants.size(), REQUIRED_ERRORS.size())
	for error_name: String in REQUIRED_ERRORS:
		assert_true(constants.has(error_name), "Missing error: %s" % error_name)
		assert_eq(constants[error_name], error_name)


func test_validation_error_codes_are_unique() -> void:
	var seen: Dictionary = {}
	for value: Variant in _error_constants().values():
		assert_false(seen.has(value), "Duplicate error code: %s" % value)
		seen[value] = true


func _error_constants() -> Dictionary:
	var constants: Dictionary = (
		ValidationErrors.new()
		.get_script()
		.get_script_constant_map()
		.duplicate()
	)
	constants.erase("OK")
	return constants
