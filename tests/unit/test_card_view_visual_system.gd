extends GutTest

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const MARKET_SCENE := preload("res://scenes/ui/panels/MarketPanel.tscn")
const FORBIDDEN_CARD_ID_WORDS: Array[String] = [
	"laundry", "stash", "thug", "cops",
]


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_card_view_scene_instantiates() -> void:
	var card: CardView = CARD_SCENE.instantiate()
	add_child_autofree(card)
	assert_not_null(card)
	assert_not_null(card.get_node_or_null("%PriceLabel"))
	assert_not_null(card.get_node_or_null("%TypeMarkerTop"))
	assert_not_null(card.get_node_or_null("%TypeMarkerBottom"))
	assert_not_null(card.get_node_or_null("%ArtPlaceholder"))
	assert_not_null(card.get_node_or_null("%TitleLabel"))
	assert_not_null(card.get_node_or_null("%EffectLabel"))
	assert_not_null(card.get_node_or_null("%BasePriceLabel"))
	assert_not_null(card.get_node_or_null("%StateLabel"))
	assert_not_null(card.get_node_or_null("%SelectButton"))


func test_card_view_accepts_all_card_type_display_dictionaries() -> void:
	var samples: Dictionary = {
		CardTypes.ENGINE: _card_dict(CardTypes.ENGINE, "Engine Card", 8, "Income bonus"),
		CardTypes.STATUS: _card_dict(CardTypes.STATUS, "Status Card", 5, "Authority bonus"),
		CardTypes.WAR: _card_dict(CardTypes.WAR, "War Card", 3, "Attack effect"),
		CardTypes.DEFENSE: _card_dict(CardTypes.DEFENSE, "Defense Card", 4, "Block effect"),
	}
	for card_type: String in CardTypes.ALL:
		var card: CardView = _card()
		card.set_card(samples[card_type])
		assert_eq(card.type_marker_top.text, CardTypeStyleMap.marker_for_type(card_type))
		assert_eq(card.type_marker_bottom.text, CardTypeStyleMap.marker_for_type(card_type))
		assert_eq(card.title_label.text, samples[card_type]["title"].to_upper())
		assert_eq(card.effect_label.text, samples[card_type]["effect_summary"])


func test_type_markers_are_distinct_and_reserved() -> void:
	var markers: Array[String] = []
	for card_type: String in CardTypes.ALL:
		var marker: String = CardTypeStyleMap.marker_for_type(card_type)
		assert_false(markers.has(marker), "Duplicate marker: %s" % marker)
		markers.append(marker)
	assert_eq(CardTypeStyleMap.marker_for_type(CardTypes.ENGINE), CardTypeStyleMap.MARKER_GEAR)
	assert_eq(CardTypeStyleMap.marker_for_type(CardTypes.STATUS), CardTypeStyleMap.MARKER_CROWN)
	assert_true(
		CardTypeStyleMap.marker_for_type(CardTypes.WAR) in [
			CardTypeStyleMap.MARKER_WAR, CardTypeStyleMap.MARKER_WAR_FALLBACK,
		]
	)
	assert_eq(CardTypeStyleMap.marker_for_type(CardTypes.DEFENSE), CardTypeStyleMap.MARKER_SHIELD)
	assert_ne(
		CardTypeStyleMap.marker_for_type(CardTypes.WAR),
		CardTypeStyleMap.marker_for_type(CardTypes.ENGINE)
	)
	assert_ne(
		CardTypeStyleMap.marker_for_type(CardTypes.WAR),
		CardTypeStyleMap.marker_for_type(CardTypes.DEFENSE)
	)


func test_missing_optional_fields_do_not_crash() -> void:
	var card: CardView = _card()
	card.set_card({"id": "minimal", "type": CardTypes.ENGINE})
	assert_eq(card.price_label.text, "0")
	assert_eq(card.title_label.text, "MINIMAL")
	assert_eq(card.effect_label.text, "")
	assert_false(card.base_price_label.visible)


func test_price_and_final_price_display_with_secondary_base_price() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "priced",
		"type": CardTypes.ENGINE,
		"title": "Priced",
		"base_price": 8,
		"price": 10,
		"effect_summary": "Scaled",
	})
	assert_eq(card.price_label.text, "10")
	assert_true(card.base_price_label.visible)
	assert_string_contains(card.base_price_label.text, "8")


func test_final_price_field_is_accepted() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "final",
		"type": CardTypes.STATUS,
		"final_price": 7,
		"base_price": 5,
	})
	assert_eq(card.price_label.text, "7")


func test_selected_disabled_and_affordable_states_use_supplied_data() -> void:
	var card: CardView = _card()
	card.set_card({
		"id": "stateful",
		"type": CardTypes.WAR,
		"price": 3,
		"affordable": false,
		"disabled": true,
		"disabled_reason": ValidationErrors.NOT_ENOUGH_NAL,
		"selected": true,
	})
	assert_true(card.selected)
	assert_eq(card.select_button.text, "SELECTED")
	assert_true(card.state_label.visible)
	assert_string_contains(
		card.state_label.text,
		ErrorTextMap.to_text(ValidationErrors.NOT_ENOUGH_NAL)
	)
	assert_eq(
		card.price_label.get_theme_color("font_color"),
		CardVisualTokens.UNAVAILABLE_PRICE
	)


func test_hover_and_selection_do_not_emit_gameplay_signals() -> void:
	var card: CardView = _card()
	card.set_card(_card_dict(CardTypes.DEFENSE, "Guard", 4, "Blocks"))
	watch_signals(card)
	card.set_selected(true)
	card.set_selected(false)
	card._on_mouse_entered()
	card._on_mouse_exited()
	assert_signal_not_emitted(card, "card_selected")


func test_card_view_source_has_no_individual_card_id_special_cases() -> void:
	var source: String = FileAccess.get_file_as_string(
		"res://scenes/ui/widgets/CardView.gd"
	)
	for word: String in FORBIDDEN_CARD_ID_WORDS:
		var expression := RegEx.new()
		assert_eq(expression.compile("\\b%s\\b" % word), OK)
		assert_null(
			expression.search(source),
			"CardView must not hardcode card ID word: %s" % word
		)
	assert_false(source.contains("GameStateManager"))
	assert_false(source.contains("PriceLogic"))
	assert_false(source.contains("MarketLogic"))


func test_card_view_fits_supported_viewports() -> void:
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var host := Control.new()
		host.size = viewport_size
		add_child_autofree(host)
		var card: CardView = CARD_SCENE.instantiate()
		host.add_child(card)
		card.set_card(_card_dict(CardTypes.ENGINE, "Viewport", 8, "Readable"))
		assert_true(card.is_visible_in_tree())
		assert_true(card.price_label.is_visible_in_tree())
		assert_true(card.title_label.is_visible_in_tree())
		assert_true(card.effect_label.is_visible_in_tree())
		assert_lte(card.custom_minimum_size.x, 220.0)
		assert_lte(card.custom_minimum_size.y, 280.0)


func test_market_panel_shows_scaled_final_price_on_card() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("scaled_price_ui", 1)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["engine"]["laundries"] = 1
	human["nal"] = 50
	state["market"]["always_available_card_ids"] = [GameIds.CARD_LAUNDRY]
	state["market"]["all_available_card_ids"] = [GameIds.CARD_LAUNDRY]
	GameStateManager.state = state
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	panel.refresh({})
	assert_eq(panel.cards_row.get_child_count(), 1)
	var card: CardView = panel.cards_row.get_child(0) as CardView
	assert_not_null(card)
	assert_eq(card.card_id, GameIds.CARD_LAUNDRY)
	var preview: Dictionary = GameStateManager.get_card_price_preview(
		GameIds.PLAYER_HUMAN, GameIds.CARD_LAUNDRY
	)
	assert_true(preview["ok"], str(preview))
	assert_eq(card.price_label.text, str(int(preview["final_price"])))
	assert_ne(int(preview["final_price"]), int(preview["base_price"]))
	assert_true(card.base_price_label.visible)
	assert_string_contains(card.base_price_label.text, str(int(preview["base_price"])))


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
