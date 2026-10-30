extends RigidBody2D

@export_category("Dados")
@export var STRONGER_VARIANT: bool = false # Versão mais forte (20% a mais de dano e 50% de velocidade)
@export var SPEED: float = 400
@export var DIRECTION: int = 1
@export var DAMAGE: int = 20
@export var DURATION: float = 5

# Nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	linear_velocity.x = SPEED * DIRECTION
	
	if DIRECTION < 0:
		animated_sprite_2d.flip_h = true
		
	if STRONGER_VARIANT:
		animated_sprite_2d.material.set_shader_parameter("mix_weight", 0.7)
		DAMAGE *= 1.2
		SPEED *= 1.5
	return

func _process(delta: float) -> void:
	
	if DURATION > 0:
		DURATION -= delta
		
		linear_velocity.x = SPEED * DIRECTION
		if DURATION <= 0:
			vanish()

# colisão
func _on_hitbox_area_entered(area: Area2D) -> void:
	var player_body = area.owner
	# player_body = player_body as Player
	player_body.take_damage(DAMAGE, Vector2(0,0)) #temporario
	vanish()

func _on_body_entered(body: Node) -> void:
	# só detecta terreno
	vanish()

# Utils

func vanish():
	linear_velocity.x = 0
	animated_sprite_2d.play("vanish")
	hitbox.collision_layer = 0
	await get_tree().create_timer(1).timeout
	queue_free()
	return
