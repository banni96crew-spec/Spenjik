extends GutTest

const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const WRAPPER_SCRIPT := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")


func test_side_ai_many_owned_displays_use_horizontal_bounded_scroll() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	_fill_many_unique_displays(ai)
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	board.set_card_presentation(PlayerBoard.CARD_PRESENTATION_FULL)
	board.custom_minimum_size = Vector2(256, 400)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(
		board.owned_cards_scroll.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_AUTO
	)
	assert_eq(
		board.owned_cards_scroll.vertical_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	assert_gt(board.owned_cards_row.get_child_count(), 8)
	var row_y: float = NAN
	for child: Node in board.owned_cards_row.get_children():
		assert_eq(child.custom_minimum_size, WRAPPER_SCRIPT.SIDE_FOOTPRINT)
		if is_nan(row_y):
			row_y = child.global_position.y
		else:
			assert_almost_eq(child.global_position.y, row_y, 0.5)
	assert_gt(board.owned_cards_row.size.x, board.owned_cards_scroll.size.x)
	assert_gt(board.owned_cards_scroll.get_h_scroll_bar().max_value, 0.0)
	assert_eq(board.name_label.get_parent(), board.layout)


func _player(view: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in view.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


func _fill_many_unique_displays(player: Dictionary) -> void:
	player["engine"]["informers"] = 1
	player["engine"]["laundries"] = 1
	player["engine"]["accountants"] = 1
	player["engine"]["brothel"] = true
	player["status_buildings"]["stash"] = 1
	player["status_buildings"]["workshop"] = 1
	player["status_buildings"]["district_control"] = 1
	player["defense"]["cops_active"] = true
	player["defense"]["cartel_state"] = DefenseStates.ACTIVE
	player["defense"]["judge_state"] = DefenseStates.ACTIVE
	player["hand"] = [
		GameIds.CARD_THUG, GameIds.CARD_BRUISER, GameIds.CARD_CLEANER,
		GameIds.CARD_FEDERAL_RAID, GameIds.CARD_SABOTEUR, GameIds.CARD_INSIDER,
	]


func _valid_config() -> Dictionary:
	var seed_value := "player_board_horizontal"
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
