class_name GameStateLogValidator

const ENTRY_KEYS: Array[String] = [
	"id", "round", "phase", "event_type", "actor_id", "target_id",
	"card_id", "summary", "details",
]
const DETAIL_KEYS := {
	"match_started": [
		"game_seed", "turf_level", "selected_role_id", "contract_offer_ids",
		"selected_contract_id", "ai_profile_ids", "strong_ai_player_id",
	],
	"round_started": ["round"],
	"phase_changed": ["from_phase", "to_phase", "round_before", "round_after"],
	"income_resolved": [
		"player_id", "die_1", "die_2", "dice_sum", "laundry_income",
		"informant_income", "brothel_income", "total_income", "nal_before", "nal_after",
	],
	"cops_upkeep_paid": [
		"player_id", "amount_paid", "interval", "timer_before", "timer_after",
		"nal_before", "nal_after",
	],
	"cops_deactivated": [
		"player_id", "interval", "timer_before", "timer_after", "nal",
	],
	"market_started": ["round", "available_card_ids"],
	"card_purchased": [
		"player_id", "card_id", "base_price", "final_price", "nal_before",
		"nal_after", "destination", "applied_modifier_ids",
	],
	"market_ended_for_player": ["player_id"],
	"action_started": ["action_order", "active_player_id"],
	"attack_executed": [
		"attacker_id", "target_id", "card_id", "mode", "modifiers",
		"engine_target_card_id", "cards_consumed",
	],
	"attack_blocked": [
		"attacker_id", "target_id", "card_id", "mode", "modifiers",
		"engine_target_card_id", "cards_consumed", "block_source",
	],
	"card_discarded": ["player_id", "card_id"],
	"action_skipped": ["player_id"],
	"action_ended_for_player": ["player_id"],
	"street_deal_offered": ["deal_id", "available_option_ids"],
	"street_deal_resolved": ["player_id", "deal_id", "option_id"],
	"debt_created": [
		"player_id", "debt_id", "source", "amount_due", "deadline_round",
	],
	"debt_repaid": ["player_id", "debt_id", "amount_paid", "nal_before", "nal_after"],
	"debt_penalty_applied": [
		"player_id", "debt_id", "lose_all_nal", "vp_delta", "nal_lost", "vp_lost",
	],
	"contact_unlocked": ["player_id", "contact_id", "source"],
	"contact_offered": ["player_id", "source", "contact_offer_ids", "created_round"],
	"contact_activated": ["player_id", "contact_id"],
	"contract_progress_updated": [
		"player_id", "contract_id", "progress_before", "progress_after",
		"source_event_type",
	],
	"contract_completed": ["player_id", "contract_id", "completed_round"],
	"contract_failed": ["player_id", "contract_id", "deadline", "failed_reason"],
	"contract_reward_claimed": [
		"player_id", "contract_id", "reward_type", "reward_amount", "claimed_round",
	],
	"game_over_reached": ["round"],
	"winner_resolved": [
		"winner_id", "final_scores", "tie_break_used", "tie_break_steps",
		"turf_level_10_ai_win_applied",
	],
}


static func validate(entry: Dictionary, expected_index: int) -> Dictionary:
	var shape: Dictionary = StateShapeValidator.exact_keys(
		entry, ENTRY_KEYS, "combat_log[]"
	)
	if not shape["ok"]:
		return shape
	var expected_id: String = "log_%06d" % expected_index
	if (
		entry["id"] != expected_id
		or typeof(entry["round"]) != TYPE_INT
		or entry["round"] < 1
		or entry["round"] > 15
		or not PhaseIds.ALL.has(entry["phase"])
		or not LogEventTypes.ALL.has(entry["event_type"])
		or not _empty_or_member(entry["actor_id"], GameIds.PLAYER_IDS)
		or not _empty_or_member(entry["target_id"], GameIds.PLAYER_IDS)
		or not _empty_or_member(entry["card_id"], GameIds.CARD_IDS)
		or typeof(entry["summary"]) != TYPE_STRING
		or typeof(entry["details"]) != TYPE_DICTIONARY
	):
		return StateShapeValidator.fail(
			ValidationErrors.INVALID_STATE, "combat_log[]", "envelope_contract"
		)
	var required: Array[String] = []
	for key: Variant in DETAIL_KEYS[entry["event_type"]]:
		required.append(key)
	return StateShapeValidator.exact_keys(
		entry["details"], required, "combat_log[].details"
	)


static func _empty_or_member(value: Variant, allowed: Array) -> bool:
	return typeof(value) == TYPE_STRING and (value == "" or allowed.has(value))
