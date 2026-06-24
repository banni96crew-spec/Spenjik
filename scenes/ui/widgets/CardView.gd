class_name CardView
extends PanelContainer

signal card_selected(card_id: String)

var card_id: String = ""
var selected: bool = false

var price_label: Label
var currency_glyph: Label
var type_marker_top: Label
var type_marker_bottom: Label
var art_placeholder: Label
var title_label: Label
var effect_label: Label
var base_price_label: Label
var state_label: Label
var select_button: Button

var _card_surface: PanelContainer
var _art_frame: PanelContainer
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
	add_theme_stylebox_override("panel", CardVisualStyle.card_surface(
		Color.TRANSPARENT, 0, Color.TRANSPARENT
	))
	_apply_visuals()


func _bind_nodes() -> void:
	if price_label != null:
		return
	price_label = %PriceLabel
	currency_glyph = %CurrencyGlyph
	type_marker_top = %TypeMarkerTop
	type_marker_bottom = %TypeMarkerBottom
	art_placeholder = %ArtPlaceholder
	title_label = %TitleLabel
	effect_label = %EffectLabel
	base_price_label = %BasePriceLabel
	state_label = %StateLabel
	select_button = %SelectButton
	_card_surface = %CardSurface
	_art_frame = %ArtFrame


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
	if data.has("disabled_reason"):
		var reason: String = str(data.get("disabled_reason", ""))
		_disabled_visual = reason != ValidationErrors.OK
	title_label.text = str(data.get("title", card_id)).to_upper()
	effect_label.text = str(data.get("effect_summary", ""))
	var marker: String = str(_type_style.get("marker", "?"))
	type_marker_top.text = marker
	type_marker_bottom.text = marker
	art_placeholder.text = str(_type_style.get("art", ""))
	price_label.text = str(_display_price)
	_update_base_price_label()
	_update_state_label(data, card_state)
	if data.has("selected"):
		set_selected(bool(data.get("selected", false)))
	tooltip_text = "%s\n%s" % [title_label.text, effect_label.text]
	_apply_visuals()


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


func _update_base_price_label() -> void:
	var show_base: bool = _base_price > 0 and _display_price != _base_price
	base_price_label.visible = show_base
	if show_base:
		base_price_label.text = "BASE %d" % _base_price


func _update_state_label(data: Dictionary, card_state: String) -> void:
	var text: String = card_state
	if text.is_empty() and data.has("disabled_reason"):
		text = ErrorTextMap.to_text(str(data.get("disabled_reason", "")))
	state_label.text = text
	state_label.visible = not text.is_empty()


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
	type_marker_bottom.add_theme_color_override("font_color", accent)
	art_placeholder.add_theme_color_override("font_color", CardVisualTokens.GRIME)
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
