extends GutTest


func test_inside_contact_flow_offers_selects_and_unlocks_one_contact() -> void:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		"integration_inside_contact", 8
	)
	state["street_deals"]["current_deal_id"] = StreetDealIds.INSIDE_CONTACT
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["nal"] = 20
	var random_before: Dictionary = state["random"].duplicate(true)
	var offered: Dictionary = StreetDealLogic.select_street_deal(state, {
		"player_id": GameIds.PLAYER_HUMAN,
		"deal_id": StreetDealIds.INSIDE_CONTACT,
		"option_id": StreetDealOptionIds.OPTION_A,
	})
	assert_true(offered["ok"], str(offered))
	var pending: Dictionary = offered["state"]["contacts"]["pending_offer"]
	assert_eq(pending["source"], StreetDealIds.INSIDE_CONTACT)
	assert_eq(pending["contact_offer_ids"].size(), 2)
	assert_gt(
		offered["state"]["random"]["step"],
		random_before["step"]
	)
	var selected_id: String = pending["contact_offer_ids"][0]
	var selected: Dictionary = ContactLogic.select_contact(
		offered["state"],
		{
			"player_id": GameIds.PLAYER_HUMAN,
			"contact_id": selected_id,
		}
	)
	assert_true(selected["ok"], str(selected))
	var human: Dictionary = TestPlayers.find(
		selected["state"], GameIds.PLAYER_HUMAN
	)
	assert_eq(human["contacts"]["unlocked"], [selected_id])
	assert_eq(selected["state"]["contacts"]["pending_offer"], {})
	assert_true(
		GameStateValidator.validate_game_state(selected["state"])["ok"]
	)
