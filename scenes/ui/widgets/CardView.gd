class_name CardView
extends Control

signal card_selected(card_id: String)

var card_id: String = ""
var selected: bool = false

var price_label: Label
var currency_glyph: Label
var type_marker_top: Label
var art_texture: Control
var art_placeholder: Label
var title_label: Label
var effect_label: Label
var base_price_label: Label
var state_label: Label
var count_badge: Label
var select_button: Button

var _card_surface: PanelContainer
var _art_frame: PanelContainer
var _price_row: Control
var _layout_context: String = "market"
var _hovered: bool = false
var _disabled_visual: bool = false
var _affordable: bool = true
var _type_style: Dictionary = {}
var _display_price: int = 0
var _base_price: int = 0


func _ready() -> void:
	_bind_nodes()
	currency_glyph.text = CardVisualTokens.CURRENCY_GLYPH
	select_button.pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_layout_context("market")
	_apply_visuals()


func _get_minimum_size() -> Vector2:
	return get_layout_size()


func _bind_nodes() -> void:
	if price_label != null:
		return
	price_label = %PriceLabel
	currency_glyph = %CurrencyGlyph
	type_marker_top = %TypeMarkerTop
	art_texture = %ArtTexture
	art_placeholder = %ArtPlaceholder
	title_label = %TitleLabel
	effect_label = %EffectLabel
	base_price_label = %BasePriceLabel
	state_label = %StateLabel
	count_badge = %CountBadge
	select_button = %SelectButton
	_card_surface = %CardSurface
	_art_frame = %ArtFrame
	_price_row = price_label.get_parent()


func set_card(
	data: Dictionary,
	display_price: int = -1,
	card_state: String = ""
) -> void:
	_bind_nodes()
	card_id = str(data.get("id", ""))
	var card_type: String = str(data.get("type", ""))
	_type_style = CardTypeStyleMap.style_for_type(card_type)
	_base_price = int(data.get("base_price", 0))
	_display_price = _resolve_display_price(data, display_price)
	_affordable = bool(data.get("affordable", true))
	_disabled_visual = bool(data.get("disabled", false))
	title_label.text = str(data.get("title", card_id)).to_upper()
	effect_label.text = str(data.get("effect_summary", ""))
	type_marker_top.text = str(_type_style.get("marker", "?"))
	art_placeholder.text = str(_type_style.get("art", ""))
	price_label.text = str(_display_price)
	_update_base_price_label()
	_update_state_label(card_state)
	if data.has("selected"):
		set_selected(bool(data.get("selected", false)))
	_apply_layout_context(str(data.get("context", "market")))
	_update_count_badge(data)
	if _layout_context == "compact":
		base_price_label.visible = false
	_update_art_texture()
	tooltip_text = "%s\n%s" % [title_label.text, effect_label.text]
	_apply_visuals()


func get_layout_size() -> Vector2:
	return (
		CardVisualTokens.COMPACT_CARD_SIZE
		if _layout_context == "compact"
		else CardVisualTokens.MARKET_CARD_SIZE
	)


func _apply_layout_context(context: String) -> void:
	_layout_context = (
		"compact" if context == "compact"
		else "owned" if context == "owned"
		else "market"
	)
	var card_size: Vector2 = get_layout_size()
	custom_minimum_size = card_size
	size = card_size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var is_compact: bool = _layout_context == "compact"
	var is_owned: bool = _layout_context == "owned"
	_price_row.visible = not is_compact and not is_owned
	select_button.visible = not is_compact and not is_owned
	type_marker_top.visible = true
	_art_frame.custom_minimum_size = (
		CardVisualTokens.COMPACT_CARD_SIZE
		if is_compact else CardVisualTokens.MARKET_CARD_SIZE
	)
	art_placeholder.visible = true
	title_label.visible = true
	effect_label.visible = true
	var title_size: int = (
		CardVisualTokens.COMPACT_TITLE_FONT
		if is_compact else CardVisualTokens.MARKET_TITLE_FONT
	)
	var effect_size: int = (
		CardVisualTokens.COMPACT_EFFECT_FONT
		if is_compact else CardVisualTokens.MARKET_EFFECT_FONT
	)
	var price_size: int = CardVisualTokens.MARKET_PRICE_FONT
	title_label.add_theme_font_size_override("font_size", title_size)
	effect_label.add_theme_font_size_override("font_size", effect_size)
	price_label.add_theme_font_size_override("font_size", price_size)
	title_label.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	effect_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	title_label.custom_minimum_size.y = 24 if not is_compact else 18
	effect_label.custom_minimum_size.y = 34 if not is_compact else 28
	title_label.max_lines_visible = 2
	effect_label.max_lines_visible = 3
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if not is_compact:
		select_button.custom_minimum_size.y = CardVisualTokens.MARKET_SELECT_BUTTON_HEIGHT


func set_selected(value: bool) -> void:
	selected = value
	select_button.text = "SELECTED" if value else "SELECT"
	_apply_visuals()


func set_interactive(value: bool) -> void:
	select_button.disabled = not value


func _resolve_display_price(data: Dictionary, display_price: int) -> int:
	if display_price >= 0:
		return display_price
	if data.has("price"):
		return int(data.get("price", 0))
	if data.has("final_price"):
		return int(data.get("final_price", 0))
	return _base_price


func _update_count_badge(data: Dictionary) -> void:
	var count: int = int(data.get("count", 1))
	var show_badge: bool = _layout_context != "market" and count > 1
	count_badge.visible = show_badge
	if show_badge:
		count_badge.text = "x%d" % count


func _update_base_price_label() -> void:
	var show_base: bool = _base_price > 0 and _display_price != _base_price
	base_price_label.visible = false
	if show_base:
		base_price_label.text = "BASE %d" % _base_price


func _update_state_label(card_state: String) -> void:
	state_label.text = card_state
	state_label.visible = (
		not card_state.is_empty() and _layout_context != "market"
	)


func _update_art_texture() -> void:
	var path: String = "res://assets/cards/illustrations/card_%s.png" % card_id
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	art_texture.set("texture", texture)
	art_texture.visible = texture != null
	art_placeholder.visible = texture == null


func _apply_visuals() -> void:
	var accent: Color = _type_style.get("accent", CardVisualTokens.INK)
	var border: Color = _type_style.get("border", CardVisualTokens.INK)
	if _hovered and not _disabled_visual:
		border = border.lerp(CardVisualTokens.HOVER_BORDER_BOOST, 0.35)
	var border_width: int = (
		CardVisualTokens.BORDER_SELECTED if selected else CardVisualTokens.BORDER_NORMAL
	)
	_card_surface.add_theme_stylebox_override(
		"panel", CardVisualStyle.card_surface(border, border_width)
	)
	_art_frame.add_theme_stylebox_override(
		"panel", CardVisualStyle.art_frame(border)
	)
	title_label.add_theme_color_override("font_color", CardVisualTokens.INK)
	effect_label.add_theme_color_override("font_color", CardVisualTokens.INK)
	type_marker_top.add_theme_color_override("font_color", accent)
	art_placeholder.add_theme_color_override("font_color", CardVisualTokens.GRIME)
	count_badge.add_theme_color_override("font_color", CardVisualTokens.INK)
	var price_color: Color = (
		CardVisualTokens.UNAVAILABLE_PRICE
		if not _affordable else CardVisualTokens.INK
	)
	price_label.add_theme_color_override("font_color", price_color)
	currency_glyph.add_theme_color_override("font_color", price_color)
	_card_surface.modulate = (
		CardVisualTokens.DIMMED_MODULATE if _disabled_visual else Color.WHITE
	)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visuals()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visuals()


func _on_pressed() -> void:
	card_selected.emit(card_id)
