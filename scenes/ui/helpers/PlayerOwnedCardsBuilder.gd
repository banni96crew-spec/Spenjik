class_name PlayerOwnedCardsBuilder
extends RefCounted

const ENGINE_KEYS_TO_CARD_IDS := {
	"informers": GameIds.CARD_INFORMANT,
	"laundries": GameIds.CARD_LAUNDRY,
	"accountants": GameIds.CARD_ACCOUNTANT,
	"brothel": GameIds.CARD_BROTHEL,
}

const STATUS_KEYS_TO_CARD_IDS := {
	"stash": GameIds.CARD_STASH,
	"workshop": GameIds.CARD_WORKSHOP,
	"district_control": GameIds.CARD_DISTRICT_CONTROL,
}


static func build_owned_displays(
	player: Dictionary,
	card_definitions: Dictionary
) -> Array[Dictionary]:
	var displays: Array[Dictionary] = []
	_append_counted_cards(
		displays, player.get("engine", {}), ENGINE_KEYS_TO_CARD_IDS, card_definitions
	)
	_append_counted_cards(
		displays,
		player.get("status_buildings", {}),
		STATUS_KEYS_TO_CARD_IDS,
		card_definitions,
	)
	_append_defense_cards(
		displays, player.get("defense", {}), card_definitions
	)
	for card_id: Variant in player.get("hand", []):
		_append_display(displays, str(card_id), card_definitions)
	return displays


static func _append_counted_cards(
	displays: Array[Dictionary],
	state: Dictionary,
	key_map: Dictionary,
	card_definitions: Dictionary
) -> void:
	for state_key: Variant in key_map.keys():
		var card_id: String = str(key_map[state_key])
		var value: Variant = state.get(state_key, 0)
		if typeof(value) == TYPE_BOOL:
			if value:
				_append_display(displays, card_id, card_definitions)
			continue
		for _i: int in int(value):
			_append_display(displays, card_id, card_definitions)


static func _append_defense_cards(
	displays: Array[Dictionary],
	defense: Dictionary,
	card_definitions: Dictionary
) -> void:
	if bool(defense.get("cops_active", false)):
		_append_display(displays, GameIds.CARD_COPS, card_definitions)
	if str(defense.get("cartel_state", "")) == DefenseStates.ACTIVE:
		_append_display(displays, GameIds.CARD_CARTEL, card_definitions)
	if str(defense.get("judge_state", "")) == DefenseStates.ACTIVE:
		_append_display(displays, GameIds.CARD_JUDGE, card_definitions)


static func _append_display(
	displays: Array[Dictionary],
	card_id: String,
	card_definitions: Dictionary
) -> void:
	if not card_definitions.has(card_id):
		return
	var display: Dictionary = card_definitions[card_id].duplicate()
	display["context"] = "compact"
	displays.append(display)
