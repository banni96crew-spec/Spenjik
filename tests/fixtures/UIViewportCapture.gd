extends SceneTree

const OUTPUT_DIR := "res://.godot/ui_checks"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIR)
	)
	root.size = Vector2i(1280, 720)
	var main: Control = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_save("setup_1280x720.png")
	var facade: Node = root.get_node("GameStateManager")
	var seed_value := "ui_capture"
	var preview: Dictionary = facade.generate_contract_offers({
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
	})
	facade.start_new_game({
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	})
	facade.advance_phase()
	await process_frame
	await process_frame
	_save("market_1280x720.png")
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	_save("market_1920x1080.png")
	quit()


func _save(file_name: String) -> void:
	root.get_texture().get_image().save_png(
		"%s/%s" % [OUTPUT_DIR, file_name]
	)
