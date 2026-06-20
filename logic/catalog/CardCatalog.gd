class_name CardCatalog

const DEFINITIONS: Array[CardDefinition] = [
	preload("res://data/resources/cards/informant.tres"),
	preload("res://data/resources/cards/laundry.tres"),
	preload("res://data/resources/cards/accountant.tres"),
	preload("res://data/resources/cards/brothel.tres"),
	preload("res://data/resources/cards/stash.tres"),
	preload("res://data/resources/cards/workshop.tres"),
	preload("res://data/resources/cards/district_control.tres"),
	preload("res://data/resources/cards/cops.tres"),
	preload("res://data/resources/cards/cartel.tres"),
	preload("res://data/resources/cards/judge.tres"),
	preload("res://data/resources/cards/thug.tres"),
	preload("res://data/resources/cards/bruiser.tres"),
	preload("res://data/resources/cards/cleaner.tres"),
	preload("res://data/resources/cards/insider.tres"),
	preload("res://data/resources/cards/saboteur.tres"),
	preload("res://data/resources/cards/federal_raid.tres"),
]


static func get_by_id(id: String) -> CardDefinition:
	for definition: CardDefinition in DEFINITIONS:
		if definition.id == id:
			return definition
	return null


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: CardDefinition in DEFINITIONS:
		ids.append(definition.id)
	return ids


static func get_all() -> Array[CardDefinition]:
	return DEFINITIONS.duplicate()
