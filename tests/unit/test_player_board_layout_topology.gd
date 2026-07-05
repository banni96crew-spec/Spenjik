extends GutTest

const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const WRAPPER_SCRIPT := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")


func test_center_dense_low_height_round_trip_restores_topology() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var human: Dictionary = _player(view, GameIds.PLAYER_HUMAN).duplicate(true)
	human["engine"]["laundries"] = 1
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.render(human, {}, view["card_definitions"])
	_assert_center_dense_topology(board)
	board.set_low_height_mode(true)
	board.render(human, {}, view["card_definitions"])
	assert_false(board.layout.visible)
	board.set_low_height_mode(false)
	board.render(human, {}, view["card_definitions"])
	_assert_center_dense_topology(board)
	assert_eq(
		_card_from_child(board.owned_cards_row.get_child(0)).get_layout_size(),
		CardVisualTokens.MARKET_CARD_SIZE
	)


func test_orientation_round_trip_center_dense_and_side_stacked() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	ai["is_strong_ai"] = true
	ai["nal"] = 23
	ai["vp"] = 2
	ai["engine"]["accountants"] = 1
	ai["hand"] = [GameIds.CARD_BRUISER]
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(board)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	_assert_center_dense_topology(board)
	board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	_assert_side_stacked_topology(board)
	board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_NORMAL)
	_assert_center_dense_topology(board)


func test_side_ai_worst_case_chrome_fits_zone_content_width() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_3).duplicate(true)
	ai["is_strong_ai"] = true
	ai["nal"] = 23
	ai["vp"] = 2
	ai["engine"]["accountants"] = 1
	ai["hand"] = [GameIds.CARD_BRUISER]
	var host := Control.new()
	host.size = Vector2(256, 500)
	host.theme = load("res://themes/main_theme.tres")
	add_child_autofree(host)
	var board: PlayerBoard = BOARD_SCENE.instantiate()
	host.add_child(board)
	board.set_card_orientation(WRAPPER_SCRIPT.ORIENTATION_SIDE_RIGHT)
	board.set_card_presentation(PlayerBoard.CARD_PRESENTATION_FULL)
	board.render(ai, {"profile_id": "enforcer"}, view["card_definitions"])
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(board.name_label.text, "RIVAL III · STRONG")
	var zone_content_w: float = host.size.x
	assert_lte(board.get_combined_minimum_size().x, zone_content_w + 0.5)
	_assert_side_stacked_topology(board)
	for control: Control in [
		board.name_label, board.profile_label, board.resources,
		board.state_label,
	]:
		assert_lte(control.size.x, zone_content_w + 0.5)


func test_low_height_round_trip_restores_center_dense_topology() -> void:
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
	_assert_center_dense_topology(board)


func _assert_center_dense_topology(board: PlayerBoard) -> void:
	assert_true(board.layout.visible)
	assert_false(board.compact_layout.visible)
	assert_true(board.identity_bar.visible)
	assert_true(board.status_bar.visible)
	assert_eq(board.name_label.get_parent(), board.identity_bar)
	assert_eq(board.resources.get_parent(), board.identity_bar)
	assert_eq(board.profile_label.get_parent(), board.status_bar)
	assert_eq(board.state_label.get_parent(), board.status_bar)
	assert_eq(board.owned_cards_scroll.get_parent(), board.layout)
	assert_eq(board.layout.get_child(0), board.identity_bar)
	assert_eq(board.layout.get_child(1), board.status_bar)
	assert_eq(board.layout.get_child(2), board.owned_cards_scroll)


func _assert_side_stacked_topology(board: PlayerBoard) -> void:
	assert_true(board.layout.visible)
	assert_false(board.identity_bar.visible)
	assert_false(board.status_bar.visible)
	assert_eq(board.name_label.get_parent(), board.layout)
	assert_eq(board.profile_label.get_parent(), board.layout)
	assert_eq(board.resources.get_parent(), board.layout)
	assert_eq(board.owned_cards_scroll.get_parent(), board.layout)
	assert_eq(board.state_label.get_parent(), board.layout)
	assert_eq(board.layout.get_child(0), board.name_label)
	assert_eq(board.layout.get_child(1), board.profile_label)
	assert_eq(board.layout.get_child(2), board.resources)
	assert_eq(board.layout.get_child(3), board.owned_cards_scroll)
	assert_eq(board.layout.get_child(4), board.state_label)


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
	var seed_value := "player_board_topology"
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
