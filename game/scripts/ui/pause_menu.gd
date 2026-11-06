extends CanvasLayer

@onready var resume_button: Button = $Control/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Control/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var new_state: bool = !get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	
	if new_state:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game/scenes/ui/main_menu.tscn")
