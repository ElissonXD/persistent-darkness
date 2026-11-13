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
		player_stats.health_changed.connect(_on_health_changed)
		player_stats.stamina_changed.connect(_on_stamina_changed)
		update_all_labels()

func update_all_labels() -> void:
	if not player_stats:
		return
		
	health_label.text = "Vida: %d / %d" % [player_stats.health, player_stats.get_stat(&"MAX_HEALTH")]
	stamina_label.text = "Estamina: %d / %d" % [player_stats.stamina, player_stats.get_stat(&"MAX_STAMINA")]
	strength_label.text = "Força: %d" % player_stats.get_stat(&"STRENGTH")
	speed_label.text = "Velocidade: %d" % player_stats.get_stat(&"MOVE_SPEED")

func _on_health_changed(current: float, maximum: float) -> void:
	health_label.text = "Vida: %d / %d" % [current, maximum]

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_label.text = "Estamina: %d / %d" % [current, maximum]
