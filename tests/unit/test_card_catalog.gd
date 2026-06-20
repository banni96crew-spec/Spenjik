extends GutTest


func test_card_catalog_has_exact_owner_membership() -> void:
	CatalogTestHelper.assert_exact_ids(
		self, CardCatalog.get_all_ids(), GameIds.CARD_IDS
	)
	assert_eq(CardCatalog.get_all().size(), 16)


func test_card_definitions_match_owner_data() -> void:
	var expected: Dictionary = {
		"informant": ["engine", 5, "table"],
		"laundry": ["engine", 8, "table"],
		"accountant": ["engine", 4, "table"],
		"brothel": ["engine", 6, "table"],
		"stash": ["status", 8, "table"],
		"workshop": ["status", 12, "table"],
		"district_control": ["status", 15, "table"],
		"cops": ["defense", 2, "table"],
		"cartel": ["defense", 6, "table"],
		"judge": ["defense", 3, "table"],
		"thug": ["war", 2, "hand"],
		"bruiser": ["war", 5, "hand"],
		"cleaner": ["war", 9, "hand"],
		"insider": ["war", 3, "hand"],
		"saboteur": ["war", 6, "hand"],
		"federal_raid": ["war", 14, "hand"],
	}
	for card_id: String in GameIds.CARD_IDS:
		var definition: CardDefinition = CardCatalog.get_by_id(card_id)
		assert_not_null(definition)
		assert_eq(
			[definition.type, definition.base_price, definition.destination],
			expected[card_id]
		)
		assert_eq(definition.max_per_player, 0)
		CatalogTestHelper.assert_display_text(
			self, definition.title, definition.effect_summary
		)


func test_unknown_card_id_is_safe_and_access_is_read_only() -> void:
	assert_false(CardCatalog.has_id("unknown_card"))
	assert_null(CardCatalog.get_by_id("unknown_card"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, CardCatalog.get_all, CardCatalog.get_all_ids
	)
