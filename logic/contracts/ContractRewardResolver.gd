class_name ContractRewardResolver


static func apply(player: Dictionary, definition: ContractDefinition) -> Dictionary:
	match definition.reward_type:
		RewardTypes.VP:
			player["vp"] += definition.reward_amount
		RewardTypes.NAL:
			player["nal"] += definition.reward_amount
		_:
			return {
				"ok": false,
				"error": ValidationErrors.REQUIREMENT_NOT_MET,
			}
	return {
		"ok": true,
		"error": ValidationErrors.OK,
		"reward_type": definition.reward_type,
		"reward_amount": definition.reward_amount,
	}
