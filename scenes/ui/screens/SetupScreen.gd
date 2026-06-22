class_name SetupScreen
extends PanelContainer

signal setup_failed(error: String)

var selected_role_id: String = ""
var selected_turf_level: int = -1
var selected_contract_id: String = ""

@onready var seed_input: LineEdit = %SeedInput
@onready var turf_options: OptionButton = %TurfOptions
@onready var role_options: OptionButton = %RoleOptions
@onready var contract_options: OptionButton = %ContractOptions
@onready var offers_button: Button = %OffersButton
@onready var start_button: Button = %StartButton
@onready var reason_label: DisabledReasonLabel = %ReasonLabel


func _ready() -> void:
	offers_button.pressed.connect(_on_generate_offers)
	start_button.pressed.connect(_on_start)
	turf_options.item_selected.connect(_on_turf_selected)
	role_options.item_selected.connect(_on_role_selected)
	contract_options.item_selected.connect(_on_contract_selected)
	seed_input.text_changed.connect(
		func(_text: String) -> void: _invalidate_contract_offers()
	)
	_load_setup_options()


func reset() -> void:
	_invalidate_contract_offers()


func _invalidate_contract_offers() -> void:
	selected_contract_id = ""
	contract_options.clear()
	contract_options.add_item("Generate contract offers")
	reason_label.set_reason(ValidationErrors.OK)
	_update_buttons()


func build_config() -> Dictionary:
	return UICommandPayloads.setup_config(
		seed_input.text.strip_edges(),
		selected_turf_level,
		selected_role_id,
		selected_contract_id
	)


func _load_setup_options() -> void:
	turf_options.clear()
	turf_options.add_item("Choose Turf Level")
	var levels: Dictionary = GameStateManager.get_available_turf_levels()
	for level: Dictionary in levels["view"]["turf_levels"]:
		turf_options.add_item("%d · %s" % [level["level"], level["title"]])
		turf_options.set_item_metadata(
			turf_options.item_count - 1, level["level"]
		)
	role_options.clear()
	role_options.add_item("Choose role")
	var roles: Dictionary = GameStateManager.get_available_roles()
	for role: Dictionary in roles["view"]["roles"]:
		role_options.add_item(str(role["title"]))
		role_options.set_item_metadata(
			role_options.item_count - 1, role["id"]
		)
	reset()


func _on_generate_offers() -> void:
	var preview: Dictionary = UICommandPayloads.setup_preview_config(
		seed_input.text.strip_edges(),
		selected_turf_level,
		selected_role_id
	)
	if (
		str(preview["game_seed"]).is_empty()
		or selected_turf_level < 0
		or selected_role_id.is_empty()
	):
		reason_label.set_reason(ValidationErrors.REQUIREMENT_NOT_MET)
		return
	var result: Dictionary = GameStateManager.generate_contract_offers(preview)
	if not result["ok"]:
		reason_label.set_reason(result["error"])
		setup_failed.emit(result["error"])
		return
	contract_options.clear()
	contract_options.add_item("Choose contract")
	for contract: Dictionary in result["contract_offers"]:
		contract_options.add_item("%s · %s" % [
			contract["title"], contract["description"]
		])
		contract_options.set_item_metadata(
			contract_options.item_count - 1, contract["id"]
		)
	selected_contract_id = ""
	reason_label.set_reason(ValidationErrors.OK)
	_update_buttons()


func _on_start() -> void:
	var config: Dictionary = build_config()
	if not UICommandPayloads.is_setup_complete(config):
		reason_label.set_reason(ValidationErrors.REQUIREMENT_NOT_MET)
		return
	var result: Dictionary = GameStateManager.start_new_game(config)
	if not result["ok"]:
		reason_label.set_reason(result["error"])
		setup_failed.emit(result["error"])


func _on_turf_selected(index: int) -> void:
	selected_turf_level = (
		int(turf_options.get_item_metadata(index)) if index > 0 else -1
	)
	_invalidate_contract_offers()


func _on_role_selected(index: int) -> void:
	selected_role_id = (
		str(role_options.get_item_metadata(index)) if index > 0 else ""
	)
	_invalidate_contract_offers()


func _on_contract_selected(index: int) -> void:
	selected_contract_id = (
		str(contract_options.get_item_metadata(index)) if index > 0 else ""
	)
	_update_buttons()


func _update_buttons() -> void:
	offers_button.disabled = (
		seed_input.text.strip_edges().is_empty()
		or selected_turf_level < 0
		or selected_role_id.is_empty()
	)
	start_button.disabled = not UICommandPayloads.is_setup_complete(
		build_config()
	)
