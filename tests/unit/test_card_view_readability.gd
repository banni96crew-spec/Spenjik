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
	var text_block := card.title_label.get_parent() as Control
	assert_gt(text_block.custom_minimum_size.y, 0.0)
	assert_eq(card.title_label.max_lines_visible, -1)
	assert_eq(card.effect_label.max_lines_visible, -1)
	assert_eq(
		card.title_label.text_overrun_behavior,
		TextServer.OVERRUN_NO_TRIMMING
	)
	assert_eq(
		card.effect_label.text_overrun_behavior,
		TextServer.OVERRUN_NO_TRIMMING
	)
	assert_gte(
		card.title_label.get_theme_font_size("font_size"),
		CardVisualTokens.MARKET_TITLE_FONT
	)
	assert_gte(
		card.effect_label.get_theme_font_size("font_size"),
		CardVisualTokens.MARKET_EFFECT_FONT
	)
	assert_true(card.type_marker_top.visible)
	assert_null(card.get_node_or_null("%TypeMarkerBottom"))
	assert_true(card.price_label.is_visible_in_tree())
	assert_true(card.art_placeholder.visible)


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


func test_owned_card_uses_market_size_with_title_and_effect() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "owned_readable",
		"type": CardTypes.WAR,
		"title": "Bruiser",
		"effect_summary": "Steal Nal or destroy Stash",
		"context": "owned",
		"count": 2,
	})
	assert_eq(card.get_layout_size(), CardVisualTokens.MARKET_CARD_SIZE)
	assert_eq(card.size, CardVisualTokens.MARKET_CARD_SIZE)
	assert_false(card.title_label.text.is_empty())
	assert_false(card.effect_label.text.is_empty())
	assert_true(card.count_badge.visible)
	assert_false(card.select_button.visible)
	assert_false(card.price_label.is_visible_in_tree())


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


func test_market_effect_stays_visible_when_disabled() -> void:
	var effect_text := "Steals up to 6 Nal"
	for reason: String in [
		ValidationErrors.NOT_ENOUGH_NAL,
		ValidationErrors.CARD_ALREADY_PURCHASED_THIS_ROUND,
		ValidationErrors.CARD_LIMIT_REACHED,
	]:
		var card: CardView = _card()
		card.set_card({
			"id": "disabled_%s" % reason,
			"type": CardTypes.WAR,
			"title": "Thug",
			"effect_summary": effect_text,
			"affordable": false,
			"disabled": true,
			"disabled_reason": reason,
			"context": "market",
		})
		assert_eq(card.effect_label.text, effect_text)
		assert_true(card.effect_label.visible)
		assert_false(card.state_label.visible)


func test_market_art_frame_covers_full_card() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "market_art",
		"type": CardTypes.ENGINE,
		"title": "Workshop",
		"effect_summary": "+1 Nal during Income",
		"context": "market",
	})
	assert_eq(
		card._art_frame.custom_minimum_size,
		CardVisualTokens.MARKET_CARD_SIZE
	)
	assert_eq(CardVisualTokens.MARKET_ART_HEIGHT, int(CardVisualTokens.MARKET_CARD_SIZE.y))
	assert_true(card.art_placeholder.visible)


func _card() -> CardView:
	var card: CardView = CARD_SCENE.instantiate()
	add_child_autofree(card)
	return card
