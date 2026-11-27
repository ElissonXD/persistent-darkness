extends ProgressBar

@export var player : CharacterBody2D

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")

	if player:
		await get_tree().process_frame
		if "STATS" in player and player.STATS:
			player.STATS.health_changed.connect(_on_health_changed)
			max_value = player.STATS.get_stat(&"MAX_HEALTH")
			value = player.STATS.health
			return

	push_warning("HealthBar: Player ou STATS não encontrados!")

func _on_health_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current
