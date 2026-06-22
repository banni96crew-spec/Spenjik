class_name GameOverScreen
extends PanelContainer

signal new_game_requested
signal main_menu_requested

@onready var winner_label: Label = %WinnerLabel
@onready var scores_label: Label = %ScoresLabel
@onready var summary_label: Label = %SummaryLabel


func _ready() -> void:
	%NewGameButton.pressed.connect(func() -> void: new_game_requested.emit())
	%MainMenuButton.pressed.connect(
		func() -> void: main_menu_requested.emit()
	)


func render(view: Dictionary) -> void:
	var result: Dictionary = view.get("game_result", {})
	winner_label.text = "WINNER · " + UIViewFormatters.player_name(
		str(result.get("winner_id", view.get("winner_id", "")))
	)
	var score_lines: Array[String] = []
	for score: Dictionary in result.get("final_scores", []):
		score_lines.append("%s  ·  VP %d  ·  NAL %d" % [
			UIViewFormatters.player_name(score["player_id"]),
			int(score["vp"]),
			int(score["nal"]),
		])
	scores_label.text = "\n".join(score_lines)
	summary_label.text = (
		"Turf Level %d\nRole: %s\nContract: %s\nTie-break: %s"
		% [
			int(view.get("turf_level", 0)),
			str(view.get("selected_role", {}).get("title", "")),
			str(view.get("selected_contract", {}).get("title", "")),
			str(result.get("tie_break_used", false)),
		]
	)
