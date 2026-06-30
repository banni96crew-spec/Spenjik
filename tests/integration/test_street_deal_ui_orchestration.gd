extends GutTest

const GAME_SCREEN_SCENE := preload("res://scenes/ui/screens/GameScreen.tscn")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_complete_human_street_deal_advances_to_income_without_contact_offer() -> void:
	var state: Dictionary = _street_deal_state(
		StreetDealIds.BLACK_MARKET_CACHE, 4
	)
	GameStateManager.state = state
	var round_before: int = GameStateManager.get_round()
	var result: Dictionary = GameStateManager.complete_human_street_deal(
		_payload(StreetDealIds.BLACK_MARKET_CACHE, StreetDealOptionIds.OPTION_A)
	)
	assert_true(result["ok"], str(result))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)
	assert_eq(GameStateManager.get_round(), round_before + 1)
	assert_eq(
		GameStateManager.get_state_snapshot()["street_deals"]["used_deal_ids"],
		[StreetDealIds.BLACK_MARKET_CACHE]
	)


func test_complete_human_street_deal_waits_for_inside_contact_offer() -> void:
	var state: Dictionary = _street_deal_state(
		StreetDealIds.INSIDE_CONTACT, 8
	)
	GameStateManager.state = state
	var round_before: int = GameStateManager.get_round()
	var result: Dictionary = GameStateManager.complete_human_street_deal(
		_payload(StreetDealIds.INSIDE_CONTACT, StreetDealOptionIds.OPTION_A)
	)
	assert_true(result["ok"], str(result))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.STREET_DEAL)
	assert_eq(GameStateManager.get_round(), round_before)
	var pending: Dictionary = GameStateManager.get_state_snapshot()["contacts"][
		"pending_offer"
	]
	assert_false(pending.is_empty())
	assert_eq(pending["source"], StreetDealIds.INSIDE_CONTACT)
	var contact_id: String = str(pending["contact_offer_ids"][0])
	var selected: Dictionary = GameStateManager.select_contact({
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": contact_id,
	})
	assert_true(selected["ok"], str(selected))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)
	assert_eq(GameStateManager.get_round(), round_before + 1)
	assert_eq(
		GameStateManager.get_state_snapshot()["contacts"]["pending_offer"],
		{}
	)


func test_select_street_deal_keeps_replay_two_step_semantics() -> void:
	var state: Dictionary = _street_deal_state(
		StreetDealIds.BLACK_MARKET_CACHE, 4
	)
	GameStateManager.state = state
	var round_before: int = GameStateManager.get_round()
	var selected: Dictionary = GameStateManager.select_street_deal(
		_payload(StreetDealIds.BLACK_MARKET_CACHE, StreetDealOptionIds.OPTION_A)
	)
	assert_true(selected["ok"], str(selected))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.STREET_DEAL)
	assert_eq(GameStateManager.get_round(), round_before)
	var advanced: Dictionary = GameStateManager.advance_phase()
	assert_true(advanced["ok"], str(advanced))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)
	assert_eq(GameStateManager.get_round(), round_before + 1)


func test_game_screen_street_deal_choice_advances_without_dead_end() -> void:
	var state: Dictionary = _street_deal_state(
		StreetDealIds.BLACK_MARKET_CACHE, 4
	)
	GameStateManager.state = state
	var screen: GameScreen = GAME_SCREEN_SCENE.instantiate()
	add_child_autofree(screen)
	screen.refresh()
	assert_true(screen.street_deal_panel.visible)
	assert_false(screen.street_deal_panel.deal_id.is_empty())
	screen.street_deal_panel._choose(StreetDealOptionIds.OPTION_A)
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)
	screen.refresh()
	assert_false(screen.street_deal_panel.visible)
	assert_true(screen.income_button.visible)


func test_street_deal_panel_shows_resolved_message_while_contact_pending() -> void:
	var state: Dictionary = _street_deal_state(
		StreetDealIds.INSIDE_CONTACT, 8
	)
	GameStateManager.state = state
	var selected: Dictionary = GameStateManager.select_street_deal(
		_payload(StreetDealIds.INSIDE_CONTACT, StreetDealOptionIds.OPTION_A)
	)
	assert_true(selected["ok"], str(selected))
	var panel: StreetDealPanel = preload(
		"res://scenes/ui/panels/StreetDealPanel.tscn"
	).instantiate()
	add_child_autofree(panel)
	panel.refresh(GameStateManager.get_view()["view"])
	assert_true(panel.option_a.disabled)
	assert_true(panel.option_b.disabled)
	assert_string_contains(
		panel.description_label.text.to_lower(),
		"street deal resolved"
	)
	assert_string_contains(panel.description_label.text.to_lower(), "contact")


func _street_deal_state(deal_id: String, round_number: int) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		"street_deal_orchestration", round_number
	)
	state["street_deals"]["current_deal_id"] = deal_id
	state["street_deals"]["option_availability"] = {
		StreetDealOptionIds.OPTION_A: ValidationErrors.OK,
		StreetDealOptionIds.OPTION_B: ValidationErrors.OK,
	}
	return state


func _payload(deal_id: String, option_id: String) -> Dictionary:
	return {
		"player_id": GameIds.PLAYER_HUMAN,
		"deal_id": deal_id,
		"option_id": option_id,
	}
