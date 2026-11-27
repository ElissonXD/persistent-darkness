class_name CardText
extends RefCounted

# Troque por outras cores se quiser uma paleta amigável para daltonismo (azul/laranja, por exemplo)
const GOOD_COLOR := "6fdc6f"
const BAD_COLOR := "ff6b6b"
const NEUTRAL_COLOR := "dddddd"
const ABILITY_COLOR := "ffd166"

const STAT_NAMES := {
	&"MAX_HEALTH": "Vida máxima",
	&"MAX_STAMINA": "Estamina máxima",
	&"STAMINA_REGEN": "Regeneração de estamina",
	&"STAMINA_REGEN_DELAY": "Atraso da regeneração",
	&"STRENGTH": "Força",
	&"STRENGTH_DAMAGE_SCALE": "Escala de dano da força",
	&"MOVE_SPEED": "Velocidade de movimento",
	&"JUMP_SPEED": "Força do pulo",
	&"ROLL_SPEED": "Velocidade da rolagem",
	&"ROLL_DURATION": "Duração da rolagem",
	&"ROLL_IFRAME_DURATION": "Invulnerabilidade da rolagem",
	&"ROLL_RECOVERY_DURATION": "Recuperação da rolagem",
	&"ROLL_STAMINA_COST": "Custo de estamina da rolagem",
	&"SWING_STAMINA_COST": "Custo de estamina dos golpes",
	&"SWING_1_DAMAGE": "Dano do golpe 1",
	&"SWING_2_DAMAGE": "Dano do golpe 2",
	&"SWING_3_DAMAGE": "Dano do golpe 3",
	&"HEAL_AMOUNT": "Cura do frasco",
	&"HEAL_DELAY": "Atraso da cura",
	&"HEAL_RECOVERY_DURATION": "Recuperação da cura",
	&"HEAL_MOVE_SPEED_MULT": "Velocidade ao curar",
	&"BURN_BUILDUP": "Acúmulo de queimadura",
	&"PARALYSIS_BUILDUP": "Acúmulo de paralisia",
	&"FROSTBITE_BUILDUP": "Acúmulo de congelamento",
}

const ABILITY_NAMES := {
	&"ROLL_PASSES_THROUGH_ENEMIES": "Habilidade: atravessa inimigos ao rolar",
}

# Stats em que um valor MENOR é melhor para o jogador
const LOWER_IS_BETTER : Array[StringName] = [
	&"STAMINA_REGEN_DELAY", &"ROLL_STAMINA_COST", &"SWING_STAMINA_COST",
	&"HEAL_DELAY", &"HEAL_RECOVERY_DURATION", &"ROLL_RECOVERY_DURATION",
]

# Stats que são troca (nem bom nem ruim por si só): aparecem em branco
const NEUTRAL_STATS : Array[StringName] = [&"ROLL_DURATION"]

# Stats cujo valor FLAT é mostrado em segundos
const TIME_STATS : Array[StringName] = [
	&"ROLL_DURATION", &"ROLL_IFRAME_DURATION", &"ROLL_RECOVERY_DURATION",
	&"STAMINA_REGEN_DELAY", &"HEAL_DELAY", &"HEAL_RECOVERY_DURATION",
]

# Se TODOS os stats do grupo tiverem o mesmo modificador, vira uma linha só
const GROUPS := {
	"Dano de todos os golpes": [&"SWING_1_DAMAGE", &"SWING_2_DAMAGE", &"SWING_3_DAMAGE"],
}


## Linhas com BBCode (cores) para usar em RichTextLabel, unidas por um separador
static func effects_bbcode(card: CardData, separator: String = "\n") -> String:
	return separator.join(effect_lines(card, true))


## Mesmas linhas, sem cor (para imprimir no Output e comparar com a descrição)
static func effects_plain(card: CardData) -> String:
	return "; ".join(effect_lines(card, false))


static func effect_lines(card: CardData, colored: bool) -> Array[String]:
	var entries : Array = []
	for m in card.MODIFIERS:
		if m != null:
			entries.append({"label": stat_name(m.STAT), "stat": m.STAT, "flat": m.FLAT, "mult": m.MULT})
	entries = group_entries(entries)

	var lines : Array[String] = []
	for e in entries:
		lines.append(format_entry(e, colored))
	for a in card.ABILITIES:
		var text : String = ABILITY_NAMES.get(a, str(a))
		lines.append("[color=#%s]%s[/color]" % [ABILITY_COLOR, text] if colored else text)
	return lines


static func group_entries(entries: Array) -> Array:
	for group_label in GROUPS:
		var members : Array = GROUPS[group_label]
		var found : Array = entries.filter(func(e): return e.stat in members)
		if found.size() != members.size():
			continue
		var first = found[0]
		var same : bool = found.all(func(e): return is_equal_approx(e.flat, first.flat) and is_equal_approx(e.mult, first.mult))
		if not same:
			continue
		var grouped := {"label": group_label, "stat": members[0], "flat": first.flat, "mult": first.mult}
		var result : Array = []
		var emitted := false
		for e in entries:
			if e.stat in members:
				if not emitted:
					result.append(grouped)   # entra na posição do primeiro membro
					emitted = true
			else:
				result.append(e)
		entries = result
	return entries


static func format_entry(e: Dictionary, colored: bool) -> String:
	var parts : Array[String] = []
	if e.flat != 0.0:
		parts.append(format_flat(e.stat, e.flat))
	if e.mult != 0.0:
		parts.append(format_percent(e.mult * 100.0))
	var text := "%s %s" % [e.label, " e ".join(parts)]
	if not colored:
		return text
	return "[color=#%s]%s[/color]" % [color_for(e.stat, signf(e.flat) + signf(e.mult)), text]


static func format_flat(stat: StringName, value: float) -> String:
	if stat in TIME_STATS:
		return "%+.2f s" % value
	if is_equal_approx(value, roundf(value)):
		return "%+d" % int(roundf(value))
	return "%+.1f" % value


static func format_percent(percent: float) -> String:
	if is_equal_approx(percent, roundf(percent)):
		return "%+d%%" % int(roundf(percent))
	return "%+.1f%%" % percent


static func color_for(stat: StringName, net: float) -> String:
	if net == 0.0 or stat in NEUTRAL_STATS:
		return NEUTRAL_COLOR
	var increases := net > 0.0
	var good := increases != (stat in LOWER_IS_BETTER)
	return GOOD_COLOR if good else BAD_COLOR


static func stat_name(stat: StringName) -> String:
	return STAT_NAMES.get(stat, str(stat).capitalize())
