extends GutTest


func before_each() -> void:
	GameStateManager.reset_game()


func after_each() -> void:
	GameStateManager.reset_game()


func test_rebuild_selectors_cover_market_panel_states() -> void:
	GameStateManager.state = TestGameStateFactory.market_state(
		"rebuild_facade", 1
	)
	var human: Dictionary = TestPlayers.find(
		GameStateManager.state, GameIds.PLAYER_HUMAN
	)
	human["status_buildings"]["workshop"] = 1
	human["status_buildings"]["district_control"] = 0
	human["status_buildings"]["can_rebuild_district_for_8"] = false
	assert_eq(
		GameStateManager.get_rebuild_district_disabled_reason(
			GameIds.PLAYER_HUMAN
		),
		ValidationErrors.REQUIREMENT_NOT_MET
	)
	human["status_buildings"]["can_rebuild_district_for_8"] = true
	human["nal"] = 7
	assert_eq(
		GameStateManager.get_rebuild_district_disabled_reason(
			GameIds.PLAYER_HUMAN
		),
		ValidationErrors.NOT_ENOUGH_NAL
	)
	human["nal"] = 8
	human["status_buildings"]["district_control"] = 1
	assert_eq(
		GameStateManager.get_rebuild_district_disabled_reason(
			GameIds.PLAYER_HUMAN
		),
		ValidationErrors.REQUIREMENT_NOT_MET
	)
	human["status_buildings"]["district_control"] = 0
	assert_eq(
		GameStateManager.get_rebuild_district_disabled_reason(
			GameIds.PLAYER_HUMAN
		),
		ValidationErrors.OK
	)
	var preview: Dictionary = GameStateManager.get_rebuild_district_preview(
		GameIds.PLAYER_HUMAN
	)
	assert_true(preview["ok"], str(preview))
	assert_eq(preview["card_id"], GameIds.CARD_DISTRICT_CONTROL)
	assert_eq(preview["final_rebuild_price"], 8)
