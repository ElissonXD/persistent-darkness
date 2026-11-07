extends Area2D

@export_category('Configurações')
@export var DAMAGE : float
@export var KNOCKBACK : Vector2

@onready var up_sword: Area2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _on_warning_state_entered() -> void:
	animated_sprite_2d.play("warning")
	up_sword.set_deferred("monitoring", false)
	up_sword.set_deferred("monitorable", false)

func _on_appear_state_entered() -> void:
	animated_sprite_2d.play("appear")
	up_sword.set_deferred("monitoring", true)
	up_sword.set_deferred("monitorable", true)

func _on_dissapear_state_entered() -> void:
	animated_sprite_2d.play("dissapear")
	up_sword.set_deferred("monitoring", false)
	up_sword.set_deferred("monitorable", false)

func _on_dissapear_state_exited() -> void:
	queue_free()
