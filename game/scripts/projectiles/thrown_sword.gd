class_name ThrownSword
extends Node2D

# Espada arremessada pelo boss (golpe SwordThrow, dentro do Attack1).
# A espada não decide nada sozinha: o boss.gd manda ela voar de um ponto a outro ao entrar nas
# fases Outward (ida) e Return (volta), e guarda ela ao sair do golpe.
# O dano é da MeleeHitbox filha, que as AttackPhase do golpe ligam e desligam (HITBOX no Inspetor).
# Cada activate() zera a lista de atingidos: acerta no máximo uma vez por passagem.
# A cena é top_level: depois de lançada não acompanha o movimento do boss.

@export_category('Espada')
## Animação do SpriteFrames tocada enquanto voa (se o Sprite for um AnimatedSprite2D)
@export var FLY_ANIMATION : StringName = &"fly"

# Nodes
@onready var sprite: Node2D = $Sprite
@onready var hitbox: MeleeHitbox = $MeleeHitbox

var start_position : Vector2
var end_position : Vector2
var travel_time : float = 0.0
var elapsed : float = 0.0
var flying : bool = false

func _ready() -> void:
	stow()

# Voa em linha reta de start até end, com velocidade constante, em duration segundos
func fly(start: Vector2, end: Vector2, duration: float) -> void:
	start_position = start
	end_position = end
	travel_time = duration
	elapsed = 0.0
	flying = true
	global_position = start
	# a lâmina aponta para onde está indo
	var direction := signf(end.x - start.x)
	if direction != 0:
		sprite.scale.x = absf(sprite.scale.x) * direction
	# com a arte final o Sprite vira AnimatedSprite2D (lâmina desenhada apontando para a direita)
	if sprite is AnimatedSprite2D:
		sprite.play(FLY_ANIMATION)
	show()

# Some com a espada (o boss pegou ela de volta ou o golpe foi interrompido)
func stow() -> void:
	flying = false
	hide()

func _physics_process(delta: float) -> void:
	if not flying:
		return

	elapsed += delta
	var t := 1.0
	if travel_time > 0:
		t = clampf(elapsed / travel_time, 0.0, 1.0)
	global_position = start_position.lerp(end_position, t)
	# chegou no fim: fica parada até a próxima fase mandar voar de novo
	if t >= 1.0:
		flying = false
