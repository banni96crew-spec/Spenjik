extends GutTest


func test_contract_catalog_matches_owner_data() -> void:
	CatalogTestHelper.assert_exact_ids(
		self, ContractCatalog.get_all_ids(), ContractIds.ALL
	)
	var expected: Dictionary = {
		"silent_expansion": [8, 2, "vp", 1],
		"bloody_turf_war": [12, 2, "nal", 6],
		"gray_capital": [10, 30, "vp", 1],
		"iron_roof": [9, 3, "nal", 4],
		"district_under_control": [12, 2, "vp", 1],
		"proxy_war": [11, 1, "nal", 5],
		"big_cashbox": [13, 3, "vp", 1],
	}
	for contract_id: String in ContractIds.ALL:
		var definition: ContractDefinition = ContractCatalog.get_by_id(contract_id)
		assert_not_null(definition)
		assert_eq(
			[
				definition.deadline_round,
				definition.progress_required,
				definition.reward_type,
				definition.reward_amount,
			],
			expected[contract_id]
		)
		CatalogTestHelper.assert_display_text(
			self, definition.title, definition.description
		)


func test_unknown_contract_id_is_safe_and_access_is_read_only() -> void:
	assert_null(ContractCatalog.get_by_id("unknown_contract"))
	assert_false(ContractCatalog.has_id("unknown_contract"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, ContractCatalog.get_all, ContractCatalog.get_all_ids
	)
