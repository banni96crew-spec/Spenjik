class_name AIActionLogic

## Builds and selects AI attack options (§5.12-5.16, §8.5). Honors mode
## preferences, deterministic Saboteur priority, and Insider-only-with-Thug.
## All validity/blocked decisions come from CombatEngine; never mutates state.

const SABOTEUR_PRIORITY: Array[String] = [
	GameIds.CARD_BROTHEL, GameIds.CARD_LAUNDRY,
	GameIds.CARD_ACCOUNTANT, GameIds.CARD_INFORMANT,
]


## Returns the War card IDs currently in a player's hand, in hand order.
static func war_cards_in_hand(state: Dictionary, player_id: String) -> Array[String]:
	var result: Array[String] = []
	var player: Dictionary = _find(state, player_id)
	for card_id: String in player.get("hand", []):
		var definition: CardDefinition = CardCatalog.get_by_id(card_id)
		if definition != null and definition.type == CardTypes.WAR:
			result.append(card_id)
	return result


## Builds valid attack options split into unblocked and blocked-valid lists.
static func build_attack_options(
	state: Dictionary,
	player_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var attacker: Dictionary = _find(state, player_id)
	var options: Array[Dictionary] = []
	var blocked: Array[Dictionary] = []
	var seen_cards: Dictionary = {}
	for card_id: String in war_cards_in_hand(state, player_id):
		if seen_cards.has(card_id):
			continue
		seen_cards[card_id] = true
		for target_id: String in AITargetLogic.get_valid_targets_for_ai(state, player_id):
			for payload: Dictionary in _card_target_payloads(
				state, attacker, target_id, card_id
			):
				if not CombatEngine.validate_attack(state, payload)["ok"]:
					continue
				var preview: Dictionary = CombatEngine.get_combat_preview(state, payload)
				if not preview["ok"]:
					continue
				var option: Dictionary = _make_option(
					state, player_id, target_id, payload, profile,
					preview["would_be_blocked"]
				)
				if preview["would_be_blocked"]:
					blocked.append(option)
				else:
					options.append(option)
	return {"ok": true, "options": options, "blocked_options": blocked}


## Selects the highest final-score option, breaking exact ties with SeededPicker.
static func choose_attack_option(
	state: Dictionary,
	options: Array[Dictionary]
) -> Dictionary:
	if options.is_empty():
		return {"ok": false, "error": ValidationErrors.NO_VALID_AI_ACTION,
			"option": {}, "random": state["random"]}
	var best: float = -1.0
	for option: Dictionary in options:
		best = maxf(best, float(option["final_score"]))
	var tied: Array[Dictionary] = []
	for option: Dictionary in options:
		if is_equal_approx(float(option["final_score"]), best):
			tied.append(option)
	var pick: Dictionary = SeededPicker.pick_best_tie(
		state["random"], tied, "ai_attack_option_tiebreak"
	)
	if not pick["ok"]:
		return {"ok": false, "error": ValidationErrors.NO_VALID_AI_ACTION,
			"option": {}, "random": state["random"]}
	return {"ok": true, "error": ValidationErrors.OK,
		"option": pick["selected"], "random": pick["random"]}


## Converts a chosen option into a canonical CombatEngine attack payload.
static func build_payload_from_option(option: Dictionary) -> Dictionary:
	return {
		"attacker_id": option["attacker_id"],
		"target_id": option["target_id"],
		"card_id": option["card_id"],
		"mode": option["mode"],
		"modifiers": option["modifiers"].duplicate(),
		"engine_target_card_id": option["engine_target_card_id"],
	}


static func _card_target_payloads(
	state: Dictionary,
	attacker: Dictionary,
	target_id: String,
	card_id: String
) -> Array[Dictionary]:
	match card_id:
		GameIds.CARD_THUG:
			return _thug_payloads(state, attacker, target_id)
		GameIds.CARD_BRUISER:
			return _destructive_payloads(
				state, attacker, target_id, card_id, AttackModes.DESTROY_STASH
			)
		GameIds.CARD_CLEANER:
			return _destructive_payloads(
				state, attacker, target_id, card_id, AttackModes.DESTROY_WORKSHOP
			)
		GameIds.CARD_FEDERAL_RAID:
			return [_payload(attacker["id"], target_id, card_id,
				AttackModes.DESTROY_DISTRICT, [], "")]
		GameIds.CARD_SABOTEUR:
			return _saboteur_payloads(state, attacker, target_id)
	return []


static func _thug_payloads(
	state: Dictionary,
	attacker: Dictionary,
	target_id: String
) -> Array[Dictionary]:
	var base: Dictionary = _payload(
		attacker["id"], target_id, GameIds.CARD_THUG, "", [], ""
	)
	var target: Dictionary = _find(state, target_id)
	var cops_active: bool = target.get("defense", {}).get("cops_active", false)
	if attacker["hand"].has(GameIds.CARD_INSIDER) and cops_active:
		var with_insider: Dictionary = _payload(
			attacker["id"], target_id, GameIds.CARD_THUG, "",
			[GameIds.CARD_INSIDER], ""
		)
		var base_preview: Dictionary = CombatEngine.get_combat_preview(state, base)
		if (
			base_preview["ok"] and base_preview["would_be_blocked"]
			and CombatEngine.validate_attack(state, with_insider)["ok"]
		):
			var insider_preview: Dictionary = CombatEngine.get_combat_preview(
				state, with_insider
			)
			if insider_preview["ok"] and not insider_preview["would_be_blocked"]:
				return [with_insider]
	return [base]


static func _destructive_payloads(
	state: Dictionary,
	attacker: Dictionary,
	target_id: String,
	card_id: String,
	destroy_mode: String
) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var destroy: Dictionary = _payload(
		attacker["id"], target_id, card_id, destroy_mode, [], ""
	)
	if CombatEngine.validate_attack(state, destroy)["ok"]:
		results.append(destroy)
		var preview: Dictionary = CombatEngine.get_combat_preview(state, destroy)
		if preview["ok"] and not preview["would_be_blocked"]:
			return results
	var steal: Dictionary = _payload(
		attacker["id"], target_id, card_id, AttackModes.STEAL_NAL, [], ""
	)
	if CombatEngine.validate_attack(state, steal)["ok"]:
		results.append(steal)
	return results


static func _saboteur_payloads(
	state: Dictionary,
	attacker: Dictionary,
	target_id: String
) -> Array[Dictionary]:
	for engine_id: String in SABOTEUR_PRIORITY:
		var payload: Dictionary = _payload(
			attacker["id"], target_id, GameIds.CARD_SABOTEUR, "", [], engine_id
		)
		if CombatEngine.validate_attack(state, payload)["ok"]:
			return [payload]
	return []


static func _make_option(
	state: Dictionary,
	player_id: String,
	target_id: String,
	payload: Dictionary,
	profile: AIProfileDefinition,
	blocked: bool
) -> Dictionary:
	var card_preference: int = int(profile.purchase_scores.get(payload["card_id"], 0))
	var target_score: float = float(
		AITargetLogic.score_target(state, player_id, target_id, profile)["score"]
	)
	return {
		"attacker_id": payload["attacker_id"],
		"target_id": payload["target_id"],
		"card_id": payload["card_id"],
		"mode": payload["mode"],
		"modifiers": payload["modifiers"].duplicate(),
		"engine_target_card_id": payload["engine_target_card_id"],
		"card_preference_score": card_preference,
		"target_score": target_score,
		"blocked": blocked,
		"final_score": float(card_preference) + target_score,
	}


static func _payload(
	attacker_id: String,
	target_id: String,
	card_id: String,
	mode: String,
	modifiers: Array,
	engine_target_card_id: String
) -> Dictionary:
	return {
		"attacker_id": attacker_id,
		"target_id": target_id,
		"card_id": card_id,
		"mode": mode,
		"modifiers": modifiers.duplicate(),
		"engine_target_card_id": engine_target_card_id,
	}


static func _find(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}
