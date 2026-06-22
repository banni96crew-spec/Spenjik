class_name CardView
extends PanelContainer

signal card_selected(card_id: String)

const INK := Color("d8c6a2")
const MUTED := Color("8f8068")
const BLACK := Color("11100e")
const WAR_RED := Color("69261e")

var card_id: String = ""
var selected: bool = false

@onready var price_label: Label = %PriceLabel
@onready var type_label: Label = %TypeLabel
@onready var art_label: Label = %ArtLabel
@onready var title_label: Label = %TitleLabel
@onready var effect_label: Label = %EffectLabel
@onready var state_label: Label = %StateLabel
@onready var select_button: Button = %SelectButton


func _ready() -> void:
	select_button.pressed.connect(_on_pressed)


func set_card(
	data: Dictionary,
	display_price: int = -1,
	card_state: String = ""
) -> void:
	card_id = str(data.get("id", ""))
	var card_type: String = str(data.get("type", ""))
	price_label.text = str(
		display_price if display_price >= 0 else data.get("base_price", 0)
	) + " ₦"
	title_label.text = str(data.get("title", card_id)).to_upper()
	effect_label.text = str(data.get("effect_summary", ""))
	state_label.text = card_state
	var visual: Dictionary = _type_visual(card_type)
	type_label.text = visual["marker"]
	art_label.text = visual["art"]
	_apply_style(visual["accent"])
	tooltip_text = "%s\n%s" % [title_label.text, effect_label.text]


func set_selected(value: bool) -> void:
	selected = value
	select_button.text = "SELECTED" if value else "SELECT"
	queue_redraw()


func set_interactive(value: bool) -> void:
	select_button.disabled = not value


func _type_visual(card_type: String) -> Dictionary:
	match card_type:
		"engine":
			return {"marker": "⚙︎", "art": "MACHINERY", "accent": INK}
		"status":
			return {"marker": "♛", "art": "INFLUENCE", "accent": INK}
		"war":
			return {"marker": "╳", "art": "HOSTILE ACTION", "accent": WAR_RED}
		"defense":
			return {"marker": "⛨", "art": "PROTECTION", "accent": INK}
	return {"marker": "?", "art": "UNKNOWN", "accent": MUTED}


func _apply_style(accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BLACK
	style.border_color = accent
	style.set_border_width_all(2 if not selected else 4)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel", style)
	title_label.add_theme_color_override("font_color", INK)
	effect_label.add_theme_color_override("font_color", INK)
	type_label.add_theme_color_override("font_color", accent)
	price_label.add_theme_color_override("font_color", INK)


func _on_pressed() -> void:
	card_selected.emit(card_id)
