class_name AITargetLogic

## Owns AI target scoring (§5.17). Read-only: never mutates state and consumes
## random only for an exact target-score tie-break.


## Legal targets are every other player; the AI never targets itself.
static func get_valid_targets_for_ai(
	state: Dictionary,
	attacker_id: String
) -> Array[String]:
	var targets: Array[String] = []
	for player_id: String in GameIds.PLAYER_IDS:
		if player_id != attacker_id and not _find(state, player_id).is_empty():
			targets.append(player_id)
	return targets


## Computes the weighted target score and its feature breakdown.
static func score_target(
	state: Dictionary,
	attacker_id: String,
	target_id: String,
	profile: AIProfileDefinition
) -> Dictionary:
	var attacker: Dictionary = _find(state, attacker_id)
	var target: Dictionary = _find(state, target_id)
	if attacker.is_empty() or target.is_empty() or attacker_id == target_id:
		return {"ok": false, "error": ValidationErrors.INVALID_TARGET,
			"score": 0.0, "features": {}}
	var status: Dictionary = target["status_buildings"]
	var features: Dictionary = {
		"vpLead": maxi(0, int(target["vp"]) - int(attacker["vp"])),
		"availableNal": maxi(0, int(target["nal"]) - PriceLogic.get_protected_nal(
			int(target["engine"]["accountants"])
		)),
		"lowDefense": _missing_active_defenses(target),
		"destructibleBuildings": int(status["stash"]) + int(status["workshop"])
			+ int(status["district_control"]),
		"revenge": 1 if target_id == attacker["last_attacked_by"] else 0,
		"humanBias": 1 if target_id == GameIds.PLAYER_HUMAN else 0,
	}
	var weights: Dictionary = profile.target_weights
	var score: int = 0
	for feature: String in features:
		score += int(features[feature]) * int(weights.get(feature, 0))
	return {"ok": true, "error": ValidationErrors.OK,
		"score": float(score), "features": features}


## Picks the highest-scoring target, breaking exact ties with SeededPicker.
static func choose_target(
	state: Dictionary,
	attacker_id: String,
	target_ids: Array[String],
	profile: AIProfileDefinition
) -> Dictionary:
	var scored: Array[Dictionary] = []
	var best: float = -1.0
	for target_id: String in target_ids:
		var result: Dictionary = score_target(state, attacker_id, target_id, profile)
		if not result["ok"]:
			continue
		scored.append({"target_id": target_id, "score": result["score"]})
		best = maxf(best, float(result["score"]))
	if scored.is_empty():
		return {"ok": false, "error": ValidationErrors.INVALID_TARGET,
			"target_id": "", "score": 0.0, "random": state["random"]}
	var tied: Array[Dictionary] = []
	for entry: Dictionary in scored:
		if is_equal_approx(float(entry["score"]), best):
			tied.append(entry)
	var pick: Dictionary = SeededPicker.pick_best_tie(
		state["random"], tied, "ai_target_tiebreak"
	)
	if not pick["ok"]:
		return {"ok": false, "error": ValidationErrors.INVALID_TARGET,
			"target_id": "", "score": 0.0, "random": state["random"]}
	return {"ok": true, "error": ValidationErrors.OK,
		"target_id": pick["selected"]["target_id"],
		"score": pick["selected"]["score"], "random": pick["random"]}


static func _missing_active_defenses(target: Dictionary) -> int:
	var defense: Dictionary = target["defense"]
	var active: int = 0
	if defense["cops_active"]:
		active += 1
	if defense["cartel_state"] == DefenseStates.ACTIVE:
		active += 1
	if defense["judge_state"] == DefenseStates.ACTIVE:
		active += 1
	return 3 - active


static func _find(state: Dictionary, player_id: String) -> Dictionary:
	for player: Dictionary in state.get("players", []):
		if player.get("id") == player_id:
			return player
	return {}
