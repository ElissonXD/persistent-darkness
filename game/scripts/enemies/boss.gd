extends CharacterBody2D

@export_category('Boss Data')
@export var HEALTH : float = 1000
@export var POSTURE : float = 100.0
@export var BUILDUP_VALUE : float = 100.0
@export var WALK_SPEED : float = 300.0
@export var JUMP_VELOCITY : float = -400.0

@export_category('IA')
## Tempo parado no início da luta antes de começar a andar
@export var IDLE_DURATION : float = 1.0
## Distância horizontal em que o boss para de andar e ataca
@export var CLOSE_RANGE : float = 250.0
## Distância horizontal a partir da qual o boss descansa após o Attack2
@export var FAR_RANGE : float = 500.0
## Duração dos ataques placeholder (Attack1 e Attack2)
@export var ATTACK_PLACEHOLDER_DURATION : float = 0.5
@export var REST_DURATION : float = 2.0
@export var STUN_DURATION : float = 3.0

@export_category('Effects buildups')
var FIRE_BUILDUP = 0
var FREEZE_BUILDUP = 0
var ELETRIC_BUILDUP = 0

# Cor do sprite por estado, só para debug enquanto não há animações
const STATE_COLORS := {
	&"Idle": Color.WHITE,
	&"Walk": Color(0.8, 1.0, 0.8),
	&"Attack1": Color(1.0, 0.6, 0.3),
	&"Attack2": Color(1.0, 0.3, 0.3),
	&"Rest": Color(0.5, 0.7, 1.0),
	&"Stunned": Color(1.0, 1.0, 0.3),
}

# Nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_chart: StateChart = $StateChart
@onready var root_state: CompoundState = $StateChart/Root
@onready var walk_state: StateChartState = $StateChart/Root/Walk
@onready var attack_2_state: StateChartState = $StateChart/Root/Attack2

# Nome do estado ativo (usado pelo debug da cena de teste)
var current_state_name : StringName = &""
var player : Node2D = null

func _ready() -> void:
	# exports usados nos delay_in_seconds/guards das transições
	state_chart.set_expression_property(&"idle_duration", IDLE_DURATION)
	state_chart.set_expression_property(&"attack_placeholder_duration", ATTACK_PLACEHOLDER_DURATION)
	state_chart.set_expression_property(&"rest_duration", REST_DURATION)
	state_chart.set_expression_property(&"stun_duration", STUN_DURATION)
	state_chart.set_expression_property(&"player_far", false)

	for state in root_state.get_children():
		if state is StateChartState:
			state.state_entered.connect(_on_state_entered.bind(state.name))
	walk_state.state_physics_processing.connect(_on_walk_state_physics_processing)
	attack_2_state.state_entered.connect(_on_attack_2_state_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

# Estados

func _on_state_entered(state_name: StringName) -> void:
	current_state_name = state_name
	animated_sprite_2d.modulate = STATE_COLORS.get(state_name, Color.WHITE)
	# só o Walk move o boss na horizontal
	if state_name != &"Walk":
		velocity.x = 0

func _on_walk_state_physics_processing(_delta: float) -> void:
	var target := get_player()
	if target == null:
		velocity.x = 0
		return

	var distance_x := target.global_position.x - global_position.x
	face(distance_x)

	if absf(distance_x) < CLOSE_RANGE:
		velocity.x = 0
		state_chart.send_event(&"player_close")
		return

	velocity.x = signf(distance_x) * WALK_SPEED

func _on_attack_2_state_entered() -> void:
	# O addon avalia o guard de uma transição atrasada quando ela é enfileirada (na entrada
	# do estado), não quando o delay termina. Por isso a distância é medida aqui.
	# TODO: medir no fim do Attack2 quando o ataque real existir.
	var target := get_player()
	var far := target != null and absf(target.global_position.x - global_position.x) > FAR_RANGE
	state_chart.set_expression_property(&"player_far", far)

# TODO: Stunned sempre volta para Walk (transição em boss.tscn). Para onde sair é decisão em aberto.

# Utils

func get_player() -> Node2D:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	return player

# O sprite original olha para a direita
func face(direction_x: float) -> void:
	if direction_x != 0:
		animated_sprite_2d.flip_h = direction_x < 0

# Contrato de dano: hurtbox do player (Area2D, camada 2) cujo dono tem take_damage()
func deal_damage(hurtbox: Area2D, amount: int, knockback: Vector2) -> void:
	var target = hurtbox.owner
	if target != null and target.has_method("take_damage"):
		target.take_damage(amount, knockback)
