class_name GameScreen
extends Control

signal command_failed(error: String)

@onready var round_label: Label = %RoundLabel
@onready var phase_label: Label = %PhaseLabel
@onready var active_label: Label = %ActiveLabel
@onready var income_button: Button = %IncomeButton
@onready var busy_label: Label = %BusyLabel
@onready var error_label: DisabledReasonLabel = %ErrorLabel
@onready var player_boards: GridContainer = %PlayerBoards
@onready var market_panel: MarketPanel = %MarketPanel
@onready var action_panel: ActionPanel = %ActionPanel
@onready var street_deal_panel: StreetDealPanel = %StreetDealPanel
@onready var contract_panel: ContractPanel = %ContractPanel
@onready var contact_panel: ContactPanel = %ContactPanel
@onready var game_log_panel: GameLogPanel = %GameLogPanel


func _ready() -> void:
	income_button.pressed.connect(_on_advance_income)
	for panel: Node in [
		market_panel, action_panel, street_deal_panel,
		contract_panel, contact_panel,
	]:
		panel.command_finished.connect(_handle_result)


func refresh() -> void:
	var result: Dictionary = GameStateManager.get_view()
	if not result["ok"]:
		_show_error(result["error"])
		return
	var view: Dictionary = result["view"]
	round_label.text = "ROUND %d / 15" % int(view["round"])
	phase_label.text = UIViewFormatters.phase_name(view["current_phase"])
	active_label.text = _active_text(view)
	_render_players(view)
	_set_phase_visibility(str(view["current_phase"]))
	market_panel.refresh(view)
	action_panel.refresh(view)
	street_deal_panel.refresh(view)
	contract_panel.refresh(view)
	contact_panel.refresh(view)
	game_log_panel.refresh(view)
	busy_label.visible = (
		not str(view["active_action_player_id"]).is_empty()
		and view["active_action_player_id"] != GameIds.PLAYER_HUMAN
	)


func clear_phase_selection() -> void:
	action_panel.clear_selection()


func show_error(error: String) -> void:
	_show_error(error)


func _render_players(view: Dictionary) -> void:
	var profiles: Dictionary = {}
	for profile: Dictionary in view.get("ai_bosses", []):
		profiles[profile["assigned_player_id"]] = profile
	var players: Array = view["players"]
	for index: int in mini(players.size(), player_boards.get_child_count()):
		var board: PlayerBoard = player_boards.get_child(index)
		board.render(players[index], profiles.get(players[index]["id"], {}))


func _set_phase_visibility(phase: String) -> void:
	income_button.visible = phase == PhaseIds.INCOME
	market_panel.visible = phase == PhaseIds.MARKET
	action_panel.visible = phase == PhaseIds.ACTION
	street_deal_panel.visible = phase == PhaseIds.STREET_DEAL


func _active_text(view: Dictionary) -> String:
	var active: String = str(view["active_action_player_id"])
	return (
		"ACTIVE: " + UIViewFormatters.player_name(active)
		if not active.is_empty() else "RESOLVE THE CURRENT PHASE"
	)


func _on_advance_income() -> void:
	_handle_result(GameStateManager.advance_phase())


func _handle_result(result: Dictionary) -> void:
	if result["ok"]:
		error_label.set_reason(ValidationErrors.OK)
		refresh()
	else:
		_show_error(result["error"])
		refresh()


func _show_error(error: String) -> void:
	error_label.set_reason(error)
	command_failed.emit(error)
