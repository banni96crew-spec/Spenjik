class_name CardOrientationWrapper
extends Control

const ORIENTATION_NORMAL := "normal"
const ORIENTATION_SIDE_LEFT := "side_left"
const ORIENTATION_SIDE_RIGHT := "side_right"
const SIDE_FOOTPRINT := Vector2(236, 172)

var orientation: String = ORIENTATION_NORMAL
var card_view: CardView


func _get_minimum_size() -> Vector2:
	return custom_minimum_size


func set_card_view(value: CardView) -> void:
	if card_view != null and card_view.get_parent() == self:
		remove_child(card_view)
	card_view = value
	add_child(card_view)
	_apply_orientation()


func set_orientation(value: String) -> void:
	orientation = value if value in [
		ORIENTATION_NORMAL, ORIENTATION_SIDE_LEFT, ORIENTATION_SIDE_RIGHT,
	] else ORIENTATION_NORMAL
	_apply_orientation()


func _apply_orientation() -> void:
	custom_minimum_size = _footprint()
	size = custom_minimum_size
	if card_view == null:
		return
	card_view.pivot_offset = Vector2.ZERO
	card_view.scale = Vector2.ONE
	card_view.rotation_degrees = 0.0
	card_view.position = Vector2.ZERO
	if orientation == ORIENTATION_NORMAL:
		return
	var card_size: Vector2 = CardVisualTokens.MARKET_CARD_SIZE
	if orientation == ORIENTATION_SIDE_LEFT:
		card_view.rotation_degrees = 90.0
		card_view.position = Vector2(card_size.y, 0.0)
	else:
		card_view.rotation_degrees = -90.0
		card_view.position = Vector2(0.0, card_size.x)


func _footprint() -> Vector2:
	return (
		CardVisualTokens.MARKET_CARD_SIZE
		if orientation == ORIENTATION_NORMAL
		else SIDE_FOOTPRINT
	)
