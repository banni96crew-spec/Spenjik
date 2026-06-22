class_name ContractPanel
extends PanelContainer

signal command_finished(result: Dictionary)

var contract_id: String = ""

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var progress_label: Label = %ProgressLabel
@onready var reason_label: DisabledReasonLabel = %ReasonLabel
@onready var claim_button: Button = %ClaimButton


func _ready() -> void:
	claim_button.pressed.connect(_on_claim)


func refresh(_view: Dictionary) -> void:
	var result: Dictionary = GameStateManager.get_contract_state(
		GameIds.PLAYER_HUMAN
	)
	if not result["ok"] or result["view"]["contract"].is_empty():
		_show_empty(result.get("error", ValidationErrors.CONTRACT_NOT_SELECTED))
		return
	var contract: Dictionary = result["view"]["contract"]
	var runtime: Dictionary = contract["runtime"]
	contract_id = str(contract["id"])
	title_label.text = str(contract["title"]).to_upper()
	description_label.text = str(contract["description"])
	progress_label.text = (
		"Progress %d / %d · Deadline R%d\n%s"
		% [
			int(runtime["progress"]),
			int(contract["progress_required"]),
			int(runtime["deadline"]),
			_status(runtime),
		]
	)
	var reason: String = (
		GameStateManager.get_contract_claim_disabled_reason(
			GameIds.PLAYER_HUMAN, contract_id
		)
	)
	reason_label.set_reason(reason)
	claim_button.disabled = reason != ValidationErrors.OK


func _on_claim() -> void:
	if contract_id.is_empty():
		return
	command_finished.emit(GameStateManager.claim_contract(
		GameIds.PLAYER_HUMAN, contract_id
	))


func _status(runtime: Dictionary) -> String:
	if runtime["claimed"]:
		return "CLAIMED"
	if runtime["completed"]:
		return "COMPLETED"
	if runtime["failed"]:
		return "FAILED"
	return "IN PROGRESS"


func _show_empty(error: String) -> void:
	contract_id = ""
	title_label.text = "CONTRACT"
	description_label.text = "No selected contract."
	progress_label.text = ""
	claim_button.disabled = true
	reason_label.set_reason(error)
