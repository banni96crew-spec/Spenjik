class_name StreetDealDefinition
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export var min_round: int = 4
@export var weight: int = 100
@export var max_uses_per_run: int = 1
@export var option_a_label: String
@export var option_a_description: String
@export var option_a_effects: Array[Dictionary]
@export var option_b_label: String
@export var option_b_description: String
@export var option_b_effects: Array[Dictionary]
