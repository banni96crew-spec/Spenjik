class_name DisabledReasonLabel
extends Label


func set_reason(error: String) -> void:
	text = ErrorTextMap.to_text(error)
	visible = not text.is_empty()
