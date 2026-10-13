@tool
class_name AttackPhase
extends AtomicState

# Fase de um ataque (Telegraphy, Hit, Gap, Recovery...), usada como estado atômico na state chart.
# Ao entrar liga ou desliga a hitbox conforme HITBOX_ACTIVE; ao sair (inclusive quando a fase é
# interrompida, ex.: Stunned) a hitbox SEMPRE é desligada.
# A duração da fase fica no delay_in_seconds da transição que sai dela.

@export_category('Fase de ataque')
@export var HITBOX : MeleeHitbox
@export var HITBOX_ACTIVE : bool = false
## Dano por golpe enquanto a hitbox estiver ativa (o boss.gd configura os combos dele)
@export var DAMAGE : int = 0
## Empurrão aplicado no alvo; x é sempre convertido para longe do atacante
@export var KNOCKBACK : Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	state_entered.connect(_on_state_entered)
	state_exited.connect(_on_state_exited)

func _on_state_entered() -> void:
	if HITBOX == null:
		return

	if HITBOX_ACTIVE:
		HITBOX.activate(DAMAGE, KNOCKBACK)
	else:
		HITBOX.deactivate()

func _on_state_exited() -> void:
	if HITBOX != null:
		HITBOX.deactivate()
