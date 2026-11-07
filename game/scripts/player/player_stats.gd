class_name PlayerStats
extends Resource

# BASE x BÔNUS (duas coisas diferentes):
#   BASE   = os @export daqui. Só mudam por LEVEL UP: STATS.raise_base(&"STRENGTH", 1.0).
#            Permanente, não tem origem e não é removível.
#   BÔNUS  = cartas e efeitos externos. Ficam na lista `modifiers`, cada um com uma ORIGEM
#            (source), então podem ser removidos depois sem afetar o resto.
#
# COMO APLICAR (todos podem ser chamados por qualquer script que tenha acesso ao STATS):
#   Carta:          STATS.apply_card(carta)    /  STATS.remove_card(carta)
#   Efeito externo: STATS.add_modifier(&"MOVE_SPEED", 0.0, -0.30, self)   # poça: -30% velocidade
#                   STATS.remove_modifiers(self)                          # ao sair da poça
#     (o 4º parâmetro é a origem: use o próprio nó/recurso que causa o efeito)
#   Assim cada efeito tira só o que ele mesmo colocou. Penalidade = valor negativo.
#   Vida máxima: bônus NÃO cura sozinho; chame STATS.heal(quantidade) se quiser.
#
# HABILIDADES LIGA/DESLIGA (booleanos), ex.: ROLL_PASSES_THROUGH_ENEMIES: NÃO passam por get_stat nem
#   add_modifier (que só tratam números). Leia e altere direto: STATS.ROLL_PASSES_THROUGH_ENEMIES = true.
#   O StatModifier das cartas só aceita números, então a carta que ligar um booleano precisa de uma
#   extensão no CardData/apply_card (ainda não existe).
#
# COMO ADICIONAR UM STATUS NOVO (ex.: ATTACK_SPEED):
#   1. Crie um @export aqui, nome em MAIÚSCULAS, dentro de uma @export_category.
#   2. No player.gd, onde usar o valor, leia com stat(&"ATTACK_SPEED").
#   3. Pronto: cartas, level up e efeitos já funcionam com ele; nada mais aqui precisa mudar.
#
# ATENÇÃO (PERSISTÊNCIA): cartas e level up valem ALÉM da morte. Se a cena do boss recarrega
# quando o player morre, este Resource NÃO pode morrer junto: o player.tscn traz um local à
# cena só para testes. Na run de verdade, guarde o PlayerStats fora da cena (ex.: autoload) e
# entregue ao player antes de adicioná-lo à árvore: player.STATS = stats_da_run.


signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal stat_changed(stat: StringName)
signal ability_changed(ability: StringName)
signal died

const MIN_STAT : Dictionary = {&"MAX_HEALTH": 1.0, &"MAX_STAMINA": 1.0}
const ON_HIT_EFFECTS : Array[StringName] = [&"BURN_BUILDUP", &"PARALYSIS_BUILDUP", &"FROSTBITE_BUILDUP"]

@export_category('Vida')
@export var MAX_HEALTH : float = 100.0

@export_category('Estamina')
@export var MAX_STAMINA : float = 100.0
@export var STAMINA_REGEN : float = 30.0
@export var STAMINA_REGEN_DELAY : float = 0.8

@export_category('Força')
@export var STRENGTH : float = 10.0
@export var STRENGTH_DAMAGE_SCALE : float = 0.02

@export_category('Movimento')
@export var MOVE_SPEED : float = 300.0
@export var JUMP_SPEED : float = 500.0

@export_category('Rolagem')
@export var ROLL_SPEED : float = 600.0
@export var ROLL_DURATION : float = 0.4
@export var ROLL_IFRAME_DURATION : float = 0.25
@export var ROLL_STAMINA_COST : float = 25.0
## Se verdadeiro, durante a rolagem o player atravessa inimigos (upgrade de carta). Falso = a rolagem colide com eles
@export var ROLL_PASSES_THROUGH_ENEMIES : bool = false

# TODO: valores provisórios, o grupo ainda não definiu
@export_category('Cura')
@export var HEAL_AMOUNT : float = 40.0
@export var HEAL_DELAY : float = 0.8
@export var HEAL_RECOVERY_DURATION : float = 0.5
@export var HEAL_MOVE_SPEED_MULT : float = 0.3

# TODO: valores provisórios, o grupo ainda não definiu
@export_category('Ataque')
@export var SWING_STAMINA_COST : float = 20.0
@export var SWING_1_DAMAGE : float = 20.0
@export var SWING_2_DAMAGE : float = 30.0
@export var SWING_3_DAMAGE : float = 45.0

@export_category('Efeitos na arma')
@export var BURN_BUILDUP : float = 0.0
@export var PARALYSIS_BUILDUP : float = 0.0
@export var FROSTBITE_BUILDUP : float = 0.0

var health : float = 0.0
var stamina : float = 0.0
var regen_timer : float = 0.0
# Bônus ativos: cada item é {"stat", "flat", "mult", "source"}
var modifiers : Array = []

# Habilidades concedidas por cartas: cada item é {"ability", "source"}
var ability_grants : Array = []

func reset() -> void:
	health = get_stat(&"MAX_HEALTH")
	stamina = get_stat(&"MAX_STAMINA")
	regen_timer = 0.0
	health_changed.emit(health, get_stat(&"MAX_HEALTH"))
	stamina_changed.emit(stamina, get_stat(&"MAX_STAMINA"))


func add_modifier(stat: StringName, flat: float = 0.0, mult: float = 0.0, source: Variant = null) -> void:
	modifiers.append({"stat": stat, "flat": flat, "mult": mult, "source": source})
	update_stat(stat)

func remove_modifiers(source: Variant) -> void:
	var affected : Array = []
	for m in modifiers:
		if m.source == source:
			affected.append(m.stat)
	modifiers = modifiers.filter(func(m): return m.source != source)
	for stat in affected:
		update_stat(stat)

# A carta inteira vira bônus, com a própria carta como origem
func apply_card(card: CardData) -> void:
	for m in card.MODIFIERS:
		add_modifier(m.STAT, m.FLAT, m.MULT, card)
	for ability in card.ABILITIES:
		grant_ability(ability, card)

func remove_card(card: CardData) -> void:
	remove_modifiers(card)
	remove_abilities(card)

func raise_base(stat: StringName, amount: float) -> void:
	set(stat, get(stat) + amount)
	update_stat(stat)

func clear_modifiers() -> void:
	modifiers.clear()
	ability_grants.clear()

func get_stat(stat: StringName) -> float:
	var flat := 0.0
	var mult := 0.0
	for m in modifiers:
		if m.stat == stat:
			flat += m.flat
			mult += m.mult
	return maxf((get(stat) + flat) * (1.0 + mult), MIN_STAT.get(stat, 0.0))

func update_stat(stat: StringName) -> void:
	stat_changed.emit(stat)
	clamp_current()

func clamp_current() -> void:
	var max_health := get_stat(&"MAX_HEALTH")
	if health > max_health:
		health = max_health
		health_changed.emit(health, max_health)
	var max_stamina := get_stat(&"MAX_STAMINA")
	if stamina > max_stamina:
		stamina = max_stamina
		stamina_changed.emit(stamina, max_stamina)

func grant_ability(ability: StringName, source: Variant = null) -> void:
	if typeof(get(ability)) != TYPE_BOOL:
		push_error("PlayerStats: '%s' não é uma habilidade booleana válida" % ability)
		return
	ability_grants.append({"ability": ability, "source": source})
	ability_changed.emit(ability)

func remove_abilities(source: Variant) -> void:
	var affected : Array = []
	for g in ability_grants:
		if g.source == source:
			affected.append(g.ability)
	ability_grants = ability_grants.filter(func(g): return g.source != source)
	for ability in affected:
		ability_changed.emit(ability)

func has_ability(ability: StringName) -> bool:
	if get(ability) == true:
		return true
	for g in ability_grants:
		if g.ability == ability:
			return true
	return false

func is_dead() -> bool:
	return health <= 0.0

func take_damage(amount: float) -> void:
	if is_dead():
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, get_stat(&"MAX_HEALTH"))
	if is_dead():
		died.emit()

func heal(amount: float) -> void:
	if is_dead():
		return
	var maximum := get_stat(&"MAX_HEALTH")
	health = minf(health + amount, maximum)
	health_changed.emit(health, maximum)

func has_stamina(amount: float) -> bool:
	return stamina >= amount

func spend_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	regen_timer = get_stat(&"STAMINA_REGEN_DELAY")
	stamina_changed.emit(stamina, get_stat(&"MAX_STAMINA"))

func tick(delta: float) -> void:
	regen_timer -= delta
	var maximum := get_stat(&"MAX_STAMINA")
	if regen_timer > 0.0 or stamina >= maximum:
		return
	stamina = minf(stamina + get_stat(&"STAMINA_REGEN") * delta, maximum)
	stamina_changed.emit(stamina, maximum)

func attack_damage(damage_stat: StringName) -> int:
	return roundi(get_stat(damage_stat) * (1.0 + get_stat(&"STRENGTH") * get_stat(&"STRENGTH_DAMAGE_SCALE")))

func on_hit_buildups() -> Dictionary:
	var result := {}
	for effect in ON_HIT_EFFECTS:
		var amount := get_stat(effect)
		if amount > 0.0:
			result[effect] = amount
	return result
