class_name StreetDealPanel
extends PanelContainer

signal command_finished(result: Dictionary)

var deal_id: String = ""

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var option_a: Button = %OptionA
@onready var option_b: Button = %OptionB
@onready var reason_label: DisabledReasonLabel = %ReasonLabel


func _ready() -> void:
	option_a.pressed.connect(
		func() -> void: _choose(StreetDealOptionIds.OPTION_A)
	)
	option_b.pressed.connect(
		func() -> void: _choose(StreetDealOptionIds.OPTION_B)
	)


func refresh(_view: Dictionary) -> void:
	var result: Dictionary = GameStateManager.get_street_deal_view(
		GameIds.PLAYER_HUMAN
	)
	if not result["ok"]:
		_show_failure(result["error"])
		return
	var deal: Dictionary = result["view"]["street_deal"]
	var definition: Dictionary = result["view"]["definition"]
	deal_id = str(deal.get("current_deal_id", ""))
	title_label.text = str(definition.get("title", "STREET DEAL")).to_upper()
	description_label.text = str(definition.get("description", ""))
	option_a.text = "%s\n%s" % [
		definition.get("option_a_label", "OPTION A"),
		definition.get("option_a_description", ""),
	]
	option_b.text = "%s\n%s" % [
		definition.get("option_b_label", "OPTION B"),
		definition.get("option_b_description", ""),
	]
	_set_option_state(option_a, StreetDealOptionIds.OPTION_A)
	_set_option_state(option_b, StreetDealOptionIds.OPTION_B)
	reason_label.set_reason(ValidationErrors.OK)


func _set_option_state(button: Button, option_id: String) -> void:
	var reason: String = GameStateManager.get_street_deal_disabled_reason(
		UICommandPayloads.street_deal_payload(deal_id, option_id)
	)
	button.disabled = reason != ValidationErrors.OK
	button.tooltip_text = ErrorTextMap.to_text(reason)


func _choose(option_id: String) -> void:
	if deal_id.is_empty():
		reason_label.set_reason(ValidationErrors.REQUIREMENT_NOT_MET)
		return
	command_finished.emit(GameStateManager.select_street_deal(
		UICommandPayloads.street_deal_payload(deal_id, option_id)
	))


func _show_failure(error: String) -> void:
	deal_id = ""
	title_label.text = "STREET DEAL"
	description_label.text = ""
	option_a.disabled = true
	option_b.disabled = true
	reason_label.set_reason(error)
