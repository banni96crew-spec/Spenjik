extends GutTest

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const WRAPPER_SCRIPT := preload("res://scenes/ui/widgets/CardOrientationWrapper.gd")


func test_normal_orientation_keeps_market_card_footprint() -> void:
	var wrapper = _wrapper(WRAPPER_SCRIPT.ORIENTATION_NORMAL)
	assert_eq(wrapper.custom_minimum_size, CardVisualTokens.MARKET_CARD_SIZE)
	assert_eq(wrapper.card_view.rotation_degrees, 0.0)
	assert_eq(wrapper.card_view.scale, Vector2.ONE)


func test_side_orientations_rotate_opposite_directions() -> void:
	var left = _wrapper(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	var right = _wrapper(WRAPPER_SCRIPT.ORIENTATION_SIDE_RIGHT)
	assert_eq(left.custom_minimum_size, WRAPPER_SCRIPT.SIDE_FOOTPRINT)
	assert_eq(right.custom_minimum_size, WRAPPER_SCRIPT.SIDE_FOOTPRINT)
	assert_eq(left.card_view.rotation_degrees, 90.0)
	assert_eq(right.card_view.rotation_degrees, -90.0)
	assert_gt(left.card_view.rotation_degrees, right.card_view.rotation_degrees)
	assert_eq(left.custom_minimum_size, Vector2(236, 172))
	assert_eq(right.custom_minimum_size, Vector2(236, 172))


func test_card_view_remains_child_of_orientation_wrapper() -> void:
	var wrapper = _wrapper(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT)
	assert_not_null(wrapper.card_view)
	assert_eq(wrapper.card_view.get_parent(), wrapper)
	assert_eq(wrapper.card_view.get_layout_size(), CardVisualTokens.MARKET_CARD_SIZE)


func test_compact_orientation_uses_compact_footprint() -> void:
	var normal = _wrapper(WRAPPER_SCRIPT.ORIENTATION_NORMAL, "compact")
	var left = _wrapper(WRAPPER_SCRIPT.ORIENTATION_SIDE_LEFT, "compact")
	var right = _wrapper(WRAPPER_SCRIPT.ORIENTATION_SIDE_RIGHT, "compact")
	assert_eq(normal.custom_minimum_size, CardVisualTokens.COMPACT_CARD_SIZE)
	assert_eq(left.custom_minimum_size, WRAPPER_SCRIPT.COMPACT_SIDE_FOOTPRINT)
	assert_eq(right.custom_minimum_size, WRAPPER_SCRIPT.COMPACT_SIDE_FOOTPRINT)
	assert_eq(left.card_view.rotation_degrees, 90.0)
	assert_eq(right.card_view.rotation_degrees, -90.0)


func _wrapper(orientation: String, context: String = "owned") -> Variant:
	var wrapper = WRAPPER_SCRIPT.new()
	add_child_autofree(wrapper)
	var card: CardView = CARD_SCENE.instantiate()
	wrapper.set_card_view(card)
	card.set_card({
		"id": "wrapped",
		"type": CardTypes.ENGINE,
		"title": "Wrapped",
		"effect_summary": "Presentation only",
		"context": context,
	})
	wrapper.set_orientation(orientation)
	return wrapper
