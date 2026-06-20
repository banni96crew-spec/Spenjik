extends GutTest

const EFFECT_KEYS: Array[String] = [
	"type", "target", "amount", "card_id", "card_type",
	"modifier_type", "delta", "minimum", "debt_amount_due",
	"deadline_round_delta", "penalty", "contact_offer_count",
]
const TARGETS: Array[String] = ["human", "random_ai", "richest_ai"]


func test_street_deal_catalog_matches_owner_membership() -> void:
	CatalogTestHelper.assert_exact_ids(
		self, StreetDealCatalog.get_all_ids(), StreetDealIds.ALL
	)
	var minimum_rounds: Dictionary = {
		"loan_shark": 8,
		"dirty_tip": 4,
		"cheap_protection": 4,
		"black_market_cache": 4,
		"inside_contact": 8,
		"risky_contract": 12,
	}
	for deal_id: String in StreetDealIds.ALL:
		var definition: StreetDealDefinition = StreetDealCatalog.get_by_id(deal_id)
		assert_not_null(definition)
		assert_eq(definition.min_round, minimum_rounds[deal_id])
		assert_eq(definition.weight, 100)
		assert_eq(definition.max_uses_per_run, 1)
		_assert_option(definition.option_a_label, definition.option_a_description,
			definition.option_a_effects)
		_assert_option(definition.option_b_label, definition.option_b_description,
			definition.option_b_effects)


func test_unknown_deal_id_is_safe_and_access_is_read_only() -> void:
	assert_null(StreetDealCatalog.get_by_id("unknown_deal"))
	assert_false(StreetDealCatalog.has_id("unknown_deal"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, StreetDealCatalog.get_all, StreetDealCatalog.get_all_ids
	)


func test_street_deal_effect_values_match_oq_004() -> void:
	var loan: StreetDealDefinition = StreetDealCatalog.get_by_id("loan_shark")
	assert_eq(loan.option_a_effects[0]["amount"], 10)
	assert_eq(loan.option_a_effects[1]["debt_amount_due"], 12)
	assert_eq(loan.option_a_effects[1]["penalty"],
		{"lose_all_nal": true, "vp_delta": -1})
	assert_eq(loan.option_b_effects[0]["amount"], 5)
	assert_eq(loan.option_b_effects[1]["debt_amount_due"], 6)
	var tip: StreetDealDefinition = StreetDealCatalog.get_by_id("dirty_tip")
	assert_eq(tip.option_a_effects[1]["card_id"], "bruiser")
	assert_eq(tip.option_b_effects[1]["target"], "random_ai")
	assert_eq(tip.option_b_effects[1]["card_id"], "thug")
	var protection: StreetDealDefinition = StreetDealCatalog.get_by_id(
		"cheap_protection"
	)
	assert_eq(protection.option_a_effects[0]["modifier_type"],
		"next_defense_card_price_delta")
	assert_eq(protection.option_a_effects[0]["delta"], -2)
	assert_eq(protection.option_a_effects[0]["minimum"], 1)
	assert_eq(protection.option_b_effects[1]["modifier_type"],
		"next_war_card_price_delta")
	assert_eq(protection.option_b_effects[1]["delta"], 1)
	var cache: StreetDealDefinition = StreetDealCatalog.get_by_id(
		"black_market_cache"
	)
	assert_eq(cache.option_a_effects[0]["amount"], 6)
	assert_eq(cache.option_b_effects[0]["amount"], 6)
	assert_eq(cache.option_b_effects[1]["amount"], 1)
	var contact: StreetDealDefinition = StreetDealCatalog.get_by_id(
		"inside_contact"
	)
	assert_eq(contact.option_a_effects[0]["contact_offer_count"], 2)
	assert_eq(contact.option_b_effects[0]["amount"], 4)
	var risky: StreetDealDefinition = StreetDealCatalog.get_by_id("risky_contract")
	assert_eq(risky.option_a_effects[0]["amount"], 3)
	assert_eq(risky.option_a_effects[1]["amount"], 1)
	assert_eq(risky.option_b_effects[0]["amount"], 5)
	assert_eq(risky.option_b_effects[1]["target"], "richest_ai")
	assert_eq(risky.option_b_effects[1]["amount"], 1)


func _assert_option(
	label: String,
	description: String,
	effects: Array[Dictionary]
) -> void:
	CatalogTestHelper.assert_display_text(self, label, description)
	assert_false(effects.is_empty())
	for effect: Dictionary in effects:
		var keys: Array[String] = []
		keys.assign(effect.keys())
		keys.sort()
		var expected_keys: Array[String] = EFFECT_KEYS.duplicate()
		expected_keys.sort()
		assert_eq(keys, expected_keys)
		assert_has(EffectTypes.ALL, effect["type"])
		assert_has(TARGETS, effect["target"])
