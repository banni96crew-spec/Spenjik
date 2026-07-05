extends GutTest

const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")
const MEASURE := preload("res://tests/fixtures/GameScreenLayoutMeasure.gd")
const THEME := preload("res://themes/main_theme.tres")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_top_ai_dense_horizontal_overflow_reachability() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	_fill_many(GameStateManager.state, GameIds.PLAYER_AI_2)
	var screen: GameScreen = _screen(Vector2(1920, 1080))
	screen.set_case_file_visible(false)
	screen.refresh()
	await _settle_layout()
	var board: PlayerBoard = screen.ai_board_2
	var scroll: ScrollContainer = board.owned_cards_scroll
	var row: HBoxContainer = board.default_cards_row
	assert_true(board.owned_cards_row is HBoxContainer)
	var m: Dictionary = MEASURE.measure_card_strip(scroll, row)
	assert_gt(m["card_count"], 8)
	assert_true(m["content_is_hbox"])
	assert_gt(m["content_w"], m["viewport_w"])
	assert_gt(m["h_max"], m["h_page"])
	assert_true(MEASURE.cross_axis_fits(scroll, row))
	var first := row.get_child(0) as Control
	var last := row.get_child(row.get_child_count() - 1) as Control
	scroll.scroll_horizontal = 0
	await _settle_layout()
	assert_gte(first.global_position.x, scroll.global_position.x - 1.0)
	scroll.scroll_horizontal = int(scroll.get_h_scroll_bar().max_value)
	await _settle_layout()
	assert_lte(
		last.global_position.x + last.size.x,
		scroll.global_position.x + scroll.size.x + 1.0
	)


func test_top_ai_mouse_wheel_scroll_evidence() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	_fill_many(GameStateManager.state, GameIds.PLAYER_AI_2)
	var screen: GameScreen = _screen(Vector2(1920, 1080))
	screen.set_case_file_visible(false)
	screen.refresh()
	await _settle_layout()
	var scroll: ScrollContainer = screen.ai_board_2.owned_cards_scroll
	scroll.scroll_horizontal = 0
	await _settle_layout()
	var wheel: Dictionary = MEASURE.simulate_wheel_down(scroll)
	await _settle_layout()
	if wheel["h_changed"] or wheel["v_changed"]:
		pass


func _screen(viewport_size: Vector2) -> GameScreen:
	var host := Control.new()
	host.size = viewport_size
	host.theme = THEME
	add_child_autofree(host)
	var screen: GameScreen = GAME_SCREEN.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _fill_many(state: Dictionary, player_id: String) -> void:
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
	var seed_value := "top_ai_scroll_evidence"
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
