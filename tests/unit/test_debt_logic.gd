extends GutTest


func test_active_debt_helpers_use_player_ownership() -> void:
	var player: Dictionary = TestPlayers.player(GameIds.PLAYER_HUMAN)
	assert_false(DebtLogic.has_active_debt(player))
	player["debts"] = [_debt(8, StreetDealOptionIds.OPTION_A)]
	assert_true(DebtLogic.has_active_debt(player))
	assert_eq(DebtLogic.get_active_debts(player).size(), 1)
	player["debts"][0]["repaid"] = true
	player["debts"][0]["repaid_round"] = 9
	assert_false(DebtLogic.has_active_debt(player))


func test_auto_repay_subtracts_exact_amount_and_is_not_repeated() -> void:
	var state: Dictionary = _income_state(9)
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 20
	human["debts"] = [_debt(8, StreetDealOptionIds.OPTION_A)]
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["nal"], 8)
	assert_true(human["debts"][0]["repaid"])
	assert_eq(human["debts"][0]["repaid_round"], 9)
	assert_eq(result["results"][0]["amount_paid"], 12)
	assert_eq(result["contract_results"].size(), 1)
	var repeated: Dictionary = DebtLogic.process_debts_for_player(
		result["state"], GameIds.PLAYER_HUMAN
	)
	assert_true(repeated["ok"])
	assert_eq(repeated["results"], [])
	assert_eq(repeated["state"], result["state"])


func test_insufficient_not_yet_due_debt_remains_active() -> void:
	var state: Dictionary = _income_state(9)
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 1
	human["debts"] = [_debt(8, StreetDealOptionIds.OPTION_A)]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	assert_false(result["results"][0]["repaid"])
	assert_eq(result["state"], before)


func test_overdue_penalties_clamp_resources_and_close_debt() -> void:
	var state: Dictionary = _income_state(11)
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 5
	human["vp"] = 0
	human["debts"] = [_debt(8, StreetDealOptionIds.OPTION_A)]
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["nal"], 0)
	assert_eq(human["vp"], 0)
	assert_true(human["debts"][0]["repaid"])
	assert_eq(human["debts"][0]["penalty_applied_round"], 11)
	assert_eq(result["results"][0]["nal_lost"], 5)
	assert_eq(result["results"][0]["vp_lost"], 0)


func test_street_medic_hook_boundary_prevents_only_vp_loss() -> void:
	var state: Dictionary = _income_state(11)
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 5
	human["vp"] = 2
	human["debts"] = [_debt(8, StreetDealOptionIds.OPTION_A)]
	human["contacts"]["unlocked"] = [ContactIds.STREET_MEDIC]
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["nal"], 0)
	assert_eq(human["vp"], 2)
	assert_true(result["results"][0]["vp_loss_prevented"])
	assert_eq(result["results"][0]["vp_lost"], 0)
	assert_true(human["role_flags"]["used_emergency_protection"])


func test_custom_debt_hook_still_overrides_default_medic_hook() -> void:
	var state: Dictionary = _income_state(11)
	var human: Dictionary = TestPlayers.find(
		state, GameIds.PLAYER_HUMAN
	)
	human["nal"] = 5
	human["vp"] = 2
	human["debts"] = [_debt(8, StreetDealOptionIds.OPTION_A)]
	human["contacts"]["unlocked"] = [ContactIds.STREET_MEDIC]
	var hook: Callable = Callable(self, "_prevent_vp_loss")
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN, hook
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["vp"], 2)
	assert_false(human["role_flags"]["used_emergency_protection"])


func test_failed_validation_does_not_mutate_state() -> void:
	var state: Dictionary = TestGameStateFactory.market_state(
		"debt_wrong_phase"
	)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_eq(result["error"], ValidationErrors.INVALID_PHASE)
	assert_eq(state, before)


func _income_state(round_number: int) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.base_state(
		"debt_round_%d" % round_number
	)
	state["round"] = round_number
	return state


func _debt(round_number: int, option_id: String) -> Dictionary:
	var amount: int = (
		12 if option_id == StreetDealOptionIds.OPTION_A else 6
	)
	return DebtLogic.create_debt(
		"loan_shark_round_%d_%s" % [round_number, option_id],
		amount,
		round_number + 2,
		{
			"lose_all_nal":
				option_id == StreetDealOptionIds.OPTION_A,
			"vp_delta": -1,
		},
		round_number
	)


func _prevent_vp_loss(
	state: Dictionary,
	_player_id: String,
	_debt_state: Dictionary
) -> Dictionary:
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"state": state,
		"vp_loss_prevented": true,
	}
