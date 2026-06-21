class_name StreetDealContactHandoff


static func apply_inside_contact_offer(
	state: Dictionary,
	deal_id: String,
	option_id: String
) -> Dictionary:
	if (
		deal_id != StreetDealIds.INSIDE_CONTACT
		or option_id != StreetDealOptionIds.OPTION_A
	):
		return {"ok": true, "error": ValidationErrors.OK, "state": state}
	return ContactLogic.generate_contact_offer(
		state,
		GameIds.PLAYER_HUMAN,
		2,
		StreetDealIds.INSIDE_CONTACT
	)
