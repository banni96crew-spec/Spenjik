class_name AIPurchaseLogic

## Owns AI Market decisions: candidate building, profile scoring, reserve rule,
## Turf Level 9 War multiplier, deterministic tie-breaks, and the multi-buy loop.
## All purchases go through MarketLogic; reserve never bypasses NOT_ENOUGH_NAL.


## Runs the multi-buy loop until no candidate remains, then applies fallback.
static func run_purchase_loop(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var working: Dictionary = state
	var purchases: Array[Dictionary] = []
	var log_entries: Array = []
	var fallback_used: String = ""
	var guard: int = int(working["market"]["all_available_card_ids"].size()) + 1
	for _iteration: int in guard:
		var built: Dictionary = build_purchase_candidates(working, player_id, profile)
		var candidates: Array[Dictionary] = built["candidates"]
		if not candidates.is_empty():
			var choice: Dictionary = choose_purchase_candidate(working, candidates)
			if not choice["ok"]:
				break
			var trial: Dictionary = _with_random(working, choice["random"])
			var bought: Dictionary = MarketLogic.buy_card(
				trial, player_id, choice["candidate"]["card_id"]
			)
			if not bought["ok"]:
				return {
					"ok": false,
					"error": bought["error"],
					"state": working,
					"purchases": purchases,
					"fallback_used": fallback_used,
					"log_entries": log_entries,
				}
			working = bought["state"]
			purchases.append(_purchase_record(choice["candidate"]))
			log_entries.append_array(bought["log_entries"])
			continue
		var fallback: Dictionary = AIFallbackLogic.apply_market_fallback(
			working, player_id, profile
		)
		working = fallback["state"]
		log_entries.append_array(fallback["log_entries"])
		if fallback["purchased"]:
			purchases.append(fallback["purchase"])
			fallback_used = fallback["fallback_used"]
			continue
		break
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": working,
		"purchases": purchases,
		"fallback_used": fallback_used,
		"log_entries": log_entries,
	}


## Builds the list of normal purchase candidates (score > 0, reserve-safe, valid).
static func build_purchase_candidates(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return {"ok": true, "candidates": candidates}
	for card_id: String in state["market"].get("all_available_card_ids", []):
		if not MarketLogic.can_buy_card(state, player_id, card_id)["ok"]:
			continue
		var candidate: Dictionary = score_purchase_candidate(
			state, player, card_id, profile
		)
		if candidate["base_score"] <= 0:
			continue
		if candidate["reserve_after_purchase"] < profile.minimum_reserve_nal:
			continue
		candidates.append(candidate)
	return {"ok": true, "candidates": candidates}


## Scores one card for a player. Read-only; consumes no random.
static func score_purchase_candidate(
	state: Dictionary,
	player: Dictionary,
	card_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var card_def: CardDefinition = CardCatalog.get_by_id(card_id)
	var final_price: int = int(
		PriceLogic.get_card_price(state, player["id"], card_id).get("final_price", 0)
	)
	var base_score: int = int(profile.purchase_scores.get(card_id, 0))
	var multiplier: float = TurfLevelLogic.get_ai_war_purchase_weight_multiplier(
		state, card_def
	)
	return {
		"player_id": player["id"],
		"card_id": card_id,
		"base_score": base_score,
		"final_score": float(base_score) * multiplier,
		"price": final_price,
		"reserve_after_purchase": int(player["nal"]) - final_price,
		"modifiers": [],
	}


## Selects the highest-score candidate, breaking exact ties with SeededPicker.
static func choose_purchase_candidate(
	state: Dictionary,
	candidates: Array[Dictionary]
) -> Dictionary:
	if candidates.is_empty():
		return _no_choice(state)
	var best: float = -1.0
	for candidate: Dictionary in candidates:
		best = maxf(best, float(candidate["final_score"]))
	var tied: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if is_equal_approx(float(candidate["final_score"]), best):
			tied.append(candidate)
	var pick: Dictionary = SeededPicker.pick_best_tie(
		state["random"], tied, "ai_purchase_tiebreak"
	)
	if not pick["ok"]:
		return _no_choice(state)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"candidate": pick["selected"],
		"random": pick["random"],
	}


static func _purchase_record(candidate: Dictionary) -> Dictionary:
	return {
		"card_id": candidate["card_id"],
		"price": candidate["price"],
		"score": candidate["base_score"],
	}


static func _no_choice(state: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"error": ValidationErrors.NO_VALID_AI_PURCHASE,
		"candidate": {},
		"random": state["random"],
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
