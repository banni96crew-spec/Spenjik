extends GutTest


func test_turf_level_catalog_contains_zero_through_ten() -> void:
	var expected_ids: Array[String] = []
	for level: int in TurfLevelIds.ALL:
		expected_ids.append(str(level))
	CatalogTestHelper.assert_exact_ids(
		self, TurfLevelCatalog.get_all_ids(), expected_ids
	)
	for level: int in TurfLevelIds.ALL:
		var definition: TurfLevelDefinition = TurfLevelCatalog.get_by_level(level)
		assert_not_null(definition)
		assert_eq(definition.level, level)
		CatalogTestHelper.assert_display_text(
			self, definition.title, definition.effect_summary
		)


func test_turf_level_summaries_match_owner_data() -> void:
	var summaries: Array[String] = [
		"No Turf Level modifier.",
		"All AI start with +1 Nal.",
		"Strong AI starts with +1 VP.",
		"Human gets -1 starting Nal after role, minimum 3.",
		"Rotating market contains 3 cards instead of 4.",
		"Human Cops upkeep interval is every 2 Income phases instead of 3.",
		"First War card bought by each AI each round costs 1 less.",
		"After victory over strong AI, player chooses contact from 2 options instead of 3.",
		"All direct upfront human Street Deal payments increase by +1.",
		"If human leads in VP, AI get +20% to War purchase weight.",
		"At equal VP, victory goes to AI if an AI is among the leaders.",
	]
	for level: int in TurfLevelIds.ALL:
		assert_eq(
			TurfLevelCatalog.get_by_level(level).effect_summary,
			summaries[level]
		)


func test_unknown_turf_level_is_safe_and_access_is_read_only() -> void:
	assert_null(TurfLevelCatalog.get_by_level(-1))
	assert_null(TurfLevelCatalog.get_by_level(11))
	assert_null(TurfLevelCatalog.get_by_id("unknown_level"))
	assert_false(TurfLevelCatalog.has_id("11"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, TurfLevelCatalog.get_all, TurfLevelCatalog.get_all_ids
	)
