class_name MeleeHitbox
extends Area2D

# Hitbox corpo a corpo reutilizável (camada boss, máscara player).
# Só causa dano enquanto ativa e atinge cada alvo no máximo uma vez por golpe:
# a lista de atingidos zera a cada activate().
# Dano segue o contrato: take_damage(amount, knockback) no dono do hurtbox, se existir.

@export_category('Debug')
## Desenha a área da hitbox enquanto ela está ativa
@export var DEBUG_DRAW : bool = true
@export var DEBUG_COLOR : Color = Color(1, 0, 0, 0.35)

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
	area_entered.connect(_on_area_entered)

func activate(amount: int, knockback_force: Vector2) -> void:
	damage = amount
	knockback = knockback_force
	hit_targets.clear()
	active = true
	set_deferred("monitoring", true)
	queue_redraw()

func deactivate() -> void:
	# a flag desliga o dano na hora; o monitoring só pode mudar no fim do frame
	active = false
	hit_targets.clear()
	set_deferred("monitoring", false)
	queue_redraw()

# Espelha a forma para o lado em que o dono está olhando
func set_facing(direction: float) -> void:
	if direction == 0:
		return

	facing = signf(direction)
	collision_shape_2d.position.x = absf(collision_shape_2d.position.x) * facing
	queue_redraw()

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

func _draw() -> void:
	if not (active and DEBUG_DRAW):
		return

	var rect_shape := collision_shape_2d.shape as RectangleShape2D
	if rect_shape == null:
		return
	draw_rect(Rect2(collision_shape_2d.position - rect_shape.size / 2, rect_shape.size), DEBUG_COLOR)
