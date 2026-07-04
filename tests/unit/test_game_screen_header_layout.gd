extends GutTest

const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")
const GAME_ROOT := preload("res://scenes/game/GameRoot.tscn")


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


func test_header_does_not_get_overlapped_on_real_buy_phase_transitions() -> void:
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var root: GameRoot = _root(viewport_size)
		assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
		await _settle_layout()
		var screen: GameScreen = root.game_screen
		var header: Dictionary = _header_metrics(screen)
		_assert_workspace_below_header(screen)
		screen.call("_on_advance_income")
		_assert_header_metrics(screen, header)
		_assert_workspace_below_header(screen)
		_assert_market_cards_match_view(screen)
		await _settle_layout()
		screen.market_panel.call("_on_end_market")
		await _settle_layout()
		_assert_table_zones_fit_workspace(screen)
		_assert_board_cards_fit_workspace(screen)
		_assert_action_buttons_fit_workspace(screen)
		screen.action_panel.call("_on_end_action")
		_assert_header_metrics(screen, header)
		_assert_workspace_below_header(screen)
		await _settle_layout()
		screen.call("_on_advance_income")
		_assert_header_metrics(screen, header)
		_assert_workspace_below_header(screen)
		_assert_market_cards_match_view(screen)
		await _settle_layout()
		GameStateManager.reset_game()


func _screen() -> GameScreen:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	host.theme = load("res://themes/main_theme.tres")
	add_child_autofree(host)
	var screen: GameScreen = GAME_SCREEN.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen


func _root(viewport_size: Vector2) -> GameRoot:
	var host := Control.new()
	host.size = viewport_size
	host.theme = load("res://themes/main_theme.tres")
	add_child_autofree(host)
	var root: GameRoot = GAME_ROOT.instantiate()
	host.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return root


func _header_metrics(screen: GameScreen) -> Dictionary:
	var header: Control = screen.get_node("%PhaseHeader")
	return {
		"header_position": header.global_position,
		"header_size": header.size,
		"round_position": screen.round_label.global_position,
		"phase_position": screen.phase_label.global_position,
	}


func _assert_header_metrics(screen: GameScreen, expected: Dictionary) -> void:
	var current: Dictionary = _header_metrics(screen)
	for key: String in expected.keys():
		assert_eq(current[key], expected[key], key)
	assert_true(screen.get_node("%PhaseHeader").visible)
	assert_true(screen.round_label.is_visible_in_tree())
	assert_true(screen.phase_label.is_visible_in_tree())


func _assert_workspace_below_header(screen: GameScreen) -> void:
	var header: Control = screen.get_node("%PhaseHeader")
	var workspace: Control = screen.get_node("%TableWorkspace")
	assert_gte(workspace.global_position.y, header.global_position.y + header.size.y)


func _assert_market_cards_match_view(screen: GameScreen) -> void:
	var result: Dictionary = GameStateManager.get_market_view(GameIds.PLAYER_HUMAN)
	assert_true(result["ok"])
	assert_eq(
		screen.market_panel.cards_row.get_child_count(),
		result["view"]["cards"].size()
	)


func _assert_table_zones_fit_workspace(screen: GameScreen) -> void:
	var workspace: Control = screen.get_node("%TableWorkspace")
	for node_name: String in ["TopOpponentZone", "CenterTable", "HumanZone"]:
		var zone: Control = screen.get_node("%" + node_name)
		assert_gte(zone.global_position.y, workspace.global_position.y, node_name)
		assert_lte(
			zone.global_position.y + zone.size.y,
			workspace.global_position.y + workspace.size.y,
			node_name
		)


func _assert_action_buttons_fit_workspace(screen: GameScreen) -> void:
	var workspace: Control = screen.get_node("%TableWorkspace")
	for node_name: String in [
		"ExecuteButton", "DiscardButton", "CancelButton", "EndButton",
	]:
		var button: Button = screen.action_panel.get_node("%" + node_name)
		assert_true(button.is_visible_in_tree(), node_name)
		assert_gte(button.global_position.y, workspace.global_position.y, node_name)
		assert_lte(
			button.global_position.y + button.size.y,
			workspace.global_position.y + workspace.size.y,
			node_name
		)


func _assert_board_cards_fit_workspace(screen: GameScreen) -> void:
	var workspace: Control = screen.get_node("%TableWorkspace")
	for board: PlayerBoard in [screen.ai_board_2, screen.human_board]:
		var row_parent := board.owned_cards_row.get_parent() as Control
		var details: String = "%s board=%s/%s row_parent=%s/%s" % [
			board.name, str(board.global_position), str(board.size),
			str(row_parent.global_position), str(row_parent.size),
		]
		for child: Node in board.owned_cards_row.get_children():
			var card: Control = child as Control
			assert_not_null(card)
			assert_gte(card.global_position.y, workspace.global_position.y,
				"%s card above workspace" % details)
			assert_lte(
				card.global_position.y + card.size.y,
				workspace.global_position.y + workspace.size.y,
				"%s card below workspace" % details
			)


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
