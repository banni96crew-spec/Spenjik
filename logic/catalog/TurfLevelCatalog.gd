class_name TurfLevelCatalog

const DEFINITIONS: Array[TurfLevelDefinition] = [
	preload("res://data/resources/turf_levels/turf_level_0.tres"),
	preload("res://data/resources/turf_levels/turf_level_1.tres"),
	preload("res://data/resources/turf_levels/turf_level_2.tres"),
	preload("res://data/resources/turf_levels/turf_level_3.tres"),
	preload("res://data/resources/turf_levels/turf_level_4.tres"),
	preload("res://data/resources/turf_levels/turf_level_5.tres"),
	preload("res://data/resources/turf_levels/turf_level_6.tres"),
	preload("res://data/resources/turf_levels/turf_level_7.tres"),
	preload("res://data/resources/turf_levels/turf_level_8.tres"),
	preload("res://data/resources/turf_levels/turf_level_9.tres"),
	preload("res://data/resources/turf_levels/turf_level_10.tres"),
]


static func get_by_level(level: int) -> TurfLevelDefinition:
	for definition: TurfLevelDefinition in DEFINITIONS:
		if definition.level == level:
			return definition
	return null


static func get_by_id(id: String) -> TurfLevelDefinition:
	if not id.is_valid_int():
		return null
	return get_by_level(id.to_int())


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: TurfLevelDefinition in DEFINITIONS:
		ids.append(str(definition.level))
	return ids


static func get_all() -> Array[TurfLevelDefinition]:
	return DEFINITIONS.duplicate()
