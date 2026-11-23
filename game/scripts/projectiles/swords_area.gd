extends Area2D

@export_category('Configurações')
@export var SwordObject : PackedScene
@export var SPACE_BETWEEN : float

@onready var end: Marker2D = $End
 
func invoke_swords(offset: bool) -> void:
	var slot_size: float = max(0.001, abs(SPACE_BETWEEN))
	var step: float = slot_size * 2.0
	var start_offset: float = slot_size if offset else 0.0

	var total_distance: float = global_position.distance_to(end.global_position)
	if total_distance < start_offset:
		return

	var direction: Vector2 = (end.global_position - global_position).normalized()
	var start_pos: Vector2 = global_position + direction * start_offset
	var remaining_distance: float = total_distance - start_offset
	var segments: int = clampi(floori(remaining_distance / step) + 1, 0, 20)

	for i in range(segments):
		var instance = SwordObject.instantiate()
		get_parent().add_child.call_deferred(instance)
		instance.global_position = start_pos + direction * (i * step)
