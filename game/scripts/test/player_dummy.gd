extends CharacterBody2D

# Player falso só para testar o boss. Implementa o contrato de dano:
# hurtbox (Area2D, camada 2) + take_damage(amount, knockback) no dono.

@export_category('Dummy Data')
@export var MAX_HEALTH : int = 100
@export var WALK_SPEED : float = 250.0
## Quanto o empurrão horizontal perde por segundo
@export var KNOCKBACK_FRICTION : float = 1200.0
## Transparência do sprite enquanto invulnerável
@export var INVULNERABLE_ALPHA : float = 0.4

# Nodes
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $Hurtbox

var health : int
var invulnerable : bool = false
var knockback_velocity : Vector2 = Vector2.ZERO

func _ready() -> void:
	health = MAX_HEALTH

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	knockback_velocity.x = move_toward(knockback_velocity.x, 0, KNOCKBACK_FRICTION * delta)
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * WALK_SPEED + knockback_velocity.x

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	# Espaço simula os i-frames do roll
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		set_invulnerable(not invulnerable)

func set_invulnerable(value: bool) -> void:
	invulnerable = value
	hurtbox.set_deferred("monitorable", not value)
	sprite_2d.modulate.a = INVULNERABLE_ALPHA if value else 1.0

func take_damage(amount: int, knockback: Vector2) -> void:
	if invulnerable or health <= 0:
		return

	health = maxi(health - amount, 0)
	knockback_velocity.x = knockback.x
	if knockback.y != 0:
		velocity.y = knockback.y
