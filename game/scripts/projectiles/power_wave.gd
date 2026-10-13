extends RigidBody2D

@export_category("Dados")
@export var SPEED: float = 400
@export var DIRECTION: int = 1
@export var DAMAGE: int = 20
@export var DURATION: float = 5

# Nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	linear_velocity.x = SPEED
	return

func _process(delta: float) -> void:
	
	if DURATION > 0:
		DURATION -= delta
		
		linear_velocity.x = SPEED
		if DURATION <= 0:
			vanish()

# colisão
func _on_hitbox_area_entered(area: Area2D) -> void:
	var player_body = area.owner
	# player_body = player_body as Player
	# causar dano
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
