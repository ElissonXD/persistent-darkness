extends Control

@export var player_stats : PlayerStats
@export_file("*.tscn") var first_level_path: String = "res://game/scenes/levels/main_level.tscn"

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()
	
	# Reseta as mortes e todos os buffs sempre que carregar o menu principal
	if player_stats:
		player_stats.reset_progress()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(first_level_path)

func _on_quit_pressed() -> void:
	get_tree().quit()
