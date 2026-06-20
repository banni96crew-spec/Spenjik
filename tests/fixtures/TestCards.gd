class_name TestCards


static func war_card_ids() -> Array[String]:
	var result: Array[String] = []
	for card_id: String in GameIds.CARD_IDS:
		var definition: CardDefinition = CardCatalog.get_by_id(card_id)
		if definition != null and definition.type == CardTypes.WAR:
			result.append(card_id)
	return result


static func first_war_card_id() -> String:
	return war_card_ids()[0]
