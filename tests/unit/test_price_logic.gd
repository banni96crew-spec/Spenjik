extends GutTest


func test_scaled_prices_and_protected_nal_match_owner_rules() -> void:
	var player: Dictionary = TestPlayers.player(GameIds.PLAYER_HUMAN)
	assert_eq(PriceLogic.get_informant_price(player), 5)
	assert_eq(PriceLogic.get_laundry_price(player), 8)
	player["engine"]["informers"] = 1
	player["engine"]["laundries"] = 1
	assert_eq(PriceLogic.get_informant_price(player), 6)
	assert_eq(PriceLogic.get_laundry_price(player), 10)
	player["engine"]["informers"] = 3
	player["engine"]["laundries"] = 3
	assert_eq(PriceLogic.get_informant_price(player), 7)
	assert_eq(PriceLogic.get_laundry_price(player), 12)
	assert_eq(
		[0, 4, 6, 7],
		[
			PriceLogic.get_protected_nal(0),
			PriceLogic.get_protected_nal(1),
			PriceLogic.get_protected_nal(2),
			PriceLogic.get_protected_nal(3),
		]
	)


func test_price_preview_applies_turf_contact_temporary_then_clamps() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("price_order")
	state["turf_level"] = 6
	for player: Dictionary in state["players"]:
		player["turf_level"] = 6
	var ai: Dictionary = TestPlayers.find(state, GameIds.PLAYER_AI_1)
	ai["temporary_modifiers"] = [_modifier(
		"cheap_ai_1_round_1", ai["id"], CardTypes.WAR, -10
	)]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = PriceLogic.get_card_price(
		state, ai["id"], GameIds.CARD_THUG, [{
			"id": "role_ai_1_round_1", "source": "role",
			"delta": 2, "flag": "", "consume_on_success": false,
		}]
	)
	assert_true(result["ok"])
	assert_eq(result["base_price"], 2)
	assert_eq(result["modifiers"].size(), 3)
	assert_eq(result["modifiers"][0]["source"], "role")
	assert_eq(result["modifiers"][1]["source"], "turf_level")
	assert_eq(result["modifiers"][2]["source"], "test")
	assert_eq(result["final_price"], 1)
	assert_eq(state, before)


func test_corrupt_clerk_preview_is_read_only_and_uses_documented_flag() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("price_contact")
	var human: Dictionary = TestPlayers.find(state, GameIds.PLAYER_HUMAN)
	human["contacts"]["unlocked"] = [ContactIds.CORRUPT_CLERK]
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = PriceLogic.get_card_price(
		state, human["id"], GameIds.CARD_STASH
	)
	assert_eq(result["final_price"], 7)
	assert_eq(result["modifiers"][0]["source"], "contact")
	assert_eq(state, before)
	human["role_flags"]["used_one_time_contact_bonus"] = true
	assert_eq(
		PriceLogic.get_card_price(
			state, human["id"], GameIds.CARD_STASH
		)["final_price"],
		8
	)


func test_card_resources_and_random_are_not_mutated_by_preview() -> void:
	var state: Dictionary = TestGameStateFactory.base_state("price_resource")
	var definition: CardDefinition = CardCatalog.get_by_id(GameIds.CARD_LAUNDRY)
	var values_before: Array = [
		definition.id, definition.type, definition.base_price,
		definition.destination, definition.effect_summary,
	]
	var random_before: Dictionary = state["random"].duplicate(true)
	PriceLogic.get_card_price(state, GameIds.PLAYER_HUMAN, definition.id)
	assert_eq(state["random"], random_before)
	assert_eq(values_before, [
		definition.id, definition.type, definition.base_price,
		definition.destination, definition.effect_summary,
	])
	assert_eq(PriceLogic.clamp_price(-20), 1)
	assert_eq(
		PriceLogic.get_rebuild_price(
			state, GameIds.PLAYER_HUMAN
		)["final_rebuild_price"],
		8
	)


func _modifier(
	id: String,
	player_id: String,
	card_type: String,
	delta: int
) -> Dictionary:
	return GameStateFactory.create_temporary_modifier({
		"id": id, "type": ModifierTypes.CARD_PRICE_DELTA,
		"source": "test", "owner_player_id": player_id,
		"affected_card_type": card_type, "delta": delta,
		"multiplier": 1.0, "min_value": 1,
		"expires_at": "next_purchase",
	})
