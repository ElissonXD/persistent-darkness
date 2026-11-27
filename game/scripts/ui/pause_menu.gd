extends CanvasLayer

@onready var resume_button: Button = $Control/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Control/MarginContainer/VBoxContainer/QuitButton
@onready var death_menu: CanvasLayer = get_node_or_null("../DeathUpgradeMenu") as CanvasLayer
@onready var player: Node = get_node_or_null("../../../World2D/Player")

func _ready() -> void:
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _death_screen_active():
		get_viewport().set_input_as_handled()
		return
	toggle_pause()

func toggle_pause() -> void:
	if _death_screen_active():
		return

	var new_state: bool = !get_tree().paused
	get_tree().paused = new_state
	visible = new_state
	
	if new_state:
		resume_button.grab_focus()

func _death_screen_active() -> bool:
	if is_instance_valid(death_menu) and death_menu.visible:
		return true
	if is_instance_valid(player) and "STATS" in player:
		var player_stats := player.get("STATS") as PlayerStats
		return player_stats != null and player_stats.is_dead()
	return false

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game/scenes/ui/main_menu.tscn")
