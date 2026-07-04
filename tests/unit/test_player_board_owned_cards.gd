extends GutTest

const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const WRAPPER_SCRIPT := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")


func test_player_board_scene_has_bounded_owned_cards_scroll() -> void:
	var scene_text: String = FileAccess.get_file_as_string(
		"res://scenes/ui/panels/PlayerBoard.tscn"
	)
	assert_true(scene_text.contains("OwnedCardsScroll"))
	assert_true(scene_text.contains("CompactCardsScroll"))
	assert_true(scene_text.contains("OwnedCardsRow"))
	assert_true(scene_text.contains("type=\"HBoxContainer\" parent=\"BoardRoot/Layout/OwnedCardsScroll\""))
	assert_true(scene_text.contains("horizontal_scroll_mode = 1"))
	assert_true(scene_text.contains("vertical_scroll_mode = 0"))
	assert_false(scene_text.contains("OwnedLabel"))
	assert_false(scene_text.contains("DefenseBadges"))


func test_player_board_renders_owned_cards_for_human_and_ai() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var definitions: Dictionary = view["card_definitions"]
	var human: Dictionary = _player(view, GameIds.PLAYER_HUMAN).duplicate(true)
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	human["engine"]["laundries"] = 2
	human["status_buildings"]["stash"] = 1
	human["defense"]["cops_active"] = true
	human["hand"] = [GameIds.CARD_THUG]
	ai["engine"]["accountants"] = 1
	ai["hand"] = [GameIds.CARD_BRUISER]
	var human_board: PlayerBoard = BOARD_SCENE.instantiate()
	var ai_board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(human_board)
	add_child_autofree(ai_board)
	ai_board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	ai_board.set_card_presentation(PlayerBoard.CARD_PRESENTATION_COMPACT)
	human_board.render(human, {}, definitions)
	ai_board.render(ai, {"profile_id": "enforcer"}, definitions)
	assert_eq(human_board.owned_cards_row.get_child_count(), 4)
	assert_eq(ai_board.owned_cards_row.get_child_count(), 2)
	for child: Node in human_board.owned_cards_row.get_children():
		assert_true(child.get_script() == WRAPPER_SCRIPT)
		assert_eq(str(child.get("orientation")), WRAPPER_SCRIPT.ORIENTATION_NORMAL)
		var chip := _card_from_child(child)
		assert_not_null(chip)
		assert_eq(chip.get_layout_size(), CardVisualTokens.MARKET_CARD_SIZE)
		assert_false(chip.select_button.visible)
		assert_true(chip.type_marker_top.visible)
		assert_false(chip.title_label.text.is_empty())
		assert_false(chip.effect_label.text.is_empty())
	for child: Node in ai_board.owned_cards_row.get_children():
		assert_true(child.get_script() == WRAPPER_SCRIPT)
		assert_eq(str(child.get("orientation")), WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
		assert_eq(child.custom_minimum_size, WRAPPER_SCRIPT.COMPACT_SIDE_FOOTPRINT)
		assert_eq(_card_from_child(child).get_layout_size(), CardVisualTokens.COMPACT_CARD_SIZE)
	var laundry_chip: CardView = _find_owned_card(
		human_board, GameIds.CARD_LAUNDRY
	)
	assert_not_null(laundry_chip)
	assert_true(laundry_chip.count_badge.visible)
	assert_eq(laundry_chip.count_badge.text, "x2")


func test_low_height_board_uses_compact_card_strip_without_accumulation() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var human: Dictionary = _player(view, GameIds.PLAYER_HUMAN).duplicate(true)
	human["engine"]["laundries"] = 2
	human["status_buildings"]["stash"] = 1
	human["hand"] = [GameIds.CARD_THUG]
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.set_low_height_mode(true)
	board.render(human, {}, view["card_definitions"])
	board.render(human, {}, view["card_definitions"])
	assert_false(board.layout.visible)
	assert_true(board.get_node("%CompactLayout").visible)
	assert_true(board.owned_cards_row.get_parent() is ScrollContainer)
	assert_eq(board.owned_cards_row.get_child_count(), 3)
	for child: Node in board.owned_cards_row.get_children():
		assert_eq(_card_from_child(child).get_layout_size(), CardVisualTokens.COMPACT_CARD_SIZE)
		assert_eq(child.custom_minimum_size, CardVisualTokens.COMPACT_CARD_SIZE)


func test_low_height_rotated_cards_use_compact_side_footprint() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	ai["engine"]["accountants"] = 1
	ai["hand"] = [GameIds.CARD_BRUISER]
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	board.set_low_height_mode(true)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	for child: Node in board.owned_cards_row.get_children():
		assert_eq(child.custom_minimum_size, WRAPPER_SCRIPT.COMPACT_SIDE_FOOTPRINT)


func test_compact_card_presentation_does_not_require_low_height_mode() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	ai["engine"]["accountants"] = 1
	ai["hand"] = [GameIds.CARD_BRUISER]
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	board.set_card_presentation(PlayerBoard.CARD_PRESENTATION_COMPACT)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	assert_true(board.layout.visible)
	assert_false(board.compact_layout.visible)
	assert_true(board.owned_cards_row.get_parent() is ScrollContainer)
	for child: Node in board.owned_cards_row.get_children():
		assert_eq(child.custom_minimum_size, WRAPPER_SCRIPT.COMPACT_SIDE_FOOTPRINT)


func test_low_height_round_trip_restores_default_order_and_cards() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var human: Dictionary = _player(view, GameIds.PLAYER_HUMAN).duplicate(true)
	human["engine"]["laundries"] = 1
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.render(human, {}, view["card_definitions"])
	board.set_low_height_mode(true)
	board.render(human, {}, view["card_definitions"])
	board.set_low_height_mode(false)
	board.render(human, {}, view["card_definitions"])
	assert_eq(board.layout.get_child(0), board.name_label)
	assert_eq(board.layout.get_child(1), board.profile_label)
	assert_eq(board.layout.get_child(2), board.resources)
	assert_eq(board.layout.get_child(3), board.owned_cards_scroll)
	assert_eq(board.layout.get_child(4), board.state_label)
	assert_eq(_card_from_child(board.owned_cards_row.get_child(0)).get_layout_size(),
		CardVisualTokens.MARKET_CARD_SIZE)


func test_player_owned_cards_builder_groups_duplicate_counts() -> void:
	var definitions: Dictionary = PresentationViewBuilder.cards_by_id()
	var player: Dictionary = TestPlayers.player(GameIds.PLAYER_HUMAN)
	player["engine"]["laundries"] = 2
	player["status_buildings"]["stash"] = 3
	player["defense"]["cartel_state"] = DefenseStates.ACTIVE
	player["hand"] = [GameIds.CARD_CLEANER, GameIds.CARD_CLEANER]
	var displays: Array[Dictionary] = PlayerOwnedCardsBuilder.build_owned_displays(
		player, definitions
	)
	assert_eq(displays.size(), 4)
	var by_id: Dictionary = {}
	for display: Dictionary in displays:
		by_id[str(display.get("id", ""))] = display
	assert_eq(int(by_id[GameIds.CARD_LAUNDRY].get("count", 1)), 2)
	assert_eq(int(by_id[GameIds.CARD_STASH].get("count", 1)), 3)
	assert_eq(int(by_id[GameIds.CARD_CLEANER].get("count", 1)), 2)
	assert_false(by_id[GameIds.CARD_CARTEL].has("count"))


func test_owned_cards_row_uses_bounded_scroll_container() -> void:
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	var row: Node = board.owned_cards_row
	assert_not_null(row)
	assert_true(row.get_parent() is ScrollContainer)


func _find_owned_card(board: PlayerBoard, card_id: String) -> CardView:
	for child: Node in board.owned_cards_row.get_children():
		var chip := _card_from_child(child)
		if chip != null and chip.card_id == card_id:
			return chip
	return null


func _card_from_child(child: Node) -> CardView:
	if child.get_script() == WRAPPER_SCRIPT:
		return child.get("card_view") as CardView
	return child as CardView


func _player(view: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in view.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


func _valid_config() -> Dictionary:
	var seed_value := "player_board_owned"
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
