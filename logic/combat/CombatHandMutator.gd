class_name CombatHandMutator


static func cards_for_attack(payload: Dictionary) -> Array[String]:
	var result: Array[String] = [payload["card_id"]]
	if payload["modifiers"].has(GameIds.CARD_INSIDER):
		result.append(GameIds.CARD_INSIDER)
	return result


static func consume_cards(
	attacker: Dictionary,
	card_ids: Array[String]
) -> void:
	for card_id: String in card_ids:
		var index: int = attacker["hand"].find(card_id)
		if index >= 0:
			attacker["hand"].remove_at(index)


static func consume_one(attacker: Dictionary, card_id: String) -> void:
	var index: int = attacker["hand"].find(card_id)
	if index >= 0:
		attacker["hand"].remove_at(index)
