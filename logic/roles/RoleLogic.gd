class_name RoleLogic


## Returns the canonical role-flag shape owned by the state factory.
static func create_empty_role_flags() -> Dictionary:
	return GameStateFactory.create_role_flags()


static func is_valid_role_id(role_id: String) -> bool:
	return RoleIds.ALL.has(role_id)


## Applies the selected role to a setup-working state without mutating input.
static func apply_role_setup(
	state: Dictionary,
	selected_role_id: String
) -> Dictionary:
	return RoleSetupResolver.apply(state, selected_role_id)


static func get_starting_nal_for_role(role_id: String) -> int:
	return RoleSetupResolver.get_starting_nal(role_id)


## Returns read-only role modifiers for one card-price preview.
static func get_role_price_modifiers(
	state: Dictionary,
	player: Dictionary,
	card_def: CardDefinition
) -> Array[Dictionary]:
	if not _role_applies(state, player) or card_def == null:
		return []
	var role_id: String = state["selected_role_id"]
	var flags: Dictionary = player["role_flags"]
	match role_id:
		RoleIds.MERCHANT:
			if (
				card_def.type == CardTypes.ENGINE
				and not flags["merchant_first_engine_discount_used"]
			):
				return [_modifier(
					role_id, "merchant_first_engine_discount_used",
					-1, "", CardTypes.ENGINE
				)]
			if (
				card_def.type == CardTypes.WAR
				and not flags["merchant_first_war_tax_applied_this_round"]
			):
				return [_modifier(
					role_id, "merchant_first_war_tax_applied_this_round",
					1, "", CardTypes.WAR
				)]
		RoleIds.ENFORCER:
			if (
				card_def.type == CardTypes.WAR
				and not flags["enforcer_first_war_discount_used"]
			):
				return [_modifier(
					role_id, "enforcer_first_war_discount_used",
					-1, "", CardTypes.WAR
				)]
			if card_def.id == GameIds.CARD_LAUNDRY:
				return [_modifier(role_id, "", 1, card_def.id, "")]
		RoleIds.GRAY_CARDINAL:
			if (
				card_def.id == GameIds.CARD_SABOTEUR
				and not flags["gray_cardinal_first_saboteur_discount_used"]
			):
				return [_modifier(
					role_id, "gray_cardinal_first_saboteur_discount_used",
					-1, card_def.id, ""
				)]
			if (
				card_def.id == GameIds.CARD_STASH
				and not flags["gray_cardinal_first_stash_tax_used"]
			):
				return [_modifier(
					role_id, "gray_cardinal_first_stash_tax_used",
					1, card_def.id, ""
				)]
		RoleIds.DISTRICT_BOSS:
			if (
				card_def.id == GameIds.CARD_STASH
				and not flags["district_boss_first_stash_discount_used"]
			):
				return [_modifier(
					role_id, "district_boss_first_stash_discount_used",
					-2, card_def.id, ""
				)]
			if (
				card_def.id == GameIds.CARD_LAUNDRY
				and not flags["district_boss_first_laundry_tax_used"]
			):
				return [_modifier(
					role_id, "district_boss_first_laundry_tax_used",
					1, card_def.id, ""
				)]
	return []


static func can_bypass_purchase_requirement(
	state: Dictionary,
	player: Dictionary,
	card_id: String,
	_requirement_id: String
) -> bool:
	return (
		card_id == GameIds.CARD_ACCOUNTANT
		and player.get("vp", 0) < 1
		and _role_applies(state, player)
		and state["selected_role_id"] == RoleIds.GRAY_CARDINAL
		and not player["role_flags"]["gray_cardinal_first_accountant_bypass_used"]
	)


## Consumes only role flags associated with a completed purchase.
static func consume_role_flags_after_purchase(
	state: Dictionary,
	player_id: String,
	card_id: String,
	applied_modifiers: Array[Dictionary]
) -> Dictionary:
	var candidate: Dictionary = state.duplicate(true)
	var player: Dictionary = _find_player(candidate, player_id)
	if not _role_applies(candidate, player):
		return candidate
	for modifier: Dictionary in applied_modifiers:
		if modifier.get("source") != "role":
			continue
		var flag: String = str(modifier.get("flag", ""))
		if modifier.get("consume_on_success", false) and player["role_flags"].has(flag):
			player["role_flags"][flag] = true
	if (
		card_id == GameIds.CARD_ACCOUNTANT
		and player["vp"] < 1
		and candidate["selected_role_id"] == RoleIds.GRAY_CARDINAL
	):
		player["role_flags"]["gray_cardinal_first_accountant_bypass_used"] = true
	return candidate


## Returns the pure District Boss rebuild role modifier.
static func get_district_rebuild_price(
	state: Dictionary,
	player: Dictionary
) -> Dictionary:
	var modifiers: Array[Dictionary] = []
	if (
		_role_applies(state, player)
		and state["selected_role_id"] == RoleIds.DISTRICT_BOSS
		and player["status_buildings"]["can_rebuild_district_for_8"]
		and (
			player["status_buildings"]["district_control"]
			< player["status_buildings"]["workshop"]
		)
		and not player["role_flags"]["district_boss_rebuild_discount_used"]
	):
		modifiers.append(_modifier(
			RoleIds.DISTRICT_BOSS, "district_boss_rebuild_discount_used",
			-1, GameIds.CARD_DISTRICT_CONTROL, ""
		))
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"modifiers": modifiers,
	}


static func consume_role_flags_after_rebuild(
	state: Dictionary,
	player_id: String,
	applied_modifiers: Array[Dictionary]
) -> Dictionary:
	return consume_role_flags_after_purchase(
		state, player_id, GameIds.CARD_DISTRICT_CONTROL, applied_modifiers
	)


static func reset_round_role_flags(
	player: Dictionary,
	selected_role_id: String
) -> Dictionary:
	var result: Dictionary = player.duplicate(true)
	if (
		result.get("id") == GameIds.PLAYER_HUMAN
		and selected_role_id == RoleIds.MERCHANT
		and result.get("role_flags", {}).has(
			"merchant_first_war_tax_applied_this_round"
		)
	):
		result["role_flags"]["merchant_first_war_tax_applied_this_round"] = false
	return result


static func _modifier(
	role_id: String,
	flag: String,
	delta: int,
	card_id: String,
	card_type: String
) -> Dictionary:
	return {
		"id": "%s_%s" % [role_id, flag if not flag.is_empty() else card_id],
		"source": "role",
		"role_id": role_id,
		"flag": flag,
		"type": ModifierTypes.CARD_PRICE_DELTA,
		"delta": delta,
		"applies_to_card_id": card_id,
		"applies_to_card_type": card_type,
		"consume_on_success": not flag.is_empty(),
	}


static func _role_applies(state: Dictionary, player: Dictionary) -> bool:
	return (
		not player.is_empty()
		and player.get("id") == GameIds.PLAYER_HUMAN
		and not player.get("is_ai", true)
		and is_valid_role_id(str(state.get("selected_role_id", "")))
		and GameStateValidator.validate_role_flags(
			player.get("role_flags", {})
		)["ok"]
	)


static func _find_player(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}
