class_name GameRoot
extends Control

@onready var setup_screen: SetupScreen = %SetupScreen
@onready var game_screen: GameScreen = %GameScreen
@onready var game_over_screen: GameOverScreen = %GameOverScreen


func _ready() -> void:
	_connect_facade_signals()
	game_over_screen.new_game_requested.connect(_reset_to_setup)
	game_over_screen.main_menu_requested.connect(_reset_to_setup)
	_refresh_screen()


func _connect_facade_signals() -> void:
	if not GameStateManager.state_changed.is_connected(_on_state_changed):
		GameStateManager.state_changed.connect(_on_state_changed)
	if not GameStateManager.action_failed.is_connected(_on_action_failed):
		GameStateManager.action_failed.connect(_on_action_failed)
	if not GameStateManager.phase_changed.is_connected(_on_phase_changed):
		GameStateManager.phase_changed.connect(_on_phase_changed)
	if not GameStateManager.game_started.is_connected(_on_game_started):
		GameStateManager.game_started.connect(_on_game_started)
	if not GameStateManager.game_ended.is_connected(_on_game_ended):
		GameStateManager.game_ended.connect(_on_game_ended)


func _refresh_screen() -> void:
	if not GameStateManager.has_active_game():
		_show_setup()
		return
	var result: Dictionary = GameStateManager.get_view()
	if not result["ok"]:
		_show_setup()
		return
	if result["view"]["current_phase"] == PhaseIds.GAME_OVER:
		_show_game_over(result["view"])
	else:
		_show_game()


func _show_setup() -> void:
	setup_screen.visible = true
	game_screen.visible = false
	game_over_screen.visible = false
	setup_screen.reset()


func _show_game() -> void:
	setup_screen.visible = false
	game_screen.visible = true
	game_over_screen.visible = false
	game_screen.refresh()


func _show_game_over(view: Dictionary) -> void:
	setup_screen.visible = false
	game_screen.visible = false
	game_over_screen.visible = true
	game_over_screen.render(view)


func _reset_to_setup() -> void:
	GameStateManager.reset_game()
	_show_setup()


func _on_state_changed(_state: Dictionary) -> void:
	_refresh_screen()


func _on_action_failed(error: String, _result: Dictionary) -> void:
	if game_screen.visible:
		game_screen.show_error(error)


func _on_phase_changed(_phase_id: String) -> void:
	game_screen.clear_phase_selection()
	_refresh_screen()


func _on_game_started(_state: Dictionary) -> void:
	_show_game()


func _on_game_ended(_result: Dictionary) -> void:
	var view: Dictionary = GameStateManager.get_view()
	if view["ok"]:
		_show_game_over(view["view"])
