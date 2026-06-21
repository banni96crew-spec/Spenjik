class_name MarketLogic

const ALWAYS_AVAILABLE_CARD_IDS: Array[String] = [
	GameIds.CARD_INFORMANT, GameIds.CARD_STASH,
	GameIds.CARD_THUG, GameIds.CARD_COPS,
]
const ROTATING_MARKET_POOL: Array[String] = [
	GameIds.CARD_LAUNDRY, GameIds.CARD_ACCOUNTANT, GameIds.CARD_BROTHEL,
	GameIds.CARD_WORKSHOP, GameIds.CARD_DISTRICT_CONTROL,
	GameIds.CARD_CARTEL, GameIds.CARD_JUDGE, GameIds.CARD_BRUISER,
	GameIds.CARD_CLEANER, GameIds.CARD_INSIDER, GameIds.CARD_SABOTEUR,
	GameIds.CARD_FEDERAL_RAID,
]


## Generates the shared market and consumes one step per rotating slot.
static func generate_market(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	var slots: int = get_rotating_slot_count(state["turf_level"])
	var picked: Dictionary = SeededPicker.pick_unique(
		state["random"], ROTATING_MARKET_POOL, slots,
		"market_round_%s" % state["round"]
	)
	if not picked["ok"]:
		return _failure(state, ValidationErrors.INVALID_RANDOM_STATE)
	var candidate: Dictionary = state.duplicate(true)
	var rotating: Array = picked["selected_items"].duplicate()
	var all_cards: Array = ALWAYS_AVAILABLE_CARD_IDS.duplicate()
	all_cards.append_array(rotating)
	candidate["random"] = picked["random"]
	candidate["market"] = {
		"round": candidate["round"],
		"always_available_card_ids": ALWAYS_AVAILABLE_CARD_IDS.duplicate(),
		"rotating_card_ids": rotating,
		"all_available_card_ids": all_cards,
	}
	return {
		"ok": true, "error": ValidationErrors.OK,
		"state": candidate, "market": candidate["market"].duplicate(true),
		"random": candidate["random"].duplicate(true),
		"steps_used": picked["steps_used"], "log_entries": [],
	}


## Resolves the complete atomic Income -> Market boundary.
static func resolve_income_and_enter_market(state: Dictionary) -> Dictionary:
	var validation: Dictionary = GameStateValidator.validate_game_state(state)
	if not validation["ok"]:
		return _failure(state, validation["error"])
	if state["current_phase"] != PhaseIds.INCOME:
		return _failure(state, ValidationErrors.INVALID_PHASE)
	var blocker: Dictionary = IncomeLogic.validate_future_income_dependencies(state)
	if not blocker["ok"]:
		return _failure(state, blocker["error"])
	var income: Dictionary = IncomeLogic.resolve_all_players(state)
	if not income["ok"]:
		return _failure(state, income["error"])
	var generated: Dictionary = generate_market(income["state"])
	if not generated["ok"]:
		return _failure(state, generated["error"])
	var candidate: Dictionary = generated["state"]
	var log_start: int = state["combat_log"].size()
	candidate["current_phase"] = PhaseIds.MARKET
	PhaseStateHelper.apply_market_reset(candidate)
	for player: Dictionary in candidate["players"]:
		player["action_done"] = false
	_append_market_started(candidate)
	_append_phase_changed(candidate)
	var final_validation: Dictionary = GameStateValidator.validate_game_state(candidate)
	if not final_validation["ok"]:
		return _failure(state, final_validation["error"])
	return {
		"ok": true, "error": ValidationErrors.OK,
		"state": candidate,
		"log_entries": candidate["combat_log"].slice(log_start),
	}


static func can_buy_card(
	state: Dictionary,
	player_id: String,
	card_id: String
) -> Dictionary:
	return PurchaseValidator.validate_purchase(state, player_id, card_id)


static func buy_card(
	state: Dictionary,
	player_id: String,
	card_id: String
) -> Dictionary:
	var validation: Dictionary = can_buy_card(state, player_id, card_id)
	if not validation["ok"]:
		return _failure(state, validation["error"], player_id, card_id,
			int(validation["price_result"].get("final_price", 0)))
	return PurchaseResolver.resolve_purchase(
		state, player_id, validation["definition"],
		validation["price_result"]
	)


static func rebuild_district_control(
	state: Dictionary,
	player_id: String
) -> Dictionary:
	var validation: Dictionary = PurchaseValidator.validate_rebuild(
		state, player_id
	)
	if not validation["ok"]:
		return _failure(state, validation["error"], player_id)
	return PurchaseResolver.resolve_rebuild(
		state, player_id, validation["price_result"]
	)


static func get_rotating_slot_count(turf_level: int) -> int:
	return 3 if turf_level >= 4 else 4


static func _append_market_started(state: Dictionary) -> void:
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		LogEventTypes.MARKET_STARTED, {
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"], "phase": PhaseIds.MARKET,
			"summary": LogEventTypes.MARKET_STARTED,
			"details": {
				"round": state["round"],
				"available_card_ids":
					state["market"]["all_available_card_ids"].duplicate(),
			},
		}
	))


static func _append_phase_changed(state: Dictionary) -> void:
	state["combat_log"].append(GameStateFactory.create_combat_log_entry(
		LogEventTypes.PHASE_CHANGED, {
			"id": "log_%06d" % (state["combat_log"].size() + 1),
			"round": state["round"], "phase": PhaseIds.MARKET,
			"summary": LogEventTypes.PHASE_CHANGED,
			"details": {
				"from_phase": PhaseIds.INCOME, "to_phase": PhaseIds.MARKET,
				"round_before": state["round"], "round_after": state["round"],
			},
		}
	))


static func _failure(
	state: Dictionary,
	error: String,
	player_id: String = "",
	card_id: String = "",
	price: int = 0
) -> Dictionary:
	return {
		"ok": false, "error": error, "state": state,
		"player_id": player_id, "card_id": card_id, "price": price,
		"log_entries": [],
	}
