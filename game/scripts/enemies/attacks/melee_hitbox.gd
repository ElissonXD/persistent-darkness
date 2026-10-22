class_name MeleeHitbox
extends Area2D

# Hitbox corpo a corpo reutilizável (camada boss, máscara player).
# Só causa dano enquanto ativa e atinge cada alvo no máximo uma vez por golpe:
# a lista de atingidos zera a cada activate().
# Dano segue o contrato: take_damage(amount, knockback) no dono do hurtbox, se existir.
# area_entered -> _on_area_entered é ligado na aba Sinais da cena que usa a hitbox.

# Nodes
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var active : bool = false
var damage : int = 0
var knockback : Vector2 = Vector2.ZERO
# 1 = olhando para a direita, -1 = esquerda
var facing : float = 1.0
var hit_targets : Array[Node] = []

func _ready() -> void:
	set_deferred("monitoring", false)
	# forma desabilitada aparece cinza em "Formas de colisão visíveis"; ativa, aparece vermelha
	collision_shape_2d.set_deferred("disabled", true)

func activate(amount: int, knockback_force: Vector2) -> void:
	damage = amount
	knockback = knockback_force
	hit_targets.clear()
	active = true
	set_deferred("monitoring", true)
	collision_shape_2d.set_deferred("disabled", false)

func deactivate() -> void:
	# a flag desliga o dano na hora; o monitoring só pode mudar no fim do frame
	active = false
	hit_targets.clear()
	set_deferred("monitoring", false)
	collision_shape_2d.set_deferred("disabled", true)

# Espelha a forma para o lado em que o dono está olhando
func set_facing(direction: float) -> void:
	if direction == 0:
		return

	facing = signf(direction)
	collision_shape_2d.position.x = absf(collision_shape_2d.position.x) * facing

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return

	var target = area.owner
	if target == null or target in hit_targets or not target.has_method("take_damage"):
		return

	hit_targets.append(target)
	# empurra para longe do atacante
	var direction := signf(area.global_position.x - global_position.x)
	if direction == 0:
		direction = facing
	target.take_damage(damage, Vector2(absf(knockback.x) * direction, knockback.y))
