class_name PresentationViewBuilder


static func card(definition: CardDefinition) -> Dictionary:
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"title": definition.title,
		"type": definition.type,
		"base_price": definition.base_price,
		"destination": definition.destination,
		"effect_summary": definition.effect_summary,
	}


static func cards_by_id() -> Dictionary:
	var result: Dictionary = {}
	for definition: CardDefinition in CardCatalog.get_all():
		result[definition.id] = card(definition)
	return result


static func cards_for_ids(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card_id: Variant in ids:
		var view: Dictionary = card(CardCatalog.get_by_id(str(card_id)))
		if not view.is_empty():
			result.append(view)
	return result


static func contract(definition: ContractDefinition) -> Dictionary:
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"title": definition.title,
		"description": definition.description,
		"deadline_round": definition.deadline_round,
		"progress_required": definition.progress_required,
		"reward_type": definition.reward_type,
		"reward_amount": definition.reward_amount,
	}


static func contracts_for_ids(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for contract_id: Variant in ids:
		var view: Dictionary = contract(
			ContractCatalog.get_by_id(str(contract_id))
		)
		if not view.is_empty():
			result.append(view)
	return result


static func contract_runtime(runtime: Dictionary) -> Dictionary:
	if runtime.is_empty():
		return {}
	var result: Dictionary = contract(
		ContractCatalog.get_by_id(str(runtime.get("contract_id", "")))
	)
	result["runtime"] = runtime.duplicate(true)
	return result


static func contact(definition: ContactDefinition) -> Dictionary:
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"title": definition.title,
		"description": definition.description,
		"effect_kind": definition.effect_kind,
		"cooldown_rounds": definition.cooldown_rounds,
	}


static func contacts_for_ids(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for contact_id: Variant in ids:
		var view: Dictionary = contact(
			ContactCatalog.get_by_id(str(contact_id))
		)
		if not view.is_empty():
			result.append(view)
	return result


static func street_deal(definition: StreetDealDefinition) -> Dictionary:
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"title": definition.title,
		"description": definition.description,
		"option_a_label": definition.option_a_label,
		"option_a_description": definition.option_a_description,
		"option_b_label": definition.option_b_label,
		"option_b_description": definition.option_b_description,
	}


static func role(definition: RoleDefinition) -> Dictionary:
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"title": definition.title,
		"effect_summary": definition.effect_summary,
		"limitation_summary": definition.limitation_summary,
	}
