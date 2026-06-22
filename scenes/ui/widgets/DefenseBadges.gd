class_name DefenseBadges
extends HBoxContainer

@onready var cops_label: Label = %CopsLabel
@onready var cartel_label: Label = %CartelLabel
@onready var judge_label: Label = %JudgeLabel


func set_defense(defense: Dictionary) -> void:
	cops_label.text = "COPS %s" % (
		"ON" if defense.get("cops_active", false) else "OFF"
	)
	cartel_label.text = "CARTEL " + str(
		defense.get("cartel_state", "none")
	).to_upper()
	judge_label.text = "JUDGE " + str(
		defense.get("judge_state", "none")
	).to_upper()
