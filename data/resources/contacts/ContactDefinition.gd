class_name ContactDefinition
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export_enum("passive", "active") var effect_kind: String
@export var cooldown_rounds: int = 0
@export var effect_type: String
