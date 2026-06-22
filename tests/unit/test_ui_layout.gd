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


func test_game_layout_uses_scrollable_regions_at_supported_viewports() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080)]:
		var screen: GameScreen = _host_scene(
			"res://scenes/ui/screens/GameScreen.tscn", viewport_size
		)
		if screen == null:
			continue
		screen.refresh()
		assert_eq(screen.size, viewport_size)
		assert_not_null(screen.get_node("Layout/PlayerBoardsScroll"))
		assert_not_null(screen.get_node("Layout/Content/PhaseScroll"))
		assert_not_null(screen.get_node("Layout/Content/SidebarScroll"))
		assert_true(screen.income_button.is_visible_in_tree())
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
