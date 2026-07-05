class_name CardTextLayout
extends RefCounted

const FULL_TEXT_BAND_HEIGHT := 80.0
const COMPACT_TEXT_BAND_HEIGHT := 74.0
const MARKET_SPACER_HEIGHT := 50.0
const OWNED_SPACER_HEIGHT := 64.0
const COMPACT_SPACER_HEIGHT := 33.0


static func apply(
	context: String,
	title_label: Label,
	effect_label: Label,
	price_label: Label,
	text_block: Control,
	vertical_spacer: Control,
	select_button: Button
) -> void:
	var is_compact: bool = context == "compact"
	title_label.add_theme_font_size_override(
		"font_size",
		CardVisualTokens.COMPACT_TITLE_FONT
		if is_compact else CardVisualTokens.MARKET_TITLE_FONT
	)
	effect_label.add_theme_font_size_override(
		"font_size",
		CardVisualTokens.COMPACT_EFFECT_FONT
		if is_compact else CardVisualTokens.MARKET_EFFECT_FONT
	)
	price_label.add_theme_font_size_override(
		"font_size", CardVisualTokens.MARKET_PRICE_FONT
	)
	_apply_label(title_label)
	_apply_label(effect_label)
	text_block.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	text_block.custom_minimum_size.y = (
		COMPACT_TEXT_BAND_HEIGHT if is_compact else FULL_TEXT_BAND_HEIGHT
	)
	vertical_spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vertical_spacer.custom_minimum_size.y = _spacer_height(context)
	if not is_compact:
		select_button.custom_minimum_size.y = (
			CardVisualTokens.MARKET_SELECT_BUTTON_HEIGHT
		)


static func _apply_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.max_lines_visible = -1
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.custom_minimum_size.y = 0.0


static func _spacer_height(context: String) -> float:
	if context == "compact":
		return COMPACT_SPACER_HEIGHT
	if context == "owned":
		return OWNED_SPACER_HEIGHT
	return MARKET_SPACER_HEIGHT
