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
	_append_hand_cards(
		displays, player.get("hand", []), card_definitions
	)
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
				_append_display(displays, card_id, card_definitions, 1)
			continue
		var count: int = int(value)
		if count > 0:
			_append_display(displays, card_id, card_definitions, count)


static func _append_hand_cards(
	displays: Array[Dictionary],
	hand: Array,
	card_definitions: Dictionary
) -> void:
	var counts: Dictionary = {}
	for card_id: Variant in hand:
		var id: String = str(card_id)
		counts[id] = int(counts.get(id, 0)) + 1
	for card_id: Variant in counts.keys():
		_append_display(
			displays, str(card_id), card_definitions, int(counts[card_id])
		)


static func _append_defense_cards(
	displays: Array[Dictionary],
	defense: Dictionary,
	card_definitions: Dictionary
) -> void:
	if bool(defense.get("cops_active", false)):
		_append_display(displays, GameIds.CARD_COPS, card_definitions, 1)
	if str(defense.get("cartel_state", "")) == DefenseStates.ACTIVE:
		_append_display(displays, GameIds.CARD_CARTEL, card_definitions, 1)
	if str(defense.get("judge_state", "")) == DefenseStates.ACTIVE:
		_append_display(displays, GameIds.CARD_JUDGE, card_definitions, 1)


static func _append_display(
	displays: Array[Dictionary],
	card_id: String,
	card_definitions: Dictionary,
	count: int = 1
) -> void:
	if not card_definitions.has(card_id):
		return
	var display: Dictionary = card_definitions[card_id].duplicate()
	display["context"] = "compact"
	if count > 1:
		display["count"] = count
	displays.append(display)
