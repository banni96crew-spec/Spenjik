class_name CardDefinition
extends Resource

@export var id: String
@export var title: String
@export_enum("engine", "status", "defense", "war") var type: String
@export var base_price: int
@export_enum("table", "hand") var destination: String
@export var max_per_player: int = 0
@export var effect_summary: String
