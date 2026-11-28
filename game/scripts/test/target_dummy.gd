extends Node2D

# Alvo de teste do player: faz o papel da hurtbox do boss (camada 3) e guarda a vida.
# Segue o contrato de dano: o dono da hurtbox implementa take_damage().

@export_category('Dummy')
@export var HEALTH : int = 500

var health : int = 0

func _ready() -> void:
	health = HEALTH

# Mesmo formato do boss: take_damage(amount, stagger, element, buildup)
func take_damage(amount: int, _stagger: float, _element: String, _buildup: float) -> void:
	health = maxi(health - amount, 0)
