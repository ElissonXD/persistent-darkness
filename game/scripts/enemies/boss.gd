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
@export var REST_DURATION : float = 2.0
@export var STUN_DURATION : float = 3.0

# TODO: ajustar todos os valores dos combos (provisórios, o grupo ainda não definiu)
@export_category('Combo A')
## Aviso antes do primeiro golpe (sem dano)
@export var COMBO_A_TELEGRAPHY : float = 0.6
## Duração de cada golpe (Hit1 e Hit2) com a hitbox ativa
@export var COMBO_A_HIT : float = 0.15
## Pausa sem dano entre Hit1 e Hit2
@export var COMBO_A_GAP : float = 0.35
## Janela de contra-ataque depois do Hit2
@export var COMBO_A_RECOVERY : float = 0.5
@export var COMBO_A_DAMAGE : int = 30
@export var COMBO_A_KNOCKBACK : Vector2 = Vector2(250, -150)

@export_category('Combo B')
## Aviso mais curto: o Combo B é continuação do Combo A
@export var COMBO_B_TELEGRAPHY : float = 0.3
@export var COMBO_B_HIT : float = 0.15
@export var COMBO_B_GAP : float = 0.35
@export var COMBO_B_RECOVERY : float = 0.5
@export var COMBO_B_DAMAGE : int = 30
@export var COMBO_B_KNOCKBACK : Vector2 = Vector2(250, -150)

@export_category('Effects buildups')
var FIRE_BUILDUP = 0
var FREEZE_BUILDUP = 0
var ELETRIC_BUILDUP = 0

# Nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_chart: StateChart = $StateChart
@onready var combo_a: CompoundState = $StateChart/Root/Attack1/ComboA
@onready var combo_b: CompoundState = $StateChart/Root/Attack2/ComboB
@onready var melee_hitbox: MeleeHitbox = $MeleeHitbox

var player : Node2D = null

func _ready() -> void:
	# exports usados nos delay_in_seconds/guards das transições
	state_chart.set_expression_property(&"idle_duration", IDLE_DURATION)
	state_chart.set_expression_property(&"rest_duration", REST_DURATION)
	state_chart.set_expression_property(&"stun_duration", STUN_DURATION)
	state_chart.set_expression_property(&"player_far", false)
	configure_combo(combo_a, "combo_a", COMBO_A_TELEGRAPHY, COMBO_A_HIT, COMBO_A_GAP, COMBO_A_RECOVERY, COMBO_A_DAMAGE, COMBO_A_KNOCKBACK)
	configure_combo(combo_b, "combo_b", COMBO_B_TELEGRAPHY, COMBO_B_HIT, COMBO_B_GAP, COMBO_B_RECOVERY, COMBO_B_DAMAGE, COMBO_B_KNOCKBACK)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

# Estados (sinais ligados na aba Sinais do boss.tscn)

# state_entered de cada filho do Root, com o nome do estado como bind
func _on_state_entered(state_name: StringName) -> void:
	# só o Walk move o boss na horizontal
	if state_name != &"Walk":
		velocity.x = 0
	# o boss só vira para o player no começo de cada ataque, não no meio do golpe
	if state_name == &"Attack1" or state_name == &"Attack2":
		var target := get_player()
		if target != null:
			face(target.global_position.x - global_position.x)

# state_entered de cada AttackPhase. Chamado depois do _on_state_entered do estado pai
# (o addon entra primeiro no pai)
func _on_attack_phase_entered() -> void:
	# O addon avalia o guard de uma transição atrasada quando ela é enfileirada (na entrada
	# da fase), não quando o delay termina. Por isso a distância é medida a cada fase: a
	# decisão Rest/Walk do fim do Combo B usa a distância do início do Recovery.
	var target := get_player()
	var far := target != null and absf(target.global_position.x - global_position.x) > FAR_RANGE
	state_chart.set_expression_property(&"player_far", far)

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

# TODO: Stunned sempre volta para Walk (transição em boss.tscn). Para onde sair é decisão em aberto.

# Utils

# Durações viram expression properties (<prefixo>_telegraphy, _hit, _gap, _recovery) usadas nos
# delay_in_seconds das transições; dano e knockback vão para as fases com hitbox ativa.
func configure_combo(combo: Node, prefix: String, telegraphy: float, hit: float, gap: float, recovery: float, damage: int, knockback: Vector2) -> void:
	state_chart.set_expression_property(prefix + "_telegraphy", telegraphy)
	state_chart.set_expression_property(prefix + "_hit", hit)
	state_chart.set_expression_property(prefix + "_gap", gap)
	state_chart.set_expression_property(prefix + "_recovery", recovery)
	for phase in find_attack_phases(combo):
		if phase.HITBOX_ACTIVE:
			phase.DAMAGE = damage
			phase.KNOCKBACK = knockback

func find_attack_phases(node: Node) -> Array[AttackPhase]:
	var phases : Array[AttackPhase] = []
	for child in node.get_children():
		if child is AttackPhase:
			phases.append(child)
		phases.append_array(find_attack_phases(child))
	return phases

func get_player() -> Node2D:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
	return player

# O sprite original olha para a direita
func face(direction_x: float) -> void:
	if direction_x != 0:
		animated_sprite_2d.flip_h = direction_x < 0
		melee_hitbox.set_facing(direction_x)

# Contrato de dano: hurtbox do player (Area2D, camada 2) cujo dono tem take_damage()
func deal_damage(hurtbox: Area2D, amount: int, knockback: Vector2) -> void:
	var target = hurtbox.owner
	if target != null and target.has_method("take_damage"):
		target.take_damage(amount, knockback)
