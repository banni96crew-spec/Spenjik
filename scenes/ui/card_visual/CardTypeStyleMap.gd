class_name CardTypeStyleMap
extends RefCounted

const MARKER_GEAR := "⚙"
const MARKER_CROWN := "♛"
const MARKER_WAR := "⚔"
const MARKER_WAR_FALLBACK := "✕✕"
const MARKER_SHIELD := "⛨"


static func marker_for_type(card_type: String) -> String:
	return str(style_for_type(card_type).get("marker", "?"))


static func style_for_type(card_type: String) -> Dictionary:
	match card_type:
		CardTypes.ENGINE:
			return {
				"marker": MARKER_GEAR,
				"art": "MACHINERY",
				"accent": CardVisualTokens.INK,
				"border": CardVisualTokens.INK,
			}
		CardTypes.STATUS:
			return {
				"marker": MARKER_CROWN,
				"art": "INFLUENCE",
				"accent": CardVisualTokens.INK,
				"border": CardVisualTokens.INK,
			}
		CardTypes.WAR:
			return {
				"marker": MARKER_WAR,
				"art": "HOSTILE ACTION",
				"accent": CardVisualTokens.WAR_RED,
				"border": CardVisualTokens.WAR_BORDER,
			}
		CardTypes.DEFENSE:
			return {
				"marker": MARKER_SHIELD,
				"art": "PROTECTION",
				"accent": CardVisualTokens.INK,
				"border": CardVisualTokens.INK,
			}
	return {
		"marker": "?",
		"art": "UNKNOWN",
		"accent": CardVisualTokens.MUTED,
		"border": CardVisualTokens.MUTED,
	}
