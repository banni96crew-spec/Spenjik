class_name AIFallbackLogic

## Owns AI fallback interpretation for Market and Action contexts (§5.9, §5.19).
## Fallbacks never bypass MarketLogic/CombatEngine validation and never override
## a failed attack probability roll.


## Applies the profile Market fallback. Only buy_cheapest_valid may purchase.
static func apply_market_fallback(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	if profile.fallback == "buy_cheapest_valid":
		return _buy_cheapest_valid(state, player_id, profile)
	return _no_market_purchase(state)


static func _buy_cheapest_valid(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return _no_market_purchase(state)
	var cheapest_price: int = -1
	var cheapest_ids: Array[String] = []
	var prices: Dictionary = {}
	for card_id: String in state["market"].get("all_available_card_ids", []):
		if not MarketLogic.can_buy_card(state, player_id, card_id)["ok"]:
			continue
		var final_price: int = int(
			PriceLogic.get_card_price(state, player_id, card_id).get("final_price", 0)
		)
		if int(player["nal"]) - final_price < profile.minimum_reserve_nal:
			continue
		prices[card_id] = final_price
		if cheapest_price < 0 or final_price < cheapest_price:
			cheapest_price = final_price
			cheapest_ids = [card_id]
		elif final_price == cheapest_price:
			cheapest_ids.append(card_id)
	if cheapest_ids.is_empty():
		return _no_market_purchase(state)
	var pick: Dictionary = SeededPicker.pick_best_tie(
		state["random"], cheapest_ids, "ai_buy_cheapest_tiebreak"
	)
	if not pick["ok"]:
		return _no_market_purchase(state)
	var working: Dictionary = _with_random(state, pick["random"])
	var chosen_id: String = str(pick["selected"])
	var bought: Dictionary = MarketLogic.buy_card(working, player_id, chosen_id)
	if not bought["ok"]:
		return _no_market_purchase(state)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": bought["state"],
		"purchased": true,
		"purchase": {
			"card_id": chosen_id,
			"price": int(prices[chosen_id]),
			"score": int(profile.purchase_scores.get(chosen_id, 0)),
		},
		"fallback_used": "buy_cheapest_valid",
		"log_entries": bought["log_entries"],
	}


static func _no_market_purchase(state: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": state,
		"purchased": false,
		"purchase": {},
		"fallback_used": "",
		"log_entries": [],
	}


## Applies the profile Action fallback when no unblocked attack remains (§5.19).
## Never overrides a failed probability roll (the caller gates this).
static func apply_action_fallback(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition,
	_context: Dictionary
) -> Dictionary:
	match profile.fallback:
		"discard_action_cards":
			return _discard_unusable_war_cards(state, player_id, profile)
		"attack_best_target":
			return _attack_best_blocked(state, player_id, profile)
	return _no_action(state)


static func _attack_best_blocked(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var built: Dictionary = AIActionLogic.build_attack_options(state, player_id, profile)
	var blocked: Array[Dictionary] = built["blocked_options"]
	if blocked.is_empty():
		return _no_action(state)
	var choice: Dictionary = AIActionLogic.choose_attack_option(state, blocked)
	if not choice["ok"]:
		return _no_action(state)
	var working: Dictionary = _with_random(state, choice["random"])
	var payload: Dictionary = AIActionLogic.build_payload_from_option(choice["option"])
	var resolved: Dictionary = CombatEngine.resolve_attack(working, payload)
	if not resolved["ok"]:
		return _no_action(state)
	return {
		"ok": true, "error": ValidationErrors.OK, "state": resolved["state"],
		"attacks": [_attack_record(resolved)], "discarded": [],
		"fallback_used": "attack_best_target", "log_entries": resolved["log_entries"],
	}


static func _discard_unusable_war_cards(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var usable: Dictionary = {}
	for option: Dictionary in AIActionLogic.build_attack_options(
		state, player_id, profile
	)["options"]:
		usable[option["card_id"]] = true
	var working: Dictionary = state
	var discarded: Array[String] = []
	var log_entries: Array = []
	for card_id: String in AIActionLogic.war_cards_in_hand(state, player_id):
		if usable.has(card_id):
			continue
		var result: Dictionary = CombatEngine.discard_war_card(working, player_id, card_id)
		if not result["ok"]:
			continue
		working = result["state"]
		discarded.append(card_id)
		log_entries.append_array(result["log_entries"])
	return {
		"ok": true, "error": ValidationErrors.OK, "state": working,
		"attacks": [], "discarded": discarded,
		"fallback_used": "discard_action_cards" if not discarded.is_empty() else "",
		"log_entries": log_entries,
	}


static func _no_action(state: Dictionary) -> Dictionary:
	return {
		"ok": true, "error": ValidationErrors.OK, "state": state,
		"attacks": [], "discarded": [], "fallback_used": "", "log_entries": [],
	}


static func _attack_record(resolved: Dictionary) -> Dictionary:
	return {
		"target_id": resolved["target_id"], "card_id": resolved["card_id"],
		"mode": resolved["mode"], "modifiers": resolved["modifiers"].duplicate(),
		"success": resolved["success"], "blocked": resolved["blocked"],
	}


static func _with_random(state: Dictionary, random_state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	working["random"] = random_state
	return working


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}
