extends "res://game/scripts/enemies/boss.gd"

var test_health: float

func _ready() -> void:
	test_health = HEALTH
	super._ready()

func take_damage(amount: int, _knockback: Vector2) -> void:
	test_health = maxf(test_health - amount, 0.0)
