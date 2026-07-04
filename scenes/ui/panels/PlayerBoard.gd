class_name PlayerBoard
extends PanelContainer

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const CARD_ORIENTATION_WRAPPER := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")
const CARD_ORIENTATION_NORMAL := "normal"
const CARD_ORIENTATION_SIDE_LEFT := "side_left"
const CARD_ORIENTATION_SIDE_RIGHT := "side_right"
const CARD_PRESENTATION_FULL := "full"
const CARD_PRESENTATION_COMPACT := "compact"
const OWNED_CARDS_SCROLL_MIN_Y := 244

var _card_orientation: String = CARD_ORIENTATION_NORMAL
var _card_presentation: String = CARD_PRESENTATION_FULL
var _low_height_mode: bool = false

@onready var layout: VBoxContainer = %Layout
@onready var compact_layout: HBoxContainer = %CompactLayout
@onready var compact_info_rail: VBoxContainer = %CompactInfoRail
@onready var identity_spacer: Control = %IdentitySpacer
@onready var status_spacer: Control = %StatusSpacer
@onready var identity_bar: HBoxContainer = %IdentityBar
@onready var status_bar: HBoxContainer = %StatusBar
@onready var owned_cards_scroll: ScrollContainer = %OwnedCardsScroll
@onready var compact_cards_scroll: ScrollContainer = %CompactCardsScroll
@onready var default_cards_row: HBoxContainer = %OwnedCardsRow
@onready var compact_cards_row: HBoxContainer = %CompactCardsRow
@onready var name_label: Label = %NameLabel
@onready var profile_label: Label = %ProfileLabel
@onready var resources: NalVpDisplay = %NalVpDisplay
@onready var owned_cards_row: Container = %OwnedCardsRow
@onready var state_label: Label = %StateLabel


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_apply_layout_mode()


func set_card_orientation(orientation: String) -> void:
	_card_orientation = orientation if orientation in [
		CARD_ORIENTATION_NORMAL,
		CARD_ORIENTATION_SIDE_LEFT,
		CARD_ORIENTATION_SIDE_RIGHT,
	] else CARD_ORIENTATION_NORMAL
	if is_node_ready():
		_apply_layout_mode()


func set_card_presentation(value: String) -> void:
	_card_presentation = (
		CARD_PRESENTATION_COMPACT
		if value == CARD_PRESENTATION_COMPACT else CARD_PRESENTATION_FULL
	)


func set_low_height_mode(value: bool) -> void:
	if _low_height_mode == value:
		return
	_low_height_mode = value
	if is_node_ready():
		_apply_layout_mode()


func render(
	player: Dictionary,
	profile: Dictionary = {},
	card_definitions: Dictionary = {}
) -> void:
	_apply_layout_mode()
	var player_id: String = str(player.get("id", ""))
	name_label.text = UIViewFormatters.player_name(player_id)
	if player.get("is_strong_ai", false):
		name_label.text += " · STRONG"
	var profile_text: String = str(profile.get("profile_id", "")).replace(
		"_", " "
	).capitalize()
	profile_label.text = profile_text
	profile_label.visible = not profile_text.is_empty()
	resources.set_values(
		int(player.get("nal", 0)), int(player.get("vp", 0))
	)
	_render_owned_cards(player, card_definitions)
	state_label.text = _state_text(player)


func _render_owned_cards(
	player: Dictionary,
	card_definitions: Dictionary
) -> void:
	for child: Node in owned_cards_row.get_children():
		owned_cards_row.remove_child(child)
		child.free()
	var inactive_row: Container = default_cards_row
	if not _low_height_mode:
		inactive_row = compact_cards_row
	for child: Node in inactive_row.get_children():
		inactive_row.remove_child(child)
		child.free()
	for display: Dictionary in PlayerOwnedCardsBuilder.build_owned_displays(
		player, card_definitions
	):
		var wrapper = CARD_ORIENTATION_WRAPPER.new()
		var chip: CardView = CARD_SCENE.instantiate()
		var owned_display: Dictionary = display.duplicate(true)
		owned_display["context"] = "compact" if _uses_compact_cards() else "owned"
		owned_cards_row.add_child(wrapper)
		wrapper.set_card_view(chip)
		chip.set_card(owned_display)
		chip.set_interactive(false)
		wrapper.set_orientation(_card_orientation)


func _apply_layout_mode() -> void:
	custom_minimum_size.y = 176.0 if _low_height_mode else 0.0
	layout.visible = not _low_height_mode
	compact_layout.visible = _low_height_mode
	if _low_height_mode:
		owned_cards_row = compact_cards_row
		identity_bar.visible = false
		status_bar.visible = false
		_move(name_label, compact_info_rail)
		_move(profile_label, compact_info_rail)
		_move(resources, compact_info_rail)
		_move(state_label, compact_info_rail)
		_restore_compact_info_order()
	elif _uses_center_dense_layout():
		owned_cards_row = default_cards_row
		_apply_center_dense_topology()
	else:
		owned_cards_row = default_cards_row
		_apply_side_stacked_topology()
	_apply_text_density()


func _uses_center_dense_layout() -> bool:
	return (
		not _low_height_mode
		and _card_orientation == CARD_ORIENTATION_NORMAL
	)


func _apply_center_dense_topology() -> void:
	identity_bar.visible = true
	status_bar.visible = true
	layout.add_theme_constant_override("separation", 2)
	owned_cards_scroll.custom_minimum_size.y = OWNED_CARDS_SCROLL_MIN_Y
	owned_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_move(name_label, identity_bar)
	_move(resources, identity_bar)
	_move(profile_label, status_bar)
	_move(state_label, status_bar)
	_order_child(identity_bar, name_label, 0)
	_order_child(identity_bar, identity_spacer, 1)
	_order_child(identity_bar, resources, 2)
	_order_child(status_bar, profile_label, 0)
	_order_child(status_bar, status_spacer, 1)
	_order_child(status_bar, state_label, 2)
	_order_child(layout, identity_bar, 0)
	_order_child(layout, status_bar, 1)
	_order_child(layout, owned_cards_scroll, 2)


func _apply_side_stacked_topology() -> void:
	identity_bar.visible = false
	status_bar.visible = false
	layout.add_theme_constant_override("separation", 4)
	owned_cards_scroll.custom_minimum_size = Vector2.ZERO
	owned_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_move(name_label, layout)
	_move(profile_label, layout)
	_move(resources, layout)
	_move(state_label, layout)
	_order_child(layout, name_label, 0)
	_order_child(layout, profile_label, 1)
	_order_child(layout, resources, 2)
	_order_child(layout, owned_cards_scroll, 3)
	_order_child(layout, state_label, 4)


func _move(child: Control, parent: Node) -> void:
	if child.get_parent() == parent:
		return
	if child.get_parent() != null:
		child.get_parent().remove_child(child)
	parent.add_child(child)


func _restore_compact_info_order() -> void:
	_order_child(compact_info_rail, name_label, 0)
	_order_child(compact_info_rail, profile_label, 1)
	_order_child(compact_info_rail, resources, 2)
	_order_child(compact_info_rail, state_label, 3)


func _order_child(parent: Node, child: Node, index: int) -> void:
	if child.get_parent() == parent:
		parent.move_child(child, index)


func _uses_compact_cards() -> bool:
	return _low_height_mode or _card_presentation == CARD_PRESENTATION_COMPACT


func _apply_text_density() -> void:
	var name_size: int = 20
	var small_size: int = 13
	var resource_size: int = 18
	if _low_height_mode:
		name_size = 15
		small_size = 11
		resource_size = 13
	elif _uses_center_dense_layout():
		name_size = 18
		small_size = 12
		resource_size = 15
	name_label.add_theme_font_size_override("font_size", name_size)
	profile_label.add_theme_font_size_override("font_size", small_size)
	state_label.add_theme_font_size_override("font_size", small_size)
	resources.nal_label.add_theme_font_size_override("font_size", resource_size)
	resources.vp_label.add_theme_font_size_override("font_size", resource_size)


func _state_text(player: Dictionary) -> String:
	if player.get("action_done", false):
		return "ACTION COMPLETE"
	if player.get("ready_for_action", false):
		return "MARKET COMPLETE"
	if player.get("skip_next_action", false):
		return "NEXT ACTION SKIPPED"
	return "WAITING"
