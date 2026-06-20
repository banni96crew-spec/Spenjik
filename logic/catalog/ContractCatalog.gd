class_name ContractCatalog

const DEFINITIONS: Array[ContractDefinition] = [
	preload("res://data/resources/contracts/silent_expansion.tres"),
	preload("res://data/resources/contracts/bloody_turf_war.tres"),
	preload("res://data/resources/contracts/gray_capital.tres"),
	preload("res://data/resources/contracts/iron_roof.tres"),
	preload("res://data/resources/contracts/district_under_control.tres"),
	preload("res://data/resources/contracts/proxy_war.tres"),
	preload("res://data/resources/contracts/big_cashbox.tres"),
]


static func get_by_id(id: String) -> ContractDefinition:
	for definition: ContractDefinition in DEFINITIONS:
		if definition.id == id:
			return definition
	return null


static func has_id(id: String) -> bool:
	return get_by_id(id) != null


static func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition: ContractDefinition in DEFINITIONS:
		ids.append(definition.id)
	return ids


static func get_all() -> Array[ContractDefinition]:
	return DEFINITIONS.duplicate()
