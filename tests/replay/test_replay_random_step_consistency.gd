extends GutTest

const ReplayScenarios = preload("res://tests/fixtures/ReplayScenarios.gd")


func before_each() -> void:
	GameStateManager.reset_game()


func test_replay_random_steps_match_command_by_command() -> void:
	var script: Array[Dictionary] = ReplayScenarios.full_game_script()
	var first: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED, script
	)
	var second: Dictionary = ReplayScriptRunner.run_scripted_game(
		ReplayScenarios.REPLAY_SEED, script
	)
	assert_true(first["ok"], str(first))
	assert_true(second["ok"], str(second))
	if not first["ok"] or not second["ok"]:
		return
	assert_eq(first["state"]["current_phase"], PhaseIds.GAME_OVER)
	assert_eq(second["state"]["current_phase"], PhaseIds.GAME_OVER)
	assert_eq(first["state"]["random"]["seed"], ReplayScenarios.REPLAY_SEED)
	assert_eq(second["state"]["random"]["seed"], ReplayScenarios.REPLAY_SEED)
	assert_eq(first["random_step"], second["random_step"])
	assert_eq(first["random_step"], first["state"]["random"]["step"])
	assert_eq(second["random_step"], second["state"]["random"]["step"])
	var first_steps: Array[int] = _random_steps(first["trace"])
	var second_steps: Array[int] = _random_steps(second["trace"])
	assert_eq(first_steps, second_steps)
	_assert_monotonic(first_steps)
	var before_snapshot: Dictionary = GameStateManager.get_state_snapshot()
	var before_step: int = before_snapshot["random"]["step"]
	var captured: Dictionary = GameStateManager.get_state_snapshot()
	assert_eq(captured["random"]["step"], before_step)
	assert_eq(GameStateManager.get_state_snapshot(), before_snapshot)


func _random_steps(trace: Array[Dictionary]) -> Array[int]:
	var result: Array[int] = []
	for checkpoint: Dictionary in trace:
		result.append(checkpoint["random_step"])
	return result


func _assert_monotonic(steps: Array[int]) -> void:
	var previous_step: int = -1
	for current_step: int in steps:
		assert_gte(current_step, previous_step)
		previous_step = current_step
