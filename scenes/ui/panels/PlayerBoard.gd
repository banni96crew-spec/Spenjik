class_name PlayerBoard
extends PanelContainer

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const CARD_ORIENTATION_WRAPPER := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")
const CARD_ORIENTATION_NORMAL := "normal"
const CARD_ORIENTATION_SIDE_LEFT := "side_left"
const CARD_ORIENTATION_SIDE_RIGHT := "side_right"

var _card_orientation: String = CARD_ORIENTATION_NORMAL

@onready var name_label: Label = %NameLabel
@onready var profile_label: Label = %ProfileLabel
@onready var resources: NalVpDisplay = %NalVpDisplay
@onready var owned_cards_row: HFlowContainer = %OwnedCardsRow
@onready var defenses: DefenseBadges = %DefenseBadges
@onready var state_label: Label = %StateLabel


func set_card_orientation(orientation: String) -> void:
	_card_orientation = orientation


func render(
	player: Dictionary,
	profile: Dictionary = {},
	card_definitions: Dictionary = {}
) -> void:
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
	defenses.set_defense(player.get("defense", {}))
	state_label.text = _state_text(player)


func _render_owned_cards(
	player: Dictionary,
	card_definitions: Dictionary
) -> void:
	for child: Node in owned_cards_row.get_children():
		child.queue_free()
	for display: Dictionary in PlayerOwnedCardsBuilder.build_owned_displays(
		player, card_definitions
	):
		var wrapper = CARD_ORIENTATION_WRAPPER.new()
		var chip: CardView = CARD_SCENE.instantiate()
		wrapper.set_orientation(_card_orientation)
		owned_cards_row.add_child(wrapper)
		wrapper.set_card_view(chip)
		chip.set_card(display)
		chip.set_interactive(false)


func _state_text(player: Dictionary) -> String:
	if player.get("action_done", false):
		return "ACTION COMPLETE"
	if player.get("ready_for_action", false):
		return "MARKET COMPLETE"
	if player.get("skip_next_action", false):
		return "NEXT ACTION SKIPPED"
	return "WAITING"
