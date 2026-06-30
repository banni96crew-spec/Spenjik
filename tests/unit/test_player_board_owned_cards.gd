extends GutTest

const BOARD_SCENE := preload("res://scenes/ui/panels/PlayerBoard.tscn")
const CARD_SCENE := preload("res://scenes/ui/widgets/CardView.tscn")


func test_player_board_renders_owned_cards_for_human_and_ai() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config())["ok"])
	var view: Dictionary = GameStateManager.get_view()["view"]
	var definitions: Dictionary = view["card_definitions"]
	var human: Dictionary = _player(view, GameIds.PLAYER_HUMAN).duplicate(true)
	var ai: Dictionary = _player(view, GameIds.PLAYER_AI_1).duplicate(true)
	human["engine"]["laundries"] = 1
	human["status_buildings"]["stash"] = 1
	human["defense"]["cops_active"] = true
	human["hand"] = [GameIds.CARD_THUG]
	ai["engine"]["accountants"] = 1
	ai["hand"] = [GameIds.CARD_BRUISER]
	var human_board: PlayerBoard = BOARD_SCENE.instantiate()
	var ai_board: PlayerBoard = BOARD_SCENE.instantiate()
	add_child_autofree(human_board)
	add_child_autofree(ai_board)
	human_board.render(human, {}, definitions)
	ai_board.render(ai, {"profile_id": "enforcer"}, definitions)
	assert_gte(human_board.owned_cards_row.get_child_count(), 4)
	assert_eq(ai_board.owned_cards_row.get_child_count(), 2)
	for child: Node in human_board.owned_cards_row.get_children():
		var chip := child as CardView
		assert_not_null(chip)
		assert_eq(chip.get_layout_size(), CardVisualTokens.COMPACT_CARD_SIZE)
		assert_false(chip.select_button.visible)


func test_player_owned_cards_builder_reconstructs_state_counts() -> void:
	var definitions: Dictionary = PresentationViewBuilder.cards_by_id()
	var player: Dictionary = TestPlayers.player(GameIds.PLAYER_HUMAN)
	player["engine"]["laundries"] = 2
	player["status_buildings"]["stash"] = 1
	player["defense"]["cartel_state"] = DefenseStates.ACTIVE
	player["hand"] = [GameIds.CARD_CLEANER]
	var displays: Array[Dictionary] = PlayerOwnedCardsBuilder.build_owned_displays(
		player, definitions
	)
	assert_eq(displays.size(), 5)
	var ids: Array[String] = []
	for display: Dictionary in displays:
		ids.append(str(display.get("id", "")))
	assert_eq(ids.count(GameIds.CARD_LAUNDRY), 2)
	assert_true(ids.has(GameIds.CARD_STASH))
	assert_true(ids.has(GameIds.CARD_CARTEL))
	assert_true(ids.has(GameIds.CARD_CLEANER))


func _player(view: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in view.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}


func _valid_config() -> Dictionary:
	var seed_value := "player_board_owned"
	var preview: Dictionary = GameStateManager.generate_contract_offers({
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
	})
	return {
		"game_seed": seed_value,
		"turf_level": TurfLevelIds.BASE,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	}
