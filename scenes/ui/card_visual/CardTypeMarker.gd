class_name CardTypeMarker
extends Control

const ASSET_ENGINE := "engine"
const ASSET_STATUS := "status"
const ASSET_WAR := "war"
const ASSET_DEFENSE := "defense"
const MARKER_SIZE := Vector2(18, 18)
const WAR_RETICLE_TICK_COUNT := 4

var marker_asset: String = ASSET_ENGINE
var marker_color: Color = CardVisualTokens.INK


func _ready() -> void:
	custom_minimum_size = MARKER_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _get_minimum_size() -> Vector2:
	return MARKER_SIZE


func set_marker(asset_id: String) -> void:
	marker_asset = asset_id
	queue_redraw()


func set_marker_color(value: Color) -> void:
	marker_color = value
	queue_redraw()


static func war_reticle_center() -> Vector2:
	return Vector2(0.5, 0.5)


static func war_reticle_ring_radius() -> float:
	return 0.34


static func war_reticle_center_dot_radius() -> float:
	return 0.07


static func war_reticle_tick_inner_radius() -> float:
	return 0.40


static func war_reticle_tick_outer_radius() -> float:
	return 0.50


static func war_reticle_ring_gap_degrees() -> float:
	return 18.0


static func war_reticle_tick_angles_deg() -> Array[float]:
	return [0.0, 90.0, 180.0, 270.0]


func _draw() -> void:
	var area: Rect2 = _square_area(Rect2(Vector2.ZERO, size))
	match marker_asset:
		ASSET_STATUS:
			_draw_status(area)
		ASSET_WAR:
			_draw_war(area)
		ASSET_DEFENSE:
			_draw_defense(area)
		_:
			_draw_engine(area)


func _draw_status(area: Rect2) -> void:
	var p: PackedVector2Array = _points(area, [
		Vector2(0.10, 0.80), Vector2(0.90, 0.80),
		Vector2(0.86, 0.38), Vector2(0.66, 0.58),
		Vector2(0.50, 0.20), Vector2(0.34, 0.58),
		Vector2(0.14, 0.38),
	])
	draw_colored_polygon(p, marker_color)
	draw_rect(Rect2(area.position + area.size * Vector2(0.18, 0.78),
		area.size * Vector2(0.64, 0.12)), marker_color)


func _draw_defense(area: Rect2) -> void:
	draw_colored_polygon(_points(area, [
		Vector2(0.50, 0.08), Vector2(0.84, 0.20),
		Vector2(0.78, 0.62), Vector2(0.50, 0.92),
		Vector2(0.22, 0.62), Vector2(0.16, 0.20),
	]), marker_color)


func _draw_war(area: Rect2) -> void:
	var center: Vector2 = area.position + area.size * war_reticle_center()
	var side: float = min(area.size.x, area.size.y)
	var ring_r: float = side * war_reticle_ring_radius()
	var line_w: float = max(1.5, side * 0.11)
	var gap: float = deg_to_rad(war_reticle_ring_gap_degrees())
	for i: int in WAR_RETICLE_TICK_COUNT:
		var start_a: float = TAU * float(i) / float(WAR_RETICLE_TICK_COUNT) + gap * 0.5
		var end_a: float = TAU * float(i + 1) / float(WAR_RETICLE_TICK_COUNT) - gap * 0.5
		draw_arc(center, ring_r, start_a, end_a, 10, marker_color, line_w, true)
	for angle_deg: float in war_reticle_tick_angles_deg():
		var angle: float = deg_to_rad(angle_deg)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var inner: float = side * war_reticle_tick_inner_radius()
		var outer: float = side * war_reticle_tick_outer_radius()
		draw_line(
			center + direction * inner,
			center + direction * outer,
			marker_color,
			line_w,
			true,
		)
	draw_circle(center, side * war_reticle_center_dot_radius(), marker_color)


func _draw_engine(area: Rect2) -> void:
	var c: Vector2 = area.position + area.size * 0.5
	var r: float = min(area.size.x, area.size.y) * 0.30
	var w: float = max(2.0, area.size.x * 0.13)
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0
		var d: Vector2 = Vector2(cos(a), sin(a))
		draw_line(c + d * r, c + d * (r + w), marker_color, w, true)
	draw_arc(c, r, 0.0, TAU, 24, marker_color, w, true)
	draw_circle(c, w * 0.72, marker_color)


func _points(area: Rect2, values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Variant in values:
		result.append(area.position + area.size * (point as Vector2))
	return result


func _square_area(area: Rect2) -> Rect2:
	var side: float = min(area.size.x, area.size.y)
	var offset: Vector2 = (area.size - Vector2(side, side)) * 0.5
	return Rect2(area.position + offset, Vector2(side, side))
