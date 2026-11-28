extends Node

const SCREEN := preload("res://game/scenes/ui/card_choice_screen.tscn")

var pool: CardPool
var stats := PlayerStats.new()


func _ready() -> void:
	pool = load("res://game/resources/card_pool.tres") as CardPool
	pool.reset()
	show_screen()


func show_screen() -> void:
	var screen := SCREEN.instantiate() as CardChoiceScreen
	add_child(screen)
	screen.open(pool, stats)
	screen.finished.connect(_on_finished.bind(screen))


func _on_finished(screen: Control) -> void:
	print("Possui: ", pool.owned.map(func(c): return c.CARD_NAME))
	print("Vida máx: ", stats.get_stat(&"MAX_HEALTH"), " | Força: ", stats.get_stat(&"STRENGTH"))
	screen.queue_free()
	show_screen()
