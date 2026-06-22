class_name ContactPanel
extends PanelContainer

signal command_finished(result: Dictionary)

var selected_contact_id: String = ""

@onready var owned_label: Label = %OwnedLabel
@onready var offer_options: OptionButton = %OfferOptions
@onready var description_label: Label = %DescriptionLabel
@onready var reason_label: DisabledReasonLabel = %ReasonLabel
@onready var select_button: Button = %SelectButton


func _ready() -> void:
	offer_options.item_selected.connect(_on_offer_selected)
	select_button.pressed.connect(_on_select)


func refresh(_view: Dictionary) -> void:
	var state: Dictionary = GameStateManager.get_contact_state(
		GameIds.PLAYER_HUMAN
	)
	if state["ok"]:
		var owned: Array = state["view"].get("owned_contacts", [])
		owned_label.text = (
			"Owned: none" if owned.is_empty()
			else "Owned: " + str(owned[0].get("title", ""))
		)
	var offer: Dictionary = GameStateManager.get_contact_offer(
		GameIds.PLAYER_HUMAN
	)
	offer_options.clear()
	offer_options.add_item("Choose contact")
	if not offer["ok"]:
		_show_failure(offer["error"])
		return
	for contact: Dictionary in offer["view"]["contacts"]:
		offer_options.add_item(str(contact["title"]))
		offer_options.set_item_metadata(
			offer_options.item_count - 1, contact["id"]
		)
	offer_options.visible = offer_options.item_count > 1
	select_button.visible = offer_options.visible
	if not _offer_has_selection(offer["view"]["contacts"]):
		selected_contact_id = ""
		description_label.text = "No pending contact offer."
		select_button.disabled = true
		reason_label.set_reason(ValidationErrors.OK)


func _on_offer_selected(index: int) -> void:
	selected_contact_id = (
		str(offer_options.get_item_metadata(index)) if index > 0 else ""
	)
	if selected_contact_id.is_empty():
		select_button.disabled = true
		return
	var payload: Dictionary = UICommandPayloads.contact_payload(
		selected_contact_id
	)
	var reason: String = GameStateManager.get_contact_disabled_reason(payload)
	reason_label.set_reason(reason)
	select_button.disabled = reason != ValidationErrors.OK
	description_label.text = offer_options.get_item_text(index)


func _on_select() -> void:
	if selected_contact_id.is_empty():
		reason_label.set_reason(ValidationErrors.REQUIREMENT_NOT_MET)
		return
	var result: Dictionary = GameStateManager.select_contact(
		UICommandPayloads.contact_payload(selected_contact_id)
	)
	if result["ok"]:
		selected_contact_id = ""
	command_finished.emit(result)


func _offer_has_selection(contacts: Array) -> bool:
	for contact: Dictionary in contacts:
		if contact["id"] == selected_contact_id:
			return true
	return false


func _show_failure(error: String) -> void:
	selected_contact_id = ""
	offer_options.visible = false
	select_button.visible = false
	description_label.text = "No pending contact offer."
	reason_label.set_reason(
		ValidationErrors.OK
		if error == ValidationErrors.CONTACT_OFFER_UNAVAILABLE else error
	)
