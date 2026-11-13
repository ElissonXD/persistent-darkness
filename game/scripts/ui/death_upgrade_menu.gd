extends CanvasLayer

@export var player_stats : PlayerStats

const AVAILABLE_UPGRADES : Array = [
	{"stat": &"MAX_HEALTH", "amount": 20.0, "text": "Aumentar Vida Máxima (+20)"},
	{"stat": &"MAX_STAMINA", "amount": 15.0, "text": "Aumentar Estamina (+15)"},
	{"stat": &"STRENGTH", "amount": 3.0, "text": "Aumentar Força (+3)"},
	{"stat": &"MOVE_SPEED", "amount": 20.0, "text": "Aumentar Velocidade (+20)"},
	{"stat": &"STAMINA_REGEN", "amount": 5.0, "text": "Regeneração de Estamina rápida (+5)"}
]

@onready var buttons_container: VBoxContainer = $Control/MarginContainer/VBoxContainer

var current_options : Array = []

func _ready() -> void:
	hide()

func show_death_screen() -> void:
	get_tree().paused = true
	show()
	generate_random_choices()

func generate_random_choices() -> void:
	var pool = AVAILABLE_UPGRADES.duplicate()
	pool.shuffle()
	current_options.clear()
	
	for i in range(min(3, pool.size())):
		current_options.append(pool[i])
	
	var child_buttons = buttons_container.get_children()
	for i in range(current_options.size()):
		if i < child_buttons.size() and child_buttons[i] is Button:
			child_buttons[i].text = current_options[i]["text"]
			
			if child_buttons[i].pressed.is_connected(_on_upgrade_selected):
				child_buttons[i].pressed.disconnect(_on_upgrade_selected)
				
			child_buttons[i].pressed.connect(_on_upgrade_selected.bind(i))

func _on_upgrade_selected(option_index: int) -> void:
	var chosen = current_options[option_index]
	
	if player_stats:
		player_stats.raise_base(chosen["stat"], chosen["amount"])
		player_stats.reset()
	
	get_tree().paused = false
	get_tree().reload_current_scene()
