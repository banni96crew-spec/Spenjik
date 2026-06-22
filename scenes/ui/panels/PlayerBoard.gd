class_name PlayerBoard
extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var profile_label: Label = %ProfileLabel
@onready var resources: NalVpDisplay = %NalVpDisplay
@onready var engine_label: Label = %EngineLabel
@onready var status_label: Label = %StatusLabel
@onready var defenses: DefenseBadges = %DefenseBadges
@onready var state_label: Label = %StateLabel


func render(player: Dictionary, profile: Dictionary = {}) -> void:
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
	engine_label.text = "ENGINE\n" + UIViewFormatters.card_count_lines(
		player.get("engine", {})
	)
	status_label.text = "STATUS\n" + UIViewFormatters.card_count_lines(
		player.get("status_buildings", {})
	)
	defenses.set_defense(player.get("defense", {}))
	state_label.text = _state_text(player)


func _state_text(player: Dictionary) -> String:
	if player.get("action_done", false):
		return "ACTION COMPLETE"
	if player.get("ready_for_action", false):
		return "MARKET COMPLETE"
	if player.get("skip_next_action", false):
		return "NEXT ACTION SKIPPED"
	return "WAITING"
