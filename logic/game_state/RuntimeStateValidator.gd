class_name RuntimeStateValidator

const RANDOM_KEYS: Array[String] = [
	"seed", "step", "last_random_tag", "random_history_enabled", "history",
]
const MARKET_KEYS: Array[String] = [
	"round", "always_available_card_ids", "rotating_card_ids",
	"all_available_card_ids",
]
const CONTACT_KEYS: Array[String] = ["unlocked", "cooldowns", "used_this_round"]
const OFFER_KEYS: Array[String] = [
	"player_id", "source", "contact_offer_ids", "resolved", "created_round",
]
const DEAL_KEYS: Array[String] = [
	"offered_this_round", "current_deal_id", "used_deal_ids",
	"choices_by_player", "option_availability",
]


static func validate_random_state(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, RANDOM_KEYS, "random"
	)
	if not shape["ok"]:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_RANDOM_STATE,
			shape["details"].get("path", "random"),
			shape["details"].get("condition", "shape")
		)
	if (
		typeof(value["seed"]) != TYPE_STRING
		or typeof(value["step"]) != TYPE_INT
		or value["step"] < 0
		or typeof(value["last_random_tag"]) != TYPE_STRING
		or typeof(value["random_history_enabled"]) != TYPE_BOOL
		or typeof(value["history"]) != TYPE_ARRAY
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_RANDOM_STATE, "random", "field_contract"
		)
	if not value["random_history_enabled"] and not value["history"].is_empty():
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_RANDOM_STATE, "random.history", "disabled_not_empty"
		)
	for entry: Variant in value["history"]:
		if typeof(entry) != TYPE_DICTIONARY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_RANDOM_STATE, "random.history", "entry_type"
			)
		var keys: Array[String] = ["step_before", "step_after", "tag", "value"]
		if not StateShapeValidator.exact_keys(entry, keys, "random.history[]")["ok"]:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_RANDOM_STATE, "random.history", "entry_shape"
			)
		if (
			typeof(entry["step_before"]) != TYPE_INT
			or typeof(entry["step_after"]) != TYPE_INT
			or entry["step_after"] != entry["step_before"] + 1
			or typeof(entry["tag"]) != TYPE_STRING
			or typeof(entry["value"]) != TYPE_FLOAT
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_RANDOM_STATE, "random.history", "entry_contract"
			)
	return StateShapeValidator.ok()


static func validate_market_state(value: Dictionary, round_number: int) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, MARKET_KEYS, "market"
	)
	if not shape["ok"]:
		return shape
	if typeof(value["round"]) != TYPE_INT or value["round"] != round_number:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "market.round", "round_mismatch"
		)
	for key: String in MARKET_KEYS.slice(1):
		if typeof(value[key]) != TYPE_ARRAY:
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "market.%s" % key, "wrong_type"
			)
		var ids: Dictionary = StateShapeValidator.unique_strings(
			value[key], GameIds.CARD_IDS, "market.%s" % key
		)
		if not ids["ok"]:
			return ids
	var expected: Array = value["always_available_card_ids"].duplicate()
	expected.append_array(value["rotating_card_ids"])
	if value["all_available_card_ids"] != expected:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "market.all_available_card_ids", "composition"
		)
	return StateShapeValidator.ok()


static func validate_contact_state(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, CONTACT_KEYS, "contacts"
	)
	if not shape["ok"]:
		return shape
	if (
		typeof(value["unlocked"]) != TYPE_ARRAY
		or typeof(value["cooldowns"]) != TYPE_DICTIONARY
		or typeof(value["used_this_round"]) != TYPE_ARRAY
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contacts", "field_types"
		)
	if value["unlocked"].size() > 1:
		return StateShapeValidator.fail(
			ValidationErrors.CONTACT_LIMIT_REACHED, "contacts.unlocked", "mvp_limit"
		)
	for key: String in ["unlocked", "used_this_round"]:
		var ids: Dictionary = StateShapeValidator.unique_strings(
			value[key], ContactIds.ALL, "contacts.%s" % key
		)
		if not ids["ok"]:
			return ids
	for contact_id: Variant in value["cooldowns"].keys():
		if (
			typeof(contact_id) != TYPE_STRING
			or not value["unlocked"].has(contact_id)
			or typeof(value["cooldowns"][contact_id]) != TYPE_INT
			or value["cooldowns"][contact_id] < 0
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "contacts.cooldowns", "invalid_entry"
			)
	for contact_id: String in value["used_this_round"]:
		if not value["unlocked"].has(contact_id):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "contacts.used_this_round", "not_unlocked"
			)
	return StateShapeValidator.ok()


static func validate_global_contact_state(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, ["pending_offer"], "contacts"
	)
	if not shape["ok"] or typeof(value.get("pending_offer")) != TYPE_DICTIONARY:
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contacts.pending_offer", "shape"
		)
	if value["pending_offer"].is_empty():
		return StateShapeValidator.ok()
	return validate_contact_offer_state(value["pending_offer"])


static func validate_contact_offer_state(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, OFFER_KEYS, "contacts.pending_offer"
	)
	if not shape["ok"]:
		return shape
	var source: Variant = value["source"]
	var expected_count: int = 2 if source == StreetDealIds.INSIDE_CONTACT else 3
	if source == "strong_ai_victory" and value["contact_offer_ids"].size() == 2:
		expected_count = 2
	if (
		value["player_id"] != GameIds.PLAYER_HUMAN
		or source not in [StreetDealIds.INSIDE_CONTACT, "strong_ai_victory"]
		or typeof(value["contact_offer_ids"]) != TYPE_ARRAY
		or value["contact_offer_ids"].size() != expected_count
		or typeof(value["resolved"]) != TYPE_BOOL
		or value["resolved"]
		or typeof(value["created_round"]) != TYPE_INT
		or value["created_round"] < 1
		or value["created_round"] > 15
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "contacts.pending_offer", "field_contract"
		)
	return StateShapeValidator.unique_strings(
		value["contact_offer_ids"], ContactIds.ALL, "contacts.pending_offer.contact_offer_ids"
	)


static func validate_street_deal_state(value: Dictionary) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		value, DEAL_KEYS, "street_deals"
	)
	if not shape["ok"]:
		return shape
	if (
		typeof(value["offered_this_round"]) != TYPE_BOOL
		or typeof(value["current_deal_id"]) != TYPE_STRING
		or typeof(value["used_deal_ids"]) != TYPE_ARRAY
		or typeof(value["choices_by_player"]) != TYPE_DICTIONARY
		or typeof(value["option_availability"]) != TYPE_DICTIONARY
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "street_deals", "field_types"
		)
	if (
		not value["current_deal_id"].is_empty()
		and not StreetDealIds.ALL.has(value["current_deal_id"])
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STREET_DEAL_ID,
			"street_deals.current_deal_id", "invalid_id"
		)
	var used: Dictionary = StateShapeValidator.unique_strings(
		value["used_deal_ids"], StreetDealIds.ALL, "street_deals.used_deal_ids"
	)
	if not used["ok"]:
		return used
	for player_id: Variant in value["choices_by_player"].keys():
		if (
			player_id != GameIds.PLAYER_HUMAN
			or not StreetDealOptionIds.ALL.has(value["choices_by_player"][player_id])
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "street_deals.choices_by_player", "entry"
			)
	for option_id: Variant in value["option_availability"].keys():
		if (
			typeof(option_id) != TYPE_STRING
			or not StreetDealOptionIds.ALL.has(option_id)
			or typeof(value["option_availability"][option_id]) != TYPE_STRING
		):
			return StateShapeValidator.fail(
				ValidationErrors.INVALID_STATE, "street_deals.option_availability", "entry"
			)
	return StateShapeValidator.ok()
