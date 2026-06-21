class_name TurfLevelLogic

const TURF_FLAG_AI_FIRST_WAR_DISCOUNT := "ai_first_war_discount_used_this_round"
const LEVEL_10_REASON := "TURF_LEVEL_10_AI_VP_TIE_BREAK"


static func create_empty_turf_flags() -> Dictionary:
	return {TURF_FLAG_AI_FIRST_WAR_DISCOUNT: false}


static func is_valid_turf_level(turf_level: int) -> bool:
	return TurfLevelIds.ALL.has(turf_level)


static func is_level_active(turf_level: int, level: int) -> bool:
	return turf_level >= level


static func apply_setup_modifiers(state: Dictionary) -> Dictionary:
	var turf_level: int = int(state.get("turf_level", -1))
	if not is_valid_turf_level(turf_level):
		return _setup_failure(state, ValidationErrors.INVALID_TURF_LEVEL, turf_level)
	if is_level_active(turf_level, TurfLevelIds.STRONG_AI_STARTS_WITH_EXTRA_VP):
		var strong_ai: Dictionary = _validate_strong_ai_assignment(state)
		if not strong_ai["ok"]:
			return _setup_failure(state, strong_ai["error"], turf_level)
	var candidate: Dictionary = state.duplicate(true)
	var effects_applied: Array[String] = []
	if is_level_active(turf_level, TurfLevelIds.AI_STARTS_WITH_EXTRA_NAL):
		for player: Dictionary in candidate["players"]:
			if player["is_ai"]:
				player["nal"] += 1
		effects_applied.append("ai_starting_nal_bonus")
	if is_level_active(turf_level, TurfLevelIds.STRONG_AI_STARTS_WITH_EXTRA_VP):
		for player: Dictionary in candidate["players"]:
			if player["is_strong_ai"]:
				player["vp"] += 1
		effects_applied.append("strong_ai_starting_vp_bonus")
	if is_level_active(turf_level, TurfLevelIds.HUMAN_STARTS_WITH_LESS_NAL):
		var human: Dictionary = _find_human(candidate)
		if human.is_empty():
			return _setup_failure(state, ValidationErrors.INVALID_TARGET, turf_level)
		human["nal"] = maxi(3, int(human["nal"]) - 1)
		effects_applied.append("human_starting_nal_penalty")
	for player: Dictionary in candidate["players"]:
		player["turf_flags"] = create_empty_turf_flags()
	if (
		is_level_active(turf_level, TurfLevelIds.HUMAN_STARTS_WITH_LESS_NAL)
		and _find_human(candidate)["nal"] < 3
	):
		return _setup_failure(state, ValidationErrors.INVALID_STATE, turf_level)
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"turf_level": turf_level,
		"effects_applied": effects_applied,
		"state": candidate,
		"log_entries": [],
	}


static func reset_round_turf_flags(player: Dictionary) -> Dictionary:
	player["turf_flags"][TURF_FLAG_AI_FIRST_WAR_DISCOUNT] = false
	return player


static func get_rotating_market_slot_count(turf_level: int) -> int:
	if is_level_active(turf_level, TurfLevelIds.SMALLER_ROTATING_MARKET):
		return 3
	return 4


static func get_cops_upkeep_interval(
	state: Dictionary,
	player: Dictionary
) -> int:
	if (
		is_level_active(int(state.get("turf_level", 0)), TurfLevelIds.HUMAN_COPS_UPKEEP_HARDER)
		and not player["is_ai"]
	):
		return 2
	return 3


static func get_ai_war_purchase_modifiers(
	state: Dictionary,
	player: Dictionary,
	card_def: CardDefinition
) -> Array[Dictionary]:
	if (
		not is_level_active(int(state.get("turf_level", 0)), TurfLevelIds.AI_FIRST_WAR_CARD_DISCOUNT)
		or not player["is_ai"]
		or card_def.type != CardTypes.WAR
		or player["turf_flags"][TURF_FLAG_AI_FIRST_WAR_DISCOUNT]
	):
		return []
	return [_war_discount_modifier(state, player)]


static func consume_turf_flags_after_purchase(
	state: Dictionary,
	player_id: String,
	applied_modifiers: Array
) -> Dictionary:
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty():
		return {
			"ok": false,
			"error": ValidationErrors.INVALID_PLAYER_ID,
			"state": state,
		}
	for modifier: Dictionary in applied_modifiers:
		if modifier.get("source") != "turf_level":
			continue
		if not modifier.get("consume_on_success", false):
			continue
		var flag: String = str(modifier.get("flag", ""))
		if flag.is_empty() or not player["turf_flags"].has(flag):
			continue
		player["turf_flags"][flag] = true
	return {"ok": true, "error": ValidationErrors.OK, "state": state}


static func get_strong_ai_victory_contact_offer_count(turf_level: int) -> int:
	if is_level_active(turf_level, TurfLevelIds.CONTACT_CHOICE_REDUCED):
		return 2
	return 3


static func get_street_deal_payment_delta(
	state: Dictionary,
	player: Dictionary
) -> int:
	if (
		is_level_active(int(state.get("turf_level", 0)), TurfLevelIds.HUMAN_STREET_DEAL_PAYMENTS_INCREASED)
		and not player["is_ai"]
	):
		return 1
	return 0


static func is_human_vp_leader(state: Dictionary) -> bool:
	var human: Dictionary = _find_human(state)
	if human.is_empty():
		return false
	var human_vp: int = int(human["vp"])
	for player_id: String in GameIds.AI_PLAYER_IDS:
		var ai: Dictionary = _find_player(state, player_id)
		if ai.is_empty() or human_vp <= int(ai["vp"]):
			return false
	return true


static func get_ai_war_purchase_weight_multiplier(state: Dictionary) -> float:
	if (
		is_level_active(int(state.get("turf_level", 0)), TurfLevelIds.AI_WAR_WEIGHT_WHEN_HUMAN_LEADS)
		and is_human_vp_leader(state)
	):
		return 1.2
	return 1.0


static func resolve_level_10_ai_tie_break(
	state: Dictionary,
	tied_players: Array
) -> Dictionary:
	var not_applied: Dictionary = {
		"ok": true,
		"applied": false,
		"winner_id": "",
		"reason": "",
		"tied_player_ids": _player_ids(tied_players),
		"ai_tie_break": {},
	}
	if not is_level_active(int(state.get("turf_level", 0)), TurfLevelIds.AI_WINS_VP_TIES):
		return not_applied
	var ai_leaders: Array[Dictionary] = []
	for player: Dictionary in tied_players:
		if player.get("is_ai", false):
			ai_leaders.append(player)
	if ai_leaders.is_empty():
		return not_applied
	var winner: Dictionary = _select_ai_leader(ai_leaders)
	return {
		"ok": true,
		"applied": true,
		"winner_id": winner["id"],
		"reason": LEVEL_10_REASON,
		"tied_player_ids": _player_ids(tied_players),
		"ai_tie_break": {
			"method": "highest_nal_then_stable_ai_order",
			"selected_ai_id": winner["id"],
		},
	}


static func _war_discount_modifier(
	state: Dictionary,
	player: Dictionary
) -> Dictionary:
	return {
		"id": "turf_level_6_%s_round_%d" % [player["id"], state["round"]],
		"source": "turf_level",
		"turf_level": TurfLevelIds.AI_FIRST_WAR_CARD_DISCOUNT,
		"flag": TURF_FLAG_AI_FIRST_WAR_DISCOUNT,
		"type": ModifierTypes.CARD_PRICE_DELTA,
		"delta": -1,
		"applies_to_card_type": CardTypes.WAR,
		"consume_on_success": true,
		"description": "Turf Level 6 first AI War card discount",
	}


static func _select_ai_leader(ai_leaders: Array[Dictionary]) -> Dictionary:
	var maximum_nal: int = -1
	for player: Dictionary in ai_leaders:
		maximum_nal = maxi(maximum_nal, int(player["nal"]))
	var nal_tied: Array[Dictionary] = []
	for player: Dictionary in ai_leaders:
		if int(player["nal"]) == maximum_nal:
			nal_tied.append(player)
	if nal_tied.size() == 1:
		return nal_tied[0]
	for player_id: String in GameIds.AI_PLAYER_IDS:
		for player: Dictionary in nal_tied:
			if player["id"] == player_id:
				return player
	return nal_tied[0]


static func _validate_strong_ai_assignment(state: Dictionary) -> Dictionary:
	var strong_count: int = 0
	for player: Dictionary in state.get("players", []):
		if player.get("is_strong_ai", false):
			strong_count += 1
	if strong_count != 1:
		return {"ok": false, "error": ValidationErrors.INVALID_AI_STATE}
	return {"ok": true, "error": ValidationErrors.OK}


static func _player_ids(players: Array) -> Array[String]:
	var ids: Array[String] = []
	for player: Dictionary in players:
		ids.append(str(player["id"]))
	return ids


static func _find_human(state: Dictionary) -> Dictionary:
	return _find_player(state, GameIds.PLAYER_HUMAN)


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


static func _setup_failure(
	state: Dictionary,
	error: String,
	turf_level: int
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"turf_level": turf_level,
		"effects_applied": [],
		"state": state,
		"log_entries": [],
	}
