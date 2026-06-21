extends GutTest


func test_purchase_rejects_invalid_boundaries_and_active_defenses() -> void:
	var state: Dictionary = _market_state([
		GameIds.CARD_DISTRICT_CONTROL, GameIds.CARD_COPS,
		GameIds.CARD_CARTEL, GameIds.CARD_JUDGE,
	])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	assert_eq(
		MarketLogic.can_buy_card(
			state, human["id"], GameIds.CARD_DISTRICT_CONTROL
		)["error"],
		ValidationErrors.REQUIREMENT_NOT_MET
	)
	for card_id: String in [
		GameIds.CARD_COPS, GameIds.CARD_CARTEL, GameIds.CARD_JUDGE,
	]:
		human["defense"]["cops_active"] = card_id == GameIds.CARD_COPS
		human["defense"]["cartel_state"] = (
			DefenseStates.ACTIVE
			if card_id == GameIds.CARD_CARTEL else DefenseStates.NONE
		)
		human["defense"]["judge_state"] = (
			DefenseStates.ACTIVE
			if card_id == GameIds.CARD_JUDGE else DefenseStates.NONE
		)
		assert_eq(
			MarketLogic.can_buy_card(state, human["id"], card_id)["error"],
			ValidationErrors.CARD_LIMIT_REACHED
		)
	assert_eq(
		MarketLogic.can_buy_card(state, "bad_player", GameIds.CARD_COPS)["error"],
		ValidationErrors.INVALID_PLAYER_ID
	)
	assert_eq(
		MarketLogic.can_buy_card(state, human["id"], "bad_card")["error"],
		ValidationErrors.INVALID_CARD_ID
	)
	state["current_phase"] = PhaseIds.ACTION
	state["action_order"] = GameIds.PLAYER_IDS.duplicate()
	state["active_action_player_id"] = GameIds.PLAYER_HUMAN
	assert_eq(
		MarketLogic.can_buy_card(
			state, human["id"], GameIds.CARD_COPS
		)["error"],
		ValidationErrors.INVALID_PHASE
	)


func _market_state(card_ids: Array[String]) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state(
		"purchase_validation"
	)
	state["market"]["always_available_card_ids"] = card_ids.duplicate()
	state["market"]["rotating_card_ids"] = []
	state["market"]["all_available_card_ids"] = card_ids.duplicate()
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 50
	return state
