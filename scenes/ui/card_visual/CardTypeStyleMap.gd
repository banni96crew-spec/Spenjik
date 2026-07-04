class_name CardTypeStyleMap
extends RefCounted

const MARKER_ENGINE := CardTypeMarker.ASSET_ENGINE
const MARKER_CROWN := CardTypeMarker.ASSET_STATUS
const MARKER_WAR := CardTypeMarker.ASSET_WAR
const MARKER_SHIELD := CardTypeMarker.ASSET_DEFENSE


static func marker_for_type(card_type: String) -> String:
	return str(style_for_type(card_type).get("marker_asset", ""))


static func style_for_type(card_type: String) -> Dictionary:
	match card_type:
		CardTypes.ENGINE:
			return {
				"marker_asset": MARKER_ENGINE,
				"art": "MACHINERY",
				"accent": CardVisualTokens.INK,
				"border": CardVisualTokens.INK,
			}
		CardTypes.STATUS:
			return {
				"marker_asset": MARKER_CROWN,
				"art": "INFLUENCE",
				"accent": CardVisualTokens.INK,
				"border": CardVisualTokens.INK,
			}
		CardTypes.WAR:
			return {
				"marker_asset": MARKER_WAR,
				"art": "HOSTILE ACTION",
				"accent": CardVisualTokens.WAR_RED,
				"border": CardVisualTokens.WAR_BORDER,
			}
		CardTypes.DEFENSE:
			return {
				"marker_asset": MARKER_SHIELD,
				"art": "PROTECTION",
				"accent": CardVisualTokens.INK,
				"border": CardVisualTokens.INK,
			}
	return {
		"marker_asset": "",
		"art": "UNKNOWN",
		"accent": CardVisualTokens.MUTED,
		"border": CardVisualTokens.MUTED,
	}
