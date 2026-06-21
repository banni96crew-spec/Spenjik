extends GutTest


func test_preview_is_read_only_and_reports_effects_and_defense() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_CLEANER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["status_buildings"]["workshop"] = 1
	target["defense"]["cartel_state"] = DefenseStates.ACTIVE
	var before: Dictionary = state.duplicate(true)
	var preview: Dictionary = CombatEngine.get_combat_preview(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_CLEANER, AttackModes.DESTROY_WORKSHOP
		)
	)
	assert_true(preview["ok"])
	assert_true(preview["would_be_blocked"])
	assert_eq(preview["blocker"], GameIds.CARD_CARTEL)
	assert_true(preview["would_deplete_cartel"])
	assert_eq(preview["cards_that_would_be_consumed"], [GameIds.CARD_CLEANER])
	assert_eq(state, before)


func test_preview_reports_protected_and_stealable_nal_without_rng_change() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["nal"] = 9
	target["engine"]["accountants"] = 1
	var before: Dictionary = state.duplicate(true)
	var preview: Dictionary = CombatEngine.get_combat_preview(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.STEAL_NAL
		)
	)
	assert_eq(preview["protected_nal"], 4)
	assert_eq(preview["stealable_nal"], 5)
	assert_eq(preview["max_steal"], 8)
	assert_eq(state, before)


func test_target_and_engine_selectors_are_read_only_and_actual() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER, GameIds.CARD_SABOTEUR]
	)
	CombatTestHelper.player(
		state, GameIds.PLAYER_AI_1
	)["status_buildings"]["stash"] = 1
	CombatTestHelper.player(
		state, GameIds.PLAYER_AI_2
	)["engine"]["informers"] = 1
	var before: Dictionary = state.duplicate(true)
	var targets: Dictionary = CombatEngine.get_valid_targets(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	assert_eq(targets["target_ids"], [GameIds.PLAYER_AI_1])
	var saboteur_targets: Dictionary = CombatEngine.get_valid_targets(
		state, CombatTestHelper.payload(GameIds.CARD_SABOTEUR)
	)
	assert_eq(saboteur_targets["target_ids"], [GameIds.PLAYER_AI_2])
	var engines: Dictionary = CombatEngine.get_valid_engine_targets(
		state, GameIds.PLAYER_HUMAN, GameIds.PLAYER_AI_2
	)
	assert_eq(
		engines["engine_target_card_ids"],
		[GameIds.CARD_INFORMANT]
	)
	assert_eq(state, before)


func test_discard_requires_action_owner_and_war_card() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG, GameIds.CARD_THUG]
	)
	var before: Dictionary = state.duplicate(true)
	assert_eq(
		CombatEngine.discard_war_card(
			state, GameIds.PLAYER_AI_1, GameIds.CARD_THUG
		)["error"],
		ValidationErrors.INVALID_TARGET
	)
	assert_eq(state, before)
	assert_eq(
		CombatEngine.discard_war_card(
			state, GameIds.PLAYER_HUMAN, GameIds.CARD_STASH
		)["error"],
		ValidationErrors.INVALID_ACTION_CARD
	)
	state["current_phase"] = PhaseIds.MARKET
	state["action_order"] = []
	state["active_action_player_id"] = ""
	assert_eq(
		CombatEngine.discard_war_card(
			state, GameIds.PLAYER_HUMAN, GameIds.CARD_THUG
		)["error"],
		ValidationErrors.INVALID_PHASE
	)


func test_discard_removes_one_copy_and_writes_only_canonical_log() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG, GameIds.CARD_THUG]
	)
	var random_before: Dictionary = state["random"].duplicate(true)
	var result: Dictionary = CombatEngine.discard_war_card(
		state, GameIds.PLAYER_HUMAN, GameIds.CARD_THUG
	)
	assert_true(result["ok"], str(result))
	assert_eq(
		CombatTestHelper.attacker(result["state"])["hand"],
		[GameIds.CARD_THUG]
	)
	assert_eq(result["state"]["random"], random_before)
	assert_eq(result["contract_hook_events"], [])
	assert_eq(result["contact_hook_events"], [])
	assert_eq(
		CombatTestHelper.target(result["state"])["last_attacked_by"],
		""
	)
	var log_entry: Dictionary = result["log_entries"][0]
	assert_eq(log_entry["event_type"], LogEventTypes.CARD_DISCARDED)
	assert_eq(log_entry["details"].keys().size(), 2)
	assert_true(log_entry["details"].has("player_id"))
	assert_true(log_entry["details"].has("card_id"))


func test_attack_result_logs_and_hook_boundaries_are_structured() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_BRUISER]
	)
	var target: Dictionary = CombatTestHelper.target(state)
	target["status_buildings"]["stash"] = 1
	target["vp"] = 2
	var result: Dictionary = CombatEngine.resolve_attack(
		state,
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.DESTROY_STASH
		)
	)
	assert_true(result["ok"], str(result))
	assert_true(result["success"])
	assert_eq(result["contract_results"].size(), 1)
	assert_false(result["contract_results"][0]["changed"])
	assert_eq(result["contact_results"].size(), 1)
	assert_eq(result["contact_results"][0]["contact_offer_ids"].size(), 3)
	assert_eq(
		result["state"]["contacts"]["pending_offer"]["source"],
		"strong_ai_victory"
	)
	assert_false(result["resolved_attack_event"]["blocked"])
	assert_true(result["resolved_attack_event"]["success"])
	assert_eq(result["contract_hook_events"].size(), 1)
	assert_eq(result["contact_hook_events"].size(), 1)
	assert_eq(
		result["contract_hook_events"][0]["destroyed_status_card_id"],
		GameIds.CARD_STASH
	)
	var attack_log: Dictionary = {}
	for entry: Dictionary in result["log_entries"]:
		if entry["event_type"] == LogEventTypes.ATTACK_EXECUTED:
			attack_log = entry
			break
	assert_eq(attack_log["event_type"], LogEventTypes.ATTACK_EXECUTED)
	assert_eq(attack_log["details"].keys().size(), 7)
	assert_eq(
		result["state"]["active_action_player_id"],
		GameIds.PLAYER_HUMAN
	)
	assert_eq(result["state"]["current_phase"], PhaseIds.ACTION)
	assert_true(GameStateValidator.validate_game_state(result["state"])["ok"])


func test_blocked_log_has_canonical_block_field_and_contract_event() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand(
		[GameIds.CARD_THUG]
	)
	CombatTestHelper.target(state)["defense"]["cops_active"] = true
	var result: Dictionary = CombatEngine.resolve_attack(
		state, CombatTestHelper.payload(GameIds.CARD_THUG)
	)
	var log_entry: Dictionary = result["log_entries"][0]
	assert_eq(log_entry["event_type"], LogEventTypes.ATTACK_BLOCKED)
	assert_eq(log_entry["details"].keys().size(), 8)
	assert_eq(log_entry["details"]["block_source"], GameIds.CARD_COPS)
	assert_true(result["resolved_attack_event"]["blocked"])
	assert_false(result["resolved_attack_event"]["success"])
	assert_eq(result["contract_hook_events"].size(), 1)
	assert_true(result["contract_hook_events"][0]["blocked"])
	assert_false(result["contract_results"][0]["changed"])
	assert_eq(result["contact_hook_events"], [])
	assert_eq(
		CombatTestHelper.target(result["state"])["last_attacked_by"],
		GameIds.PLAYER_HUMAN
	)


func test_multiple_attacks_chain_without_ending_action_or_consuming_unused_cards() -> void:
	var state: Dictionary = CombatTestHelper.state_with_hand([
		GameIds.CARD_THUG, GameIds.CARD_BRUISER, GameIds.CARD_INSIDER,
	])
	CombatTestHelper.target(state)["nal"] = 30
	var first: Dictionary = CombatEngine.resolve_attack(
		state, CombatTestHelper.payload(GameIds.CARD_THUG)
	)
	var second: Dictionary = CombatEngine.resolve_attack(
		first["state"],
		CombatTestHelper.payload(
			GameIds.CARD_BRUISER, AttackModes.STEAL_NAL
		)
	)
	assert_true(first["ok"])
	assert_true(second["ok"])
	assert_eq(
		CombatTestHelper.attacker(second["state"])["hand"],
		[GameIds.CARD_INSIDER]
	)
	assert_false(CombatTestHelper.attacker(second["state"])["action_done"])
	assert_eq(second["state"]["current_phase"], PhaseIds.ACTION)
	assert_eq(
		second["state"]["active_action_player_id"],
		GameIds.PLAYER_HUMAN
	)
