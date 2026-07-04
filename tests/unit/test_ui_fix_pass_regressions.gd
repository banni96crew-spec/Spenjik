extends GutTest

const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_profile_empty_row_is_hidden_for_human_board() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var screen: GameScreen = _screen(Vector2(1920, 1080))
	screen.refresh()
	await _settle_layout()
	assert_false(screen.human_board.profile_label.visible)
	_assert_inside(screen.human_zone, screen.human_board.name_label, "human name")
	_assert_inside(screen.human_zone, screen.human_board.resources, "human nal/vp")
	screen.get_parent().queue_free()


func test_normal_board_zone_heights_stay_stable_across_refreshes() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var screen: GameScreen = _screen(Vector2(1920, 1080))
	screen.refresh()
	await _settle_layout()
	var top_height: float = screen.top_opponent_zone.size.y
	var human_height: float = screen.human_zone.size.y
	var human: Dictionary = TestPlayers.find(GameStateManager.state,
		GameIds.PLAYER_HUMAN)
	human["engine"]["laundries"] = 1
	human["status_buildings"]["stash"] = 1
	screen.refresh()
	await _settle_layout()
	assert_eq(screen.top_opponent_zone.size.y, top_height)
	assert_eq(screen.human_zone.size.y, human_height)
	assert_true(GameStateManager.advance_phase()["ok"])
	await _settle_layout()
	assert_eq(screen.top_opponent_zone.size.y, top_height)
	assert_eq(screen.human_zone.size.y, human_height)
	screen.get_parent().queue_free()


func test_ai_compact_boards_use_bounded_card_overflow() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	for id: String in [GameIds.PLAYER_AI_1, GameIds.PLAYER_AI_2,
		GameIds.PLAYER_AI_3]:
		_fill_many_unique_displays(GameStateManager.state, id)
	var screen: GameScreen = _screen(Vector2(1920, 1080))
	screen.refresh()
	await _settle_layout()
	for pair: Array in [
		[screen.get_node("%LeftOpponentZone"), screen.ai_board_1],
		[screen.get_node("%TopOpponentZone"), screen.ai_board_2],
		[screen.get_node("%RightOpponentZone"), screen.ai_board_3],
	]:
		var zone: Control = pair[0]
		var board: PlayerBoard = pair[1]
		assert_gt(board.owned_cards_row.get_child_count(), 8)
		_assert_inside(zone, board.name_label, "%s name" % board.name)
		_assert_inside(zone, board.resources, "%s resources" % board.name)
		_assert_inside(zone, board.owned_cards_scroll,
			"%s card scroll" % board.name)
	screen.get_parent().queue_free()


func _screen(viewport_size: Vector2) -> GameScreen:
	var host := Control.new()
	host.size = viewport_size
	host.theme = load("res://themes/main_theme.tres")
	add_child_autofree(host)
	var screen: GameScreen = GAME_SCREEN.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _assert_inside(parent: Control, child: Control, label: String) -> void:
	var parent_rect := Rect2(parent.global_position, parent.size)
	var child_rect := Rect2(child.global_position, child.size)
	assert_true(parent_rect.encloses(child_rect), "%s outside %s" % [
		label, parent.name,
	])


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
	var seed_value := "ui_fix_pass"
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
