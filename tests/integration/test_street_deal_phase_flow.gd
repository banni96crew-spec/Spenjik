extends GutTest


func test_completed_actions_enter_generated_street_deal() -> void:
	for round_number: int in [4, 8, 12]:
		var state: Dictionary = TestGameStateFactory.completed_action_state(
			round_number, "phase_deal_%d" % round_number
		)
		var result: Dictionary = GamePhaseController.advance_phase(state)
		assert_true(result["ok"], str(result))
		assert_eq(result["state"]["current_phase"], PhaseIds.STREET_DEAL)
		assert_eq(result["state"]["round"], round_number)
		assert_ne(result["state"]["street_deals"]["current_deal_id"], "")
		assert_eq(
			result["state"]["combat_log"][-1]["event_type"],
			LogEventTypes.STREET_DEAL_OFFERED
		)


func test_resolved_street_deal_starts_next_income_round() -> void:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		"phase_deal_exit", 4
	)
	state["street_deals"]["current_deal_id"] = ""
	state["street_deals"]["choices_by_player"] = {
		GameIds.PLAYER_HUMAN: StreetDealOptionIds.OPTION_A,
	}
	state["street_deals"]["used_deal_ids"] = [StreetDealIds.DIRTY_TIP]
	var result: Dictionary = GamePhaseController.advance_phase(state)
	assert_true(result["ok"], str(result))
	assert_eq(result["state"]["current_phase"], PhaseIds.INCOME)
	assert_eq(result["state"]["round"], 5)
	assert_false(result["state"]["street_deals"]["offered_this_round"])
	assert_eq(result["state"]["street_deals"]["current_deal_id"], "")
	assert_eq(result["state"]["street_deals"]["choices_by_player"], {})
	assert_eq(
		result["state"]["street_deals"]["used_deal_ids"],
		[StreetDealIds.DIRTY_TIP]
	)
