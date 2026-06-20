extends GutTest

const DOMAIN_PATHS: Array[String] = [
	"res://data/resources/cards",
	"res://data/resources/roles",
	"res://data/resources/contracts",
	"res://data/resources/contacts",
	"res://data/resources/street_deals",
	"res://data/resources/ai_profiles",
	"res://data/resources/turf_levels",
]
const FORBIDDEN_RESOURCE_FIELDS: Array[String] = [
	"runtime_state", "owner_player_id", "cooldowns", "progress",
	"market_state", "random_state", "debts",
]


func test_exact_resource_file_count_and_no_extra_tres() -> void:
	var paths: Array[String] = _resource_paths()
	assert_eq(paths.size(), 53)


func test_resources_contain_no_runtime_state_fields() -> void:
	for path: String in _resource_paths():
		var resource: Resource = load(path)
		assert_not_null(resource, "Failed to load %s" % path)
		var property_names: Array[String] = []
		for property: Dictionary in resource.get_property_list():
			property_names.append(property["name"])
		for forbidden: String in FORBIDDEN_RESOURCE_FIELDS:
			assert_false(
				property_names.has(forbidden),
				"%s contains runtime field %s" % [path, forbidden]
			)


func test_every_resource_loads_through_its_catalog() -> void:
	assert_eq(CardCatalog.get_all().size(), 16)
	assert_eq(RoleCatalog.get_all().size(), 4)
	assert_eq(ContractCatalog.get_all().size(), 7)
	assert_eq(ContactCatalog.get_all().size(), 3)
	assert_eq(StreetDealCatalog.get_all().size(), 6)
	assert_eq(AIProfileCatalog.get_all().size(), 6)
	assert_eq(TurfLevelCatalog.get_all().size(), 11)


func _resource_paths() -> Array[String]:
	var result: Array[String] = []
	for domain_path: String in DOMAIN_PATHS:
		var directory: DirAccess = DirAccess.open(domain_path)
		assert_not_null(directory, "Missing Resource directory: %s" % domain_path)
		for file_name: String in directory.get_files():
			if file_name.ends_with(".tres"):
				result.append("%s/%s" % [domain_path, file_name])
	result.sort()
	return result
