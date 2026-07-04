class_name CardTypeMarker
extends Control

const ASSET_ENGINE := "engine"
const ASSET_STATUS := "status"
const ASSET_WAR := "war"
const ASSET_DEFENSE := "defense"
const MARKER_SIZE := Vector2(18, 18)

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
	_draw_dagger_silhouette(area, [
		Vector2(0.20, 0.78), Vector2(0.28, 0.70), Vector2(0.42, 0.56),
		Vector2(0.50, 0.48), Vector2(0.54, 0.44), Vector2(0.74, 0.18),
		Vector2(0.62, 0.38), Vector2(0.34, 0.68),
	])
	_draw_dagger_silhouette(area, [
		Vector2(0.80, 0.78), Vector2(0.72, 0.70), Vector2(0.58, 0.56),
		Vector2(0.50, 0.48), Vector2(0.46, 0.44), Vector2(0.26, 0.18),
		Vector2(0.38, 0.38), Vector2(0.66, 0.68),
	])


func _draw_dagger_silhouette(area: Rect2, coords: Array[Vector2]) -> void:
	draw_colored_polygon(_points(area, coords), marker_color)


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


func _points(area: Rect2, values: Array[Vector2]) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in values:
		result.append(area.position + area.size * point)
	return result


func _square_area(area: Rect2) -> Rect2:
	var side: float = min(area.size.x, area.size.y)
	var offset: Vector2 = (area.size - Vector2(side, side)) * 0.5
	return Rect2(area.position + offset, Vector2(side, side))
