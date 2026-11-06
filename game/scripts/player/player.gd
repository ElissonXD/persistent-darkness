extends CharacterBody2D

# DURAÇÕES: ficam no delay_in_seconds das transições da cena (ex.: "roll_iframe_duration"). O valor
# da expressão é definido aqui com state_chart.set_expression_property(). Defina-o no state_entered
# do estado PAI: o addon só avalia os delays dos filhos depois desse sinal.
#
# INVULNERABILIDADE: a variável `invulnerable` é ligada/desligada pelos sinais do estado
# Invulnerable. Qualquer habilidade que dê invencibilidade deve usar um estado próprio igual a esse.
#
# COMO ADICIONAR UMA HABILIDADE NOVA (ex.: Dash), seguindo o padrão do Roll:
#   1. Status: crie os @export dela em player_stats.gd (DASH_SPEED, DASH_DURATION, DASH_STAMINA_COST...).
#   2. Cena (player.tscn): dentro de StateChart/Root/Grounded adicione um AtomicState "Dash"
#      (ou um CompoundState com fases, como o Swing, se tiver golpe).
#   3. Entrada: em Grounded adicione uma Transition com event = dash e to = ../Dash.
#   4. Saída: dentro do Dash adicione uma Transition com to = ../../Idle e
#      delay_in_seconds = dash_duration.
#   5. Sinais (aba Sinais do Dash): state_entered -> _on_dash_state_entered.
#   6. Neste script escreva _on_dash_state_entered(): gaste estamina com STATS.spend_stamina(...),
#      aplique velocity.x e defina a duração com
#      state_chart.set_expression_property(&"dash_duration", stat(&"DASH_DURATION")).
#   7. Input: crie a ação no Mapa de Entrada e em read_actions() mande
#      state_chart.send_event(&"dash"), só se a habilidade estiver desbloqueada e houver estamina.
#   Se a habilidade causa dano: use a MeleeHitbox do player e fases AttackPhase com
#   HITBOX_ACTIVE ligado (copie o formato do Swing1) e atualize o dano a cada uso como em
#   set_swing_damage(), para bônus e força valerem na hora.
#
# STATUS EM JOGO: sempre stat(&"NOME") (valor base + bônus da partida), nunca um número fixo.

@export_category('Player Data')
@export var STATS : PlayerStats

# TODO: duração provisória; no futuro pode depender do ataque recebido e de um cálculo.
@export_category('Hurt')
@export var HURT_DURATION : float = 0.5

# TODO: valores dos golpes provisórios, o grupo ainda não definiu
@export_category('Swing 1')
@export var SWING_1_WINDUP : float = 0.15
@export var SWING_1_HIT : float = 0.12
@export var SWING_1_RECOVERY : float = 0.4
@export var SWING_1_KNOCKBACK : Vector2 = Vector2(150, -50)

@export_category('Swing 2')
@export var SWING_2_WINDUP : float = 0.2
@export var SWING_2_HIT : float = 0.15
@export var SWING_2_RECOVERY : float = 0.5
@export var SWING_2_KNOCKBACK : Vector2 = Vector2(250, -150)


@onready var state_chart: StateChart = $StateChart
@onready var melee_hitbox: MeleeHitbox = $MeleeHitbox
@onready var swing_1: CompoundState = $StateChart/Root/Grounded/Attack/Swing1
@onready var swing_2: CompoundState = $StateChart/Root/Grounded/Attack/Swing2


var facing : float = 1.0
var invulnerable : bool = false
var pending_knockback : Vector2 = Vector2.ZERO

func _ready() -> void:
	STATS.reset()
	state_chart.set_expression_property(&"hurt_duration", HURT_DURATION)

	
	configure_swing(swing_1, "swing1", SWING_1_WINDUP, SWING_1_HIT, SWING_1_RECOVERY, SWING_1_KNOCKBACK)
	configure_swing(swing_2, "swing2", SWING_2_WINDUP, SWING_2_HIT, SWING_2_RECOVERY, SWING_2_KNOCKBACK)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	STATS.tick(delta)
	move_and_slide()

# TODO: A cena usa roll_duration na transição de saída, mas o script define roll_iframe_duration e
# roll_recovery_duration; também há uma conexão para _on_roll_state_exited, método que ainda não existe.
func _on_roll_state_entered() -> void:
	STATS.spend_stamina(stat(&"ROLL_STAMINA_COST"))
	velocity.x = facing * stat(&"ROLL_SPEED")
	state_chart.set_expression_property(&"roll_iframe_duration", stat(&"ROLL_IFRAME_DURATION"))
	state_chart.set_expression_property(&"roll_recovery_duration", stat(&"ROLL_RECOVERY_DURATION"))

func _on_invulnerable_state_entered() -> void:
	invulnerable = true

func _on_invulnerable_state_exited() -> void:
	invulnerable = false

func _on_swing_state_entered() -> void:
	STATS.spend_stamina(stat(&"SWING_STAMINA_COST"))
	velocity.x = 0
	set_swing_damage(swing_1, &"SWING_1_DAMAGE")
	set_swing_damage(swing_2, &"SWING_2_DAMAGE")

func _on_dead_state_entered() -> void:
	velocity.x = 0

func _on_hurt_state_entered() -> void:
	velocity.x = pending_knockback.x
	if pending_knockback.y != 0.0:
		velocity.y = pending_knockback.y


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

func _on_swing_1_recovery_state_physics_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("attack") and STATS.has_stamina(stat(&"SWING_STAMINA_COST")):
		state_chart.send_event(&"swing_2")


func take_damage(amount: int, knockback: Vector2) -> void:
	if invulnerable or STATS.is_dead():
		return
	STATS.take_damage(amount)
	if STATS.is_dead():
		state_chart.send_event(&"died")
		return

	pending_knockback = knockback
	if not is_on_floor() or knockback.y < 0.0:
		state_chart.send_event(&"hurt_airborne")
	else:
		state_chart.send_event(&"hurt_grounded")


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
		# TODO: A altura máxima do salto é menor que a altura da hitbox do ataque à distância do boss, então não é possível desviar dela pulando.
		velocity.y = -stat(&"JUMP_SPEED")
		state_chart.send_event(&"airborne")
		return true
	if Input.is_action_just_pressed("roll") and STATS.has_stamina(stat(&"ROLL_STAMINA_COST")):
		state_chart.send_event(&"roll")
		return true
	if Input.is_action_just_pressed("attack") and STATS.has_stamina(stat(&"SWING_STAMINA_COST")):
		state_chart.send_event(&"attack")
		return true
	return false

func configure_swing(swing: Node, prefix: String, windup: float, hit: float, recovery: float, knockback: Vector2) -> void:
	state_chart.set_expression_property(prefix + "_windup", windup)
	state_chart.set_expression_property(prefix + "_hit", hit)
	state_chart.set_expression_property(prefix + "_recovery", recovery)
	for phase in find_attack_phases(swing):
		if phase.HITBOX == null:
			phase.HITBOX = melee_hitbox
		if phase.HITBOX_ACTIVE:
			phase.KNOCKBACK = knockback

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
