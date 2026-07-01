extends GutTest

const ACTION_PANEL := preload("res://scenes/ui/panels/ActionPanel.tscn")

const REQUIRED_NODES: Array[String] = [
	"CardOptions",
	"TargetOptions",
	"ModeOptions",
	"EngineOptions",
	"InsiderCheck",
	"PreviewLabel",
	"ReasonLabel",
	"ExecuteButton",
	"DiscardButton",
	"CancelButton",
	"EndButton",
]


func test_action_panel_scene_instantiates_with_required_nodes() -> void:
	var panel: ActionPanel = ACTION_PANEL.instantiate()
	add_child_autofree(panel)
	for node_name: String in REQUIRED_NODES:
		assert_not_null(panel.get_node_or_null("%" + node_name), node_name)


func test_action_panel_presentation_is_not_raw_grid_form() -> void:
	var scene_text: String = FileAccess.get_file_as_string(
		"res://scenes/ui/panels/ActionPanel.tscn"
	)
	assert_false(scene_text.contains("GridContainer"))
	assert_true(scene_text.contains("SelectorSection"))
	assert_true(scene_text.contains("PreviewFrame"))
