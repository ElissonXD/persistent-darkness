class_name AreaWave
extends Node2D

# Onda do ataque em área do boss (estado AreaAttack, só na fase 2).
# A onda não decide nada sozinha: as fases do AreaAttack chamam os métodos pela aba Sinais:
#   Telegraphy.state_entered -> show_warning (marca o raio no chão)
#   Hit.state_entered        -> show_wave    (toca a onda; a AttackPhase liga a MeleeHitbox)
#   AreaAttack.state_exited  -> hide_all     (inclusive se o golpe for interrompido)
# A animação da onda some sozinha ao terminar (Sprite.animation_finished -> hide_wave).
# O dano é da MeleeHitbox filha, que empurra o player para longe do centro (o boss).
# A área é uma faixa no chão: 2 * raio de largura e altura `height` a partir do pé do boss,
# então quem estiver numa plataforma acima dela não é atingido.
# A origem desta cena fica no pé do boss (o boss.gd posiciona no _ready).

@export_category('Indicador')
## Cor da marca do raio no chão durante a Telegrafia
@export var WARNING_COLOR : Color = Color(1.0, 0.35, 0.1, 0.45)
## Espessura da marca do raio no chão
@export var WARNING_THICKNESS : float = 12.0

@export_category('Sprite da onda')
## Animação do SpriteFrames tocada no Hit
@export var WAVE_ANIMATION : StringName = &"wave"
## Altura das chamas (em pixels do sheet) no quadro mais alto: a escala vertical faz essa altura
## virar a altura da hitbox, para o desenho mostrar até onde a onda acerta
@export var WAVE_SPRITE_FLAME_HEIGHT : float = 166.0

# Nodes
@onready var hitbox: MeleeHitbox = $MeleeHitbox
@onready var collision_shape_2d: CollisionShape2D = $MeleeHitbox/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite

var radius : float = 0.0
var height : float = 0.0
var warning_visible : bool = false

func _ready() -> void:
	sprite.visible = false

# Tamanho da área: largura 2 * area_radius centrada no boss, do chão até area_height para cima.
# O sprite da onda é escalado para cobrir a mesma área da hitbox.
func setup(area_radius: float, area_height: float) -> void:
	radius = area_radius
	height = area_height
	var shape := RectangleShape2D.new()
	shape.size = Vector2(radius * 2.0, height)
	collision_shape_2d.shape = shape
	collision_shape_2d.position = Vector2(0, -height / 2.0)

	var frame := sprite.sprite_frames.get_frame_texture(WAVE_ANIMATION, 0)
	if frame != null:
		sprite.scale = Vector2(radius * 2.0 / frame.get_width(), height / WAVE_SPRITE_FLAME_HEIGHT)
	queue_redraw()

func show_warning() -> void:
	warning_visible = true
	queue_redraw()

func show_wave() -> void:
	warning_visible = false
	queue_redraw()
	sprite.visible = true
	sprite.stop()
	sprite.play(WAVE_ANIMATION)

func hide_wave() -> void:
	sprite.stop()
	sprite.visible = false

func hide_all() -> void:
	warning_visible = false
	queue_redraw()
	hide_wave()

func _draw() -> void:
	if warning_visible:
		draw_rect(Rect2(-radius, -WARNING_THICKNESS, radius * 2.0, WARNING_THICKNESS), WARNING_COLOR)
