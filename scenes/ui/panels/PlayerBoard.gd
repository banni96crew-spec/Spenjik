class_name PlayerBoard
extends PanelContainer

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")

@onready var name_label: Label = %NameLabel
@onready var profile_label: Label = %ProfileLabel
@onready var resources: NalVpDisplay = %NalVpDisplay
@onready var owned_cards_row: HFlowContainer = %OwnedCardsRow
@onready var defenses: DefenseBadges = %DefenseBadges
@onready var state_label: Label = %StateLabel


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
		var chip: CardView = CARD_SCENE.instantiate()
		owned_cards_row.add_child(chip)
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
