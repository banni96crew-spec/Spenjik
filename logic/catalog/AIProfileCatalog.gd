class_name AIProfileCatalog

const DEFINITIONS: Array[AIProfileDefinition] = [
	preload("res://data/resources/ai_profiles/builder.tres"),
	preload("res://data/resources/ai_profiles/racketeer.tres"),
	preload("res://data/resources/ai_profiles/merchant_ai.tres"),
	preload("res://data/resources/ai_profiles/paranoid.tres"),
	preload("res://data/resources/ai_profiles/schemer.tres"),
	preload("res://data/resources/ai_profiles/avenger.tres"),
]


static func get_by_id(id: String) -> AIProfileDefinition:
	for definition: AIProfileDefinition in DEFINITIONS:
		if definition.id == id:
			return definition
	return null


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: AIProfileDefinition in DEFINITIONS:
		ids.append(definition.id)
	return ids


static func get_all() -> Array[AIProfileDefinition]:
	return DEFINITIONS.duplicate()
