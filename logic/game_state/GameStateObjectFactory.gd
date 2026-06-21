class_name GameStateObjectFactory


static func create_engine_state() -> Dictionary:
	return {
		"informers": 0, "laundries": 0, "accountants": 0, "brothel": false,
	}


static func create_status_buildings_state() -> Dictionary:
	return {
		"stash": 0, "workshop": 0, "district_control": 0,
		"can_rebuild_district_for_8": false,
	}


static func create_defense_state() -> Dictionary:
	return {
		"cops_active": false, "cops_timer": 0,
		"cartel_state": DefenseStates.NONE,
		"judge_state": DefenseStates.NONE,
	}


static func create_player_contact_state() -> Dictionary:
	return {"unlocked": [], "cooldowns": {}, "used_this_round": []}


static func create_global_contact_state() -> Dictionary:
	return {"pending_offer": {}}


static func create_contact_offer_state(
	player_id: String = "",
	source: String = "",
	contact_offer_ids: Array[String] = [],
	created_round: int = 0
) -> Dictionary:
	return {
		"player_id": player_id,
		"source": source,
		"contact_offer_ids": contact_offer_ids.duplicate(),
		"resolved": false,
		"created_round": created_round,
	}


static func create_contract_runtime(contract_id: String, deadline: int) -> Dictionary:
	return {
		"contract_id": contract_id, "progress": 0, "completed": false,
		"failed": false, "claimed": false, "deadline": deadline,
		"failed_reason": "", "completed_round": 0, "claimed_round": 0,
	}


static func create_debt_state(
	debt_id: String,
	amount_due: int,
	deadline_round: int,
	penalty: Dictionary,
	created_round: int
) -> Dictionary:
	return {
		"id": debt_id, "source": StreetDealIds.LOAN_SHARK,
		"amount_due": amount_due, "deadline_round": deadline_round,
		"penalty": penalty.duplicate(true), "repaid": false,
		"created_round": created_round, "repaid_round": 0,
		"penalty_applied_round": 0,
	}


static func create_temporary_modifier(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"type": data.get("type", ""),
		"source": data.get("source", ""),
		"owner_player_id": data.get("owner_player_id", ""),
		"affected_card_id": data.get("affected_card_id", ""),
		"affected_card_type": data.get("affected_card_type", ""),
		"delta": data.get("delta", 0),
		"multiplier": data.get("multiplier", 1.0),
		"min_value": data.get("min_value", 0),
		"expires_at": data.get("expires_at", ""),
		"consumed": data.get("consumed", false),
	}


static func create_role_flags() -> Dictionary:
	return {
		"merchant_first_engine_discount_used": false,
		"merchant_first_war_tax_applied_this_round": false,
		"enforcer_first_war_discount_used": false,
		"gray_cardinal_first_accountant_bypass_used": false,
		"gray_cardinal_first_saboteur_discount_used": false,
		"gray_cardinal_first_stash_tax_used": false,
		"district_boss_first_stash_discount_used": false,
		"district_boss_first_laundry_tax_used": false,
		"district_boss_rebuild_discount_used": false,
		"used_first_card_discount": false,
		"used_emergency_protection": false,
		"used_one_time_contact_bonus": false,
	}


static func create_turf_flags() -> Dictionary:
	return TurfLevelLogic.create_empty_turf_flags()


static func create_street_deal_state() -> Dictionary:
	return {
		"offered_this_round": false, "current_deal_id": "",
		"used_deal_ids": [], "choices_by_player": {},
		"option_availability": {},
	}


static func create_market_state() -> Dictionary:
	return {
		"round": 1, "always_available_card_ids": [],
		"rotating_card_ids": [], "all_available_card_ids": [],
	}


static func create_ai_boss_state(
	profile_id: String,
	is_strong: bool,
	assigned_player_id: String
) -> Dictionary:
	return {
		"profile_id": profile_id,
		"is_strong": is_strong,
		"assigned_player_id": assigned_player_id,
	}


static func create_combat_log_entry(
	event_type: String,
	data: Dictionary
) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"round": data.get("round", 1),
		"phase": data.get("phase", ""),
		"event_type": event_type,
		"actor_id": data.get("actor_id", ""),
		"target_id": data.get("target_id", ""),
		"card_id": data.get("card_id", ""),
		"summary": data.get("summary", ""),
		"details": data.get("details", {}).duplicate(true),
	}


static func create_game_result() -> Dictionary:
	return {
		"winner_id": "", "final_scores": [], "tie_break_used": false,
		"tie_break_steps": [], "turf_level_10_ai_win_applied": false,
	}
