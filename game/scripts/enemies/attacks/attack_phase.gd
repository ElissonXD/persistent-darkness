@tool
class_name AttackPhase
extends AtomicState

# Fase de um ataque (Telegraphy, Hit, Gap, Recovery...), usada como estado atômico na state chart.
# Toda fase faz o mesmo: ao entrar toca ANIMATION e liga ou desliga a hitbox conforme HITBOX_ACTIVE; ao sair (inclusive quando a fase é
# interrompida, ex.: Stunned) a hitbox SEMPRE é desligada.
# A duração da fase fica no delay_in_seconds da transição que sai dela.
# Toda AttackPhase precisa ter, na aba Sinais, state_entered -> _on_state_entered e
# state_exited -> _on_state_exited ligados nela mesma; sem o segundo a hitbox fica ligada.

@export_category('Fase de ataque')
## Sprite que toca a animação da fase (o AnimatedSprite2D do boss)
@export var SPRITE : AnimatedSprite2D
## Animação do SpriteFrames tocada ao entrar na fase (padrão: <golpe>_<fase>, ex.: combo_a_telegraphy).
## Vazio = a fase não troca a animação.
@export var ANIMATION : StringName = &""
@export var HITBOX : MeleeHitbox
@export var HITBOX_ACTIVE : bool = false
## Dano por golpe enquanto a hitbox estiver ativa (o boss.gd configura os combos dele)
@export var DAMAGE : int = 0
## Empurrão aplicado no alvo; x é sempre convertido para longe do atacante
@export var KNOCKBACK : Vector2 = Vector2.ZERO

func _on_state_entered() -> void:
	play_animation()

	if HITBOX == null:
		return

	if HITBOX_ACTIVE:
		HITBOX.activate(DAMAGE, KNOCKBACK)
	else:
		HITBOX.deactivate()

func _on_state_exited() -> void:
	if HITBOX != null:
		HITBOX.deactivate()

# Sempre recomeça do frame 0, mesmo que a fase anterior tenha usado a mesma animação (ex.: Hit1 e Hit2)
func play_animation() -> void:
	if SPRITE == null or ANIMATION == &"":
		return
	if not SPRITE.sprite_frames.has_animation(ANIMATION):
		push_warning("AttackPhase %s: animação '%s' não existe no SpriteFrames" % [name, ANIMATION])
		return
	SPRITE.stop()
	SPRITE.play(ANIMATION)
