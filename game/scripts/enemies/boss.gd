extends CharacterBody2D

@export_category('Boss Data')
@export var HEALTH : float = 1000
@export var POSTURE : float = 100.0
@export var BUILDUP_VALUE : float = 100.0
@export var WALK_SPEED : float = 300.0
@export var JUMP_VELOCITY : float = -400.0

@export_category('Effects buildups')
var FIRE_BUILDUP = 0
var FREEZE_BUILDUP = 0
var ELETRIC_BUILDUP = 0

func _physics_process(delta: float) -> void:
	pass

	move_and_slide()
