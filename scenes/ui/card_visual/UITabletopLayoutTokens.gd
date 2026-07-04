class_name UITabletopLayoutTokens
extends RefCounted

# Must stay aligned with GameScreen.tscn tabletop layout mins.
const DESIGN_VIEWPORT := Vector2(1920, 1080)
const TABLETOP_MARGIN := 6
const OPPONENT_ZONE_WIDTH := 244
const SIDE_INFO_WIDTH := 255
const TABLE_WORKSPACE_SEPARATION := 6
const MIN_CENTER_WIDTH_FOR_SIX_MARKET_CARDS := 1072


static func expected_center_column_width(viewport_width: float) -> float:
	var margins: float = TABLETOP_MARGIN * 2.0
	var workspace_width: float = viewport_width - margins
	var fixed: float = (
		OPPONENT_ZONE_WIDTH * 2.0
		+ SIDE_INFO_WIDTH
		+ TABLE_WORKSPACE_SEPARATION * 3.0
	)
	return workspace_width - fixed
