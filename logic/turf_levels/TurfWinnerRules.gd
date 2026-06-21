class_name TurfWinnerRules

const LEVEL_10_REASON := "TURF_LEVEL_10_AI_VP_TIE_BREAK"


static func resolve_level_10_ai_tie_break(
	state: Dictionary,
	tied_players: Array
) -> Dictionary:
	var not_applied: Dictionary = {
		"ok": true,
		"applied": false,
		"winner_id": "",
		"reason": "",
		"tied_player_ids": _player_ids(tied_players),
		"ai_tie_break": {},
	}
	if not TurfLevelLogic.is_level_active(
		int(state.get("turf_level", 0)), TurfLevelIds.AI_WINS_VP_TIES
	):
		return not_applied
	var ai_leaders: Array[Dictionary] = []
	for player: Dictionary in tied_players:
		if player.get("is_ai", false):
			ai_leaders.append(player)
	if ai_leaders.is_empty():
		return not_applied
	var winner: Dictionary = _select_ai_leader(ai_leaders)
	return {
		"ok": true,
		"applied": true,
		"winner_id": winner["id"],
		"reason": LEVEL_10_REASON,
		"tied_player_ids": _player_ids(tied_players),
		"ai_tie_break": {
			"method": "highest_nal_then_stable_ai_order",
			"selected_ai_id": winner["id"],
		},
	}


static func _select_ai_leader(ai_leaders: Array[Dictionary]) -> Dictionary:
	var maximum_nal: int = -1
	for player: Dictionary in ai_leaders:
		maximum_nal = maxi(maximum_nal, int(player["nal"]))
	var nal_tied: Array[Dictionary] = []
	for player: Dictionary in ai_leaders:
		if int(player["nal"]) == maximum_nal:
			nal_tied.append(player)
	if nal_tied.size() == 1:
		return nal_tied[0]
	for player_id: String in GameIds.AI_PLAYER_IDS:
		for player: Dictionary in nal_tied:
			if player["id"] == player_id:
				return player
	return nal_tied[0]


static func _player_ids(players: Array) -> Array[String]:
	var ids: Array[String] = []
	for player: Dictionary in players:
		ids.append(str(player["id"]))
	return ids
