extends GutTest


func test_ai_profile_catalog_matches_owner_data() -> void:
	CatalogTestHelper.assert_exact_ids(
		self, AIProfileCatalog.get_all_ids(), AIProfileIds.ALL
	)
	var expected: Dictionary = {
		"builder": [0.25, 3, "hold_nal"],
		"racketeer": [0.80, 1, "attack_best_target"],
		"merchant": [0.20, 6, "hold_nal"],
		"paranoid": [0.20, 4, "buy_cheapest_valid"],
		"schemer": [0.55, 3, "end_phase"],
		"avenger": [0.65, 2, "attack_best_target"],
	}
	for profile_id: String in AIProfileIds.ALL:
		var definition: AIProfileDefinition = AIProfileCatalog.get_by_id(profile_id)
		assert_not_null(definition)
		assert_eq(
			[
				definition.attack_probability,
				definition.minimum_reserve_nal,
				definition.fallback,
			],
			expected[profile_id]
		)
		assert_eq(definition.purchase_scores.size(), 6)
		assert_eq(definition.target_weights.size(), 6)


func test_ai_profile_scores_and_weights_are_exact() -> void:
	var scores: Dictionary = {
		"builder": {"stash": 100, "workshop": 90, "district_control": 85,
			"laundry": 65, "cartel": 55, "cops": 45},
		"racketeer": {"thug": 100, "bruiser": 90, "insider": 75,
			"cleaner": 70, "cops": 45, "stash": 35},
		"merchant": {"laundry": 100, "informant": 85, "brothel": 70,
			"accountant": 65, "stash": 50, "judge": 40},
		"paranoid": {"cops": 100, "cartel": 90, "judge": 85,
			"accountant": 75, "stash": 55, "workshop": 40},
		"schemer": {"saboteur": 100, "insider": 85, "judge": 70,
			"accountant": 65, "bruiser": 60, "informant": 45},
		"avenger": {"bruiser": 100, "cops": 75, "cartel": 70,
			"thug": 65, "cleaner": 60, "stash": 35},
	}
	var weights: Dictionary = {
		"builder": [4, 1, 1, 3, 2, 1],
		"racketeer": [2, 5, 3, 2, 2, 1],
		"merchant": [2, 3, 1, 1, 1, 0],
		"paranoid": [3, 1, 1, 2, 5, 1],
		"schemer": [3, 2, 2, 1, 2, 1],
		"avenger": [3, 2, 2, 4, 6, 1],
	}
	for profile_id: String in AIProfileIds.ALL:
		var definition: AIProfileDefinition = AIProfileCatalog.get_by_id(profile_id)
		assert_eq(definition.purchase_scores, scores[profile_id])
		assert_eq(
			[
				definition.target_weights["vpLead"],
				definition.target_weights["availableNal"],
				definition.target_weights["lowDefense"],
				definition.target_weights["destructibleBuildings"],
				definition.target_weights["revenge"],
				definition.target_weights["humanBias"],
			],
			weights[profile_id]
		)


func test_unknown_profile_id_is_safe_and_access_is_read_only() -> void:
	assert_null(AIProfileCatalog.get_by_id("unknown_profile"))
	assert_false(AIProfileCatalog.has_id("unknown_profile"))
	CatalogTestHelper.assert_catalog_access_is_read_only(
		self, AIProfileCatalog.get_all, AIProfileCatalog.get_all_ids
	)
