class_name MarketPanel
extends PanelContainer

signal command_finished(result: Dictionary)

const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")

var selected_card_id: String = ""

@onready var cards_row: HBoxContainer = %CardsRow
@onready var preview_label: Label = %PreviewLabel
@onready var reason_label: DisabledReasonLabel = %ReasonLabel
@onready var buy_button: Button = %BuyButton
@onready var rebuild_button: Button = %RebuildButton
@onready var end_button: Button = %EndButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	rebuild_button.pressed.connect(_on_rebuild)
	end_button.pressed.connect(_on_end_market)


func refresh(_view: Dictionary) -> void:
	_clear_cards()
	var result: Dictionary = GameStateManager.get_market_view(
		GameIds.PLAYER_HUMAN
	)
	if not result["ok"]:
		_show_failure(result["error"])
		return
	for card: Dictionary in result["view"]["cards"]:
		var widget: CardView = CARD_SCENE.instantiate()
		cards_row.add_child(widget)
		var enriched: Dictionary = _enrich_market_card(card)
		widget.set_card(enriched)
		widget.card_selected.connect(_on_card_selected)
		widget.set_selected(card["id"] == selected_card_id)
	if not _selection_exists(result["view"]["cards"]):
		selected_card_id = ""
		_clear_preview()
	end_button.disabled = bool(result["view"]["ready_for_action"])
	_refresh_rebuild()


func _on_card_selected(card_id: String) -> void:
	selected_card_id = card_id
	var price: Dictionary = GameStateManager.get_card_price_preview(
		GameIds.PLAYER_HUMAN, card_id
	)
	var reason: String = GameStateManager.get_purchase_disabled_reason(
		GameIds.PLAYER_HUMAN, card_id
	)
	if price["ok"]:
		preview_label.text = "FINAL PRICE: %d NAL\n%s" % [
			int(price["final_price"]),
			_format_modifiers(price["modifiers"]),
		]
	reason_label.set_reason(reason)
	buy_button.disabled = reason != ValidationErrors.OK
	for child: Node in cards_row.get_children():
		var widget := child as CardView
		if widget != null:
			widget.set_selected(widget.card_id == card_id)


func _enrich_market_card(card: Dictionary) -> Dictionary:
	var card_id: String = str(card.get("id", ""))
	var enriched: Dictionary = card.duplicate()
	var price: Dictionary = GameStateManager.get_card_price_preview(
		GameIds.PLAYER_HUMAN, card_id
	)
	var reason: String = GameStateManager.get_purchase_disabled_reason(
		GameIds.PLAYER_HUMAN, card_id
	)
	if price["ok"]:
		enriched["price"] = int(price["final_price"])
	enriched["disabled_reason"] = reason
	enriched["affordable"] = reason == ValidationErrors.OK
	enriched["disabled"] = reason != ValidationErrors.OK
	return enriched


func _on_buy() -> void:
	if selected_card_id.is_empty():
		reason_label.set_reason(ValidationErrors.REQUIREMENT_NOT_MET)
		return
	var result: Dictionary = GameStateManager.buy_card(
		GameIds.PLAYER_HUMAN, selected_card_id
	)
	if result["ok"]:
		selected_card_id = ""
	command_finished.emit(result)


func _refresh_rebuild() -> void:
	var reason: String = GameStateManager.get_rebuild_district_disabled_reason(
		GameIds.PLAYER_HUMAN
	)
	var preview: Dictionary = GameStateManager.get_rebuild_district_preview(
		GameIds.PLAYER_HUMAN
	)
	rebuild_button.disabled = reason != ValidationErrors.OK
	if preview["ok"]:
		rebuild_button.tooltip_text = "REBUILD: %d NAL" % int(
			preview["final_rebuild_price"]
		)
	else:
		rebuild_button.tooltip_text = ErrorTextMap.to_text(reason)


func _on_rebuild() -> void:
	command_finished.emit(GameStateManager.rebuild_district_control(
		GameIds.PLAYER_HUMAN
	))


func _on_end_market() -> void:
	command_finished.emit(GameStateManager.end_market_for_player(
		GameIds.PLAYER_HUMAN
	))


func _selection_exists(cards: Array) -> bool:
	for card: Dictionary in cards:
		if card["id"] == selected_card_id:
			return true
	return false


func _format_modifiers(modifiers: Array) -> String:
	if modifiers.is_empty():
		return "No modifiers"
	var lines: Array[String] = []
	for modifier: Dictionary in modifiers:
		lines.append("%s: %+d" % [
			str(modifier.get("source", "modifier")).replace("_", " "),
			int(modifier.get("delta", 0)),
		])
	return "\n".join(lines)


func _clear_cards() -> void:
	for child: Node in cards_row.get_children():
		child.queue_free()


func _clear_preview() -> void:
	preview_label.text = "Select a market card."
	reason_label.set_reason(ValidationErrors.OK)
	buy_button.disabled = true


func _show_failure(error: String) -> void:
	_clear_preview()
	reason_label.set_reason(error)
	end_button.disabled = true
	rebuild_button.disabled = true
