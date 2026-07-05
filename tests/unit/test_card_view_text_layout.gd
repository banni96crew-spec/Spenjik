extends GutTest

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")
const THEME := preload("res://themes/main_theme.tres")
const CONTEXTS: Array[String] = ["market", "owned", "compact"]
const EPS := 0.75


func test_canonical_diagnostic_cases_match_current_resources() -> void:
	assert_eq(_longest_title().id, GameIds.CARD_WORKSHOP)
	assert_eq(_longest_effect().id, GameIds.CARD_CARTEL)
	assert_eq(_worst_combined().id, GameIds.CARD_CARTEL)


func test_all_canonical_cards_fit_text_layout_in_all_contexts() -> void:
	var host: Control = _host()
	for context: String in CONTEXTS:
		for definition: CardDefinition in CardCatalog.get_all():
			var card: CardView = _card(host, definition, context)
			await _settle_layout()
			_assert_text_semantics(card, definition)
			_assert_text_presentation(card)
			_assert_text_fits(card.title_label)
			_assert_text_fits(card.effect_label)
			_assert_text_geometry(card, context)
			_assert_full_card_art_coverage(card)
			host.remove_child(card)
			card.free()


func _host() -> Control:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	host.theme = THEME
	add_child_autofree(host)
	return host


func _card(
	host: Control,
	definition: CardDefinition,
	context: String
) -> CardView:
	var card: CardView = CARD_SCENE.instantiate()
	host.add_child(card)
	var display: Dictionary = {
		"id": definition.id,
		"type": definition.type,
		"title": definition.title,
		"base_price": definition.base_price,
		"effect_summary": definition.effect_summary,
		"context": context,
	}
	if context != "market":
		display["count"] = 2
	card.set_card(display)
	return card


func _assert_text_semantics(
	card: CardView,
	definition: CardDefinition
) -> void:
	assert_eq(card.title_label.text, definition.title.to_upper())
	assert_eq(card.effect_label.text, definition.effect_summary)


func _assert_text_presentation(card: CardView) -> void:
	for label: Label in [card.title_label, card.effect_label]:
		assert_eq(label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
		assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
		assert_eq(label.max_lines_visible, -1)
		assert_eq(label.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)


func _assert_text_fits(label: Label) -> void:
	var required_height: float = _required_label_height(label)
	assert_lte(required_height, label.size.y + EPS, label.text)
	assert_eq(label.get_visible_line_count(), label.get_line_count(), label.text)


func _assert_text_geometry(card: CardView, context: String) -> void:
	var card_rect: Rect2 = card.get_global_rect()
	var title_rect: Rect2 = card.title_label.get_global_rect()
	var effect_rect: Rect2 = card.effect_label.get_global_rect()
	var title_center_y: float = title_rect.get_center().y - card_rect.position.y
	assert_between(
		title_center_y,
		card_rect.size.y * 0.35,
		card_rect.size.y * 0.65,
		"Title must stay in central visual zone"
	)
	assert_gte(effect_rect.position.y, title_rect.end.y - EPS)
	assert_false(_overlaps(title_rect, effect_rect))
	assert_true(_covers(card_rect, title_rect), "Title outside card")
	assert_true(_covers(card_rect, effect_rect), "Effect outside card")
	_assert_no_text_neighbor_overlap(card, context, title_rect, effect_rect)


func _assert_no_text_neighbor_overlap(
	card: CardView,
	context: String,
	title_rect: Rect2,
	effect_rect: Rect2
) -> void:
	var controls: Array[Control] = [
		card.get_node("CardSurface/OverlayMargin/Layout/TopBar") as Control,
	]
	if context == "market":
		controls.append(card.select_button)
	else:
		controls.append(
			card.get_node("CardSurface/OverlayMargin/Layout/BottomBar") as Control
		)
		controls.append(card.count_badge)
	for control: Control in controls:
		if control.visible and control.size.length() > 0.0:
			var rect: Rect2 = control.get_global_rect()
			assert_false(_overlaps(title_rect, rect), control.name)
			assert_false(_overlaps(effect_rect, rect), control.name)


func _assert_full_card_art_coverage(card: CardView) -> void:
	var card_rect: Rect2 = card.get_global_rect()
	var art_frame: Control = card.get_node("%ArtFrame") as Control
	var art_texture: Control = card.get_node("%ArtTexture") as Control
	var art_frame_rect: Rect2 = art_frame.get_global_rect()
	var art_texture_rect: Rect2 = art_texture.get_global_rect()
	assert_true(art_texture.visible)
	assert_true(_covers(art_frame_rect, card_rect), "ArtFrame no longer full-card")
	assert_true(_covers(art_texture_rect, art_frame_rect), "ArtTexture no longer full-card")


func _required_label_height(label: Label) -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	return font.get_height(font_size) * float(label.get_line_count())


func _covers(outer: Rect2, inner: Rect2) -> bool:
	return (
		outer.position.x <= inner.position.x + EPS
		and outer.position.y <= inner.position.y + EPS
		and outer.end.x + EPS >= inner.end.x
		and outer.end.y + EPS >= inner.end.y
	)


func _overlaps(a: Rect2, b: Rect2) -> bool:
	return (
		a.position.x < b.end.x - EPS
		and a.end.x > b.position.x + EPS
		and a.position.y < b.end.y - EPS
		and a.end.y > b.position.y + EPS
	)


func _longest_title() -> CardDefinition:
	var result: CardDefinition = null
	for definition: CardDefinition in CardCatalog.get_all():
		if result == null or definition.title.length() > result.title.length():
			result = definition
	return result


func _longest_effect() -> CardDefinition:
	var result: CardDefinition = null
	for definition: CardDefinition in CardCatalog.get_all():
		if (
			result == null
			or definition.effect_summary.length() > result.effect_summary.length()
		):
			result = definition
	return result


func _worst_combined() -> CardDefinition:
	var result: CardDefinition = null
	for definition: CardDefinition in CardCatalog.get_all():
		var current_score: int = (
			definition.title.length() + definition.effect_summary.length()
		)
		var result_score: int = (
			0 if result == null
			else result.title.length() + result.effect_summary.length()
		)
		if result == null or current_score > result_score:
			result = definition
	return result


func _settle_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
