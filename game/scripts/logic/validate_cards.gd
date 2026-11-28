@tool
extends EditorScript

const CARDS_DIR := "res://game/resources/cards/"

func _run() -> void:
	var cards := load_cards()
	print("=== %d cartas encontradas ===" % cards.size())
	var errors := 0
	var by_rarity := {}

	for card in cards:
		errors += check_card(card)
		by_rarity[card.RARITY] = by_rarity.get(card.RARITY, 0) + 1

	print("Por raridade (0=comum, 1=rara, 2=lendária): ", by_rarity)
	print("=== %d problema(s) ===" % errors)
	#stress_test(cards)
	#power_table(cards)
	#for n in [5, 15, 25]:
		#simulate_runs(cards, n)
	#cards_touching(cards, &"HEAL_AMOUNT")
	#cards_touching(cards, &"SWING_1_DAMAGE")
	#dump_cards(cards)
	dump_effects(cards)

func dump_effects(cards: Array[CardData]) -> void:
	var lines : Array[String] = []
	for card in cards:
		lines.append("%s: %s | \"%s\"" % [card.CARD_NAME, CardText.effects_plain(card), card.DESCRIPTION])
	var text := "\n".join(lines)
	print(text)
	DisplayServer.clipboard_set(text)

func dump_cards(cards: Array[CardData]) -> void:
	var sorted := cards.duplicate()
	sorted.sort_custom(func(a, b): return a.RARITY < b.RARITY or (a.RARITY == b.RARITY and a.CARD_NAME < b.CARD_NAME))
	var tags := ["C", "R", "L"]   # comum, rara, lendária
	var lines : Array[String] = [dump_base()]

	for card in sorted:
		var parts : Array[String] = []
		for m in card.MODIFIERS:
			if m == null:
				continue
			var s := str(m.STAT)
			if m.FLAT != 0.0:
				s += " " + signed(m.FLAT)
			if m.MULT != 0.0:
				s += " " + signed(m.MULT * 100.0) + "%"
			parts.append(s)
		for a in card.ABILITIES:
			parts.append("HABILIDADE " + str(a))
		lines.append("[%s] %s: %s | \"%s\"" % [tags[card.RARITY], card.CARD_NAME, ", ".join(parts), card.DESCRIPTION.replace("\n", " ")])

	var text := "\n".join(lines)
	print(text)
	DisplayServer.clipboard_set(text)


func dump_base() -> String:
	var snap := snapshot(PlayerStats.new())
	var parts : Array[String] = []
	for key in snap:
		parts.append("%s=%s" % [key, String.num(snap[key], 2)])
	return "BASE: " + ", ".join(parts)


func signed(value: float) -> String:
	return ("+" if value > 0.0 else "") + String.num(value, 2)

func cards_touching(cards: Array[CardData], stat: StringName) -> void:
	print("--- Cartas que mexem em %s ---" % stat)
	for card in cards:
		for m in card.MODIFIERS:
			if m != null and m.STAT == stat:
				print("%s: FLAT %.2f | MULT %.2f" % [card.CARD_NAME, m.FLAT, m.MULT])

func simulate_runs(cards: Array[CardData], picks: int, runs: int = 2000) -> void:
	var lo := {}
	var hi := {}
	var at_floor := {}
	var dmg := {}   # por golpe: [min, soma, max]
	for i in runs:
		var ps := PlayerStats.new()
		var pool := cards.duplicate()
		pool.shuffle()
		for card in pool.slice(0, picks):
			ps.apply_card(card)
		var snap := snapshot(ps)
		for key in snap:
			lo[key] = minf(lo.get(key, INF), snap[key])
			hi[key] = maxf(hi.get(key, -INF), snap[key])
			var floor_value : float = PlayerStats.MIN_STAT.get(key, 0.0)
			if ps.get(key) > floor_value and snap[key] <= floor_value + 0.001:
				at_floor[key] = at_floor.get(key, 0) + 1
		for swing in [&"SWING_1_DAMAGE", &"SWING_2_DAMAGE", &"SWING_3_DAMAGE"]:
			var d := float(ps.attack_damage(swing))
			var e : Array = dmg.get(swing, [INF, 0.0, -INF])
			dmg[swing] = [minf(e[0], d), e[1] + d, maxf(e[2], d)]
	print("--- %d runs com %d cartas sorteadas ---" % [runs, picks])
	for key in lo:
		if not is_equal_approx(lo[key], hi[key]):
			print("%s: min %.2f | max %.2f" % [key, lo[key], hi[key]])
	for key in at_floor:
		print("%s no piso em %d%% das runs" % [key, 100 * at_floor[key] / runs])
	for swing in dmg:
		print("%s dano real: min %.0f | média %.0f | max %.0f" % [swing, dmg[swing][0], dmg[swing][1] / runs, dmg[swing][2]])

func load_cards() -> Array[CardData]:
	var result : Array[CardData] = []
	for file in DirAccess.get_files_at(CARDS_DIR):
		if file.ends_with(".tres"):
			var res := load(CARDS_DIR + file)
			if res is CardData:
				result.append(res)
			else:
				push_error("%s não é um CardData" % file)
	return result


func check_card(card: CardData) -> int:
	var problems := 0
	var label := "%s (%s)" % [card.CARD_NAME, card.resource_path.get_file()]
	var ps := PlayerStats.new()

	if card.CARD_NAME.strip_edges() == "" or card.DESCRIPTION.strip_edges() == "":
		push_error("%s: nome ou descrição vazios" % label)
		problems += 1
	if card.MODIFIERS.is_empty() and card.ABILITIES.is_empty():
		push_error("%s: não tem nenhum efeito" % label)
		problems += 1

	for m in card.MODIFIERS:
		if m == null:
			push_error("%s: modificador vazio na lista" % label)
			problems += 1
			continue
		var base = ps.get(m.STAT)
		if typeof(base) != TYPE_FLOAT:
			push_error("%s: STAT '%s' não existe ou não é numérico" % [label, m.STAT])
			problems += 1
		elif m.FLAT == 0.0 and m.MULT == 0.0:
			push_warning("%s: modificador de %s com FLAT e MULT zerados" % [label, m.STAT])
		elif base == 0.0 and m.FLAT == 0.0:
			push_warning("%s: MULT em %s não faz nada (base é 0, use FLAT)" % [label, m.STAT])
		if not CardText.STAT_NAMES.has(m.STAT):
			push_warning("%s: '%s' sem nome em CardText.STAT_NAMES" % [label, m.STAT])
	for a in card.ABILITIES:
		if not CardText.ABILITY_NAMES.has(a):
			push_warning("%s: habilidade '%s' sem nome em CardText.ABILITY_NAMES" % [label, a])
		if typeof(ps.get(a)) != TYPE_BOOL:
			push_error("%s: habilidade '%s' não existe ou não é booleana" % [label, a])
			problems += 1

	if problems == 0 and not round_trip_ok(card):
		push_error("%s: aplicar e remover não volta ao estado original" % label)
		problems += 1
	return problems


# Aplica e remove a carta e confere se tudo volta ao que era
func round_trip_ok(card: CardData) -> bool:
	var ps := PlayerStats.new()
	var before := snapshot(ps)
	ps.apply_card(card)
	ps.remove_card(card)
	var after := snapshot(ps)
	for key in before:
		if not is_equal_approx(before[key], after[key]):
			return false
	return true


# Aplica TODAS as cartas de uma vez para ver como os stats se comportam no pior caso
func stress_test(cards: Array[CardData]) -> void:
	var ps := PlayerStats.new()
	var base := snapshot(ps)
	for card in cards:
		ps.apply_card(card)
	var final := snapshot(ps)
	print("--- Todas as cartas juntas (stat: base -> final) ---")
	for key in base:
		if not is_equal_approx(base[key], final[key]):
			print("%s: %.2f -> %.2f" % [key, base[key], final[key]])


func snapshot(ps: PlayerStats) -> Dictionary:
	var result := {}
	for p in ps.get_property_list():
		var is_export : bool = (p.usage & PROPERTY_USAGE_EDITOR) and (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE)
		if is_export and p.type == TYPE_FLOAT:
			result[p.name] = ps.get_stat(p.name)
	return result

func combo_damage(ps: PlayerStats) -> float:
	var factor := 1.0 + ps.get_stat(&"STRENGTH") * ps.get_stat(&"STRENGTH_DAMAGE_SCALE")
	var total := 0.0
	for swing in [&"SWING_1_DAMAGE", &"SWING_2_DAMAGE", &"SWING_3_DAMAGE"]:
		total += ps.get_stat(swing) * factor
	return total


func power_table(cards: Array[CardData]) -> void:
	var base := PlayerStats.new()
	var base_hp := base.get_stat(&"MAX_HEALTH")
	var base_dmg := combo_damage(base)
	var rows : Array = []
	for card in cards:
		var ps := PlayerStats.new()
		ps.apply_card(card)
		var hp := ps.get_stat(&"MAX_HEALTH") / base_hp
		var dmg := combo_damage(ps) / base_dmg
		var line := "%.2f | vida x%.2f | dano x%.2f | [%s] %s" % [hp * dmg, hp, dmg, ["C", "R", "L"][card.RARITY], card.CARD_NAME]
		rows.append([hp * dmg, line])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	var lines : Array[String] = ["produto | vida | dano | carta"]
	for r in rows:
		lines.append(r[1])
	var text := "\n".join(lines)
	print(text)
	DisplayServer.clipboard_set(text)
