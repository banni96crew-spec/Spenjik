extends GutTest

const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")
const THEME := preload("res://themes/main_theme.tres")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_vertical_budget_phase_matrix_at_1080p() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var screen: GameScreen = _screen(Vector2(1920, 1080))
	screen.refresh()
	await _settle_layout()
	_assert_phase_layout(screen, "INCOME")
	assert_true(GameStateManager.advance_phase()["ok"])
	screen.refresh()
	await _settle_layout()
	_assert_phase_layout(screen, "MARKET")
	var top_h: float = screen.top_opponent_zone.size.y
	var human_h: float = screen.human_zone.size.y
	var human: Dictionary = TestPlayers.find(
		GameStateManager.state, GameIds.PLAYER_HUMAN
	)
	human["engine"]["laundries"] = 2
	human["status_buildings"]["stash"] = 1
	screen.refresh()
	await _settle_layout()
	assert_eq(screen.top_opponent_zone.size.y, top_h)
	assert_eq(screen.human_zone.size.y, human_h)
	_assert_phase_layout(screen, "MARKET_REFRESH")
	assert_true(GameStateManager.end_market_for_player(GameIds.PLAYER_HUMAN)["ok"])
	screen.refresh()
	await _settle_layout()
	_assert_phase_layout(screen, "ACTION")
	var roundtrip_top_h: float = screen.top_opponent_zone.size.y
	var roundtrip_human_h: float = screen.human_zone.size.y
	for id: String in [
		GameIds.PLAYER_AI_1, GameIds.PLAYER_AI_2, GameIds.PLAYER_AI_3,
	]:
		_fill_many_unique_displays(GameStateManager.state, id)
	screen.refresh()
	await _settle_layout()
	var ended: Dictionary = GameStateManager.end_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	assert_true(ended["ok"], str(ended))
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.INCOME)
	screen.refresh()
	await _settle_layout()
	assert_true(GameStateManager.advance_phase()["ok"])
	assert_eq(GameStateManager.get_current_phase(), PhaseIds.MARKET)
	screen.refresh()
	await _settle_layout()
	_assert_phase_layout(screen, "MARKET_ROUNDTRIP")
	assert_eq(screen.top_opponent_zone.size.y, roundtrip_top_h)
	assert_eq(screen.human_zone.size.y, roundtrip_human_h)
	for board: PlayerBoard in [
		screen.ai_board_1, screen.ai_board_3,
	]:
		_assert_vertical_strip(board)
	_assert_horizontal_strip(screen.ai_board_2)
	screen.get_parent().queue_free()


func test_vertical_budget_at_720p_market() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	var screen: GameScreen = _screen(Vector2(1280, 720))
	screen.refresh()
	await _settle_layout()
	var header_y: float = screen.round_label.global_position.y
	_assert_low_height_phase_layout(screen, "MARKET_720")
	screen.refresh()
	await _settle_layout()
	assert_eq(screen.round_label.global_position.y, header_y)
	screen.get_parent().queue_free()


func test_vertical_budget_at_720p_action() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	assert_true(GameStateManager.end_market_for_player(GameIds.PLAYER_HUMAN)["ok"])
	var screen: GameScreen = _screen(Vector2(1280, 720))
	screen.refresh()
	await _settle_layout()
	_assert_low_height_phase_layout(screen, "ACTION_720")
	screen.get_parent().queue_free()


func _assert_phase_layout(screen: GameScreen, label: String) -> void:
	var workspace: Control = screen.get_node("%TableWorkspace")
	for zone_name: String in ["TopOpponentZone", "CenterTable", "HumanZone"]:
		var zone: Control = screen.get_node("%" + zone_name)
		_assert_inside(workspace, zone, "%s %s" % [label, zone_name])
	var human_zone: Control = screen.get_node("%HumanZone")
	var board: PlayerBoard = screen.human_board
	if board.compact_layout.visible:
		_assert_inside(human_zone, board.compact_cards_scroll, label)
		_assert_inside(human_zone, board.name_label, label)
	else:
		_assert_inside(human_zone, board.name_label, label)
		_assert_inside(human_zone, board.resources, label)
		_assert_inside(human_zone, board.owned_cards_scroll, label)
		_assert_inside(human_zone, board.state_label, label)
	assert_lte(
		human_zone.global_position.y + human_zone.size.y,
		workspace.global_position.y + workspace.size.y + 0.5,
		label
	)
	assert_eq(
		int(screen.top_opponent_zone.custom_minimum_size.y),
		UITabletopLayoutTokens.NORMAL_BOARD_ZONE_HEIGHT
	)
	assert_eq(
		int(screen.human_zone.custom_minimum_size.y),
		UITabletopLayoutTokens.NORMAL_BOARD_ZONE_HEIGHT
	)


func _assert_low_height_phase_layout(screen: GameScreen, label: String) -> void:
	var workspace: Control = screen.get_node("%TableWorkspace")
	var top_zone: Control = screen.get_node("%TopOpponentZone")
	_assert_inside(workspace, top_zone, "%s TopOpponentZone" % label)
	var human_zone: Control = screen.get_node("%HumanZone")
	var board: PlayerBoard = screen.human_board
	var scroll: Control = (
		board.compact_cards_scroll
		if board.compact_layout.visible else board.owned_cards_scroll
	)
	_assert_inside(human_zone, scroll, label)
	assert_true(scroll.is_visible_in_tree())
	assert_eq(int(screen.top_opponent_zone.custom_minimum_size.y), 176)
	assert_eq(int(screen.human_zone.custom_minimum_size.y), 176)


func _screen(viewport_size: Vector2) -> GameScreen:
	var host := Control.new()
	host.size = viewport_size
	host.theme = THEME
	add_child_autofree(host)
	var screen: GameScreen = GAME_SCREEN.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen


func _assert_inside(parent: Control, child: Control, label: String) -> void:
	var parent_rect := Rect2(parent.global_position, parent.size)
	var child_rect := Rect2(child.global_position, child.size)
	assert_true(parent_rect.encloses(child_rect), "%s outside %s" % [label, parent.name])


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _assert_horizontal_strip(board: PlayerBoard) -> void:
	assert_eq(
		board.owned_cards_scroll.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_AUTO
	)
	assert_eq(
		board.owned_cards_scroll.vertical_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	assert_true(board.owned_cards_row is HBoxContainer)
	assert_gt(board.owned_cards_row.get_child_count(), 8)
	assert_gt(board.owned_cards_row.size.x, board.owned_cards_scroll.size.x)
	var row_y: float = NAN
	for child: Node in board.owned_cards_row.get_children():
		var wrapper := child as Control
		assert_not_null(wrapper)
		assert_lte(wrapper.size.y, board.owned_cards_scroll.size.y + 0.5)
		if is_nan(row_y):
			row_y = wrapper.global_position.y
		else:
			assert_almost_eq(wrapper.global_position.y, row_y, 0.5)


func _assert_vertical_strip(board: PlayerBoard) -> void:
	assert_eq(
		board.owned_cards_scroll.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	assert_eq(
		board.owned_cards_scroll.vertical_scroll_mode,
		ScrollContainer.SCROLL_MODE_AUTO
	)
	assert_true(board.owned_cards_row is VBoxContainer)
	assert_gt(board.owned_cards_row.get_child_count(), 8)
	assert_gt(board.owned_cards_row.size.y, board.owned_cards_scroll.size.y)
	var row_x: float = NAN
	for child: Node in board.owned_cards_row.get_children():
		var wrapper := child as Control
		assert_not_null(wrapper)
		assert_lte(wrapper.size.x, board.owned_cards_scroll.size.x + 0.5)
		if is_nan(row_x):
			row_x = wrapper.global_position.x
		else:
			assert_almost_eq(wrapper.global_position.x, row_x, 0.5)


func _fill_many_unique_displays(state: Dictionary, player_id: String) -> void:
	var player: Dictionary = TestPlayers.find(state, player_id)
	for key: String in ["informers", "laundries", "accountants"]:
		player["engine"][key] = 1
	player["engine"]["brothel"] = true
	for key: String in ["stash", "workshop", "district_control"]:
		player["status_buildings"][key] = 1
	player["defense"]["cops_active"] = true
	player["defense"]["cartel_state"] = DefenseStates.ACTIVE
	player["defense"]["judge_state"] = DefenseStates.ACTIVE
	player["hand"] = [
		GameIds.CARD_THUG, GameIds.CARD_BRUISER, GameIds.CARD_CLEANER,
		GameIds.CARD_FEDERAL_RAID, GameIds.CARD_SABOTEUR, GameIds.CARD_INSIDER,
	]


func _valid_config() -> Dictionary:
	var seed_value := "vertical_budget"
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
