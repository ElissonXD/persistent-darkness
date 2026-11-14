extends Node2D

@onready var player: Node = $Player
@onready var boss: Node = $Boss
@onready var debug_label: Label = $CanvasLayer/DebugLabel

func _process(_delta: float) -> void:
	var stats: PlayerStats = player.get("STATS")
	debug_label.text = "Player HP: %d | Estamina: %d | Boss HP (teste): %d\nA/D: mover | W: pular | Espaço: rolar | Clique esquerdo: atacar | 3: forçar fase 2 do boss" % [
		roundi(stats.health),
		roundi(stats.stamina),
		roundi(boss.get("test_health"))
	]

# [3] força a fase 2 do boss (só para teste)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_3:
		# boss está tipado como Node: call evita erro de método desconhecido
		boss.call(&"enter_phase_2")
