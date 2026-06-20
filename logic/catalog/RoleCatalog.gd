class_name RoleCatalog

const DEFINITIONS: Array[RoleDefinition] = [
	preload("res://data/resources/roles/merchant.tres"),
	preload("res://data/resources/roles/enforcer.tres"),
	preload("res://data/resources/roles/gray_cardinal.tres"),
	preload("res://data/resources/roles/district_boss.tres"),
]


static func get_by_id(id: String) -> RoleDefinition:
	for definition: RoleDefinition in DEFINITIONS:
		if definition.id == id:
			return definition
	return null


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: RoleDefinition in DEFINITIONS:
		ids.append(definition.id)
	return ids


static func get_all() -> Array[RoleDefinition]:
	return DEFINITIONS.duplicate()
