extends GutTest

const REQUIRED_SCENES: Array[String] = [
	"res://scenes/main/Main.tscn",
	"res://scenes/game/GameRoot.tscn",
	"res://scenes/ui/screens/SetupScreen.tscn",
	"res://scenes/ui/screens/GameScreen.tscn",
	"res://scenes/ui/screens/GameOverScreen.tscn",
	"res://scenes/ui/panels/PlayerBoard.tscn",
	"res://scenes/ui/panels/MarketPanel.tscn",
	"res://scenes/ui/panels/ActionPanel.tscn",
	"res://scenes/ui/panels/StreetDealPanel.tscn",
	"res://scenes/ui/panels/ContactPanel.tscn",
	"res://scenes/ui/panels/ContractPanel.tscn",
	"res://scenes/ui/panels/GameLogPanel.tscn",
	"res://scenes/ui/widgets/CardView.tscn",
	"res://scenes/ui/widgets/DefenseBadges.tscn",
	"res://scenes/ui/widgets/NalVpDisplay.tscn",
	"res://scenes/ui/widgets/DisabledReasonLabel.tscn",
]


func test_required_ui_scenes_instantiate() -> void:
	for path: String in REQUIRED_SCENES:
		var packed: PackedScene = load(path)
		assert_not_null(packed, path)
		if packed == null:
			continue
		var instance: Node = packed.instantiate()
		assert_not_null(instance, path)
		instance.free()


func test_game_root_has_stable_screen_paths() -> void:
	var root: Node = _instantiate("res://scenes/game/GameRoot.tscn")
	if root == null:
		return
	assert_not_null(root.get_node_or_null("ScreenHost/SetupScreen"))
	assert_not_null(root.get_node_or_null("ScreenHost/GameScreen"))
	assert_not_null(root.get_node_or_null("ScreenHost/GameOverScreen"))
	root.free()


func test_game_screen_has_required_panels() -> void:
	var screen: Node = _instantiate("res://scenes/ui/screens/GameScreen.tscn")
	if screen == null:
		return
	for path: String in [
		"Layout/PlayerBoardsScroll/PlayerBoards",
		"Layout/Content/PhaseScroll/PhasePanels/MarketPanel",
		"Layout/Content/PhaseScroll/PhasePanels/ActionPanel",
		"Layout/Content/PhaseScroll/PhasePanels/StreetDealPanel",
		"Layout/Content/SidebarScroll/Sidebar/ContractPanel",
		"Layout/Content/SidebarScroll/Sidebar/ContactPanel",
		"Layout/Content/SidebarScroll/Sidebar/GameLogPanel",
	]:
		assert_not_null(screen.get_node_or_null(path), path)
	screen.free()


func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path)
	assert_not_null(packed, path)
	return packed.instantiate() if packed != null else null
