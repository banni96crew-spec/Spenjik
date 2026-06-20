extends GutTest


func test_contact_catalog_matches_oq_005() -> void:
	CatalogTestHelper.assert_exact_ids(
		self, ContactCatalog.get_all_ids(), ContactIds.ALL
	)
	var expected: Dictionary = {
		"black_cash": ["Black Cash",
			"Brothel double bonus gives +6 Nal instead of +5.",
			"passive", "brothel_double_bonus_plus_one"],
		"corrupt_clerk": ["Corrupt Clerk",
			"First Status card after receiving this contact is cheaper by 1.",
			"passive", "first_status_card_discount"],
		"street_medic": ["Street Medic",
			"Once per game prevents loss of 1 VP from a debt penalty.",
			"active", "prevent_debt_vp_loss_once"],
	}
	for contact_id: String in ContactIds.ALL:
		var definition: ContactDefinition = ContactCatalog.get_by_id(contact_id)
		assert_not_null(definition)
		assert_eq(
			[
				definition.title,
				definition.description,
				definition.effect_kind,
				definition.effect_type,
			],
			expected[contact_id]
		)
		assert_eq(definition.cooldown_rounds, 0)
		CatalogTestHelper.assert_display_text(
			self, definition.title, definition.description
		)


func test_unknown_contact_id_is_safe_and_access_is_read_only() -> void:
	assert_null(ContactCatalog.get_by_id("unknown_contact"))
	assert_false(ContactCatalog.has_id("unknown_contact"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, ContactCatalog.get_all, ContactCatalog.get_all_ids
	)
