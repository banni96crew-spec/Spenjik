class_name ErrorTextMap
extends RefCounted

const TEXT: Dictionary = {
	ValidationErrors.OK: "",
	ValidationErrors.INVALID_PHASE: "Not available in this phase.",
	ValidationErrors.PHASE_NOT_READY: "Other players are not ready yet.",
	ValidationErrors.NOT_ENOUGH_NAL: "Not enough Nal.",
	ValidationErrors.CARD_NOT_AVAILABLE_IN_MARKET: "Card is unavailable.",
	ValidationErrors.CARD_ALREADY_PURCHASED_THIS_ROUND: "Already purchased.",
	ValidationErrors.REQUIREMENT_NOT_MET: "Requirement not met.",
	ValidationErrors.CARD_LIMIT_REACHED: "Card limit reached.",
	ValidationErrors.INVALID_TARGET: "Choose a valid target.",
	ValidationErrors.INVALID_ACTION_CARD: "Choose a valid War card.",
	ValidationErrors.ATTACK_MODE_REQUIRED: "Choose an attack mode.",
	ValidationErrors.INVALID_ATTACK_MODE: "Invalid attack mode.",
	ValidationErrors.STREET_DEAL_CHOICE_UNAVAILABLE: "Choice unavailable.",
	ValidationErrors.INVALID_STREET_DEAL_OPTION: "Choose a valid option.",
	ValidationErrors.ACTIVE_DEBT_EXISTS: "An active debt already exists.",
	ValidationErrors.CONTACT_LOCKED: "Contact is unavailable.",
	ValidationErrors.CONTACT_ON_COOLDOWN: "Contact is on cooldown.",
	ValidationErrors.CONTACT_LIMIT_REACHED: "Contact limit reached.",
	ValidationErrors.CONTACT_OFFER_UNAVAILABLE: "No contact offer is available.",
	ValidationErrors.CONTRACT_NOT_COMPLETED: "Contract is not completed.",
	ValidationErrors.CONTRACT_NOT_CLAIMABLE: "Reward cannot be claimed.",
	ValidationErrors.CONTRACT_ALREADY_CLAIMED: "Reward already claimed.",
	ValidationErrors.GAME_NOT_STARTED: "Start a game first.",
	ValidationErrors.GAME_ALREADY_OVER: "The match is over.",
}


static func to_text(error: String) -> String:
	if TEXT.has(error):
		return str(TEXT[error])
	return error.replace("_", " ").capitalize()
