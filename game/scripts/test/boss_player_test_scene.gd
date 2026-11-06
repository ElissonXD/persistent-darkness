extends Node2D

@onready var player: Node = $Player
@onready var boss: Node = $Boss
@onready var debug_label: Label = $CanvasLayer/DebugLabel

func _process(_delta: float) -> void:
	var stats: PlayerStats = player.get("STATS")
	debug_label.text = "Player HP: %d | Estamina: %d | Boss HP (teste): %d\nA/D: mover | W: pular | Espaço: rolar | Clique esquerdo: atacar" % [
		roundi(stats.health),
		roundi(stats.stamina),
		roundi(boss.get("test_health"))
	]
