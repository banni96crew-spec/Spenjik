class_name PlayerBoard
extends PanelContainer

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const CARD_ORIENTATION_WRAPPER := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")
const CARD_ORIENTATION_NORMAL := "normal"
const CARD_ORIENTATION_SIDE_LEFT := "side_left"
const CARD_ORIENTATION_SIDE_RIGHT := "side_right"

var _card_orientation: String = CARD_ORIENTATION_NORMAL
var _low_height_mode: bool = false

@onready var layout: VBoxContainer = %Layout
@onready var compact_layout: HBoxContainer = %CompactLayout
@onready var compact_info_rail: VBoxContainer = %CompactInfoRail
@onready var compact_cards_scroll: ScrollContainer = %CompactCardsScroll
@onready var default_cards_row: HFlowContainer = %OwnedCardsRow
@onready var compact_cards_row: HBoxContainer = %CompactCardsRow
@onready var name_label: Label = %NameLabel
@onready var profile_label: Label = %ProfileLabel
@onready var resources: NalVpDisplay = %NalVpDisplay
@onready var owned_cards_row: Container = %OwnedCardsRow
@onready var state_label: Label = %StateLabel


func set_card_orientation(orientation: String) -> void:
	_card_orientation = orientation


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
	profile_label.text = str(profile.get("profile_id", "")).replace(
		"_", " "
	).capitalize()
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
		owned_display["context"] = "compact" if _low_height_mode else "owned"
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
		_move(name_label, compact_info_rail)
		_move(profile_label, compact_info_rail)
		_move(resources, compact_info_rail)
		_move(state_label, compact_info_rail)
	else:
		owned_cards_row = default_cards_row
		_move(name_label, layout)
		_move(profile_label, layout)
		_move(resources, layout)
		_move(state_label, layout)
	_apply_text_density()


func _move(child: Control, parent: Node) -> void:
	if child.get_parent() == parent:
		return
	if child.get_parent() != null:
		child.get_parent().remove_child(child)
	parent.add_child(child)


func _apply_text_density() -> void:
	var name_size: int = 15 if _low_height_mode else 20
	var small_size: int = 11 if _low_height_mode else 13
	var resource_size: int = 13 if _low_height_mode else 18
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
