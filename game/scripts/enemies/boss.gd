extends CharacterBody2D

@export_category('Boss Data')
@export var HEALTH : float = 1000
@export var POSTURE : float = 100.0
@export var BUILDUP_VALUE : float = 100.0
@export var WALK_SPEED : float = 300.0
@export var JUMP_VELOCITY : float = -400.0
## Marque se o desenho do spritesheet olha para a direita (os sheets do boss olham para a esquerda)
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
## Golpes exclusivos da fase 2 (ex.: go_to_sword_spawn). Sorteados junto com o Attack1 quando o
## Walk acaba o tempo sem alcançar o player; na fase 1 não entram no sorteio
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

## Uppercut
@export_category('Uppercut')
@export var UPPERCUT_TELEGRAPHY : float = 0.5
@export var UPPERCUT_HIT : float = 0.5
@export var UPPERCUT_RECOVERY : float = 0.5
@export var UPPERCUT_DAMAGE : int = 40
@export var UPPERCUT_KNOCKBACK : Vector2 = Vector2(250, -500)
@export var UPPERCUT_STEP_VELOCITY : float = 500
var uppercut_direction : int

## Power wave
var power_wave = preload("res://game/scenes/projectiles/power_wave.tscn") 
@export_category('Power Wave')
@export var POWER_WAVE_TELEGRAPHY : float = 0.3
@export var POWER_WAVE_HIT : float = 0.5
@export var POWER_WAVE_GAP : float = 1.5
@export var POWER_WAVE_RECOVERY : float = 0.5
@export var POWER_WAVE_DAMAGE : int = 10
@export var POWER_WAVE_KNOCKBACK : Vector2 = Vector2(250, -150)

@export_category('Combo B')
## Aviso mais curto: o Combo B é continuação do Combo A
@export var COMBO_B_TELEGRAPHY : float = 0.3
@export var COMBO_B_HIT : float = 0.15
@export var COMBO_B_GAP : float = 0.35
@export var COMBO_B_RECOVERY : float = 0.5
@export var COMBO_B_DAMAGE : int = 30
@export var COMBO_B_KNOCKBACK : Vector2 = Vector2(250, -150)

@export_category('Stinger')
@export var STINGER_SPEED : float = 200
@export var STINGER_TELEGRAPHY:float = 0.4
@export var STINGER_HIT:float = 1.0
@export var STINGER_RECOVERY : float = 0.4
@export var STINGER_DAMAGE : int = 40
@export var STINGER_KNOCKBACK : Vector2 = Vector2(1000, -150)
var stinger_distance : float
var stinger_direction : int
var stinger_stop : bool
var stinger_hit_timer : float

# TODO: ajustar valores da espada arremessada (durações e alcance "a definir" no Notion)
@export_category('Sword Throw')
## Aviso antes do arremesso (sem dano): o boss recua o braço
@export var SWORD_THROW_TELEGRAPHY : float = 0.7
## Tempo da ida, até o fim do alcance (hitbox ativa)
@export var SWORD_THROW_OUTWARD : float = 0.6
## Tempo da volta pelo mesmo caminho (hitbox ativa)
@export var SWORD_THROW_RETURN : float = 0.6
## Janela de contra-ataque depois de pegar a espada de volta
@export var SWORD_THROW_RECOVERY : float = 0.6
## Distância horizontal que a espada percorre na ida
@export var SWORD_THROW_RANGE : float = 900.0
## Distância horizontal da mão do boss até o centro dele, para o lado em que ele olha (a espada sai e volta daqui).
## Não usa o Marker2D: ele é o ponto de saída do Power Wave, no chão
@export var SWORD_THROW_HAND_X : float = 105.0
## Altura do arremesso em relação à origem do boss (positivo = para baixo); deve ficar no peito do player
@export var SWORD_THROW_HEIGHT : float = 110.0
## Dano por passagem (acerta até 2 vezes: ida e volta)
@export var SWORD_THROW_DAMAGE : int = 25
@export var SWORD_THROW_KNOCKBACK : Vector2 = Vector2(250, -150)
# ponto de onde a espada sai e para onde ela volta (fixado na ida)
var sword_throw_origin : Vector2

@export_category('Fase 2')
## Fração da vida máxima (HEALTH) em que o boss entra na fase 2 (0.5 = 50%)
@export_range(0.0, 1.0, 0.05) var PHASE_2_HEALTH_RATIO : float = 0.5
# vida atual (começa em HEALTH)
var health : float
# vira true uma vez e não volta (enter_phase_2)
var phase_2 : bool = false

# TODO: valores provisórios do ataque em área (Notion: "a definir"); escolhidos para o player
# (MOVE_SPEED 300, rolagem de 240 px com 0.25 s de i-frames, 100 de vida) conseguir reagir
@export_category('Ataque em área')
## Aviso com a marca do raio no chão (sem dano). Mais longo que os outros golpes: dá tempo de sair
## andando do raio mesmo colado no boss (~1 s andando + tempo de reação)
@export var AREA_ATTACK_TELEGRAPHY : float = 1.4
## Tempo com a onda ativa. Menor que os i-frames da rolagem, então rolar na hora certa também esquiva
@export var AREA_ATTACK_HIT : float = 0.25
## Boss parado depois da onda: janela para o player contra-atacar
@export var AREA_ATTACK_RECOVERY : float = 1.2
## Alcance horizontal da onda para cada lado do boss (maior que MEDIUM_DISTANCE: pega quem está perto)
@export var AREA_ATTACK_RADIUS : float = 400.0
## Altura da onda a partir do pé do boss: acima disso (plataforma, pulo no ápice) não acerta
@export var AREA_ATTACK_HEIGHT : float = 120.0
## Tempo mínimo entre dois ataques em área (conta a partir do início do golpe)
@export var AREA_ATTACK_COOLDOWN : float = 12.0
## Dano: 3 acertos matam o player (menos que o Uppercut/Stinger, porque é bem avisado e cobre área)
@export var AREA_ATTACK_DAMAGE : int = 35
## Empurrão para longe do boss
@export var AREA_ATTACK_KNOCKBACK : Vector2 = Vector2(600, -250)
# tempo que falta para o ataque em área ficar pronto de novo
var area_attack_cooldown_left : float = 0.0

@export_category("Sword Spawn")
@export var SWORD_SPAWN_TELEGRAPHY : float = 0.3
@export var SWORD_SPAWN_HIT : float = 0.15
@export var SWORD_SPAWN_GAP : float = 0.35
@export var SWORD_SPAWN_RECOVERY : float = 0.5


@export_category('Effects buildups')
var FIRE_BUILDUP = 0
var FREEZE_BUILDUP = 0
var ELETRIC_BUILDUP = 0

# Nodes
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_chart: StateChart = $StateChart
@onready var combo_a: CompoundState = $StateChart/Root/Attack1/ComboA
@onready var uppercut: CompoundState = $StateChart/Root/Attack1/Uppercut
@onready var combo_b: CompoundState = $StateChart/Root/Attack2/ComboB
@onready var power_wave_a: CompoundState = $StateChart/Root/Attack1/PowerWaveA
@onready var power_wave_b: CompoundState = $StateChart/Root/Attack2/PowerWaveB
@onready var stinger: CompoundState = $StateChart/Root/Attack2/Stinger
@onready var sword_throw: CompoundState = $StateChart/Root/Attack1/SwordThrow
@onready var thrown_sword: ThrownSword = $ThrownSword
@onready var area_attack: CompoundState = $StateChart/Root/AreaAttack
@onready var area_wave: AreaWave = $AreaWave
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sword_spawn: CompoundState = $StateChart/Root/SwordSpawn
@onready var melee_hitbox: MeleeHitbox = $MeleeHitbox
@onready var marker_2d: Marker2D = $Marker2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


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
	configure_combo(power_wave_a, "power_wave", POWER_WAVE_TELEGRAPHY, POWER_WAVE_HIT, POWER_WAVE_GAP, POWER_WAVE_RECOVERY, POWER_WAVE_DAMAGE, POWER_WAVE_KNOCKBACK)
	configure_combo(power_wave_b, "power_wave", POWER_WAVE_TELEGRAPHY, POWER_WAVE_HIT, POWER_WAVE_GAP, POWER_WAVE_RECOVERY, POWER_WAVE_DAMAGE, POWER_WAVE_KNOCKBACK)
	configure_combo(stinger, "stinger", STINGER_TELEGRAPHY, 0, 0, STINGER_RECOVERY, STINGER_DAMAGE, STINGER_KNOCKBACK)
	configure_combo(uppercut, "uppercut", UPPERCUT_TELEGRAPHY, UPPERCUT_HIT, 0, UPPERCUT_RECOVERY, UPPERCUT_DAMAGE, UPPERCUT_KNOCKBACK)
	configure_combo(sword_throw, "sword_throw", SWORD_THROW_TELEGRAPHY, 0, 0, SWORD_THROW_RECOVERY, SWORD_THROW_DAMAGE, SWORD_THROW_KNOCKBACK)
	configure_combo(sword_spawn, "sword_spawn", SWORD_SPAWN_TELEGRAPHY, SWORD_SPAWN_HIT, SWORD_SPAWN_GAP, SWORD_SPAWN_RECOVERY, 0, Vector2.ZERO)
	state_chart.set_expression_property(&"sword_throw_outward", SWORD_THROW_OUTWARD)
	state_chart.set_expression_property(&"sword_throw_return", SWORD_THROW_RETURN)

	# fase 2 e ataque em área
	health = HEALTH
	state_chart.set_expression_property(&"phase_2", false)
	state_chart.set_expression_property(&"area_attack_ready", false)
	configure_combo(area_attack, "area_attack", AREA_ATTACK_TELEGRAPHY, AREA_ATTACK_HIT, 0, AREA_ATTACK_RECOVERY, AREA_ATTACK_DAMAGE, AREA_ATTACK_KNOCKBACK)
	# a onda nasce no pé do boss (base da colisão)
	var body_shape := collision_shape_2d.shape as RectangleShape2D
	area_wave.position = Vector2(0, collision_shape_2d.position.y + body_shape.size.y / 2.0)
	area_wave.setup(AREA_ATTACK_RADIUS, AREA_ATTACK_HEIGHT)

func _physics_process(delta: float) -> void:
	area_attack_cooldown_left = maxf(area_attack_cooldown_left - delta, 0.0)

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
		animated_sprite_2d.play("walk")
	if state_name == &"Attack1" or state_name == &"Attack2":
		var attack := pick_attack(get_attack_state(state_name))
		if attack != "":
			state_chart.send_event(attack)
	if state_name == &"AreaAttack":
		area_attack_cooldown_left = AREA_ATTACK_COOLDOWN

func on_power_waveA_enter() -> void:
	instatiate_power_wave(false)
	return

func on_power_waveB_enter() -> void:
	instatiate_power_wave(true)
	return

func on_stinger_hit_enter() -> void:
	stinger_distance = player_distance()
	stinger_direction = signf(stinger_distance)
	velocity.x = stinger_direction * STINGER_SPEED
	stinger_stop = false
	stinger_hit_timer = STINGER_HIT
	return

#------UPPERCUT-------
func on_uppercut_hit_enter() -> void:
	uppercut_direction = sign(player_distance())
	velocity.x = 0
	return
# Ida: a espada sai da mão e vai em linha reta até o fim do alcance, para o lado em que o boss
# está olhando (definido ao entrar no Attack1)
func on_sword_throw_outward_enter() -> void:
	sword_throw_origin = global_position + Vector2(melee_hitbox.facing * SWORD_THROW_HAND_X, SWORD_THROW_HEIGHT)
	var end := sword_throw_origin + Vector2(melee_hitbox.facing * SWORD_THROW_RANGE, 0)
	thrown_sword.fly(sword_throw_origin, end, SWORD_THROW_OUTWARD)

# Volta: pelo mesmo caminho, do ponto onde a espada está até a mão do boss
func on_sword_throw_return_enter() -> void:
	thrown_sword.fly(thrown_sword.global_position, sword_throw_origin, SWORD_THROW_RETURN)


# state_entered de cada AttackPhase. Chamado depois do _on_state_entered do estado pai
# (o addon entra primeiro no pai)
func _on_attack_phase_entered() -> void:
	# O addon avalia o guard de uma transição atrasada quando ela é enfileirada (na entrada
	# da fase), não quando o delay termina. Por isso a distância é medida a cada fase: a
	# decisão Rest/Walk do fim do Combo B usa a distância do início do Recovery
	# (este sinal é emitido antes do addon avaliar as transições da fase).
	state_chart.set_expression_property(&"player_far", is_player_far())
	# guard da saída Attack2 -> AreaAttack (vem depois do Go Rest, então só vale com o player perto)
	state_chart.set_expression_property(&"area_attack_ready", is_area_attack_ready())

#====== SWORDSPAWN
func _on_swordspawn_telegraphy_state_entered() -> void:
	velocity = Vector2.ZERO
	return

func _on_swordspawn_hit1_state_entered() -> void:
	var area_spawn = get_tree().get_first_node_in_group('sword_area')
	if area_spawn:
		area_spawn.invoke_swords(false)
	return

func _on_swordspawn_hit2_state_entered() -> void:
	var area_spawn = get_tree().get_first_node_in_group('sword_area')
	if area_spawn:
		area_spawn.invoke_swords(true)
	return

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
		# fase 1: sempre Attack1. Fase 2: sorteia entre o Attack1 e um golpe exclusivo
		var attacks = [&'go_attack_1']
		if phase_2 and not EXCLUSIVE_ATTACKS.is_empty():
			attacks.append(EXCLUSIVE_ATTACKS.pick_random())
		state_chart.send_event(attacks.pick_random())
		velocity.x = 0
		return

	velocity.x = signf(distance_x) * WALK_SPEED

func on_stinger_hit_physics_processing(_delta:float) -> void:
	velocity.x = move_toward(velocity.x, stinger_direction*stinger_distance, stinger_direction*STINGER_SPEED * _delta)
	
	melee_hitbox.set_facing(stinger_direction)
	
	stinger_hit_timer -= _delta
	
	if stinger_hit_timer <= 0:
		stinger_stop = true
	
	if stinger_stop:
		state_chart.send_event(&'go_stinger_recovery')
		return
	
	return


# -------UPPERCUT---------

func on_uppercut_physics_processing(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, uppercut_direction*UPPERCUT_STEP_VELOCITY,UPPERCUT_STEP_VELOCITY* _delta)
	melee_hitbox.set_facing(uppercut_direction)
	return
# Recovery é uma AttackPhase igual às outras: o que muda de um golpe para outro é só a animação
# e a transição de saída (com delay), configuradas na cena:
#   Attack1/<golpe>/Recovery -> Attack2
#   Attack2/<golpe>/Recovery -> Rest (guard player_far) ou Walk

# TODO: Stunned sempre volta para Walk (transição em boss.tscn). Para onde sair é decisão em aberto.

# ---------------ESTADOS DE SAÍDA----------------

func on_stinger_hit_exit():
	velocity.x = 0
	return

# Ligado no state_exited do Return (o boss pegou a espada) e do SwordThrow (golpe interrompido,
# ex.: Stunned no meio da ida)
func on_sword_throw_exit() -> void:
	thrown_sword.stow()

# ---------------UTILS----------------

# Durações viram expression properties (<prefixo>_telegraphy, _hit, _gap, _recovery) usadas nos
# delay_in_seconds das transições; dano e knockback vão para as fases com hitbox ativa.
# HITBOX e SPRITE vazios nas fases são preenchidos com a MeleeHitbox e o AnimatedSprite2D do boss.
func configure_combo(combo: Node, prefix: String, telegraphy: float, hit: float, gap: float, recovery: float, damage: int, knockback: Vector2) -> void:
	state_chart.set_expression_property(prefix + "_telegraphy", telegraphy)
	state_chart.set_expression_property(prefix + "_hit", hit)
	state_chart.set_expression_property(prefix + "_gap", gap)
	state_chart.set_expression_property(prefix + "_recovery", recovery)
	for phase in find_attack_phases(combo):
		# fase sem HITBOX/SPRITE no Inspetor usa os do boss (sem isso a fase não liga a hitbox)
		if phase.HITBOX == null:
			phase.HITBOX = melee_hitbox
		if phase.SPRITE == null:
			phase.SPRITE = animated_sprite_2d
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

# Ataque em área: só na fase 2, com o cooldown zerado e o player perto (< MEDIUM_DISTANCE)
func is_area_attack_ready() -> bool:
	return phase_2 and area_attack_cooldown_left <= 0.0 and player_abs_distance() < MEDIUM_DISTANCE

# Dano recebido pelo boss. Ao chegar em PHASE_2_HEALTH_RATIO da vida, entra na fase 2
func take_damage(amount: int, _knockback: Vector2) -> void:
	health = maxf(health - amount, 0.0)
	if health <= HEALTH * PHASE_2_HEALTH_RATIO:
		enter_phase_2()

# Libera os golpes da fase 2. Também chamado pelas cenas de teste para forçar a fase 2
func enter_phase_2() -> void:
	if phase_2:
		return
	phase_2 = true
	state_chart.set_expression_property(&"phase_2", true)

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
		marker_2d.position.x = abs(marker_2d.position.x) * sign(direction_x)

# Contrato de dano: hurtbox do player (Area2D, camada 2) cujo dono tem take_damage()
func deal_damage(hurtbox: Area2D, amount: int, knockback: Vector2) -> void:
	var target = hurtbox.owner
	if target != null and target.has_method("take_damage"):
		target.take_damage(amount, knockback)
		


func _on_gap_1_state_entered() -> void:
	pass # Replace with function body.

func instatiate_power_wave(isStronger:bool):
	var instance = power_wave.instantiate()
	if animated_sprite_2d.flip_h: instance.DIRECTION = 1
	else: instance.DIRECTION = -1
	instance.position = marker_2d.global_position
	instance.STRONGER_VARIANT = isStronger;
	get_tree().current_scene.add_child(instance)
	return


func _on_melee_hitbox_area_entered(area: Area2D) -> void:
	stinger_stop = true
