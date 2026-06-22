extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_setup_screen_starts_game_through_facade() -> void:
	var screen: SetupScreen = _add_scene(
		"res://scenes/ui/screens/SetupScreen.tscn"
	)
	if screen == null:
		return
	screen.seed_input.text = "ui_setup_signal"
	screen.selected_turf_level = TurfLevelIds.BASE
	screen.selected_role_id = RoleIds.MERCHANT
	screen.call("_on_generate_offers")
	assert_gt(screen.contract_options.item_count, 1)
	screen.contract_options.select(1)
	screen.call("_on_contract_selected", 1)
	screen.call("_on_start")
	assert_true(GameStateManager.has_active_game())
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)


func test_setup_input_change_invalidates_generated_contract_offer() -> void:
	var screen: SetupScreen = _add_scene(
		"res://scenes/ui/screens/SetupScreen.tscn"
	)
	if screen == null:
		return
	screen.seed_input.text = "ui_stale_offer"
	screen.selected_turf_level = TurfLevelIds.BASE
	screen.selected_role_id = RoleIds.MERCHANT
	screen.call("_on_generate_offers")
	assert_gt(screen.contract_options.item_count, 1)
	screen.contract_options.select(1)
	screen.call("_on_contract_selected", 1)
	assert_false(screen.selected_contract_id.is_empty())
	assert_false(screen.start_button.disabled)
	screen.seed_input.text = "ui_stale_offer_changed"
	screen.seed_input.text_changed.emit(screen.seed_input.text)
	assert_eq(screen.selected_contract_id, "")
	assert_eq(screen.contract_options.item_count, 1)
	assert_eq(
		screen.contract_options.get_item_text(0),
		"Generate contract offers"
	)
	assert_true(screen.start_button.disabled)


func test_game_root_switches_and_displays_failed_action() -> void:
	var root: GameRoot = _add_scene("res://scenes/game/GameRoot.tscn")
	if root == null:
		return
	assert_true(root.setup_screen.visible)
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(root.game_screen.visible)
	assert_false(root.setup_screen.visible)
	var failure: Dictionary = GameStateManager.buy_card(
		GameIds.PLAYER_HUMAN, GameIds.CARD_STASH
	)
	assert_false(failure["ok"])
	assert_true(root.game_screen.error_label.visible)
	assert_false(root.game_screen.error_label.text.is_empty())


func test_phase_change_refreshes_visible_panel_and_clears_selection() -> void:
	var root: GameRoot = _add_scene("res://scenes/game/GameRoot.tscn")
	if root == null:
		return
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	root.game_screen.action_panel.selected_card_id = GameIds.CARD_THUG
	assert_true(GameStateManager.advance_phase()["ok"])
	assert_true(root.game_screen.market_panel.visible)
	assert_false(root.game_screen.action_panel.visible)
	assert_eq(root.game_screen.action_panel.selected_card_id, "")


func test_human_end_buttons_complete_ai_phase_through_one_facade_call() -> void:
	var root: GameRoot = _add_scene("res://scenes/game/GameRoot.tscn")
	if root == null:
		return
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	root.game_screen.market_panel.call("_on_end_market")
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.ACTION)
	root.game_screen.action_panel.call("_on_end_action")
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)


func _add_scene(path: String) -> Variant:
	var packed: PackedScene = load(path)
	assert_not_null(packed, path)
	if packed == null:
		return null
	var instance: Node = packed.instantiate()
	add_child_autofree(instance)
	return instance


func _valid_config() -> Dictionary:
	var seed_value := "ui_signal_game"
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
