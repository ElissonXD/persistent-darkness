extends Node

const CHECK_STATS : Array[StringName] = [&"MAX_HEALTH", &"STRENGTH", &"MOVE_SPEED", &"SWING_1_DAMAGE"]


func _ready() -> void:
	var pool := load("res://game/resources/card_pool.tres") as CardPool
	if pool == null:
		push_error("card_pool.tres não encontrado: confira o caminho")
		return
	pool.reset()
	var stats := PlayerStats.new()
	print("Cartas no pool: ", pool.ALL_CARDS.size())

	# 1) Seis rodadas de escolha normais
	for i in 6:
		var offers := pool.draw_offers()
		check(offers.size() == 3, "rodada %d: 3 ofertas" % i)
		check(all_distinct(offers), "rodada %d: ofertas distintas" % i)
		check(offers.all(func(c): return c not in pool.owned), "rodada %d: nenhuma oferta já possuída" % i)
		pool.pick(offers[0], stats)
	check(pool.luck == 0, "sorte zera depois de escolher")

	# 2) Sacrifício
	var shown := pool.draw_offers()
	var target := pool.owned[0]
	var new_offers := pool.sacrifice(target, stats)
	check(target not in pool.owned, "carta sacrificada saiu das possuídas")
	check(target in pool.exiled, "carta sacrificada foi para o exílio")
	check(target not in new_offers, "carta sacrificada não volta nas ofertas")
	check(shown.all(func(c): return c not in new_offers), "reroll não repete as ofertas anteriores")
	check(pool.luck == CardPool.LUCK_VALUE[target.RARITY], "sorte = valor da raridade sacrificada")

	# 3) Os stats devem ser os mesmos de quem nunca teve a carta
	var expected := PlayerStats.new()
	for c in pool.owned:
		expected.apply_card(c)
	for s in CHECK_STATS:
		check(is_equal_approx(stats.get_stat(s), expected.get_stat(s)), "%s volta ao esperado" % s)

	# 4) Escolher depois do sacrifício encerra a rodada
	pool.pick(new_offers[0], stats)
	check(pool.luck == 0, "sorte zera depois de escolher no reroll")
	print("Chances com sorte 3: ", pool.rarity_chances(3))


func check(ok: bool, msg: String) -> void:
	print(("OK     " if ok else "FALHOU ") + msg)


func all_distinct(cards: Array) -> bool:
	for i in cards.size():
		for j in range(i + 1, cards.size()):
			if cards[i] == cards[j]:
				return false
	return true
