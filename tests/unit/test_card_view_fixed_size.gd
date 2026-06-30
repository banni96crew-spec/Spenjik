extends GutTest

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const MARKET_SCENE := preload("res://scenes/ui/panels/MarketPanel.tscn")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_card_view_keeps_fixed_market_size_for_all_card_types() -> void:
	var expected := CardVisualTokens.MARKET_CARD_SIZE
	for card_type: String in CardTypes.ALL:
		var card: CardView = _card()
		card.set_card(_card_dict(card_type, "Title", 5, "Effect text"))
		assert_eq(card.custom_minimum_size, expected)
		assert_eq(card.size, expected)
		assert_eq(card.get_layout_size(), expected)


func test_long_title_and_effect_do_not_change_card_size() -> void:
	var expected := CardVisualTokens.MARKET_CARD_SIZE
	var long_title := "VERY LONG TITLE THAT SHOULD WRAP INSIDE THE CARD WITHOUT RESIZING"
	var long_effect := (
		"Gain many resources and trigger a very long rules summary that must stay inside "
		+ "the fixed card frame for every market card in the row."
	)
	for card_type: String in CardTypes.ALL:
		var card: CardView = _card()
		card.set_card({
			"id": "%s_long" % card_type,
			"type": card_type,
			"title": long_title,
			"base_price": 9,
			"effect_summary": long_effect,
		})
		assert_eq(card.custom_minimum_size, expected)
		assert_eq(card.size, expected)


func test_market_panel_cards_use_identical_sizes() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("market_card_sizes", 1)
	state["market"]["always_available_card_ids"] = [
		GameIds.CARD_LAUNDRY,
		GameIds.CARD_STASH,
		GameIds.CARD_THUG,
		GameIds.CARD_COPS,
	]
	state["market"]["all_available_card_ids"] = (
		state["market"]["always_available_card_ids"].duplicate()
	)
	GameStateManager.state = state
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	panel.refresh({})
	assert_eq(panel.cards_row.get_child_count(), 4)
	var expected := CardVisualTokens.MARKET_CARD_SIZE
	for child: Node in panel.cards_row.get_children():
		var card := child as CardView
		assert_not_null(card)
		assert_eq(card.custom_minimum_size, expected)
		assert_eq(card.size, expected)


func test_card_view_fits_supported_viewports_with_fixed_size() -> void:
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var host := Control.new()
		host.size = viewport_size
		add_child_autofree(host)
		var card: CardView = CARD_SCENE.instantiate()
		host.add_child(card)
		card.set_card(_card_dict(CardTypes.ENGINE, "Viewport", 8, "Readable"))
		assert_true(card.is_visible_in_tree())
		assert_eq(card.custom_minimum_size, CardVisualTokens.MARKET_CARD_SIZE)
		assert_eq(card.size, CardVisualTokens.MARKET_CARD_SIZE)


func _card() -> CardView:
	var card: CardView = CARD_SCENE.instantiate()
	add_child_autofree(card)
	return card


func _card_dict(
	card_type: String, title: String, base_price: int, effect_summary: String
) -> Dictionary:
	return {
		"id": "%s_card" % card_type,
		"type": card_type,
		"title": title,
		"base_price": base_price,
		"effect_summary": effect_summary,
	}
