extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_setup_layout_fits_supported_viewports() -> void:
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var setup: SetupScreen = _host_scene(
			"res://scenes/ui/screens/SetupScreen.tscn", viewport_size
		)
		if setup == null:
			continue
		assert_eq(setup.size, viewport_size)
		assert_true(setup.start_button.is_visible_in_tree())
		setup.get_parent().queue_free()


func test_game_layout_exposes_tabletop_zones_at_supported_viewports() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var screen: GameScreen = _host_scene(
			"res://scenes/ui/screens/GameScreen.tscn", viewport_size
		)
		if screen == null:
			continue
		screen.refresh()
		assert_eq(screen.size, viewport_size)
		assert_not_null(screen.get_node("%PhaseHeader"))
		assert_not_null(screen.get_node("%AIZones"))
		assert_not_null(screen.get_node("%CentralPhaseArea"))
		assert_not_null(screen.get_node("%HumanZone"))
		assert_not_null(screen.get_node("%SideInfoColumn"))
		assert_eq(screen.get_node("%AIZones").get_child_count(), 3)
		assert_true(screen.income_button.is_visible_in_tree())
		assert_true(screen.round_label.is_visible_in_tree())
		assert_true(screen.phase_label.is_visible_in_tree())
		assert_true(screen.active_label.is_visible_in_tree())
		var human_board: PlayerBoard = screen.get_node("%HumanBoard")
		assert_true(human_board.is_visible_in_tree())
		assert_true(human_board.resources.is_visible_in_tree())
		screen.get_parent().queue_free()


func test_core_phase_buttons_have_stable_reachable_paths() -> void:
	var screen: Node = _host_scene(
		"res://scenes/ui/screens/GameScreen.tscn", Vector2(1280, 720)
	)
	if screen == null:
		return
	for button_name: String in [
		"IncomeButton", "BuyButton", "RebuildButton", "ExecuteButton",
		"DiscardButton", "OptionA", "OptionB", "ClaimButton", "SelectButton",
	]:
		assert_not_null(
			screen.find_child(button_name, true, false),
			"Missing core button: %s" % button_name
		)
	assert_gte(
		screen.find_children("EndButton", "Button", true, false).size(),
		2,
		"Market and Action end buttons must remain reachable"
	)
	screen.get_parent().queue_free()


func _host_scene(path: String, viewport_size: Vector2) -> Variant:
	var packed: PackedScene = load(path)
	assert_not_null(packed, path)
	if packed == null:
		return null
	var host := Control.new()
	host.size = viewport_size
	add_child_autofree(host)
	var instance: Control = packed.instantiate()
	host.add_child(instance)
	instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return instance


func _valid_config() -> Dictionary:
	var seed_value := "ui_layout"
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
