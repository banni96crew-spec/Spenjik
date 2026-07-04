class_name GameScreenLayoutMeasure
extends RefCounted

const GAME_SCREEN := preload("res://scenes/ui/screens/GameScreen.tscn")
const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const THEME := preload("res://themes/main_theme.tres")


static func measure_game_screen(screen: GameScreen) -> Dictionary:
	var workspace: Control = screen.get_node("%TableWorkspace")
	var center_table: Control = screen.get_node("%CenterTable")
	var human_zone: Control = screen.get_node("%HumanZone")
	var top_zone: Control = screen.get_node("%TopOpponentZone")
	var market: MarketPanel = screen.market_panel
	var result := {
		"table_workspace_h": workspace.size.y,
		"center_table_h": center_table.size.y,
		"center_table_min_h": center_table.get_combined_minimum_size().y,
		"market_panel_min_h": market.get_combined_minimum_size().y if market.visible else 0.0,
		"human_zone_h": human_zone.size.y,
		"top_zone_h": top_zone.size.y,
		"human_zone_bottom": human_zone.global_position.y + human_zone.size.y,
		"workspace_bottom": workspace.global_position.y + workspace.size.y,
		"human_overflow_px": (
			human_zone.global_position.y + human_zone.size.y
			- (workspace.global_position.y + workspace.size.y)
		),
	}
	return result


static func measure_player_board(board: PlayerBoard) -> Dictionary:
	var scroll: ScrollContainer = board.owned_cards_scroll
	var row: Control = board.owned_cards_row
	var identity_bar: Node = board.get_node_or_null("%IdentityBar")
	var status_bar: Node = board.get_node_or_null("%StatusBar")
	var result := {
		"board_min_h": board.get_combined_minimum_size().y,
		"board_min_w": board.get_combined_minimum_size().x,
		"scroll_min_h": scroll.get_combined_minimum_size().y,
		"scroll_size_h": scroll.size.y,
		"identity_bar_h": identity_bar.get_minimum_size().y if identity_bar != null else 0.0,
		"status_bar_h": status_bar.get_minimum_size().y if status_bar != null else 0.0,
		"row_child_h": row.get_child(0).size.y if row.get_child_count() > 0 else 0.0,
		"h_scroll_max": scroll.get_h_scroll_bar().max_value,
	}
	return result
