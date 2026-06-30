extends GutTest

const MARKET_SCENE := preload("res://scenes/ui/panels/MarketPanel.tscn")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_market_panel_cards_share_uniform_size() -> void:
	var state: Dictionary = _market_state_with_cards(6)
	GameStateManager.state = state
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	panel.refresh({})
	var expected := CardVisualTokens.MARKET_CARD_SIZE
	for child: Node in panel.cards_row.get_children():
		var card := child as CardView
		assert_not_null(card)
		assert_eq(card.custom_minimum_size, expected)
		assert_eq(card.size, expected)


func test_market_row_uses_controlled_spacing() -> void:
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	assert_eq(
		panel.cards_row.get_theme_constant("separation"),
		CardVisualTokens.MARKET_ROW_SEPARATION
	)


func test_six_market_cards_fit_center_budget_at_design_viewport() -> void:
	var center_budget: float = UITabletopLayoutTokens.expected_center_column_width(
		UITabletopLayoutTokens.DESIGN_VIEWPORT.x
	)
	var card_width: float = CardVisualTokens.MARKET_CARD_SIZE.x
	var gap: float = float(CardVisualTokens.MARKET_ROW_SEPARATION)
	var visible_slots: int = int(
		floor((center_budget + gap) / (card_width + gap))
	)
	assert_gte(
		visible_slots,
		6,
		"Center budget should fit six market cards before horizontal scroll"
	)


func test_market_card_text_does_not_change_card_size() -> void:
	var state: Dictionary = _market_state_with_cards(1)
	GameStateManager.state = state
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	panel.refresh({})
	var card: CardView = panel.cards_row.get_child(0) as CardView
	assert_not_null(card)
	assert_eq(card.size, CardVisualTokens.MARKET_CARD_SIZE)
	assert_false(card.title_label.text.is_empty())
	assert_false(card.effect_label.text.is_empty())


func test_market_panel_reason_label_shows_selected_card_disabled_reason() -> void:
	var state: Dictionary = TestGameStateFactory.market_state("market_reason", 1)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 0
	state["market"]["always_available_card_ids"] = [GameIds.CARD_LAUNDRY]
	state["market"]["all_available_card_ids"] = [GameIds.CARD_LAUNDRY]
	GameStateManager.state = state
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	panel.refresh({})
	var card: CardView = panel.cards_row.get_child(0) as CardView
	assert_not_null(card)
	assert_false(card.state_label.visible)
	assert_false(card.effect_label.text.is_empty())
	panel._on_card_selected(GameIds.CARD_LAUNDRY)
	assert_string_contains(
		panel.reason_label.text,
		ErrorTextMap.to_text(ValidationErrors.NOT_ENOUGH_NAL)
	)


func test_market_panel_cards_keep_effect_after_refresh_with_selection() -> void:
	var state: Dictionary = _market_state_with_cards(2)
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 0
	GameStateManager.state = state
	var panel: MarketPanel = MARKET_SCENE.instantiate()
	add_child_autofree(panel)
	panel.refresh({})
	panel._on_card_selected(GameIds.CARD_LAUNDRY)
	panel.refresh({})
	var card: CardView = panel.cards_row.get_child(0) as CardView
	assert_not_null(card)
	assert_false(card.effect_label.text.is_empty())
	assert_false(card.state_label.visible)
	assert_string_contains(
		panel.reason_label.text,
		ErrorTextMap.to_text(ValidationErrors.NOT_ENOUGH_NAL)
	)


func _market_state_with_cards(count: int) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state("market_layout", 1)
	var ids: Array[String] = [
		GameIds.CARD_LAUNDRY,
		GameIds.CARD_STASH,
		GameIds.CARD_THUG,
		GameIds.CARD_COPS,
		GameIds.CARD_INFORMANT,
		GameIds.CARD_WORKSHOP,
		GameIds.CARD_ACCOUNTANT,
		GameIds.CARD_BROTHEL,
	]
	var selected: Array[String] = []
	for i: int in range(mini(count, ids.size())):
		selected.append(ids[i])
	state["market"]["always_available_card_ids"] = selected.slice(0, 4)
	state["market"]["all_available_card_ids"] = selected
	return state


func _valid_config() -> Dictionary:
	var seed_value := "market_panel_layout"
	var preview: Dictionary = GameStateManager.generate_contract_offers({
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
	})
	return {
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	}
