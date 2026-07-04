extends GutTest

const MEASURE := preload("res://tests/fixtures/GameScreenLayoutMeasure.gd")
const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")
const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const WRAPPER := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")


func test_baseline_market_layout_measurements() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	assert_true(GameStateManager.advance_phase()["ok"])
	var screen: GameScreen = _screen()
	screen.refresh()
	await _settle_layout()
	var m: Dictionary = MEASURE.measure_game_screen(screen)
	gut.p("BASELINE_MEASURE " + JSON.stringify(m))
	assert_gt(m["table_workspace_h"], 0.0)
	assert_gt(m["center_table_min_h"], 0.0)
	screen.get_parent().queue_free()


func test_dense_board_layout_measurements() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var definitions: Dictionary = view["card_definitions"]
	var human: Dictionary = _player(view, GameIds.PLAYER_HUMAN).duplicate(true)
	human["engine"]["laundries"] = 1
	human["hand"] = [GameIds.CARD_THUG]
	var top_ai: Dictionary = _player(view, GameIds.PLAYER_AI_2).duplicate(true)
	top_ai["is_strong_ai"] = true
	top_ai["nal"] = 23
	top_ai["vp"] = 2
	top_ai["engine"]["accountants"] = 1
	top_ai["hand"] = [GameIds.CARD_BRUISER]
	_fill_many(human)
	_fill_many(top_ai)
	var host := Control.new()
	host.size = Vector2(800, 600)
	host.theme = MEASURE.THEME
	add_child_autofree(host)
	var human_board: PlayerBoard = BOARD_SCENE.instantiate()
	var top_board: PlayerBoard = BOARD_SCENE.instantiate()
	host.add_child(human_board)
	host.add_child(top_board)
	human_board.set_card_orientation(PlayerBoard.CARD_ORIENTATION_NORMAL)
	top_board.set_card_orientation(PlayerBoard.CARD_ORIENTATION_NORMAL)
	human_board.custom_minimum_size = Vector2(600, 0)
	top_board.custom_minimum_size = Vector2(600, 0)
	human_board.render(human, {}, definitions)
	top_board.render(top_ai, {"profile_id": "enforcer"}, definitions)
	await _settle_layout()
	var human_m: Dictionary = MEASURE.measure_player_board(human_board)
	var top_m: Dictionary = MEASURE.measure_player_board(top_board)
	var dense_h: float = (
		human_m["identity_bar_h"] + human_m["status_bar_h"]
		+ 4.0 + human_m["scroll_min_h"]
	)
	gut.p("DENSE_HUMAN " + JSON.stringify(human_m))
	gut.p("DENSE_TOP " + JSON.stringify(top_m))
	gut.p("DENSE_REQUIRED_H " + str(dense_h))
	assert_gte(human_m["scroll_min_h"], float(PlayerBoard.OWNED_CARDS_SCROLL_MIN_Y))
	assert_eq(human_m["row_child_h"], CardVisualTokens.MARKET_CARD_SIZE.y)
	assert_gt(human_m["h_scroll_max"], 0.0)


func _screen() -> GameScreen:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	host.theme = MEASURE.THEME
	add_child_autofree(host)
	var screen: GameScreen = GAME_SCREEN.instantiate()
	host.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return screen


func _fill_many(player: Dictionary) -> void:
	for key: String in ["informers", "laundries", "accountants"]:
		player["engine"][key] = 1
	player["engine"]["brothel"] = true
	player["status_buildings"]["stash"] = 1
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
	var seed_value := "layout_measure_baseline"
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
