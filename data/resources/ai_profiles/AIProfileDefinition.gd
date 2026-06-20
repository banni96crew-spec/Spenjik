class_name AIProfileDefinition
extends Resource

@export var id: String
@export var purchase_scores: Dictionary
@export var attack_probability: float
@export var target_weights: Dictionary
@export var minimum_reserve_nal: int
@export_enum(
	"end_phase",
	"buy_cheapest_valid",
	"discard_action_cards",
	"attack_best_target",
	"hold_nal"
) var fallback: String
