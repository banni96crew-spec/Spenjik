class_name CardVisualStyle
extends RefCounted


static func card_surface(
	border_color: Color,
	border_width: int,
	bg_color: Color = CardVisualTokens.SURFACE
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(CardVisualTokens.CORNER_RADIUS)
	style.set_content_margin_all(CardVisualTokens.CONTENT_MARGIN)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 2
	return style


static func art_frame(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CardVisualTokens.ART_BG
	style.border_color = border_color.darkened(0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	return style


static func title_divider(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = border_color.darkened(0.45)
	style.set_content_margin_top(0)
	style.set_content_margin_bottom(0)
	return style
