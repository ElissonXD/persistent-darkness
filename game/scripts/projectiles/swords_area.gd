extends Area2D

@export_category('Configurações')
@export var SwordObject : PackedScene
@export var SPACE_BETWEEN : float
@export var OFFSET : float

@onready var end: Marker2D = $End
 
func _ready() -> void:
	var offset = false
	var cur_global_pos = global_position
	if offset:
		cur_global_pos.x += OFFSET
		
	var distance = cur_global_pos.distance_to(end.global_position)
	
	var space = max(0.001, abs(SPACE_BETWEEN))
	
	var segments = clampi(int(distance / space), 0, 10)
	
	var direction = (end.global_position - cur_global_pos).normalized()
	
	for i in range(segments):
		var instance = SwordObject.instantiate()
		add_child.call_deferred(instance)
		instance.global_position = cur_global_pos + direction * (i * space)
