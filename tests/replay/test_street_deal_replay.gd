extends GutTest


func test_same_seed_replays_generation_and_random_ai_effect() -> void:
	var first: Dictionary = _empty_deal_state("replay_street_deal")
	var second: Dictionary = first.duplicate(true)
	var first_offer: Dictionary = StreetDealLogic.generate_street_deal(first)
	var second_offer: Dictionary = StreetDealLogic.generate_street_deal(
		second
	)
	assert_true(first_offer["ok"], str(first_offer))
	assert_eq(first_offer["state"], second_offer["state"])
	var first_tip: Dictionary = _dirty_tip_state("replay_dirty_tip")
	var second_tip: Dictionary = first_tip.duplicate(true)
	var first_result: Dictionary = StreetDealLogic.select_street_deal(
		first_tip, _dirty_tip_payload()
	)
	var second_result: Dictionary = StreetDealLogic.select_street_deal(
		second_tip, _dirty_tip_payload()
	)
	assert_true(first_result["ok"], str(first_result))
	assert_eq(first_result["selected_ai_id"], second_result["selected_ai_id"])
	assert_eq(first_result["state"], second_result["state"])
	assert_eq(
		first_result["state"]["random"]["step"],
		first_tip["random"]["step"] + 1
	)


func _empty_deal_state(game_seed: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		game_seed, 4
	)
	state["street_deals"] = StreetDealLogic.create_empty_state()
	return state


func _dirty_tip_state(game_seed: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		game_seed, 4
	)
	state["street_deals"]["current_deal_id"] = StreetDealIds.DIRTY_TIP
	return state


func _dirty_tip_payload() -> Dictionary:
	return {
		"player_id": GameIds.PLAYER_HUMAN,
		"deal_id": StreetDealIds.DIRTY_TIP,
		"option_id": StreetDealOptionIds.OPTION_B,
	}
