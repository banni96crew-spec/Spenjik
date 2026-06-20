extends GutTest


func test_role_catalog_matches_owner_data() -> void:
	CatalogTestHelper.assert_exact_ids(
		self, RoleCatalog.get_all_ids(), RoleIds.ALL
	)
	var starting_nal: Dictionary = {
		"merchant": 7,
		"enforcer": 5,
		"gray_cardinal": 4,
		"district_boss": 5,
	}
	for role_id: String in RoleIds.ALL:
		var definition: RoleDefinition = RoleCatalog.get_by_id(role_id)
		assert_not_null(definition)
		assert_eq(definition.starting_nal, starting_nal[role_id])
		CatalogTestHelper.assert_display_text(
			self, definition.title, definition.effect_summary
		)
		assert_false(definition.limitation_summary.is_empty())


func test_unknown_role_id_is_safe_and_access_is_read_only() -> void:
	assert_null(RoleCatalog.get_by_id("unknown_role"))
	assert_false(RoleCatalog.has_id("unknown_role"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, RoleCatalog.get_all, RoleCatalog.get_all_ids
	)
