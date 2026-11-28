class_name CardView
extends PanelContainer

signal action_pressed(card: CardData)
signal card_focused(card: CardData)

const RARITY_NAMES := ["Comum", "Rara", "Lendária"]
const RARITY_COLORS := [Color("b0b0b0"), Color("5aa0ff"), Color("ffd6a4ff")]
const FOCUS_TINT := Color(1.25, 1.25, 1.25)
const SHOW_DESCRIPTION := false

var card: CardData

@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var rarity_label: Label = $Margin/VBox/RarityLabel
@onready var description_label: Label = $Margin/VBox/DescriptionLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel
@onready var action_button: Button = $Margin/VBox/ActionButton
@onready var effects_label: RichTextLabel = $Margin/VBox/EffectsLabel


func _ready() -> void:
	effects_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects_label.focus_mode = Control.FOCUS_NONE
	action_button.pressed.connect(func(): action_pressed.emit(card))
	action_button.focus_entered.connect(_on_focus_entered)
	action_button.focus_exited.connect(func(): modulate = Color.WHITE)
	# O mouse sobre a carta também move o foco: teclado, controle e mouse usam o mesmo caminho
	mouse_entered.connect(_grab_focus_now)
	action_button.mouse_entered.connect(_grab_focus_now)


## Chame DEPOIS de add_child: antes disso os nós acima ainda não existem.
func setup(new_card: CardData, action_text: String, hint: String = "", compact: bool = false) -> void:
	card = new_card
	name_label.text = card.CARD_NAME
	rarity_label.text = RARITY_NAMES[card.RARITY]
	rarity_label.visible = not compact   # a cor da carta já indica a raridade
	description_label.text = card.DESCRIPTION
	description_label.visible = SHOW_DESCRIPTION and not compact
	effects_label.text = CardText.effects_bbcode(card)
	effects_label.visible = not compact
	hint_label.text = hint
	hint_label.visible = hint != ""
	action_button.text = action_text
	custom_minimum_size = Vector2(160, 110) if compact else Vector2(220, 280)
	self_modulate = RARITY_COLORS[card.RARITY]   # tinge só o fundo da carta


## Adiado porque o nó pode ter acabado de entrar na árvore.
func focus_button() -> void:
	action_button.grab_focus.call_deferred()


func _grab_focus_now() -> void:
	action_button.grab_focus()


func _on_focus_entered() -> void:
	modulate = FOCUS_TINT   # destaque na carta inteira, não só no botão
	card_focused.emit(card)
