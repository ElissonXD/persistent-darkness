extends "res://game/scripts/enemies/boss.gd"

var test_health: float

func _ready() -> void:
	test_health = HEALTH
	super._ready()

# passa pelo take_damage do boss para a fase 2 começar ao chegar em PHASE_2_HEALTH_RATIO da vida
func take_damage(amount: int, knockback: Vector2) -> void:
	super.take_damage(amount, knockback)
	test_health = health
