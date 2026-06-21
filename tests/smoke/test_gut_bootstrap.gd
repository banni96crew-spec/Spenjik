extends GutTest


func test_gut_bootstrap() -> void:
	assert_true(FileAccess.file_exists("res://project.godot"))
	assert_true(FileAccess.file_exists("res://addons/gut/plugin.cfg"))
	assert_eq(2 + 2, 4)
