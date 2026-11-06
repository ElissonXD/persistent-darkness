extends ProgressBar

@export var player_dummy : Node2D 

func _process(_delta: float) -> void:
	if player_dummy and "health" in player_dummy:
		max_value = player_dummy.MAX_HEALTH
		value = player_dummy.health
