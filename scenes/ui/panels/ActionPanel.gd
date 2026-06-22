class_name ActionPanel
extends PanelContainer

signal command_finished(result: Dictionary)

var selected_card_id: String = ""
var selected_target_id: String = ""
var selected_mode: String = ""
var selected_engine_target_card_id: String = ""
var selected_modifiers: Array[String] = []
var _view: Dictionary = {}

@onready var card_options: OptionButton = %CardOptions
@onready var target_options: OptionButton = %TargetOptions
@onready var mode_options: OptionButton = %ModeOptions
@onready var engine_options: OptionButton = %EngineOptions
@onready var insider_check: CheckBox = %InsiderCheck
@onready var preview_label: Label = %PreviewLabel
@onready var reason_label: DisabledReasonLabel = %ReasonLabel
@onready var execute_button: Button = %ExecuteButton


func _ready() -> void:
	card_options.item_selected.connect(_on_card_selected)
	target_options.item_selected.connect(_on_target_selected)
	mode_options.item_selected.connect(_on_mode_selected)
	engine_options.item_selected.connect(_on_engine_selected)
	insider_check.toggled.connect(_on_insider_toggled)
	execute_button.pressed.connect(_on_execute)
	%DiscardButton.pressed.connect(_on_discard)
	%EndButton.pressed.connect(_on_end_action)
	%CancelButton.pressed.connect(clear_selection)


func refresh(view: Dictionary) -> void:
	_view = view
	var hand: Array = _human_player().get("hand", [])
	if not hand.has(selected_card_id):
		clear_selection()
	_fill_card_options(hand)
	_refresh_controls()


func clear_selection() -> void:
	selected_card_id = ""
	selected_target_id = ""
	selected_mode = ""
	selected_engine_target_card_id = ""
	selected_modifiers.clear()


func build_payload() -> Dictionary:
	return UICommandPayloads.attack_payload(
		selected_card_id, selected_target_id, selected_mode,
		selected_modifiers, selected_engine_target_card_id
	)


func _fill_card_options(hand: Array) -> void:
	card_options.clear()
	card_options.add_item("Choose War card")
	for card_id: String in hand:
		if card_id == GameIds.CARD_INSIDER:
			continue
		card_options.add_item(_card_title(card_id))
		card_options.set_item_metadata(card_options.item_count - 1, card_id)
	_select_metadata(card_options, selected_card_id)


func _refresh_controls() -> void:
	_fill_modes()
	_fill_targets()
	_fill_engine_targets()
	var payload: Dictionary = build_payload()
	var complete: bool = UICommandPayloads.is_attack_complete(payload)
	var reason: String = (
		GameStateManager.get_action_disabled_reason(payload)
		if complete else ValidationErrors.REQUIREMENT_NOT_MET
	)
	reason_label.set_reason(reason)
	execute_button.disabled = reason != ValidationErrors.OK
	%DiscardButton.disabled = selected_card_id.is_empty()
	insider_check.visible = (
		selected_card_id == GameIds.CARD_THUG
		and _human_player().get("hand", []).has(GameIds.CARD_INSIDER)
	)
	if complete:
		_show_preview(GameStateManager.get_combat_preview(payload))
	else:
		preview_label.text = "Complete card, target, mode and target-card choices."


func _fill_modes() -> void:
	mode_options.clear()
	mode_options.add_item("No mode")
	var modes: Array[String] = []
	if selected_card_id == GameIds.CARD_BRUISER:
		modes = [AttackModes.STEAL_NAL, AttackModes.DESTROY_STASH]
	elif selected_card_id == GameIds.CARD_CLEANER:
		modes = [AttackModes.STEAL_NAL, AttackModes.DESTROY_WORKSHOP]
	elif selected_card_id == GameIds.CARD_FEDERAL_RAID:
		modes = [AttackModes.DESTROY_DISTRICT]
		selected_mode = AttackModes.DESTROY_DISTRICT
	for mode: String in modes:
		mode_options.add_item(mode.replace("_", " ").capitalize())
		mode_options.set_item_metadata(mode_options.item_count - 1, mode)
	mode_options.visible = not modes.is_empty()
	_select_metadata(mode_options, selected_mode)


func _fill_targets() -> void:
	target_options.clear()
	target_options.add_item("Choose target")
	if selected_card_id.is_empty():
		return
	var result: Dictionary = GameStateManager.get_valid_targets(build_payload())
	for target_id: String in result.get("target_ids", []):
		target_options.add_item(UIViewFormatters.player_name(target_id))
		target_options.set_item_metadata(target_options.item_count - 1, target_id)
	_select_metadata(target_options, selected_target_id)


func _fill_engine_targets() -> void:
	engine_options.clear()
	engine_options.add_item("Choose Engine card")
	engine_options.visible = selected_card_id == GameIds.CARD_SABOTEUR
	if not engine_options.visible or selected_target_id.is_empty():
		return
	var result: Dictionary = GameStateManager.get_valid_engine_targets(
		GameIds.PLAYER_HUMAN, selected_target_id
	)
	for card_id: String in result.get("engine_target_card_ids", []):
		engine_options.add_item(_card_title(card_id))
		engine_options.set_item_metadata(engine_options.item_count - 1, card_id)
	_select_metadata(engine_options, selected_engine_target_card_id)


func _show_preview(preview: Dictionary) -> void:
	if not preview["ok"]:
		preview_label.text = ErrorTextMap.to_text(preview["error"])
		return
	preview_label.text = (
		"Blocked: %s · Steal: %d · Destroy: %s\nConsumes: %s"
		% [
			str(preview["would_be_blocked"]),
			int(preview["stealable_nal"]),
			str(preview["would_destroy"]),
			", ".join(preview["cards_that_would_be_consumed"]),
		]
	)


func _on_card_selected(index: int) -> void:
	selected_card_id = str(card_options.get_item_metadata(index)) if index > 0 else ""
	selected_target_id = ""
	selected_mode = ""
	selected_engine_target_card_id = ""
	selected_modifiers.clear()
	insider_check.button_pressed = false
	_refresh_controls()


func _on_target_selected(index: int) -> void:
	selected_target_id = str(target_options.get_item_metadata(index)) if index > 0 else ""
	selected_engine_target_card_id = ""
	_refresh_controls()


func _on_mode_selected(index: int) -> void:
	selected_mode = str(mode_options.get_item_metadata(index)) if index > 0 else ""
	selected_target_id = ""
	_refresh_controls()


func _on_engine_selected(index: int) -> void:
	selected_engine_target_card_id = (
		str(engine_options.get_item_metadata(index)) if index > 0 else ""
	)
	_refresh_controls()


func _on_insider_toggled(enabled: bool) -> void:
	selected_modifiers = [GameIds.CARD_INSIDER] if enabled else []
	_refresh_controls()


func _on_execute() -> void:
	if not UICommandPayloads.is_attack_complete(build_payload()):
		reason_label.set_reason(ValidationErrors.REQUIREMENT_NOT_MET)
		return
	var result: Dictionary = GameStateManager.execute_attack(build_payload())
	if result["ok"]:
		clear_selection()
	command_finished.emit(result)


func _on_discard() -> void:
	if selected_card_id.is_empty():
		return
	var result: Dictionary = GameStateManager.discard_war_card(
		GameIds.PLAYER_HUMAN, selected_card_id
	)
	if result["ok"]:
		clear_selection()
	command_finished.emit(result)


func _on_end_action() -> void:
	var result: Dictionary = GameStateManager.end_action_for_player(
		GameIds.PLAYER_HUMAN
	)
	if result["ok"]:
		clear_selection()
	command_finished.emit(result)


func _human_player() -> Dictionary:
	for player: Dictionary in _view.get("players", []):
		if player.get("id") == GameIds.PLAYER_HUMAN:
			return player
	return {}


func _card_title(card_id: String) -> String:
	return str(
		_view.get("card_definitions", {}).get(card_id, {}).get("title", card_id)
	)


func _select_metadata(options: OptionButton, value: String) -> void:
	for index: int in options.item_count:
		if str(options.get_item_metadata(index)) == value:
			options.select(index)
			return
