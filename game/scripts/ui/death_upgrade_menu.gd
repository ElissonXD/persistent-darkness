extends CanvasLayer

@export var player_stats : PlayerStats
@export_file("*.tscn") var main_menu_path: String = "res://game/scenes/ui/main_menu.tscn"

const AVAILABLE_UPGRADES : Array = [
	{"stat": &"MAX_HEALTH", "amount": 20.0, "text": "Aumentar Vida Máxima (+20)"},
	{"stat": &"MAX_STAMINA", "amount": 15.0, "text": "Aumentar Estamina (+15)"},
	{"stat": &"STRENGTH", "amount": 3.0, "text": "Aumentar Força (+3)"},
	{"stat": &"MOVE_SPEED", "amount": 20.0, "text": "Aumentar Velocidade (+20)"},
	{"stat": &"STAMINA_REGEN", "amount": 5.0, "text": "Regeneração de Estamina rápida (+5)"}
]

@onready var buttons_container: VBoxContainer = $Control/MarginContainer/VBoxContainer
@onready var death_count_label: Label = $Control/MarginContainer/VBoxContainer/DeathCountLabel 
@onready var menu_button: Button = $Control/MarginContainer/VBoxContainer/MenuButton        

var current_options : Array = []

func _ready() -> void:
	hide()
	if menu_button:
		if not menu_button.pressed.is_connected(_on_menu_button_pressed):
			menu_button.pressed.connect(_on_menu_button_pressed)

func show_death_screen() -> void:
	get_tree().paused = true
	
	if player_stats:
		player_stats.add_death()
		if death_count_label:
			death_count_label.text = "Total de Mortes: %d" % player_stats.death_count
			
	show()
	generate_random_choices()

func generate_random_choices() -> void:
	var pool = AVAILABLE_UPGRADES.duplicate()
	pool.shuffle()
	current_options.clear()
	
	for i in range(min(3, pool.size())):
		current_options.append(pool[i])
	
	var child_buttons = buttons_container.get_children()
	var option_index = 0
	
	for child in child_buttons:
		if child is Button and child != menu_button:
			if option_index < current_options.size():
				child.show()
				child.text = current_options[option_index]["text"]
				
				if child.pressed.is_connected(_on_upgrade_selected):
					child.pressed.disconnect(_on_upgrade_selected)
					
				child.pressed.connect(_on_upgrade_selected.bind(option_index))
				option_index += 1
			else:
				child.hide()

func _on_upgrade_selected(option_index: int) -> void:
	
	if option_index < 0 or option_index >= current_options.size():
		return
		
	var chosen = current_options[option_index]
	
	if player_stats:
		player_stats.raise_base(chosen["stat"], chosen["amount"])
		player_stats.reset()
		
	
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_path)
