extends Node2D



@onready var player: Node = $Player
@onready var target_dummy: Node = $TargetDummy
@onready var debug_label: Label = $CanvasLayer/DebugLabel

func _process(_delta: float) -> void:
	debug_label.text = "Vida: %d | Estamina: %d | Dummy: %d" % [player.STATS.health, player.STATS.stamina, target_dummy.health]
