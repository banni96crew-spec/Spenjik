class_name ContactAttackHookLogic


static func on_attack_resolved(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	var enriched: Dictionary = _enrich_attack_event(state, event)
	if not ContactValidator.is_strong_ai_victory_event(enriched):
		return _noop(state)
	var player: Dictionary = ContactValidator._find_player(
		state, GameIds.PLAYER_HUMAN
	)
	if (
		player.is_empty()
		or ContactValidator.has_owned_contact(player)
		or ContactValidator.has_unresolved_pending_offer(state)
	):
		return _noop(state)
	var count: int = ContactOfferLogic.get_strong_ai_offer_count(state)
	return ContactOfferLogic.generate_contact_offer(
		state,
		GameIds.PLAYER_HUMAN,
		count,
		ContactValidator.STRONG_AI_VICTORY_SOURCE
	)


static func _noop(state: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"player_id": GameIds.PLAYER_HUMAN,
		"source": "",
		"contact_offer_ids": [],
		"offer_created": false,
		"state": state,
	}


static func _enrich_attack_event(
	state: Dictionary,
	event: Dictionary
) -> Dictionary:
	var enriched: Dictionary = event.duplicate(true)
	if enriched.has("target_is_strong_ai"):
		return enriched
	var target: Dictionary = ContactValidator._find_player(
		state, str(enriched.get("target_id", ""))
	)
	if target.is_empty():
		return enriched
	enriched["target_is_ai"] = target["is_ai"]
	enriched["target_is_strong_ai"] = target["is_strong_ai"]
	return enriched
