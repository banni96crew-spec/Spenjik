extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_required_public_api_exists() -> void:
	var methods: Array[String] = [
		"has_active_game", "get_state_snapshot", "get_view", "reset_game",
		"start_new_game", "get_available_roles", "get_available_turf_levels",
		"generate_contract_offers", "get_contract_offers", "advance_phase",
		"end_market_for_player", "end_action_for_player",
		"skip_action_for_player", "get_current_phase", "get_round",
		"buy_card", "rebuild_district_control", "get_market_view",
		"get_card_price_preview", "get_purchase_disabled_reason",
		"get_income_preview", "get_cops_upkeep_preview",
		"get_protected_nal_preview", "execute_attack", "discard_war_card",
		"get_combat_preview", "get_valid_targets",
		"get_valid_engine_targets", "get_action_disabled_reason",
		"claim_contract", "get_contract_state",
		"get_contract_claim_disabled_reason", "select_street_deal",
		"get_street_deal_view", "get_street_deal_disabled_reason",
		"get_debt_status", "select_contact", "activate_contact",
		"get_contact_offer", "get_contact_state",
		"get_contact_disabled_reason", "run_market_for_ai",
		"run_action_for_ai", "run_all_ai_market", "run_all_ai_actions",
		"get_ai_state", "get_ai_profiles_view", "get_turf_level",
		"get_turf_level_view",
	]
	for method_name: String in methods:
		assert_true(
			GameStateManager.has_method(method_name),
			"Missing facade method: %s" % method_name
		)


func test_start_new_game_commits_valid_deterministic_setup() -> void:
	var config: Dictionary = _valid_config("facade_setup")
	watch_signals(GameStateManager)
	var result: Dictionary = GameStateManager.start_new_game(config)
	assert_true(result["ok"], str(result))
	assert_true(GameStateManager.has_active_game())
	var snapshot: Dictionary = GameStateManager.get_state_snapshot()
	assert_true(GameStateValidator.validate_game_state(snapshot)["ok"])
	assert_eq(snapshot["current_phase"], PhaseIds.INCOME)
	assert_eq(snapshot["random"]["step"], 7)
	assert_eq(snapshot["combat_log"][-1]["event_type"], LogEventTypes.MATCH_STARTED)
	assert_signal_emitted(GameStateManager, "game_started")
	assert_signal_emitted(GameStateManager, "state_changed")


func test_failed_replacement_setup_preserves_previous_game() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config("facade_first"))["ok"])
	var before: Dictionary = GameStateManager.get_state_snapshot()
	var invalid: Dictionary = _valid_config("facade_invalid")
	invalid["selected_contract_id"] = "missing_contract"
	watch_signals(GameStateManager)
	var result: Dictionary = GameStateManager.start_new_game(invalid)
	assert_false(result["ok"])
	assert_eq(result["error"], ValidationErrors.INVALID_CONTRACT_ID)
	assert_eq(GameStateManager.get_state_snapshot(), before)
	assert_signal_not_emitted(GameStateManager, "state_changed")
	assert_signal_emitted(GameStateManager, "action_failed")


func test_contract_preview_is_deterministic_and_does_not_touch_active_state() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config("active_seed"))["ok"])
	var before: Dictionary = GameStateManager.get_state_snapshot()
	var preview_config: Dictionary = {
		"game_seed": "preview_seed",
		"turf_level": 3,
		"selected_role_id": RoleIds.ENFORCER,
	}
	var first: Dictionary = GameStateManager.generate_contract_offers(preview_config)
	var second: Dictionary = GameStateManager.generate_contract_offers(preview_config)
	assert_true(first["ok"])
	assert_eq(first["contract_offer_ids"], second["contract_offer_ids"])
	assert_eq(first["contract_offer_ids"].size(), 3)
	assert_eq(GameStateManager.get_state_snapshot(), before)


func test_snapshot_and_signal_payloads_are_isolated() -> void:
	watch_signals(GameStateManager)
	assert_true(GameStateManager.start_new_game(_valid_config("safe_payload"))["ok"])
	var snapshot: Dictionary = GameStateManager.get_state_snapshot()
	snapshot["players"][0]["nal"] = 999
	assert_ne(GameStateManager.get_state_snapshot()["players"][0]["nal"], 999)
	var payloads: Array = get_signal_parameters(GameStateManager, "state_changed")
	var emitted: Dictionary = payloads[0]
	emitted["players"][0]["nal"] = 777
	assert_ne(GameStateManager.get_state_snapshot()["players"][0]["nal"], 777)


func test_reset_game_clears_state_without_exposing_live_reference() -> void:
	assert_true(GameStateManager.start_new_game(_valid_config("reset_seed"))["ok"])
	var result: Dictionary = GameStateManager.reset_game()
	assert_true(result["ok"])
	assert_false(GameStateManager.has_active_game())
	result["state"]["unexpected"] = true
	assert_eq(GameStateManager.get_state_snapshot(), {})


func _valid_config(seed_value: String) -> Dictionary:
	var preview: Dictionary = GameStateManager.generate_contract_offers({
		"game_seed": seed_value,
		"turf_level": 0,
		"selected_role_id": RoleIds.MERCHANT,
	})
	return {
		"game_seed": seed_value,
		"turf_level": 0,
		"selected_role_id": RoleIds.MERCHANT,
		"selected_contract_id": preview["contract_offer_ids"][0],
	}
