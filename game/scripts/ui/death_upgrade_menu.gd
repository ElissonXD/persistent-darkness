extends CanvasLayer

@export var player_stats: PlayerStats
@export var card_pool: CardPool
@export_file("*.tscn") var main_menu_path: String = "res://game/scenes/ui/main_menu.tscn"

const CARD_CHOICE_SCENE := preload("res://game/scenes/ui/card_choice_screen.tscn")

@onready var card_container: Control = $Control

var _active_card_screen: CardChoiceScreen = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func show_death_screen() -> void:
	if visible:
		return

	visible = true
	get_tree().paused = true

	if player_stats:
		player_stats.add_death()

	_open_card_choice()


func _open_card_choice() -> void:
	_clear_card_screen()

	if not card_pool or not player_stats:
		push_warning("DeathScreen: 'card_pool' ou 'player_stats' não atribuídos no Inspetor.")
		return

	_active_card_screen = CARD_CHOICE_SCENE.instantiate() as CardChoiceScreen
	card_container.add_child(_active_card_screen)

	_active_card_screen.open(card_pool, player_stats)
	_active_card_screen.finished.connect(_on_card_choice_finished)
	_active_card_screen.menu_requested.connect(_on_menu_button_pressed)


func _on_card_choice_finished() -> void:
	_clear_card_screen()
	if player_stats:
		player_stats.reset()

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_button_pressed() -> void:
	_clear_card_screen()
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_path)


func _clear_card_screen() -> void:
	if _active_card_screen:
		_active_card_screen.queue_free()
		_active_card_screen = null
