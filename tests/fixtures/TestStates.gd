class_name TestStates


static func committed_state(game_seed: String = "test_seed_001") -> Dictionary:
	var state: Dictionary = GameStateFactory.create_new_game_state(game_seed, 0)
	state["current_phase"] = PhaseIds.INCOME
	state["selected_role_id"] = RoleIds.MERCHANT
	state["contract_offer_ids"] = [
		ContractIds.SILENT_EXPANSION,
		ContractIds.BLOODY_TURF_WAR,
		ContractIds.GRAY_CAPITAL,
	]
	state["selected_contract_id"] = ContractIds.SILENT_EXPANSION
	var definition: ContractDefinition = ContractCatalog.get_by_id(
		ContractIds.SILENT_EXPANSION
	)
	TestPlayers.find(state, GameIds.PLAYER_HUMAN)["contracts"] = [
		GameStateFactory.create_contract_runtime(
			ContractIds.SILENT_EXPANSION,
			definition.deadline_round
		)
	]
	TestPlayers.find(state, GameIds.PLAYER_AI_1)["is_strong_ai"] = true
	state["ai_bosses"] = [
		GameStateFactory.create_ai_boss_state(
			AIProfileIds.BUILDER, true, GameIds.PLAYER_AI_1
		),
		GameStateFactory.create_ai_boss_state(
			AIProfileIds.RACKETEER, false, GameIds.PLAYER_AI_2
		),
		GameStateFactory.create_ai_boss_state(
			AIProfileIds.MERCHANT, false, GameIds.PLAYER_AI_3
		),
	]
	return state


static func clone_state(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


static func without_key(state: Dictionary, key: String) -> Dictionary:
	var result: Dictionary = clone_state(state)
	result.erase(key)
	return result


static func assert_no_mutation(
	test_ref: GutTest,
	before: Dictionary,
	after: Dictionary
) -> void:
	test_ref.assert_eq(after, before)
