class_name ContactCatalog

const DEFINITIONS: Array[ContactDefinition] = [
	preload("res://data/resources/contacts/black_cash.tres"),
	preload("res://data/resources/contacts/corrupt_clerk.tres"),
	preload("res://data/resources/contacts/street_medic.tres"),
]


static func get_by_id(id: String) -> ContactDefinition:
	for definition: ContactDefinition in DEFINITIONS:
		if definition.id == id:
			return definition
	return null


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: ContactDefinition in DEFINITIONS:
		ids.append(definition.id)
	return ids


static func get_all() -> Array[ContactDefinition]:
	return DEFINITIONS.duplicate()
