class_name PlayerBoard
extends PanelContainer

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const CARD_ORIENTATION_WRAPPER := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")
const CARD_STRIP := preload("res://scenes/ui/helpers/PlayerBoardCardStrip.gd")
const LAYOUT_CHROME := preload("res://scenes/ui/helpers/PlayerBoardLayoutChrome.gd")
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
@onready var default_cards_column: VBoxContainer = %OwnedCardsColumn
@onready var compact_cards_row: HBoxContainer = %CompactCardsRow
@onready var compact_cards_column: VBoxContainer = %CompactCardsColumn
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
	CARD_STRIP.clear_containers(_all_card_containers())
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
	var strip_mode: String = CARD_STRIP.mode_for_orientation(_card_orientation)
	if _low_height_mode:
		owned_cards_row = CARD_STRIP.apply_topology(
			compact_cards_scroll,
			compact_cards_row,
			compact_cards_column,
			strip_mode,
		)
		identity_bar.visible = false
		status_bar.visible = false
		LAYOUT_CHROME.apply_compact_rail(self)
	elif _uses_center_dense_layout():
		owned_cards_row = CARD_STRIP.apply_topology(
			owned_cards_scroll,
			default_cards_row,
			default_cards_column,
			strip_mode,
		)
		LAYOUT_CHROME.apply_center_dense(self)
	else:
		owned_cards_row = CARD_STRIP.apply_topology(
			owned_cards_scroll,
			default_cards_row,
			default_cards_column,
			strip_mode,
		)
		LAYOUT_CHROME.apply_side_stacked(self)
	_apply_text_density()


func _all_card_containers() -> Array:
	return [
		default_cards_row,
		default_cards_column,
		compact_cards_row,
		compact_cards_column,
	]


func _uses_center_dense_layout() -> bool:
	return (
		not _low_height_mode
		and _card_orientation == CARD_ORIENTATION_NORMAL
	)


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
