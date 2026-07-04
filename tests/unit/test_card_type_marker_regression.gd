extends GutTest

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")


func test_type_markers_use_centered_square_draw_area() -> void:
	var marker := CardTypeMarker.new()
	add_child_autofree(marker)
	for rect: Rect2 in [
		Rect2(Vector2.ZERO, Vector2(28, 18)),
		Rect2(Vector2.ZERO, Vector2(18, 28)),
	]:
		var square: Rect2 = marker._square_area(rect)
		assert_eq(square.size.x, square.size.y)
		assert_eq(square.position, (rect.size - square.size) * 0.5)


func test_type_markers_are_visible_in_all_card_contexts() -> void:
	for context: String in ["market", "owned", "compact"]:
		var card: CardView = CARD_SCENE.instantiate()
		add_child_autofree(card)
		card.set_card({
			"id": "marker_%s" % context,
			"type": CardTypes.DEFENSE,
			"title": "Marker",
			"effect_summary": "Presentation",
			"context": context,
		})
		assert_true(card.type_marker_top.visible, context)
		assert_eq(card.type_marker_top.custom_minimum_size,
			CardTypeMarker.MARKER_SIZE)


func test_war_marker_uses_ink_accent_and_war_border() -> void:
	var card: CardView = CARD_SCENE.instantiate()
	add_child_autofree(card)
	card.set_card({
		"id": GameIds.CARD_THUG,
		"type": CardTypes.WAR,
		"title": "Thug",
		"effect_summary": "Attack",
	})
	assert_eq(card.type_marker_top.marker_color, CardVisualTokens.INK)
	assert_eq(
		CardTypeStyleMap.style_for_type(CardTypes.WAR).get("border"),
		CardVisualTokens.WAR_BORDER
	)
