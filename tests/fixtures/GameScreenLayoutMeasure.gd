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
	var strip: Dictionary = measure_card_strip(scroll, row)
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
	result.merge(strip)
	return result


static func measure_card_strip(
	scroll: ScrollContainer,
	content: Control
) -> Dictionary:
	var hbar: ScrollBar = scroll.get_h_scroll_bar()
	var vbar: ScrollBar = scroll.get_v_scroll_bar()
	var result := {
		"card_count": content.get_child_count(),
		"content_w": content.size.x,
		"content_h": content.size.y,
		"viewport_w": scroll.size.x,
		"viewport_h": scroll.size.y,
		"h_max": hbar.max_value,
		"h_page": hbar.page,
		"h_range": maxf(0.0, hbar.max_value - hbar.page),
		"v_max": vbar.max_value,
		"v_page": vbar.page,
		"v_range": maxf(0.0, vbar.max_value - vbar.page),
		"scroll_h_mode": scroll.horizontal_scroll_mode,
		"scroll_v_mode": scroll.vertical_scroll_mode,
		"content_is_vbox": content is VBoxContainer,
		"content_is_hbox": content is HBoxContainer,
	}
	if content.get_child_count() > 0:
		var first := content.get_child(0) as Control
		var last := content.get_child(content.get_child_count() - 1) as Control
		var vertical: bool = content is VBoxContainer
		result["strip_vertical"] = vertical
		result["first_x"] = first.global_position.x
		result["last_x"] = last.global_position.x
		result["first_y"] = first.global_position.y
		result["last_y"] = last.global_position.y
		result["wrapper_footprint_w"] = first.custom_minimum_size.x
		result["wrapper_footprint_h"] = first.custom_minimum_size.y
	return result


static func simulate_wheel_down(scroll: ScrollContainer) -> Dictionary:
	var before_h: float = scroll.scroll_horizontal
	var before_v: float = scroll.scroll_vertical
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev.pressed = true
	ev.factor = 1.0
	scroll.get_viewport().push_input(ev)
	return {
		"scroll_h_before": before_h,
		"scroll_v_before": before_v,
		"scroll_h_after": scroll.scroll_horizontal,
		"scroll_v_after": scroll.scroll_vertical,
		"h_changed": scroll.scroll_horizontal != before_h,
		"v_changed": scroll.scroll_vertical != before_v,
	}


static func cross_axis_fits(scroll: ScrollContainer, content: Control) -> bool:
	if content.get_child_count() == 0:
		return true
	var max_cross: float = 0.0
	for child: Node in content.get_children():
		var wrapper := child as Control
		if wrapper == null:
			continue
		if content is VBoxContainer:
			max_cross = maxf(max_cross, wrapper.size.x)
		elif content is HBoxContainer:
			max_cross = maxf(max_cross, wrapper.size.y)
	if content is VBoxContainer:
		return max_cross <= scroll.size.x + 0.5
	if content is HBoxContainer:
		return max_cross <= scroll.size.y + 0.5
	return true


static func _first_reachable(
	scroll: ScrollContainer, content: Control, vertical: bool
) -> bool:
	if content.get_child_count() == 0:
		return true
	var first := content.get_child(0) as Control
	if vertical:
		scroll.scroll_vertical = 0
		return first.global_position.y >= scroll.global_position.y - 1.0
	scroll.scroll_horizontal = 0
	return first.global_position.x >= scroll.global_position.x - 1.0


static func _last_reachable(
	scroll: ScrollContainer, content: Control, vertical: bool
) -> bool:
	if content.get_child_count() == 0:
		return true
	var last := content.get_child(content.get_child_count() - 1) as Control
	if vertical:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		return (
			last.global_position.y + last.size.y
			<= scroll.global_position.y + scroll.size.y + 1.0
		)
	scroll.scroll_horizontal = int(scroll.get_h_scroll_bar().max_value)
	return (
		last.global_position.x + last.size.x
		<= scroll.global_position.x + scroll.size.x + 1.0
	)
