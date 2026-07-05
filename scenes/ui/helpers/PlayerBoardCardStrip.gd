class_name PlayerBoardCardStrip
extends RefCounted

const MODE_HORIZONTAL := "horizontal"
const MODE_VERTICAL := "vertical"


static func mode_for_orientation(orientation: String) -> String:
	if orientation in ["side_left", "side_right"]:
		return MODE_VERTICAL
	return MODE_HORIZONTAL


static func apply_topology(
	scroll: ScrollContainer,
	hbox: BoxContainer,
	vbox: BoxContainer,
	mode: String
) -> BoxContainer:
	var vertical: bool = mode == MODE_VERTICAL
	hbox.visible = not vertical
	vbox.visible = vertical
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
		if vertical else ScrollContainer.SCROLL_MODE_AUTO
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
		if vertical else ScrollContainer.SCROLL_MODE_DISABLED
	)
	return vbox if vertical else hbox


static func clear_containers(containers: Array) -> void:
	for container: Variant in containers:
		if container == null:
			continue
		for child: Node in (container as Container).get_children():
			(container as Container).remove_child(child)
			child.free()
