extends GutTest

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")


func test_market_card_title_and_effect_are_visible() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "market_readable",
		"type": CardTypes.ENGINE,
		"title": "Laundry District",
		"base_price": 8,
		"effect_summary": "+2 Nal during Income each round",
		"context": "market",
	})
	assert_true(card.title_label.visible)
	assert_true(card.effect_label.visible)
	assert_false(card.title_label.text.is_empty())
	assert_false(card.effect_label.text.is_empty())
	assert_gte(
		card.title_label.get_theme_font_size("font_size"),
		CardVisualTokens.MARKET_TITLE_FONT
	)
	assert_gte(
		card.effect_label.get_theme_font_size("font_size"),
		CardVisualTokens.MARKET_EFFECT_FONT
	)
	assert_true(card.type_marker_top.visible)
	assert_true(card.price_label.is_visible_in_tree())


func test_compact_card_title_and_effect_are_visible() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "compact_readable",
		"type": CardTypes.STATUS,
		"title": "Stash",
		"effect_summary": "Authority bonus",
		"context": "compact",
		"count": 2,
	})
	assert_true(card.title_label.visible)
	assert_true(card.effect_label.visible)
	assert_false(card.title_label.text.is_empty())
	assert_false(card.effect_label.text.is_empty())
	assert_true(card.type_marker_top.visible)
	assert_true(card.count_badge.visible)


func test_long_market_text_keeps_fixed_card_size() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "market_long",
		"type": CardTypes.WAR,
		"title": "VERY LONG MARKET TITLE THAT SHOULD STAY READABLE",
		"effect_summary": (
			"Long effect summary that wraps inside the fixed market card without "
			+ "changing the card footprint."
		),
		"context": "market",
	})
	assert_eq(card.size, CardVisualTokens.MARKET_CARD_SIZE)
	assert_true(card.title_label.visible)
	assert_true(card.effect_label.visible)


func _card() -> CardView:
	var card: CardView = CARD_SCENE.instantiate()
	add_child_autofree(card)
	return card
