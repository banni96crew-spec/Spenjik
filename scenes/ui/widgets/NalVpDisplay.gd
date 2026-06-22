class_name NalVpDisplay
extends HBoxContainer

@onready var nal_label: Label = %NalLabel
@onready var vp_label: Label = %VpLabel


func set_values(nal: int, vp: int) -> void:
	nal_label.text = "NAL %d" % nal
	vp_label.text = "VP %d" % vp
