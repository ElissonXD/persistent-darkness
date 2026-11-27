class_name CardPool
extends Resource

const LUCK_VALUE := {
	CardData.Rarity.COMMON: 1,
	CardData.Rarity.RARE: 2,
	CardData.Rarity.LEGENDARY: 3,
}
const MAX_LUCK := 5

## Todas as cartas do jogo. Arraste os .tres aqui no Inspetor (funciona no jogo exportado).
@export var ALL_CARDS : Array[CardData] = []

var owned : Array[CardData] = []
var exiled : Array[CardData] = []       # sacrificadas: fora do pool até o fim da run
var last_offers : Array[CardData] = []  # evita repetir as mesmas ofertas num reroll
var luck : int = 0                      # zera ao escolher ou pular


func draw_offers(count: int = 3) -> Array[CardData]:
	var available : Array = available_cards()
	# num reroll, tenta não repetir as ofertas anteriores
	var fresh := available.filter(func(c): return c not in last_offers)
	if fresh.size() >= count:
		available = fresh
	var offers : Array[CardData] = []
	while offers.size() < count and not available.is_empty():
		var rarity := roll_rarity(available)
		var of_rarity := available.filter(func(c): return c.RARITY == rarity)
		var card : CardData = of_rarity.pick_random()
		offers.append(card)
		available.erase(card)
	last_offers = offers.duplicate() 
	return offers


func pick(card: CardData, stats: PlayerStats) -> void:
	if card not in last_offers:
		return
	owned.append(card)
	stats.apply_card(card)
	end_round()


func skip() -> void:
	end_round()


## Tira a carta da run, soma sorte e devolve novas ofertas.
func sacrifice(card: CardData, stats: PlayerStats) -> Array[CardData]:
	if card not in owned:
		return []
	owned.erase(card)
	exiled.append(card)
	stats.remove_card(card)
	luck = luck_after(card)
	return draw_offers()


func luck_after(card: CardData) -> int:
	return mini(luck + LUCK_VALUE[card.RARITY], MAX_LUCK)


## Chances por slot. Sem argumento usa a sorte atual; a UI pode passar luck_after(carta) para a prévia.
func rarity_chances(l: int = -1) -> Dictionary:
	if l < 0:
		l = luck
	return {
		CardData.Rarity.COMMON: 0.60 - 0.10 * l,
		CardData.Rarity.RARE: 0.30 + 0.05 * l,
		CardData.Rarity.LEGENDARY: 0.10 + 0.05 * l,
	}


func end_round() -> void:
	luck = 0
	last_offers.clear()


func reset() -> void:
	owned.clear()
	exiled.clear()
	last_offers.clear()
	luck = 0


func available_cards() -> Array[CardData]:
	var result : Array[CardData] = []
	for card in ALL_CARDS:
		if card not in owned and card not in exiled:
			result.append(card)
	return result


# Sorteia a raridade só entre as que ainda têm cartas disponíveis
func roll_rarity(available: Array) -> int:
	var chances := rarity_chances()
	var weights := {}
	for c in available:
		weights[c.RARITY] = chances[c.RARITY]
	var total := 0.0
	for w in weights.values():
		total += w
	var roll := randf() * total
	for rarity in weights:
		roll -= weights[rarity]
		if roll <= 0.0:
			return rarity
	return weights.keys()[0]
