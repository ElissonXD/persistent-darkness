extends CharacterBody2D


# DURAÇÕES: ficam no delay_in_seconds das transições da cena (ex.: "roll_iframe_duration"). O valor
# da expressão é definido aqui com state_chart.set_expression_property(). Defina-o no state_entered
# do estado PAI: o addon só avalia os delays dos filhos depois desse sinal.
#
# COLISÃO COM INIMIGOS: o corpo do player colide com o terreno (camada 1) e com inimigos (camada 3,
# boss), então em qualquer estado ele não atravessa inimigos. Só na rolagem isso pode mudar: se
# STATS.ROLL_PASSES_THROUGH_ENEMIES for true, a máscara de inimigos é desligada enquanto o estado
# Roll estiver ativo (_on_roll_state_entered) e religada ao sair (_on_roll_state_exited).
#
# COMO ADICIONAR UM GOLPE NOVO NO COMBO (ex.: Swing4), copiando o Swing3:
#   1. Cena: duplique o Swing3 dentro de Attack (Ctrl+D) e renomeie. Em Swing3/Recovery crie uma
#      Transition com event = swing_4 e to = ../../../Swing4, e mude o delay do Go Idle do Swing3
#      se precisar. Ajuste os delay_in_seconds do novo golpe para swing4_windup, swing4_hit e swing4_recovery.
#   2. Sinais: ligue Swing4 state_entered -> _on_swing_4_state_entered, e as fases como nas outras
#      (_on_state_entered/_on_state_exited em cada AttackPhase), e Swing3/Recovery
#      state_physics_processing -> _on_swing_3_recovery_state_physics_processing.
#   3. Aqui: @export_category 'Swing 4' (WINDUP, HIT, RECOVERY), @onready swing_4, configure_swing(...)
#      no _ready, o handler _on_swing_4_state_entered (copie o do Swing3, que chama begin_swing) e o
#      handler do Recovery do Swing3 (copie o do Swing2). Em player_stats.gd crie SWING_4_DAMAGE e SWING_4_STAGGER.

@export_category('Player Data')
@export var STATS : PlayerStats

# TODO: valores dos golpes provisórios, o grupo ainda não definiu
@export_category('Swing 1')
@export var SWING_1_WINDUP : float = 0.15
@export var SWING_1_HIT : float = 0.12
@export var SWING_1_RECOVERY : float = 0.4

@export_category('Swing 2')
@export var SWING_2_WINDUP : float = 0.2
@export var SWING_2_HIT : float = 0.15
@export var SWING_2_RECOVERY : float = 0.5

@export_category('Swing 3')
@export var SWING_3_WINDUP : float = 0.25
@export var SWING_3_HIT : float = 0.18
@export var SWING_3_RECOVERY : float = 0.6

const ENEMY_LAYER : int = 3

# Nodes
@onready var state_chart: StateChart = $StateChart
@onready var melee_hitbox: PlayerHitbox = $MeleeHitbox
@onready var swing_1: CompoundState = $StateChart/Root/Grounded/Attack/Swing1
@onready var swing_2: CompoundState = $StateChart/Root/Grounded/Attack/Swing2
@onready var swing_3: CompoundState = $StateChart/Root/Grounded/Attack/Swing3
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurt: CompoundState = $StateChart/Root/Hurt

var facing : float = 1.0
var invulnerable : bool = false
# empurrão do golpe recebido (aplicado ao entrar no Hurt) e o atrito que o faz parar durante o stagger
var hurt_knockback : Vector2 = Vector2.ZERO
var hurt_friction : float = 0.0

func _ready() -> void:
	STATS.reset()
	configure_swing(swing_1, "swing1", SWING_1_WINDUP, SWING_1_HIT, SWING_1_RECOVERY)
	configure_swing(swing_2, "swing2", SWING_2_WINDUP, SWING_2_HIT, SWING_2_RECOVERY)
	configure_swing(swing_3, "swing3", SWING_3_WINDUP, SWING_3_HIT, SWING_3_RECOVERY)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	STATS.tick(delta)
	move_and_slide()

func _on_roll_state_entered() -> void:
	STATS.spend_stamina(stat(&"ROLL_STAMINA_COST"))
	velocity.x = facing * stat(&"ROLL_SPEED")
	set_collision_mask_value(ENEMY_LAYER, not STATS.has_ability(&"ROLL_PASSES_THROUGH_ENEMIES"))
	var duration := stat(&"ROLL_DURATION")
	var iframes := minf(stat(&"ROLL_IFRAME_DURATION"), duration)
	state_chart.set_expression_property(&"roll_iframe_duration", iframes)
	state_chart.set_expression_property(&"roll_recovery_duration", duration - iframes)

func _on_roll_state_exited() -> void:
	set_collision_mask_value(ENEMY_LAYER, true)

func _on_invulnerable_state_entered() -> void:
	invulnerable = true
	hurtbox.monitorable = false
	hurtbox.monitoring = false

func _on_invulnerable_state_exited() -> void:
	invulnerable = false
	hurtbox.monitorable = true
	hurtbox.monitoring = true


func _on_heal_state_entered() -> void:
	use_heal_item()
	state_chart.set_expression_property(&"heal_delay", stat(&"HEAL_DELAY"))
	state_chart.set_expression_property(&"heal_recovery_duration", stat(&"HEAL_RECOVERY_DURATION"))

func _on_heal_recovery_state_entered() -> void:
	STATS.heal(stat(&"HEAL_AMOUNT"))

func _on_swing_1_state_entered() -> void:
	begin_swing(swing_1, &"SWING_1_DAMAGE", &"SWING_1_STAGGER")

func _on_swing_2_state_entered() -> void:
	begin_swing(swing_2, &"SWING_2_DAMAGE", &"SWING_2_STAGGER")

func _on_swing_3_state_entered() -> void:
	begin_swing(swing_3, &"SWING_3_DAMAGE", &"SWING_3_STAGGER")

func _on_dead_state_entered() -> void:
	velocity.x = 0

# state_entered de Hurt (qualquer estado -> Hurt pelo evento hurt). As durações entram aqui (estado
# pai); o empurrão é aplicado e vai diminuindo até zero ao longo do Stagger
func _on_hurt_state_entered() -> void:
	var duration := stat(&"HURT_DURATION")
	state_chart.set_expression_property(&"hurt_duration", duration)
	state_chart.set_expression_property(&"hurt_iframe_duration", stat(&"HURT_IFRAME_DURATION"))
	velocity = hurt_knockback
	hurt_friction = absf(hurt_knockback.x) / maxf(duration, 0.01)


func _on_idle_state_physics_processing(_delta: float) -> void:
	velocity.x = 0
	if read_actions():
		return
	if move_direction() != 0:
		state_chart.send_event(&"move")

func _on_run_state_physics_processing(_delta: float) -> void:
	var direction := move_direction()
	velocity.x = direction * stat(&"MOVE_SPEED")
	if read_actions():
		return
	if direction == 0:
		state_chart.send_event(&"stop")

func _on_airborne_state_physics_processing(_delta: float) -> void:
	velocity.x = move_direction() * stat(&"MOVE_SPEED")
	if is_on_floor() and velocity.y >= 0.0:
		state_chart.send_event(&"landed")

# state_physics_processing do Stagger: o empurrão diminui até parar
func _on_hurt_state_physics_processing(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, hurt_friction * delta)

func _on_heal_state_physics_processing(_delta: float) -> void:
	velocity.x = move_direction() * stat(&"MOVE_SPEED") * stat(&"HEAL_MOVE_SPEED_MULT")

func _on_swing_1_recovery_state_physics_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") and STATS.has_stamina(stat(&"SWING_STAMINA_COST")):
		state_chart.send_event(&"swing_2")

func _on_swing_2_recovery_state_physics_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") and STATS.has_stamina(stat(&"SWING_STAMINA_COST")):
		state_chart.send_event(&"swing_3")

# Contrato de dano: quem causa dano chama take_damage(amount, knockback) no dono da hurtbox
func take_damage(amount: int, knockback: Vector2) -> void:
	if invulnerable or STATS.is_dead():
		return
	STATS.take_damage(amount)
	if STATS.is_dead():
		state_chart.send_event(&"died")
		return
	# já em Hurt o dano conta, mas não reinicia o stagger (mesma ideia do boss com o Stunned)
	if hurt.active:
		return
	hurt_knockback = knockback * (1.0 - clampf(stat(&"KNOCKBACK_RESISTANCE"), 0.0, 1.0))
	state_chart.send_event(&"hurt")


# TODO: a cura é infinita por enquanto; trocar pela consulta ao item no inventário
func has_heal_item() -> bool:
	return true

# TODO: aqui vai o consumo do item no inventário (chamado ao começar a beber)
func use_heal_item() -> void:
	pass

func stat(stat_name: StringName) -> float:
	return STATS.get_stat(stat_name)

func move_direction() -> float:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		facing = signf(direction)
		melee_hitbox.set_facing(facing)
	return direction

func read_actions() -> bool:
	if not is_on_floor():
		state_chart.send_event(&"airborne")
		return true
	if Input.is_action_just_pressed("jump"):
		velocity.y = -stat(&"JUMP_SPEED")
		state_chart.send_event(&"airborne")
		return true
	if Input.is_action_just_pressed("roll") and STATS.has_stamina(stat(&"ROLL_STAMINA_COST")):
		state_chart.send_event(&"roll")
		return true
	if Input.is_action_just_pressed("attack") and STATS.has_stamina(stat(&"SWING_STAMINA_COST")):
		state_chart.send_event(&"attack")
		return true
	if Input.is_action_just_pressed("heal") and has_heal_item():
		state_chart.send_event(&"heal")
		return true
	return false

func configure_swing(swing: Node, prefix: String, windup: float, hit: float, recovery: float) -> void:
	state_chart.set_expression_property(prefix + "_windup", windup)
	state_chart.set_expression_property(prefix + "_hit", hit)
	state_chart.set_expression_property(prefix + "_recovery", recovery)
	for phase in find_attack_phases(swing):
		if phase.HITBOX == null:
			phase.HITBOX = melee_hitbox

# Começo de cada golpe: gasta estamina e entrega ao PlayerHitbox o dano (força e bônus em jogo),
# o stagger e os efeitos da arma (buildup) deste golpe
func begin_swing(swing: Node, damage_stat: StringName, stagger_stat: StringName) -> void:
	STATS.spend_stamina(stat(&"SWING_STAMINA_COST"))
	velocity.x = 0
	set_swing_damage(swing, damage_stat)
	melee_hitbox.stagger = stat(stagger_stat)
	melee_hitbox.buildups = STATS.on_hit_buildups()

func set_swing_damage(swing: Node, damage_stat: StringName) -> void:
	for phase in find_attack_phases(swing):
		if phase.HITBOX_ACTIVE:
			phase.DAMAGE = STATS.attack_damage(damage_stat)

func find_attack_phases(node: Node) -> Array[AttackPhase]:
	var phases : Array[AttackPhase] = []
	for child in node.get_children():
		if child is AttackPhase:
			phases.append(child)
		phases.append_array(find_attack_phases(child))
	return phases
