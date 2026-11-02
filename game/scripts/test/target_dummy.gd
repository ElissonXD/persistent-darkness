extends Node2D



@export_category('Dummy')
@export var HEALTH : int = 500

var health : int = 0

func _ready() -> void:
	health = HEALTH

func take_damage(amount: int, _knockback: Vector2) -> void:
	health = maxi(health - amount, 0)
