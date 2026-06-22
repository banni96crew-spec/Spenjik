extends GutTest

const Payloads = preload("res://scenes/ui/helpers/UICommandPayloads.gd")


func test_setup_config_preserves_ids_and_turf_integer() -> void:
	var config: Dictionary = Payloads.setup_config(
		"seed_ui", 4, RoleIds.ENFORCER, ContractIds.GRAY_CAPITAL
	)
	assert_eq(config, {
		"game_seed": "seed_ui",
		"turf_level": 4,
		"selected_role_id": RoleIds.ENFORCER,
		"selected_contract_id": ContractIds.GRAY_CAPITAL,
	})
	assert_true(Payloads.is_setup_complete(config))
	config["game_seed"] = ""
	assert_false(Payloads.is_setup_complete(config))


func test_attack_payload_has_exact_fields() -> void:
	var payload: Dictionary = Payloads.attack_payload(
		GameIds.CARD_THUG, GameIds.PLAYER_AI_1, "", [GameIds.CARD_INSIDER], ""
	)
	assert_eq(payload.keys(), [
		"attacker_id", "target_id", "card_id", "mode", "modifiers",
		"engine_target_card_id",
	])
	assert_eq(payload["attacker_id"], GameIds.PLAYER_HUMAN)
	assert_true(Payloads.is_attack_complete(payload))


func test_attack_completeness_covers_modes_and_engine_target() -> void:
	var bruiser: Dictionary = Payloads.attack_payload(
		GameIds.CARD_BRUISER, GameIds.PLAYER_AI_1, "", [], ""
	)
	assert_false(Payloads.is_attack_complete(bruiser))
	bruiser["mode"] = AttackModes.STEAL_NAL
	assert_true(Payloads.is_attack_complete(bruiser))
	var raid: Dictionary = Payloads.attack_payload(
		GameIds.CARD_FEDERAL_RAID, GameIds.PLAYER_AI_1,
		AttackModes.DESTROY_DISTRICT, [], ""
	)
	assert_true(Payloads.is_attack_complete(raid))
	var saboteur: Dictionary = Payloads.attack_payload(
		GameIds.CARD_SABOTEUR, GameIds.PLAYER_AI_1, "", [], ""
	)
	assert_false(Payloads.is_attack_complete(saboteur))
	saboteur["engine_target_card_id"] = GameIds.CARD_LAUNDRY
	assert_true(Payloads.is_attack_complete(saboteur))


func test_insider_is_complete_only_as_thug_modifier() -> void:
	var invalid: Dictionary = Payloads.attack_payload(
		GameIds.CARD_BRUISER, GameIds.PLAYER_AI_1,
		AttackModes.STEAL_NAL, [GameIds.CARD_INSIDER], ""
	)
	assert_false(Payloads.is_attack_complete(invalid))
	invalid["card_id"] = GameIds.CARD_THUG
	invalid["mode"] = ""
	assert_true(Payloads.is_attack_complete(invalid))


func test_deal_and_contact_payloads_use_canonical_ids() -> void:
	assert_eq(Payloads.street_deal_payload(
		StreetDealIds.DIRTY_TIP, StreetDealOptionIds.OPTION_A
	), {
		"player_id": GameIds.PLAYER_HUMAN,
		"deal_id": StreetDealIds.DIRTY_TIP,
		"option_id": "option_a",
	})
	assert_eq(Payloads.contact_payload(ContactIds.BLACK_CASH), {
		"player_id": GameIds.PLAYER_HUMAN,
		"contact_id": ContactIds.BLACK_CASH,
	})
