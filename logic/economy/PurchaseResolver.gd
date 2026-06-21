class_name PurchaseResolver


## Applies a previously validated purchase to a deep working copy.
static func resolve_purchase(
	state: Dictionary,
	player_id: String,
	definition: CardDefinition,
	price_result: Dictionary
) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = _find_player(candidate, player_id)
	var nal_before: int = player["nal"]
	player["nal"] -= int(price_result["final_price"])
	_place_card(player, definition.id)
	player["purchased_this_round"].append(definition.id)
	_consume_modifiers(player, price_result["modifiers"])
	_append_purchase_log(
		candidate, player_id, definition, price_result, nal_before
	)
	return _validated_result(state, candidate, {
		"player_id": player_id, "card_id": definition.id,
		"price": price_result["final_price"],
		"destination": definition.destination,
	})


## Applies a previously validated dedicated rebuild to a deep copy.
static func resolve_rebuild(
	state: Dictionary,
	player_id: String,
	price_result: Dictionary
) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = _find_player(candidate, player_id)
	var nal_before: int = player["nal"]
	var price: int = int(price_result["final_rebuild_price"])
	player["nal"] -= price
	player["status_buildings"]["district_control"] += 1
	player["status_buildings"]["can_rebuild_district_for_8"] = false
	player["vp"] += 3
	_consume_modifiers(player, price_result["modifiers"])
	var card: CardDefinition = CardCatalog.get_by_id(
		GameIds.CARD_DISTRICT_CONTROL
	)
	_append_purchase_log(candidate, player_id, card, {
		"base_price": price_result["base_rebuild_price"],
		"final_price": price,
		"modifiers": price_result["modifiers"],
	}, nal_before)
	return _validated_result(state, candidate, {
		"player_id": player_id,
		"price": price,
		"destination": card.destination,
	})


static func _place_card(player: Dictionary, card_id: String) -> void:
	match card_id:
		GameIds.CARD_INFORMANT:
			player["engine"]["informers"] += 1
		GameIds.CARD_LAUNDRY:
			player["engine"]["laundries"] += 1
		GameIds.CARD_ACCOUNTANT:
			player["engine"]["accountants"] += 1
		GameIds.CARD_BROTHEL:
			player["engine"]["brothel"] = true
		GameIds.CARD_STASH:
			_add_status(player, "stash", 1)
		GameIds.CARD_WORKSHOP:
			_add_status(player, "workshop", 2)
		GameIds.CARD_DISTRICT_CONTROL:
			_add_status(player, "district_control", 3)
		GameIds.CARD_COPS:
			player["defense"]["cops_active"] = true
			player["defense"]["cops_timer"] = 0
		GameIds.CARD_CARTEL:
			player["defense"]["cartel_state"] = DefenseStates.ACTIVE
		GameIds.CARD_JUDGE:
			player["defense"]["judge_state"] = DefenseStates.ACTIVE
		_:
			player["hand"].append(card_id)


static func _add_status(
	player: Dictionary,
	key: String,
	vp: int
) -> void:
	player["status_buildings"][key] += 1
	player["vp"] += vp


static func _consume_modifiers(
	player: Dictionary,
	modifiers: Array
) -> void:
	for modifier: Dictionary in modifiers:
		if not modifier.get("consume_on_success", false):
			continue
		var flag: String = str(modifier.get("flag", ""))
		if modifier.get("source") == "contact":
			player["role_flags"]["used_one_time_contact_bonus"] = true
		elif modifier.get("source") == "turf_level":
			player["turf_flags"][flag] = true
		elif not flag.is_empty() and player["role_flags"].has(flag):
			player["role_flags"][flag] = true
		for stored: Dictionary in player["temporary_modifiers"]:
			if stored["id"] == modifier.get("id"):
				stored["consumed"] = true


static func _append_purchase_log(
	state: Dictionary,
	player_id: String,
	definition: CardDefinition,
	price: Dictionary,
	nal_before: int
) -> void:
	var ids: Array[String] = []
	for modifier: Dictionary in price["modifiers"]:
		ids.append(str(modifier.get("id", "")))
	var player: Dictionary = _find_player(state, player_id)
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		LogEventTypes.CARD_PURCHASED, {
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"], "phase": state["current_phase"],
			"actor_id": player_id, "card_id": definition.id,
			"summary": LogEventTypes.CARD_PURCHASED,
			"details": {
				"player_id": player_id,
				"card_id": definition.id,
				"base_price": price["base_price"],
				"final_price": price["final_price"],
				"nal_before": nal_before, "nal_after": player["nal"],
				"destination": definition.destination,
				"applied_modifier_ids": ids,
			},
		}
	))


static func _validated_result(
	original: Dictionary,
	candidate: Dictionary,
	fields: Dictionary
) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not validation["ok"]:
		return _failure(original, validation["error"])
	var result: Dictionary = {
		"ok": true, "error": ValidationErrors.OK,
		"state": candidate, "log_entries": [candidate["combat_log"][-1]],
	}
	result.merge(fields)
	return result


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state["players"]:
		if player["id"] == player_id:
			return player
	return {}


static func _failure(state: Dictionary, error: String) -> Dictionary:
	return {
		"ok": false, "error": error, "state": state,
		"log_entries": [],
	}
