extends GutTest


func before_each() -> void:
	GameStateManager.state = TestGameStateFactory.market_state(
		"selector_seed", 1
	)


func after_each() -> void:
	GameStateManager.reset_game()


func test_selectors_are_read_only_and_do_not_consume_random() -> void:
	var calls: Array[Callable] = [
		func() -> Variant: return GameStateManager.get_view(),
		func() -> Variant:
			return GameStateManager.get_market_view(GameIds.PLAYER_HUMAN),
		func() -> Variant:
			return GameStateManager.get_card_price_preview(
				GameIds.PLAYER_HUMAN, GameIds.CARD_STASH
			),
		func() -> Variant:
			return GameStateManager.get_income_preview(GameIds.PLAYER_HUMAN),
		func() -> Variant:
			return GameStateManager.get_cops_upkeep_preview(
				GameIds.PLAYER_HUMAN
			),
		func() -> Variant:
			return GameStateManager.get_protected_nal_preview(
				GameIds.PLAYER_HUMAN
			),
		func() -> Variant:
			return GameStateManager.get_contract_state(
				GameIds.PLAYER_HUMAN
			),
		func() -> Variant:
			return GameStateManager.get_debt_status(GameIds.PLAYER_HUMAN),
		func() -> Variant:
			return GameStateManager.get_contact_state(
				GameIds.PLAYER_HUMAN
			),
		func() -> Variant:
			return GameStateManager.get_ai_profiles_view(),
		func() -> Variant: return GameStateManager.get_turf_level_view(),
	]
	for invoke: Callable in calls:
		var before: Dictionary = GameStateManager.get_state_snapshot()
		watch_signals(GameStateManager)
		invoke.call()
		assert_eq(GameStateManager.get_state_snapshot(), before)
		assert_signal_not_emitted(GameStateManager, "state_changed")


func test_selector_results_do_not_expose_nested_active_references() -> void:
	var market_result: Dictionary = GameStateManager.get_market_view(
		GameIds.PLAYER_HUMAN
	)
	assert_true(market_result["ok"])
	market_result["view"]["market"]["all_available_card_ids"].append("fake")
	assert_false(
		GameStateManager.get_state_snapshot()["market"]
			["all_available_card_ids"].has("fake")
	)
	var contact: Dictionary = GameStateManager.get_contact_state(
		GameIds.PLAYER_HUMAN
	)
	contact["view"]["unlocked"].append(ContactIds.BLACK_CASH)
	assert_eq(
		TestPlayers.find(
			GameStateManager.get_state_snapshot(), GameIds.PLAYER_HUMAN
		)["contacts"]["unlocked"],
		[]
	)


func test_ui_views_include_dictionary_only_presentation_data() -> void:
	GameStateManager.state["market"]["always_available_card_ids"] = [
		GameIds.CARD_THUG
	]
	GameStateManager.state["market"]["all_available_card_ids"] = [
		GameIds.CARD_THUG
	]
	TestPlayers.find(
		GameStateManager.state, GameIds.PLAYER_HUMAN
	)["contracts"] = [
		GameStateFactory.create_contract_runtime(
			ContractIds.GRAY_CAPITAL, 10
		)
	]
	var market: Dictionary = GameStateManager.get_market_view(
		GameIds.PLAYER_HUMAN
	)
	assert_true(market["ok"], str(market))
	assert_true(market["view"].has("cards"))
	if not market["view"].has("cards"):
		return
	assert_eq(
		market["view"]["cards"].size(),
		market["view"]["market"]["all_available_card_ids"].size()
	)
	var card: Dictionary = market["view"]["cards"][0]
	assert_true(card.has("id"))
	assert_true(card.has("title"))
	assert_true(card.has("type"))
	assert_true(card.has("base_price"))
	assert_true(card.has("effect_summary"))
	var contract: Dictionary = GameStateManager.get_contract_state(
		GameIds.PLAYER_HUMAN
	)
	assert_true(contract["ok"], str(contract))
	assert_true(contract["view"].has("contract"))
	if not contract["view"].has("contract"):
		return
	assert_true(contract["view"]["contract"].has("title"))
	var view: Dictionary = GameStateManager.get_view()
	assert_true(view["ok"], str(view))
	assert_true(view["view"].has("card_definitions"))
	if not view["view"].has("card_definitions"):
		return
	assert_true(view["view"]["card_definitions"].has(GameIds.CARD_THUG))


func test_selectors_before_setup_fail_safely() -> void:
	GameStateManager.reset_game()
	var selectors: Array[Callable] = [
		func() -> Dictionary: return GameStateManager.get_view(),
		func() -> Dictionary:
			return GameStateManager.get_market_view(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_contract_state(GameIds.PLAYER_HUMAN),
		func() -> Dictionary:
			return GameStateManager.get_contact_offer(GameIds.PLAYER_HUMAN),
	]
	for invoke: Callable in selectors:
		var result: Dictionary = invoke.call()
		assert_false(result["ok"])
		assert_eq(result["error"], ValidationErrors.GAME_NOT_STARTED)
