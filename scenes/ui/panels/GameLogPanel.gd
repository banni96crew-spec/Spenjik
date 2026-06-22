class_name GameLogPanel
extends PanelContainer

@onready var entries: VBoxContainer = %Entries


func refresh(view: Dictionary) -> void:
	for child: Node in entries.get_children():
		child.queue_free()
	var logs: Array = view.get("combat_log", view.get("logs", []))
	if logs.is_empty():
		var empty := Label.new()
		empty.text = "No activity yet."
		entries.add_child(empty)
		return
	for entry: Dictionary in logs:
		var button := Button.new()
		button.text = UIViewFormatters.log_entry(entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = JSON.stringify(entry.get("details", {}), "  ")
		entries.add_child(button)
