class_name GameScreen
extends Control

signal command_failed(error: String)

@onready var round_label: Label = %RoundLabel
@onready var phase_label: Label = %PhaseLabel
@onready var active_label: Label = %ActiveLabel
@onready var income_button: Button = %IncomeButton
@onready var busy_label: Label = %BusyLabel
@onready var error_label: DisabledReasonLabel = %ErrorLabel
@onready var case_file_toggle_button: Button = %CaseFileToggleButton
@onready var human_board: PlayerBoard = %HumanBoard
@onready var ai_board_1: PlayerBoard = %AiBoard1
@onready var ai_board_2: PlayerBoard = %AiBoard2
@onready var ai_board_3: PlayerBoard = %AiBoard3
@onready var top_opponent_zone: Control = %TopOpponentZone
@onready var center_table: Control = %CenterTable
@onready var human_zone: Control = %HumanZone
@onready var side_info_column: Control = %SideInfoColumn
@onready var market_panel: MarketPanel = %MarketPanel
@onready var action_panel: ActionPanel = %ActionPanel
@onready var street_deal_panel: StreetDealPanel = %StreetDealPanel
@onready var contract_panel: ContractPanel = %ContractPanel
@onready var contact_panel: ContactPanel = %ContactPanel
@onready var game_log_panel: GameLogPanel = %GameLogPanel

var _case_file_visible: bool = false


func _ready() -> void:
	human_board.set_card_orientation(PlayerBoard.CARD_ORIENTATION_NORMAL)
	ai_board_1.set_card_orientation(PlayerBoard.CARD_ORIENTATION_SIDE_LEFT)
	ai_board_2.set_card_orientation(PlayerBoard.CARD_ORIENTATION_NORMAL)
	ai_board_3.set_card_orientation(PlayerBoard.CARD_ORIENTATION_SIDE_RIGHT)
	human_board.set_card_presentation(PlayerBoard.CARD_PRESENTATION_FULL)
	ai_board_1.set_card_presentation(PlayerBoard.CARD_PRESENTATION_COMPACT)
	ai_board_2.set_card_presentation(PlayerBoard.CARD_PRESENTATION_COMPACT)
	ai_board_3.set_card_presentation(PlayerBoard.CARD_PRESENTATION_COMPACT)
	income_button.pressed.connect(_on_advance_income)
	case_file_toggle_button.pressed.connect(_on_case_file_toggle_pressed)
	for panel: Node in [
		market_panel, action_panel, street_deal_panel,
		contract_panel, contact_panel,
	]:
		panel.command_finished.connect(_handle_result)
	set_case_file_visible(false)


func refresh() -> void:
	var result: Dictionary = GameStateManager.get_view()
	if not result["ok"]:
		_show_error(result["error"])
		return
	var view: Dictionary = result["view"]
	_apply_responsive_layout()
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


func set_case_file_visible(value: bool) -> void:
	_case_file_visible = value
	side_info_column.visible = value
	case_file_toggle_button.text = "CASE <" if value else "CASE >"


func is_case_file_visible() -> bool:
	return _case_file_visible


func _render_players(view: Dictionary) -> void:
	var profiles: Dictionary = {}
	for profile: Dictionary in view.get("ai_bosses", []):
		profiles[profile["assigned_player_id"]] = profile
	var boards: Dictionary = {
		GameIds.PLAYER_HUMAN: human_board,
		GameIds.PLAYER_AI_1: ai_board_1,
		GameIds.PLAYER_AI_2: ai_board_2,
		GameIds.PLAYER_AI_3: ai_board_3,
	}
	for player: Dictionary in view["players"]:
		var player_id: String = str(player["id"])
		var board: PlayerBoard = boards.get(player_id)
		if board != null:
			board.render(
				player,
				profiles.get(player_id, {}),
				view.get("card_definitions", {})
			)


func _apply_responsive_layout() -> void:
	var screen_height: float = size.y if size.y > 0.0 else get_viewport_rect().size.y
	var low_height: bool = screen_height <= 760.0
	ai_board_1.set_low_height_mode(false)
	ai_board_2.set_low_height_mode(low_height)
	ai_board_3.set_low_height_mode(false)
	human_board.set_low_height_mode(low_height)
	human_board.set_card_presentation(
		PlayerBoard.CARD_PRESENTATION_COMPACT
		if low_height else PlayerBoard.CARD_PRESENTATION_FULL
	)
	top_opponent_zone.custom_minimum_size.y = 176.0 if low_height else 326.0
	human_zone.custom_minimum_size.y = 176.0 if low_height else 326.0
	center_table.custom_minimum_size.y = 304.0 if low_height else 0.0


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


func _on_case_file_toggle_pressed() -> void:
	set_case_file_visible(not _case_file_visible)


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
