extends RefCounted

const REPLAY_SEED: String = "test_seed_replay"
const REPLAY_ROLE: String = "merchant"
const REPLAY_CONTRACT: String = "iron_roof"
const STREET_DEALS_BY_ROUND: Dictionary = {
	4: "black_market_cache",
	8: "loan_shark",
	12: "dirty_tip",
}


static func setup_preview_config(seed_value: String) -> Dictionary:
	return {
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": REPLAY_ROLE,
	}


static func setup_command() -> Dictionary:
	return _command("start_new_game", {
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": REPLAY_ROLE,
		"selected_contract_id": REPLAY_CONTRACT,
	})


static func full_round_one_script() -> Array[Dictionary]:
	var script: Array[Dictionary] = [setup_command()]
	script.append_array(_normal_round_commands())
	return script


static func full_game_script() -> Array[Dictionary]:
	var script: Array[Dictionary] = [setup_command()]
	for round_number: int in range(1, 16):
		script.append_array(_normal_round_commands())
		if STREET_DEALS_BY_ROUND.has(round_number):
			script.append(_command("select_street_deal", {
				"player_id": GameIds.PLAYER_HUMAN,
				"deal_id": STREET_DEALS_BY_ROUND[round_number],
				"option_id": StreetDealOptionIds.OPTION_B,
			}))
			script.append(_command("advance_phase"))
	return script


static func _normal_round_commands() -> Array[Dictionary]:
	return [
		_command("advance_phase"),
		_command("end_market_for_player", {
			"player_id": GameIds.PLAYER_HUMAN,
		}),
		_command("run_all_ai_market"),
		_command("advance_phase"),
		_command("end_action_for_player", {
			"player_id": GameIds.PLAYER_HUMAN,
		}),
		_command("run_all_ai_actions"),
		_command("advance_phase"),
	]


static func _command(
	operation: String,
	payload: Dictionary = {}
) -> Dictionary:
	return {
		"operation": operation,
		"payload": payload.duplicate(true),
	}
