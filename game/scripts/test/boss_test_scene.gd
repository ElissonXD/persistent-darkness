extends Node2D

# Cena de teste do boss: mostra a vida do dummy (estado do boss: usar o debugger do addon).
# [<-/->] anda, [Espaço] alterna invulnerável,
# [1] envia posture_broken ao boss, [2] aplica dano de teste no dummy pelo contrato,
# [R] restaura a vida do dummy.

@export_category('Teste')
@export var TEST_DAMAGE : int = 10
@export var TEST_KNOCKBACK : Vector2 = Vector2(400, -200)

# Nodes
@onready var boss = $Boss
@onready var player_dummy = $PlayerDummy
@onready var debug_label: Label = $CanvasLayer/DebugLabel

func _process(_delta: float) -> void:
	debug_label.text = "Dummy HP: %d" % player_dummy.health

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_1:
			boss.state_chart.send_event(&"posture_broken")
		KEY_2:
			# empurra o dummy para longe do boss
			var side := signf(player_dummy.global_position.x - boss.global_position.x)
			boss.deal_damage(player_dummy.hurtbox, TEST_DAMAGE, Vector2(TEST_KNOCKBACK.x * side, TEST_KNOCKBACK.y))
		KEY_R:
			player_dummy.health = player_dummy.MAX_HEALTH
