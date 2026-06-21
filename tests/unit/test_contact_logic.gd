extends GutTest


func test_contact_resources_and_state_shapes() -> void:
	assert_eq(ContactIds.ALL.size(), 3)
	for contact_id: String in ContactIds.ALL:
		assert_true(ContactLogic.is_valid_contact_id(contact_id))
	var player_state: Dictionary = ContactLogic.create_empty_state()
	assert_eq(player_state.keys(), ["unlocked", "cooldowns", "used_this_round"])
	var global_state: Dictionary = ContactLogic.create_empty_global_state()
	assert_eq(global_state.keys(), ["pending_offer"])


func test_inside_contact_offer_is_deterministic_with_exact_rng_steps() -> void:
	var state_a: Dictionary = _offer_state("contact_offer_seed_a")
	var state_b: Dictionary = _offer_state("contact_offer_seed_a")
	var first: Dictionary = ContactLogic.generate_contact_offer(
		state_a, GameIds.PLAYER_HUMAN, 2, StreetDealIds.INSIDE_CONTACT
	)
	var second: Dictionary = ContactLogic.generate_contact_offer(
		state_b, GameIds.PLAYER_HUMAN, 2, StreetDealIds.INSIDE_CONTACT
	)
	assert_true(first["ok"], str(first))
	assert_true(second["ok"], str(second))
	assert_eq(first["contact_offer_ids"], second["contact_offer_ids"])
	assert_eq(first["random"], second["random"])
	assert_eq(first["steps_used"], 2)
	assert_eq(first["contact_offer_ids"].size(), 2)


func test_strong_ai_offer_count_follows_turf_level() -> void:
	var low: Dictionary = _offer_state("strong_ai_low")
	var high: Dictionary = _offer_state("strong_ai_high")
	high["turf_level"] = 7
	for player: Dictionary in high["players"]:
		player["turf_level"] = 7
	var low_offer: Dictionary = ContactLogic.generate_contact_offer(
		low,
		GameIds.PLAYER_HUMAN,
		3,
		"strong_ai_victory"
	)
	var high_offer: Dictionary = ContactLogic.generate_contact_offer(
		high,
		GameIds.PLAYER_HUMAN,
		2,
		"strong_ai_victory"
	)
	assert_true(low_offer["ok"], str(low_offer))
	assert_true(high_offer["ok"], str(high_offer))
	assert_eq(low_offer["contact_offer_ids"].size(), 3)
	assert_eq(high_offer["contact_offer_ids"].size(), 2)


func test_offer_fails_when_available_contacts_are_insufficient() -> void:
	var state: Dictionary = _offer_state("contact_short_pool")
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["contacts"]["unlocked"] = [ContactIds.BLACK_CASH]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = ContactLogic.generate_contact_offer(
		state, GameIds.PLAYER_HUMAN, 2, StreetDealIds.INSIDE_CONTACT
	)
	assert_eq(result["error"], ValidationErrors.CONTACT_LIMIT_REACHED)
	assert_eq(state, before)


func test_offer_fails_when_required_count_exceeds_available_pool() -> void:
	var state: Dictionary = _offer_state("contact_strict_count")
	state["contacts"]["pending_offer"] = GameStateFactory.create_contact_offer_state(
		GameIds.PLAYER_HUMAN,
		StreetDealIds.INSIDE_CONTACT,
		[ContactIds.BLACK_CASH, ContactIds.CORRUPT_CLERK],
		state["round"]
	)
	var before_random: Dictionary = state["random"].duplicate(true)
	var result: Dictionary = ContactLogic.generate_contact_offer(
		state, GameIds.PLAYER_HUMAN, 2, StreetDealIds.INSIDE_CONTACT
	)
	assert_eq(result["error"], ValidationErrors.CONTACT_OFFER_UNAVAILABLE)
	assert_eq(state["random"], before_random)


func test_select_contact_unlocks_one_and_clears_pending_offer() -> void:
	var state: Dictionary = _pending_offer_state(
		[ContactIds.BLACK_CASH, ContactIds.STREET_MEDIC]
	)
	var selected_id: String = state["contacts"]["pending_offer"]["contact_offer_ids"][0]
	var result: Dictionary = ContactLogic.select_contact(state, {
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": selected_id,
	})
	assert_true(result["ok"], str(result))
	var human: Dictionary = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["contacts"]["unlocked"], [selected_id])
	assert_eq(result["state"]["contacts"]["pending_offer"], {})


func test_failed_selection_does_not_mutate_state() -> void:
	var state: Dictionary = _pending_offer_state(
		[ContactIds.BLACK_CASH, ContactIds.STREET_MEDIC]
	)
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = ContactLogic.select_contact(state, {
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": ContactIds.CORRUPT_CLERK,
	})
	assert_eq(result["error"], ValidationErrors.CONTACT_LOCKED)
	assert_eq(state, before)


func test_corrupt_clerk_modifier_and_consume_after_success() -> void:
	var state: Dictionary = _market_state([GameIds.CARD_STASH])
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["contacts"]["unlocked"] = [ContactIds.CORRUPT_CLERK]
	human["nal"] = 20
	var preview: Dictionary = PriceLogic.get_card_price(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_eq(preview["modifiers"][0]["source"], "contact")
	assert_eq(preview["final_price"], 7)
	var bought: Dictionary = MarketLogic.buy_card(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_true(bought["ok"], str(bought))
	human = TestPlayers.find(bought["state"], human["id"])
	assert_true(human["role_flags"]["used_one_time_contact_bonus"])


func test_street_medic_prevents_vp_loss_but_not_nal_loss() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("contact_medic")
	state["round"] = 11
	state["current_phase"] = PhaseIds.INCOME
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["nal"] = 5
	human["vp"] = 2
	human["contacts"]["unlocked"] = [ContactIds.STREET_MEDIC]
	human["debts"] = [
		DebtLogic.create_debt(
			"loan_shark_round_8_option_a",
			12,
			9,
			{"lose_all_nal": true, "vp_delta": -1},
			8
		),
	]
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_eq(human["nal"], 0)
	assert_eq(human["vp"], 2)
	assert_true(human["role_flags"]["used_emergency_protection"])


func test_street_medic_not_consumed_when_effective_vp_loss_is_zero() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("contact_medic_zero_vp")
	state["round"] = 11
	state["current_phase"] = PhaseIds.INCOME
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["vp"] = 0
	human["contacts"]["unlocked"] = [ContactIds.STREET_MEDIC]
	human["debts"] = [
		DebtLogic.create_debt(
			"loan_shark_round_8_option_b",
			1,
			9,
			{"lose_all_nal": false, "vp_delta": -1},
			8
		),
	]
	var result: Dictionary = DebtLogic.process_debts_for_player(
		state, GameIds.PLAYER_HUMAN
	)
	assert_true(result["ok"], str(result))
	human = TestPlayers.find(result["state"], GameIds.PLAYER_HUMAN)
	assert_false(human["role_flags"]["used_emergency_protection"])


func test_strong_ai_attack_hook_creates_offer_only_for_valid_status_destroy() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER], "contact_combat_hook"
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["status_buildings"]["stash"] = 1
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	assert_true(result["ok"], str(result))
	assert_eq(result["contact_results"].size(), 1)
	assert_eq(
		result["state"]["contacts"]["pending_offer"]["contact_offer_ids"].size(),
		3
	)


func test_reset_round_contact_usage_clears_only_used_this_round() -> void:
	var player: Dictionary = TestPlayers.player(GameIds.PLAYER_HUMAN)
	player["contacts"] = ContactLogic.create_empty_state()
	player["contacts"]["unlocked"] = [ContactIds.STREET_MEDIC]
	player["contacts"]["used_this_round"] = [ContactIds.STREET_MEDIC]
	ContactLogic.reset_round_contact_usage(player)
	assert_eq(player["contacts"]["used_this_round"], [])
	assert_eq(player["contacts"]["unlocked"], [ContactIds.STREET_MEDIC])


func _market_state(card_ids: Array[String]) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.market_state("contact_price")
	state["market"]["always_available_card_ids"] = card_ids.duplicate()
	state["market"]["rotating_card_ids"] = []
	state["market"]["all_available_card_ids"] = card_ids.duplicate()
	return state


func _offer_state(game_seed: String) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.street_deal_state(
		game_seed, 8
	)
	state["street_deals"]["current_deal_id"] = StreetDealIds.INSIDE_CONTACT
	return state


func _pending_offer_state(offer_ids: Array[String]) -> Dictionary:
	var state: Dictionary = TestGameStateFactory.base_state("contact_select")
	state["contacts"]["pending_offer"] = (
		GameStateFactory.create_contact_offer_state(
			GameIds.PLAYER_HUMAN,
			StreetDealIds.INSIDE_CONTACT,
			offer_ids,
			state["round"]
		)
	)
	return state
