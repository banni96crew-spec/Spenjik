class_name ContractConditionChecker

const STATUS_CARD_IDS: Array[String] = [
	GameIds.CARD_STASH,
	GameIds.CARD_WORKSHOP,
	GameIds.CARD_DISTRICT_CONTROL,
]


static func current_progress(contract_id: String, player: Dictionary) -> int:
	match contract_id:
		ContractIds.GRAY_CAPITAL:
			return mini(player["nal"], 30)
		ContractIds.IRON_ROOF:
			return _active_defense_count(player)
		ContractIds.DISTRICT_UNDER_CONTROL:
			return _district_control_progress(player)
		ContractIds.BIG_CASHBOX:
			return _big_cashbox_progress(player)
	return -1


static func purchase_progress(
	contract: Dictionary,
	event: Dictionary
) -> int:
	if (
		contract["contract_id"] == ContractIds.SILENT_EXPANSION
		and event.get("player_id") == GameIds.PLAYER_HUMAN
		and event.get("card_type") == CardTypes.STATUS
		and STATUS_CARD_IDS.has(event.get("card_id", ""))
	):
		return contract["progress"] + 1
	return -1


static func attack_progress(
	contract: Dictionary,
	event: Dictionary
) -> int:
	if event.get("attacker_id") != GameIds.PLAYER_HUMAN:
		return -1
	if contract["contract_id"] == ContractIds.BLOODY_TURF_WAR:
		return (
			contract["progress"] + 1
			if _is_counted_status_destruction(event) else -1
		)
	if contract["contract_id"] == ContractIds.PROXY_WAR:
		return (
			1
			if (
				event.get("valid_attack", false)
				and event.get("success", false)
				and not event.get("blocked", false)
				and event.get("card_id") == GameIds.CARD_SABOTEUR
			)
			else -1
		)
	return -1


static func breaks_silent_expansion(event: Dictionary) -> bool:
	return (
		event.get("attacker_id") == GameIds.PLAYER_HUMAN
		and event.get("valid_attack", false)
	)


static func _is_counted_status_destruction(event: Dictionary) -> bool:
	if (
		not event.get("valid_attack", false)
		or event.get("blocked", false)
		or not event.get("success", false)
		or not event.get("target_is_ai", false)
	):
		return false
	var card_id: String = event.get("card_id", "")
	var mode: String = event.get("mode", "")
	var destroyed: String = event.get("destroyed_status_card_id", "")
	return (
		(
			card_id == GameIds.CARD_BRUISER
			and mode == AttackModes.DESTROY_STASH
			and destroyed == GameIds.CARD_STASH
		)
		or (
			card_id == GameIds.CARD_CLEANER
			and mode == AttackModes.DESTROY_WORKSHOP
			and destroyed == GameIds.CARD_WORKSHOP
		)
		or (
			card_id == GameIds.CARD_FEDERAL_RAID
			and mode == AttackModes.DESTROY_DISTRICT
			and destroyed == GameIds.CARD_DISTRICT_CONTROL
		)
	)


static func _active_defense_count(player: Dictionary) -> int:
	var defense: Dictionary = player["defense"]
	var count: int = 0
	count += 1 if defense["cops_active"] else 0
	count += 1 if defense["cartel_state"] == DefenseStates.ACTIVE else 0
	count += 1 if defense["judge_state"] == DefenseStates.ACTIVE else 0
	return count


static func _district_control_progress(player: Dictionary) -> int:
	var has_district: bool = (
		player["status_buildings"]["district_control"] > 0
	)
	var has_protection: bool = _active_defense_count(player) > 0
	return int(has_district) + int(has_protection)


static func _big_cashbox_progress(player: Dictionary) -> int:
	var engine: Dictionary = player["engine"]
	var count: int = 0
	count += 1 if engine["laundries"] >= 2 else 0
	count += 1 if engine["accountants"] >= 1 else 0
	count += 1 if player["nal"] >= 20 else 0
	return count
