class_name PlayerBoardLayoutChrome
extends RefCounted

const OWNED_CARDS_SCROLL_MIN_Y := 244


static func apply_compact_rail(board: PlayerBoard) -> void:
	board.identity_bar.visible = false
	board.status_bar.visible = false
	move_to(board.name_label, board.compact_info_rail)
	move_to(board.profile_label, board.compact_info_rail)
	move_to(board.resources, board.compact_info_rail)
	move_to(board.state_label, board.compact_info_rail)
	restore_compact_info_order(board)


static func apply_center_dense(board: PlayerBoard) -> void:
	board.identity_bar.visible = true
	board.status_bar.visible = true
	board.layout.add_theme_constant_override("separation", 2)
	board.owned_cards_scroll.custom_minimum_size.y = OWNED_CARDS_SCROLL_MIN_Y
	board.owned_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	move_to(board.name_label, board.identity_bar)
	move_to(board.resources, board.identity_bar)
	move_to(board.profile_label, board.status_bar)
	move_to(board.state_label, board.status_bar)
	_order_child(board.identity_bar, board.name_label, 0)
	_order_child(board.identity_bar, board.identity_spacer, 1)
	_order_child(board.identity_bar, board.resources, 2)
	_order_child(board.status_bar, board.profile_label, 0)
	_order_child(board.status_bar, board.status_spacer, 1)
	_order_child(board.status_bar, board.state_label, 2)
	_order_child(board.layout, board.identity_bar, 0)
	_order_child(board.layout, board.status_bar, 1)
	_order_child(board.layout, board.owned_cards_scroll, 2)


static func apply_side_stacked(board: PlayerBoard) -> void:
	board.identity_bar.visible = false
	board.status_bar.visible = false
	board.layout.add_theme_constant_override("separation", 4)
	board.owned_cards_scroll.custom_minimum_size = Vector2.ZERO
	board.owned_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_move(board.name_label, board.layout)
	_move(board.profile_label, board.layout)
	_move(board.resources, board.layout)
	_move(board.state_label, board.layout)
	_order_child(board.layout, board.name_label, 0)
	_order_child(board.layout, board.profile_label, 1)
	_order_child(board.layout, board.resources, 2)
	_order_child(board.layout, board.owned_cards_scroll, 3)
	_order_child(board.layout, board.state_label, 4)


static func restore_compact_info_order(board: PlayerBoard) -> void:
	_order_child(board.compact_info_rail, board.name_label, 0)
	_order_child(board.compact_info_rail, board.profile_label, 1)
	_order_child(board.compact_info_rail, board.resources, 2)
	_order_child(board.compact_info_rail, board.state_label, 3)


static func move_to(child: Control, parent: Node) -> void:
	if child.get_parent() == parent:
		return
	if child.get_parent() != null:
		child.get_parent().remove_child(child)
	parent.add_child(child)


static func _move(child: Control, parent: Node) -> void:
	move_to(child, parent)


static func _order_child(parent: Node, child: Node, index: int) -> void:
	if child.get_parent() == parent:
		parent.move_child(child, index)
