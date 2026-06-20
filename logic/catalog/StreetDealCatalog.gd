class_name StreetDealCatalog

const DEFINITIONS: Array[StreetDealDefinition] = [
	preload("res://data/resources/street_deals/loan_shark.tres"),
	preload("res://data/resources/street_deals/dirty_tip.tres"),
	preload("res://data/resources/street_deals/cheap_protection.tres"),
	preload("res://data/resources/street_deals/black_market_cache.tres"),
	preload("res://data/resources/street_deals/inside_contact.tres"),
	preload("res://data/resources/street_deals/risky_contract.tres"),
]


static func get_by_id(id: String) -> StreetDealDefinition:
	for definition: StreetDealDefinition in DEFINITIONS:
		if definition.id == id:
			return definition
	return null


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: StreetDealDefinition in DEFINITIONS:
		ids.append(definition.id)
	return ids


static func get_all() -> Array[StreetDealDefinition]:
	return DEFINITIONS.duplicate()
