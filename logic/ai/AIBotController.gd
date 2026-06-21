class_name AIBotController

## Coordinates AI decisions. Owns no game rules: it calls owner modules for
## setup, market, combat, and deterministic random, and never mutates state
## outside those owner APIs and phase-safe flow.


## Selects strong AI and assigns unique profiles deterministically (§8.1).
static func setup_ai_bosses(state: Dictionary) -> Dictionary:
	return AISetupLogic.setup(state)


## Returns the AIBossState assigned to a player, or an empty Dictionary.
static func get_ai_boss_state(state: Dictionary, player_id: String) -> Dictionary:
	for boss: Dictionary in state.get("ai_bosses", []):
		if boss.get("assigned_player_id") == player_id:
			return boss
	return {}


## Returns the immutable AI profile Resource for a profile ID, or null.
static func get_ai_profile(profile_id: String) -> AIProfileDefinition:
	return AIProfileCatalog.get_by_id(profile_id)


## Runs the full AI Market turn: multi-buy loop then phase-safe Market end (§8.2).
static func run_market_for_ai(state: Dictionary, player_id: String) -> Dictionary:
	var resolved: Dictionary = _resolve_profile(state, player_id, PhaseIds.MARKET)
	if not resolved["ok"]:
		return _market_failure(state, resolved["error"], player_id, "")
	var profile: AIProfileDefinition = resolved["profile"]
	var loop: Dictionary = AIPurchaseLogic.run_purchase_loop(state, player_id, profile)
	if not loop["ok"]:
		return _market_failure(state, loop["error"], player_id, profile.id)
	var ended: Dictionary = GamePhaseController.end_market_for_player(
		loop["state"], player_id
	)
	if not ended["ok"]:
		return _market_failure(state, ended["error"], player_id, profile.id)
	var log_entries: Array = loop["log_entries"].duplicate()
	log_entries.append_array(ended["log_entries"])
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": player_id,
		"profile_id": profile.id,
		"purchases": loop["purchases"],
		"fallback_used": loop["fallback_used"],
		"state": ended["state"],
		"log_entries": log_entries,
	}


static func _resolve_profile(
	state: Dictionary,
	player_id: String,
	expected_phase: String
) -> Dictionary:
	if state.get("current_phase") != expected_phase:
		return {"ok": false, "error": ValidationErrors.INVALID_PHASE}
	var player: Dictionary = _find_player(state, player_id)
	if player.is_empty() or not player["is_ai"]:
		return {"ok": false, "error": ValidationErrors.INVALID_AI_STATE}
	var boss: Dictionary = get_ai_boss_state(state, player_id)
	if boss.is_empty():
		return {"ok": false, "error": ValidationErrors.INVALID_AI_STATE}
	var profile: AIProfileDefinition = AIProfileCatalog.get_by_id(boss["profile_id"])
	if profile == null:
		return {"ok": false, "error": ValidationErrors.INVALID_AI_PROFILE_ID}
	return {"ok": true, "error": ValidationErrors.OK, "profile": profile}


static func _market_failure(
	state: Dictionary,
	error: String,
	player_id: String,
	profile_id: String
) -> Dictionary:
	return {
		"ok": false,
		"error": error,
		"player_id": player_id,
		"profile_id": profile_id,
		"purchases": [],
		"fallback_used": "",
		"state": state,
		"log_entries": [],
	}


## Runs the full AI Action turn: one probability roll, an unblocked attack loop,
## a fallback when no unblocked attack was possible, then phase-safe end (§8.3).
static func run_action_for_ai(state: Dictionary, player_id: String) -> Dictionary:
	var resolved: Dictionary = _resolve_profile(state, player_id, PhaseIds.ACTION)
	if not resolved["ok"]:
		return _action_failure(state, resolved["error"], player_id, "")
	var profile: AIProfileDefinition = resolved["profile"]
	if state.get("active_action_player_id") != player_id:
		return _action_failure(state, ValidationErrors.NOT_ACTIVE_PLAYER, player_id, profile.id)
	var working: Dictionary = state
	var attacks: Array = []
	var log_entries: Array = []
	var attack_roll: float = -1.0
	var fallback_used: String = ""
	var war_cards: Array[String] = AIActionLogic.war_cards_in_hand(working, player_id)
	if not war_cards.is_empty():
		var roll: Dictionary = SeededRandom.next(
			working["random"],
			"ai_%s_attack_probability_round_%s" % [player_id, working["round"]]
		)
		if not roll["ok"]:
			return _action_failure(state, roll["error"], player_id, profile.id)
		working = _with_random(working, roll["random"])
		attack_roll = roll["value"]
		if attack_roll <= profile.attack_probability:
			var loop: Dictionary = _attack_loop(working, player_id, profile, war_cards.size())
			working = loop["state"]
			attacks = loop["attacks"]
			log_entries = loop["log_entries"]
			var remaining: Dictionary = AIActionLogic.build_attack_options(
				working, player_id, profile
			)
			var should_fallback: bool = remaining["options"].is_empty()
			if should_fallback and (
				attacks.is_empty() or profile.fallback == "attack_best_target"
			):
				var fb: Dictionary = AIFallbackLogic.apply_action_fallback(
					working, player_id, profile, {}
				)
				working = fb["state"]
				attacks.append_array(fb["attacks"])
				fallback_used = fb["fallback_used"]
				log_entries.append_array(fb["log_entries"])
	var ended: Dictionary = GamePhaseController.end_action_for_player(working, player_id)
	if not ended["ok"]:
		return _action_failure(state, ended["error"], player_id, profile.id)
	log_entries.append_array(ended["log_entries"])
	return {
		"ok": true, "error": ValidationErrors.OK,
		"player_id": player_id, "profile_id": profile.id,
		"attack_roll": attack_roll, "attack_probability": profile.attack_probability,
		"attacks": attacks, "fallback_used": fallback_used,
		"state": ended["state"], "log_entries": log_entries,
	}


static func _attack_loop(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition,
	max_iterations: int
) -> Dictionary:
	var working: Dictionary = state
	var attacks: Array = []
	var log_entries: Array = []
	for _iteration: int in max_iterations:
		var built: Dictionary = AIActionLogic.build_attack_options(working, player_id, profile)
		if built["options"].is_empty():
			break
		var choice: Dictionary = AIActionLogic.choose_attack_option(working, built["options"])
		working = _with_random(working, choice["random"])
		if not choice["ok"]:
			break
		var payload: Dictionary = AIActionLogic.build_payload_from_option(choice["option"])
		var resolved: Dictionary = CombatEngine.resolve_attack(working, payload)
		if not resolved["ok"]:
			break
		working = resolved["state"]
		attacks.append(_attack_record(resolved))
		log_entries.append_array(resolved["log_entries"])
	return {"state": working, "attacks": attacks, "log_entries": log_entries}


static func _action_failure(
	state: Dictionary,
	error: String,
	player_id: String,
	profile_id: String
) -> Dictionary:
	return {
		"ok": false, "error": error, "player_id": player_id, "profile_id": profile_id,
		"attack_roll": -1.0, "attack_probability": 0.0, "attacks": [],
		"fallback_used": "", "state": state, "log_entries": [],
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
