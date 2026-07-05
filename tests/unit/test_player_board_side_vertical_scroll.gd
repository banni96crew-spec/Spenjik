extends GutTest

const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const WRAPPER := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")
const MEASURE := preload("res://tests/fixtures/GameScreenLayoutMeasure.gd")
const THEME := preload("res://themes/main_theme.tres")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_side_left_dense_vertical_topology_and_scroll() -> void:
	_assert_side_dense_vertical(WRAPPER.ORIENTATION_SIDE_LEFT, GameIds.PLAYER_AI_1)


func test_side_right_dense_vertical_topology_and_scroll() -> void:
	_assert_side_dense_vertical(WRAPPER.ORIENTATION_SIDE_RIGHT, GameIds.PLAYER_AI_3)


func test_side_orientation_switch_clears_all_card_containers() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	_fill_many(ai)
	var board_setup: Array = _board(WRAPPER.ORIENTATION_SIDE_LEFT)
	var host: Control = board_setup[0]
	var board: PlayerBoard = board_setup[1]
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await _settle_layout()
	board.set_card_orientation(WRAPPER.ORIENTATION_NORMAL)
	board.render(ai, {}, view["card_definitions"])
	await _settle_layout()
	assert_eq(board.default_cards_row.get_child_count(), board.owned_cards_row.get_child_count())
	assert_eq(board.default_cards_column.get_child_count(), 0)
	assert_eq(board.compact_cards_row.get_child_count(), 0)
	assert_eq(board.compact_cards_column.get_child_count(), 0)
	host.queue_free()


func test_side_low_height_round_trip_clears_stale_cards() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	_fill_many(ai)
	var board_setup: Array = _board(WRAPPER.ORIENTATION_SIDE_LEFT)
	var host: Control = board_setup[0]
	var board: PlayerBoard = board_setup[1]
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await _settle_layout()
	board.set_low_height_mode(true)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await _settle_layout()
	board.set_low_height_mode(false)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await _settle_layout()
	assert_eq(board.default_cards_column.get_child_count(), board.owned_cards_row.get_child_count())
	assert_eq(board.default_cards_row.get_child_count(), 0)
	assert_eq(board.compact_cards_row.get_child_count(), 0)
	assert_eq(board.compact_cards_column.get_child_count(), 0)
	host.queue_free()


func _assert_side_dense_vertical(orientation: String, player_id: String) -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, player_id).duplicate(true)
	_fill_many(ai)
	var board_setup: Array = _board(orientation)
	var host: Control = board_setup[0]
	var board: PlayerBoard = board_setup[1]
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await _settle_layout()
	var scroll: ScrollContainer = board.owned_cards_scroll
	var column: VBoxContainer = board.default_cards_column
	assert_true(board.owned_cards_row is VBoxContainer)
	assert_eq(board.owned_cards_row, column)
	assert_eq(
		scroll.vertical_scroll_mode,
		ScrollContainer.SCROLL_MODE_AUTO
	)
	assert_eq(
		scroll.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	var m: Dictionary = MEASURE.measure_card_strip(scroll, column)
	assert_gt(m["card_count"], 8)
	assert_true(m["content_is_vbox"])
	assert_gt(m["content_h"], m["viewport_h"])
	assert_gt(m["v_max"], m["v_page"])
	assert_lte(m["h_range"], 0.5)
	assert_true(MEASURE.cross_axis_fits(scroll, column))
	var prev_y: float = NAN
	var row_x: float = NAN
	for child: Node in column.get_children():
		assert_eq(str(child.get("orientation")), orientation)
		assert_eq(child.custom_minimum_size, WRAPPER.SIDE_FOOTPRINT)
		var wrapper := child as Control
		if is_nan(row_x):
			row_x = wrapper.global_position.x
		else:
			assert_almost_eq(wrapper.global_position.x, row_x, 0.5)
		if is_nan(prev_y):
			prev_y = wrapper.global_position.y
		else:
			assert_gt(wrapper.global_position.y, prev_y)
			prev_y = wrapper.global_position.y
	scroll.scroll_vertical = 0
	await _settle_layout()
	var first := column.get_child(0) as Control
	var last := column.get_child(column.get_child_count() - 1) as Control
	assert_gte(first.global_position.y, scroll.global_position.y - 1.0)
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await _settle_layout()
	assert_lte(
		last.global_position.y + last.size.y,
		scroll.global_position.y + scroll.size.y + 1.0
	)
	scroll.scroll_vertical = 0
	await _settle_layout()
	host.queue_free()


func _board(orientation: String) -> Array:
	var host := Control.new()
	host.size = Vector2(256, 900)
	host.theme = THEME
	add_child(host)
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	host.add_child(board)
	board.set_card_orientation(orientation)
	board.set_card_presentation(PlayerBoard.CARD_PRESENTATION_FULL)
	return [host, board]


func _fill_many(player: Dictionary) -> void:
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


func _player(view: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in view.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _valid_config() -> Dictionary:
	var seed_value := "player_board_side_vertical"
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
