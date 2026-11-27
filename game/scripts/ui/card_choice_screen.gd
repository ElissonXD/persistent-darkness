class_name CardChoiceScreen
extends Control

## Avisa que o jogador terminou (escolheu ou pulou). Quem abriu a tela decide o que vem depois.
signal finished

const CARD_VIEW := preload("res://game/scenes/ui/card_view.tscn")
const SKIP_TEXT := "Pular: segue sem escolher nenhuma carta."

@onready var offers_row: HBoxContainer = $Margin/Columns/Main/OffersRow
@onready var detail_label: RichTextLabel = $Margin/Columns/Main/DetailLabel
@onready var luck_label: Label = $Margin/Columns/Main/LuckLabel
@onready var skip_button: Button = $Margin/Columns/Main/SkipButton
@onready var owned_row: Container = $Margin/Columns/Sidebar/OwnedScroll/OwnedRow

var pool: CardPool
var stats: PlayerStats
var offers: Array[CardData] = []
var pending_sacrifice: CardData = null   # sacrifício pede um segundo clique para confirmar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skip_button.pressed.connect(_on_skip_pressed)

	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.focus_mode = Control.FOCUS_NONE
	skip_button.focus_entered.connect(func(): detail_label.text = "[center]%s[/center]" % SKIP_TEXT)

## Chame depois de adicionar a tela à árvore.
func open(card_pool: CardPool, player_stats: PlayerStats) -> void:
	pool = card_pool
	stats = player_stats
	pending_sacrifice = null
	offers = pool.draw_offers()
	refresh()


## focus_card: carta que deve manter o foco depois de reconstruir (padrão: a primeira oferta).
func refresh(focus_card: CardData = null) -> void:
	clear_children(offers_row)
	clear_children(owned_row)
	detail_label.text = ""
	var to_focus: CardView = null

	for card in offers:
		var view := add_card(offers_row, card, "Escolher", duplicate_hint(card), false, _on_offer_chosen)
		if to_focus == null:
			to_focus = view

	for card in pool.owned:
		var text := "Confirmar?" if card == pending_sacrifice else "Sacrificar"
		var view := add_card(owned_row, card, text, sacrifice_hint(card), true, _on_sacrifice_pressed)
		if card == focus_card:
			to_focus = view

	if offers.is_empty():
		luck_label.text = "Não há mais cartas disponíveis"
	else:
		luck_label.text = "Chance de lendária por oferta: %d%%" % legendary_percent(pool.luck)

	if to_focus != null:
		to_focus.focus_button()
	else:
		skip_button.grab_focus.call_deferred()


func add_card(row: Container, card: CardData, text: String, hint: String, compact: bool, on_pressed: Callable) -> CardView:
	var view := CARD_VIEW.instantiate() as CardView
	row.add_child(view)
	view.setup(card, text, hint, compact)
	view.action_pressed.connect(on_pressed)
	view.card_focused.connect(_on_card_focused)
	return view


func duplicate_hint(card: CardData) -> String:
	for ability in card.ABILITIES:
		if stats.has_ability(ability):
			return "Você já tem esta habilidade"
	return ""


func sacrifice_hint(card: CardData) -> String:
	return "Lendária: %d%%" % legendary_percent(pool.luck_after(card))


func legendary_percent(luck: int) -> int:
	return roundi(pool.rarity_chances(luck)[CardData.Rarity.LEGENDARY] * 100.0)


func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _on_card_focused(card: CardData) -> void:
	detail_label.text = "[center][b]%s[/b] (%s)\n%s\n%s[/center]" % [
		card.CARD_NAME, CardView.RARITY_NAMES[card.RARITY], card.DESCRIPTION,
		CardText.effects_bbcode(card, "  ·  ")]


func _on_offer_chosen(card: CardData) -> void:
	pool.pick(card, stats)
	finished.emit()


func _on_sacrifice_pressed(card: CardData) -> void:
	if pending_sacrifice != card:
		pending_sacrifice = card   # primeiro clique: só marca
		refresh(card)              # mantém o foco na mesma carta
		return
	pending_sacrifice = null       # segundo clique: executa
	offers = pool.sacrifice(card, stats)
	refresh()


func _on_skip_pressed() -> void:
	pool.skip()
	finished.emit()
