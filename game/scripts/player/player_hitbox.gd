class_name PlayerHitbox
extends MeleeHitbox

# Hitbox do player. Igual à MeleeHitbox (as AttackPhase ligam e desligam do mesmo jeito), mas
# entrega o dano no formato do boss: take_damage(amount, stagger, element, buildup).
# O boss tem outras áreas na mesma camada (MeleeHitbox, AreaWave, ThrownSword) que NÃO podem
# receber dano, então só vale a hurtbox dele: uma Area2D chamada Hurtbox, cujo dono tem take_damage.

# Mapa do efeito da arma (PlayerStats.ON_HIT_EFFECTS) para o elemento que o boss entende
const ELEMENT_BY_EFFECT : Dictionary = {
	&"BURN_BUILDUP": "fire",
	&"PARALYSIS_BUILDUP": "eletric",
	&"FROSTBITE_BUILDUP": "freeze",
}

# Stagger do golpe atual (desconta da postura do boss). O player define ao começar cada golpe
var stagger : float = 0.0
# Buildup de cada efeito da arma no golpe atual: {&"BURN_BUILDUP": 10.0, ...}
var buildups : Dictionary = {}

func _on_area_entered(area: Area2D) -> void:
	if not active or area.name != &"Hurtbox":
		return

	var target = area.owner
	if target == null or target in hit_targets or not target.has_method("take_damage"):
		return

	hit_targets.append(target)
	target.take_damage(damage, stagger, "", 0.0)
	# cada efeito vai numa chamada própria só com buildup (dano 0), senão o dano se repetiria
	for effect in buildups:
		target.take_damage(0, 0.0, ELEMENT_BY_EFFECT[effect], buildups[effect])
