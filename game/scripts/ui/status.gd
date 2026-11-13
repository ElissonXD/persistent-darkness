extends CanvasLayer

@export var player_stats : PlayerStats

@onready var health_label: Label = $VBoxContainer/HealthLabel
@onready var stamina_label: Label = $VBoxContainer/StaminaLabel
@onready var strength_label: Label = $VBoxContainer/StrengthLabel
@onready var speed_label: Label = $VBoxContainer/SpeedLabel

func _ready() -> void:
	if not player_stats:
		var player = get_tree().get_first_node_in_group("player")
		if player and "STATS" in player:
			player_stats = player.STATS
			
	if player_stats:
		if not player_stats.health_changed.is_connected(_on_health_changed):
			player_stats.health_changed.connect(_on_health_changed)
		if not player_stats.stamina_changed.is_connected(_on_stamina_changed):
			player_stats.stamina_changed.connect(_on_stamina_changed)
			
		if not player_stats.stat_changed.is_connected(_on_stat_changed):
			player_stats.stat_changed.connect(_on_stat_changed)
			
		update_all_labels()

func _on_stat_changed(_stat: StringName) -> void:
	update_all_labels()

func update_all_labels() -> void:
	if not player_stats:
		return
		
	var vida_max = player_stats.get_stat(&"MAX_HEALTH")
	var forca = player_stats.get_stat(&"STRENGTH")
	
	health_label.text = "Vida: %d / %d" % [player_stats.health, vida_max]
	stamina_label.text = "Estamina: %d / %d" % [player_stats.stamina, player_stats.get_stat(&"MAX_STAMINA")]
	strength_label.text = "Força: %d" % forca
	speed_label.text = "Velocidade: %d" % player_stats.get_stat(&"MOVE_SPEED")

func _on_health_changed(current: float, maximum: float) -> void:
	health_label.text = "Vida: %d / %d" % [current, maximum]

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_label.text = "Estamina: %d / %d" % [current, maximum]
