extends Area2D

@export_category('Configurações')
@export var DAMAGE : float
@export var KNOCKBACK : Vector2

@onready var up_sword: Area2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_warning_state_entered() -> void:
	animation_player.play("warning")
	up_sword.set_deferred("monitoring", false)
	up_sword.set_deferred("monitorable", false)

func _on_appear_state_entered() -> void:
	animation_player.play("appear")
	up_sword.set_deferred("monitoring", true)
	up_sword.set_deferred("monitorable", true)

func _on_dissapear_state_entered() -> void:
	animation_player.play("dissapear")

func _on_dissapear_state_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	#só colide com player
	var player = area.owner
	var dir_x: float = 1.0 if player.global_position.x >= global_position.x else -1.0
	
	var final_knockback: Vector2 = KNOCKBACK
	final_knockback.x = abs(KNOCKBACK.x) * dir_x
	
	player.take_damage(DAMAGE, final_knockback)
