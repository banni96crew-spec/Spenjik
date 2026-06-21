class_name CombatEffectResolver


## Applies one validated, unblocked attack effect to a working state.
static func resolve_effect(
	state: Dictionary,
	payload: Dictionary
) -> Dictionary:
	var attacker: Dictionary = AttackValidator.find_player(
		state, payload["attacker_id"]
	)
	var target: Dictionary = AttackValidator.find_player(
		state, payload["target_id"]
	)
	var result: Dictionary = _empty_result()
	match payload["card_id"]:
		GameIds.CARD_THUG:
			return _resolve_steal(attacker, target, 6)
		GameIds.CARD_BRUISER:
			if payload["mode"] == AttackModes.STEAL_NAL:
				return _resolve_steal(attacker, target, 8)
			target["status_buildings"]["stash"] -= 1
			target["vp"] = maxi(0, target["vp"] - 1)
			attacker["nal"] += 3
			result["destroyed_status_card_id"] = GameIds.CARD_STASH
			result["vp_loss"] = 1
			result["nal_gain"] = 3
		GameIds.CARD_CLEANER:
			if payload["mode"] == AttackModes.STEAL_NAL:
				return _resolve_steal(attacker, target, 14)
			target["status_buildings"]["workshop"] -= 1
			target["vp"] = maxi(0, target["vp"] - 2)
			target["skip_next_action"] = true
			attacker["nal"] += 5
			result["destroyed_status_card_id"] = GameIds.CARD_WORKSHOP
			result["vp_loss"] = 2
			result["nal_gain"] = 5
			result["skip_next_action_set"] = true
		GameIds.CARD_SABOTEUR:
			_destroy_engine(target, payload["engine_target_card_id"])
			result["destroyed_engine_card_id"] = payload["engine_target_card_id"]
		GameIds.CARD_FEDERAL_RAID:
			target["status_buildings"]["district_control"] -= 1
			target["status_buildings"]["can_rebuild_district_for_8"] = true
			target["vp"] = maxi(0, target["vp"] - 3)
			result["destroyed_status_card_id"] = (
				GameIds.CARD_DISTRICT_CONTROL
			)
			result["vp_loss"] = 3
			result["district_rebuild_enabled"] = true
	return result


static func preview_effect(
	state: Dictionary,
	payload: Dictionary,
	blocked: bool
) -> Dictionary:
	if blocked:
		return _empty_result()
	var target: Dictionary = AttackValidator.find_player(
		state, payload["target_id"]
	)
	var result: Dictionary = _empty_result()
	if payload["card_id"] == GameIds.CARD_THUG:
		return _steal_preview(target, 6)
	if (
		payload["card_id"] == GameIds.CARD_BRUISER
		and payload["mode"] == AttackModes.STEAL_NAL
	):
		return _steal_preview(target, 8)
	if (
		payload["card_id"] == GameIds.CARD_CLEANER
		and payload["mode"] == AttackModes.STEAL_NAL
	):
		return _steal_preview(target, 14)
	match payload["card_id"]:
		GameIds.CARD_BRUISER:
			result["destroyed_status_card_id"] = GameIds.CARD_STASH
			result["vp_loss"] = mini(1, target["vp"])
			result["nal_gain"] = 3
		GameIds.CARD_CLEANER:
			result["destroyed_status_card_id"] = GameIds.CARD_WORKSHOP
			result["vp_loss"] = mini(2, target["vp"])
			result["nal_gain"] = 5
			result["skip_next_action_set"] = true
		GameIds.CARD_SABOTEUR:
			result["destroyed_engine_card_id"] = payload["engine_target_card_id"]
		GameIds.CARD_FEDERAL_RAID:
			result["destroyed_status_card_id"] = (
				GameIds.CARD_DISTRICT_CONTROL
			)
			result["vp_loss"] = mini(3, target["vp"])
			result["district_rebuild_enabled"] = true
	return result


static func _resolve_steal(
	attacker: Dictionary,
	target: Dictionary,
	max_steal: int
) -> Dictionary:
	var result: Dictionary = _steal_preview(target, max_steal)
	var stolen: int = result["stolen_nal"]
	target["nal"] = maxi(0, target["nal"] - stolen)
	attacker["nal"] += stolen
	return result


static func _steal_preview(target: Dictionary, max_steal: int) -> Dictionary:
	var result: Dictionary = _empty_result()
	var protected: int = PriceLogic.get_protected_nal(
		target["engine"]["accountants"]
	)
	result["protected_nal"] = protected
	result["max_steal"] = max_steal
	result["stolen_nal"] = mini(
		max_steal, maxi(0, target["nal"] - protected)
	)
	result["nal_gain"] = result["stolen_nal"]
	return result


static func _destroy_engine(target: Dictionary, card_id: String) -> void:
	match card_id:
		GameIds.CARD_INFORMANT:
			target["engine"]["informers"] = maxi(
				0, target["engine"]["informers"] - 1
			)
		GameIds.CARD_LAUNDRY:
			target["engine"]["laundries"] = maxi(
				0, target["engine"]["laundries"] - 1
			)
		GameIds.CARD_ACCOUNTANT:
			target["engine"]["accountants"] = maxi(
				0, target["engine"]["accountants"] - 1
			)
		GameIds.CARD_BROTHEL:
			target["engine"]["brothel"] = false


static func _empty_result() -> Dictionary:
	return {
		"stolen_nal": 0,
		"protected_nal": 0,
		"max_steal": 0,
		"vp_loss": 0,
		"nal_gain": 0,
		"destroyed_status_card_id": "",
		"destroyed_engine_card_id": "",
		"skip_next_action_set": false,
		"district_rebuild_enabled": false,
	}
