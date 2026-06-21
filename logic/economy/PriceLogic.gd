class_name PriceLogic

const REBUILD_BASE_PRICE := 8


## Returns a read-only full card-price preview.
static func get_card_price(
	state: Dictionary,
	player_id: String,
	card_id: String,
	role_modifiers: Array[Dictionary] = []
) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	var definition: CardDefinition = CardCatalog.get_by_id(card_id)
	if player.is_empty() or definition == null:
		return _failure(card_id)
	var scaled_price: int = _scaled_price(player, definition)
	var modifiers: Array[Dictionary] = []
	modifiers.append_array(role_modifiers.duplicate(true))
	modifiers.append_array(_turf_modifiers(state, player, definition))
	modifiers.append_array(_contact_modifiers(state, player, definition))
	modifiers.append_array(_temporary_modifiers(player, definition))
	var final_price: int = scaled_price
	for modifier: Dictionary in modifiers:
		final_price += int(modifier.get("delta", 0))
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"card_id": card_id,
		"base_price": definition.base_price,
		"scaled_price": scaled_price,
		"modifiers": modifiers,
		"final_price": clamp_price(final_price),
	}


## Returns the dedicated District Control rebuild preview.
static func get_rebuild_price(
	state: Dictionary,
	player_id: String,
	role_modifiers: Array[Dictionary] = []
) -> Dictionary:
	if _find_player(state, player_id).is_empty():
		return {
			"ok": false,
			"error": ValidationErrors.INVALID_PLAYER_ID,
			"base_rebuild_price": REBUILD_BASE_PRICE,
			"final_rebuild_price": REBUILD_BASE_PRICE,
			"modifiers": [],
		}
	var final_price: int = REBUILD_BASE_PRICE
	for modifier: Dictionary in role_modifiers:
		final_price += int(modifier.get("delta", 0))
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"base_rebuild_price": REBUILD_BASE_PRICE,
		"final_rebuild_price": clamp_price(final_price),
		"modifiers": role_modifiers.duplicate(true),
	}


static func get_informant_price(player: Dictionary) -> int:
	var count: int = int(player["engine"]["informers"])
	return 5 if count == 0 else (6 if count == 1 else 7)


static func get_laundry_price(player: Dictionary) -> int:
	var count: int = int(player["engine"]["laundries"])
	return 8 if count == 0 else (10 if count == 1 else 12)


static func get_protected_nal(accountants: int) -> int:
	if accountants <= 0:
		return 0
	if accountants == 1:
		return 4
	if accountants == 2:
		return 6
	return 6 + accountants - 2


static func clamp_price(price: int, min_price: int = 1) -> int:
	return maxi(price, min_price)


static func _scaled_price(
	player: Dictionary,
	definition: CardDefinition
) -> int:
	if definition.id == GameIds.CARD_INFORMANT:
		return get_informant_price(player)
	if definition.id == GameIds.CARD_LAUNDRY:
		return get_laundry_price(player)
	return definition.base_price


static func _turf_modifiers(
	state: Dictionary,
	player: Dictionary,
	definition: CardDefinition
) -> Array[Dictionary]:
	if (
		int(state.get("turf_level", 0)) < 6
		or not player["is_ai"]
		or definition.type != CardTypes.WAR
		or player["turf_flags"]["ai_first_war_discount_used_this_round"]
	):
		return []
	return [_modifier(
		"turf_level_6_%s_round_%d" % [player["id"], state["round"]],
		"turf_level", -1, "ai_first_war_discount_used_this_round"
	)]


static func _contact_modifiers(
	state: Dictionary,
	player: Dictionary,
	definition: CardDefinition
) -> Array[Dictionary]:
	if (
		definition.type != CardTypes.STATUS
		or not player["contacts"]["unlocked"].has(ContactIds.CORRUPT_CLERK)
		or player["role_flags"]["used_one_time_contact_bonus"]
	):
		return []
	return [_modifier(
		"corrupt_clerk_%s_round_%d" % [player["id"], state["round"]],
		"contact", -1, "used_one_time_contact_bonus"
	)]


static func _temporary_modifiers(
	player: Dictionary,
	definition: CardDefinition
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for modifier: Dictionary in player["temporary_modifiers"]:
		if not modifier["consumed"] and _matches(modifier, definition):
			result.append({
				"id": modifier["id"],
				"source": modifier["source"],
				"delta": modifier["delta"],
				"flag": "",
				"consume_on_success": modifier["expires_at"] == "next_purchase",
			})
	return result


static func _matches(
	modifier: Dictionary,
	definition: CardDefinition
) -> bool:
	if modifier["affected_card_id"] not in ["", definition.id]:
		return false
	if modifier["affected_card_type"] not in ["", definition.type]:
		return false
	match modifier["type"]:
		ModifierTypes.CARD_PRICE_DELTA:
			return true
		ModifierTypes.NEXT_DEFENSE_CARD_PRICE_DELTA:
			return definition.type == CardTypes.DEFENSE
		ModifierTypes.NEXT_WAR_CARD_PRICE_DELTA:
			return definition.type == CardTypes.WAR
		ModifierTypes.NEXT_STATUS_CARD_PRICE_DELTA:
			return definition.type == CardTypes.STATUS
	return false


static func _modifier(
	id: String,
	source: String,
	delta: int,
	flag: String
) -> Dictionary:
	return {
		"id": id, "source": source, "delta": delta, "flag": flag,
		"consume_on_success": true,
	}


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _failure(card_id: String) -> Dictionary:
	return {
		"ok": false, "error": ValidationErrors.INVALID_CARD_ID,
		"card_id": card_id, "base_price": 0, "scaled_price": 0,
		"modifiers": [], "final_price": 0,
	}
