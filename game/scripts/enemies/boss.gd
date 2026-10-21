extends CharacterBody2D

@export_category('Boss Data')
@export var HEALTH : float = 1000
@export var POSTURE : float = 100.0
@export var BUILDUP_VALUE : float = 100.0
@export var WALK_SPEED : float = 300.0
@export var JUMP_VELOCITY : float = -400.0
## Marque se o desenho do spritesheet olha para a direita (o spritesheet_6x6_running olha para a esquerda)
@export var SPRITE_FACES_RIGHT : bool = false

@export_category('Ataques')
# Cada item é o nome de um evento do StateChart que leva a um golpe (ex.: go_combo_a).
# Ao entrar no Attack1/Attack2 o boss sorteia um evento da lista da faixa de distância do player;
# se a lista da faixa estiver vazia, usa a faixa mais próxima que tiver golpe.
## Golpes do Attack1 com o player longe (>= LONG_DISTANCE)
@export var LONG_ATTACKS_1 : Array[String]
## Golpes do Attack1 com o player a média distância (>= MEDIUM_DISTANCE)
@export var MEDIUM_ATTACKS_1 : Array[String]
## Golpes do Attack1 com o player perto (< MEDIUM_DISTANCE)
@export var CLOSE_ATTACKS_1 : Array[String]
## Golpes do Attack2 com o player longe (>= LONG_DISTANCE)
@export var LONG_ATTACKS_2 : Array[String]
## Golpes do Attack2 com o player a média distância (>= MEDIUM_DISTANCE)
@export var MEDIUM_ATTACKS_2 : Array[String]
## Golpes do Attack2 com o player perto (< MEDIUM_DISTANCE)
@export var CLOSE_ATTACKS_2 : Array[String]
## Golpes exclusivos da fase 2 (ainda não usados)
@export var EXCLUSIVE_ATTACKS : Array[String]

@export_category('IA')
## Tempo parado no início da luta antes de começar a andar
@export var IDLE_DURATION : float = 1.0
## A partir desta distância horizontal o player está longe (golpes longos; descanso após o Attack2)
@export var LONG_DISTANCE : float = 500.0
## A partir desta distância horizontal o player está a média distância; abaixo dela, perto
@export var MEDIUM_DISTANCE : float = 300.0
## Duração do descanso
@export var REST_DURATION : float = 2.0
@export var STUN_DURATION : float = 3.0


@export_category('Walk')
@export var WALK_MAX_DURATION : float = 3.0
var walk_timer : float = 0

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
	# pegar o player
	player = get_player()
	
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

# ---------------LÓGICA DE TRANSIÇÃO GERAL----------------
"""
Walk -> ataque1 -> ataque2 -> walk/rest
exçeções: Heal, Ataque giratório e ataque estacas no chão (usadas a qualquer momento quando está 50% da vida)
qualquer estado vai pra stun
ESTADOS COMPOSTOS - 1 para cada elemento, 1 para fase 2 
"""



# ---------------ESTADOS DE ENTRADA----------------

# state_entered de cada filho do Root, com o nome do estado como bind
func _on_state_entered(state_name: StringName) -> void:
	# SEMPRE ao ir para um estado, ficar olhando pro player (antes de escolher o golpe)
	face(player_distance())

	# só o Walk move o boss na horizontal
	if state_name != &"Walk":
		velocity.x = 0

	# --- CONDICIONAIS DE CADA ESTADO ---
	if state_name == &"Walk":
		walk_timer = WALK_MAX_DURATION
	if state_name == &"Attack1" or state_name == &"Attack2":
		var attack := pick_attack(get_attack_state(state_name))
		if attack != "":
			state_chart.send_event(attack)

# state_entered de cada AttackPhase. Chamado depois do _on_state_entered do estado pai
# (o addon entra primeiro no pai)
func _on_attack_phase_entered() -> void:
	# O addon avalia o guard de uma transição atrasada quando ela é enfileirada (na entrada
	# da fase), não quando o delay termina. Por isso a distância é medida a cada fase: a
	# decisão Rest/Walk do fim do Combo B usa a distância do início do Recovery
	# (este sinal é emitido antes do addon avaliar as transições da fase).
	state_chart.set_expression_property(&"player_far", is_player_far())

# ---------------ESTADOS DE PROCESSAMENTO ----------------

func _on_walk_state_physics_processing(_delta: float) -> void:
	var target := get_player()
	if target == null:
		velocity.x = 0
		return
	
	walk_timer -= _delta
	
	var distance_x := player_distance()
	face(distance_x)

	if absf(distance_x) < MEDIUM_DISTANCE:
		velocity.x = 0
		state_chart.send_event(&"go_attack_1")
		return
	
	if walk_timer <= 0:
		# aqui vou ir para qualquer estado de ataque 1 ou ataque exclusivo
		# if fase 2....choice ataque 1 ou exclsuivo
		# por enquanto vai pra ataque 1 ja que nao tem fase 2
		state_chart.send_event(&'go_attack_1')
		velocity.x = 0
		return

	velocity.x = signf(distance_x) * WALK_SPEED

# Recovery é uma AttackPhase igual às outras: o que muda de um golpe para outro é só a animação
# e a transição de saída (com delay), configuradas na cena:
#   Attack1/<golpe>/Recovery -> Attack2
#   Attack2/<golpe>/Recovery -> Rest (guard player_far) ou Walk

# TODO: Stunned sempre volta para Walk (transição em boss.tscn). Para onde sair é decisão em aberto.

# ---------------ESTADOS DE SAÍDA----------------


# ---------------UTILS----------------

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

# Distância horizontal até o player COM sinal (negativa = player à esquerda). Para direção.
func player_distance() -> float:
	var target := get_player()
	if target: return (target.global_position.x - global_position.x)
	return 0.0

# Distância horizontal até o player SEM sinal. Para comparar com as faixas de distância.
func player_abs_distance() -> float:
	return absf(player_distance())

func is_player_far() -> bool:
	return player_abs_distance() >= LONG_DISTANCE

# Listas de golpes do estado de ataque: [longos, médios, curtos], nessa ordem
func get_attack_state(state_number : String) -> Array:
	if state_number == &"Attack1": return [LONG_ATTACKS_1,MEDIUM_ATTACKS_1,CLOSE_ATTACKS_1]
	else: return [LONG_ATTACKS_2, MEDIUM_ATTACKS_2, CLOSE_ATTACKS_2]

# Sorteia um evento de golpe pela faixa de distância do player. Se a lista da faixa estiver
# vazia, tenta as faixas mais próximas. Retorna "" se nenhuma lista tiver golpe.
func pick_attack(lists: Array) -> String:
	var distance := player_abs_distance()
	var order : Array[int]
	if distance >= LONG_DISTANCE:
		order = [0, 1, 2]
	elif distance >= MEDIUM_DISTANCE:
		order = [1, 2, 0]
	else:
		order = [2, 1, 0]
	for i in order:
		if not lists[i].is_empty():
			return lists[i].pick_random()
	push_warning("Boss: nenhum golpe configurado nas listas de ataque")
	return ""

# Espelha o sprite conforme o lado para onde o desenho original olha (SPRITE_FACES_RIGHT)
func face(direction_x: float) -> void:
	if direction_x != 0:
		animated_sprite_2d.flip_h = (direction_x < 0) == SPRITE_FACES_RIGHT
		melee_hitbox.set_facing(direction_x)

# Contrato de dano: hurtbox do player (Area2D, camada 2) cujo dono tem take_damage()
func deal_damage(hurtbox: Area2D, amount: int, knockback: Vector2) -> void:
	var target = hurtbox.owner
	if target != null and target.has_method("take_damage"):
		target.take_damage(amount, knockback)
