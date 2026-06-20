extends GutTest

const ROOT_KEYS: Array[String] = [
	"round", "current_phase", "players", "game_seed", "random", "turf_level",
	"selected_role_id", "selected_contract_id", "contract_offer_ids", "market",
	"street_deals", "contacts", "ai_bosses", "action_order",
	"active_action_player_id", "combat_log", "winner_id", "game_result", "debug",
]
const PLAYER_KEYS: Array[String] = [
	"id", "is_ai", "nal", "vp", "turf_level", "engine", "status_buildings",
	"defense", "hand", "purchased_this_round", "ready_for_action", "action_done",
	"skip_next_action", "contracts", "contacts", "debts", "role_flags",
	"turf_flags", "temporary_modifiers", "is_strong_ai", "last_attacked_by",
]


func test_new_game_factory_creates_complete_setup_working_shape() -> void:
	var state: Dictionary = GameStateFactory.create_new_game_state("factory_seed", 3)
	assert_eq(_sorted_keys(state), _sorted(ROOT_KEYS))
	assert_eq(state["round"], 1)
	assert_eq(state["current_phase"], PhaseIds.SETUP)
	assert_eq(state["game_seed"], "factory_seed")
	assert_eq(state["debug"]["schema_version"], "1.0.0")
	assert_eq(state["players"].size(), 4)
	assert_eq(state["ai_bosses"], [])
	assert_eq(state["contacts"], {"pending_offer": {}})
	assert_true(GameStateValidator.validate_setup_working_state(state)["ok"])


func test_players_have_exact_keys_order_and_independent_nested_values() -> void:
	var state: Dictionary = TestGameStateFactory.setup_state()
	var ids: Array[String] = []
	for player: Dictionary in state["players"]:
		ids.append(player["id"])
		assert_eq(_sorted_keys(player), _sorted(PLAYER_KEYS))
	assert_eq(ids, GameIds.PLAYER_IDS)
	state["players"][0]["hand"].append(TestCards.first_war_card_id())
	state["players"][0]["contacts"]["unlocked"].append(ContactIds.BLACK_CASH)
	assert_eq(state["players"][1]["hand"], [])
	assert_eq(state["players"][1]["contacts"]["unlocked"], [])


func test_factory_uses_m3_random_state_without_consuming_steps() -> void:
	var first: Dictionary = TestGameStateFactory.setup_state("stable_seed")
	var second: Dictionary = TestGameStateFactory.setup_state("stable_seed")
	assert_eq(first, second)
	assert_eq(first["random"], SeededRandom.create_random_state("stable_seed"))
	assert_eq(first["random"]["step"], 0)


func test_contact_offer_defaults_are_compatible_and_not_stored_at_root() -> void:
	assert_eq(
		GameStateFactory.create_contact_offer_state(),
		{
			"player_id": "",
			"source": "",
			"contact_offer_ids": [],
			"resolved": false,
			"created_round": 0,
		}
	)
	assert_eq(GameStateFactory.create_global_contact_state(), {"pending_offer": {}})
	assert_eq(TestGameStateFactory.setup_state()["contacts"]["pending_offer"], {})


func _sorted_keys(value: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key: Variant in value.keys():
		result.append(key)
	result.sort()
	return result


func _sorted(values: Array[String]) -> Array[String]:
	var result: Array[String] = values.duplicate()
	result.sort()
	return result
