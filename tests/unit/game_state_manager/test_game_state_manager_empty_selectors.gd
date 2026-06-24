extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_all_selectors_return_game_not_started_without_crash() -> void:
	var dictionary_selectors: Array[Callable] = [
		func() -> Dictionary: return GameStateManager.get_view(),
		func() -> Dictionary: return GameStateManager.get_contract_offers(),
		func() -> Dictionary:
			return GameStateManager.get_market_view(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_card_price_preview(
				GameIds.PLAYER_HUMAN, GameIds.CARD_STASH
			),
		func() -> Dictionary:
			return GameStateManager.get_income_preview(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_cops_upkeep_preview(
				GameIds.PLAYER_HUMAN
			),
		func() -> Dictionary:
			return GameStateManager.get_protected_nal_preview(
				GameIds.PLAYER_HUMAN
			),
		func() -> Dictionary: return GameStateManager.get_combat_preview({}),
		func() -> Dictionary: return GameStateManager.get_valid_targets({}),
		func() -> Dictionary:
			return GameStateManager.get_valid_engine_targets(
				GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_1
			),
		func() -> Dictionary:
			return GameStateManager.get_contract_state(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_street_deal_view(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_debt_status(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_contact_offer(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_contact_state(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_ai_state(GameIds.PLAYER_AI_1),
		func() -> Dictionary: return GameStateManager.get_ai_profiles_view(),
		func() -> Dictionary: return GameStateManager.get_turf_level_view(),
		func() -> Dictionary:
			return GameStateManager.get_rebuild_district_preview(
				GameIds.PLAYER_HUMAN
			),
	]
	for invoke: Callable in dictionary_selectors:
		var result: Dictionary = invoke.call()
		assert_false(result["ok"], str(result))
		assert_eq(result["error"], ValidationErrors.GAME_NOT_STARTED)
	var reason_selectors: Array[Callable] = [
		func() -> String:
			return GameStateManager.get_purchase_disabled_reason(
				GameIds.PLAYER_HUMAN, GameIds.CARD_STASH
			),
		func() -> String:
			return GameStateManager.get_action_disabled_reason({}),
		func() -> String:
			return GameStateManager.get_contract_claim_disabled_reason(
				GameIds.PLAYER_HUMAN, ContractIds.SILENT_EXPANSION
			),
		func() -> String:
			return GameStateManager.get_street_deal_disabled_reason({
				"player_id": GameIds.PLAYER_HUMAN,
				"option_id": "option_a",
			}),
		func() -> String:
			return GameStateManager.get_contact_disabled_reason({
				"player_id": GameIds.PLAYER_HUMAN,
				"contact_id": ContactIds.STREET_MEDIC,
			}),
		func() -> String:
			return GameStateManager.get_rebuild_district_disabled_reason(
				GameIds.PLAYER_HUMAN
			),
	]
	for invoke: Callable in reason_selectors:
		assert_eq(invoke.call(), ValidationErrors.GAME_NOT_STARTED)
