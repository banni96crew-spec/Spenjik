extends GutTest

const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_header_round_and_phase_positions_stay_fixed_between_market_and_action() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	var screen: GameScreen = _screen()
	screen.refresh()
	await _settle_layout()
	var market_round_x: float = screen.round_label.global_position.x
	var market_phase_x: float = screen.phase_label.global_position.x
	var market_header_x: float = screen.get_node("%PhaseHeader").global_position.x
	var market_height: float = screen.get_node("%PhaseHeader").size.y
	assert_lte(market_height, 36.0)
	assert_eq(
		screen.round_label.get_theme_font_size("font_size"),
		CardVisualTokens.HEADER_FONT
	)
	assert_eq(
		screen.phase_label.get_theme_font_size("font_size"),
		CardVisualTokens.HEADER_FONT
	)
	assert_true(GameStateManager.end_market_for_player(GameIds.PLAYER_HUMAN)["ok"])
	screen.refresh()
	await _settle_layout()
	assert_eq(screen.round_label.global_position.x, market_round_x)
	assert_eq(screen.phase_label.global_position.x, market_phase_x)
	assert_eq(screen.get_node("%PhaseHeader").global_position.x, market_header_x)
	assert_eq(screen.get_node("%PhaseHeader").size.y, market_height)


func test_busy_error_and_long_active_text_do_not_move_round_or_phase() -> void:
	GameStateManager.state = TestGameStateFactory.action_state("header_busy", 1)
	var screen: GameScreen = _screen()
	screen.refresh()
	await _settle_layout()
	var round_x: float = screen.round_label.global_position.x
	var phase_x: float = screen.phase_label.global_position.x
	screen.active_label.text = (
		"ACTIVE: A VERY LONG PLAYER STATUS THAT MUST STAY INSIDE ITS SLOT"
	)
	screen.busy_label.visible = true
	screen.show_error(ValidationErrors.REQUIREMENT_NOT_MET)
	await _settle_layout()
	assert_eq(screen.round_label.global_position.x, round_x)
	assert_eq(screen.phase_label.global_position.x, phase_x)


func _screen() -> GameScreen:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child_autofree(host)
	var screen: GameScreen = GAME_SCREEN.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _valid_config() -> Dictionary:
	var seed_value := "header_layout"
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
