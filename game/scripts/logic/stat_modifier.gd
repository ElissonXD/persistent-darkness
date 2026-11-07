class_name StatModifier
extends Resource



## Nome EXATO de um @export do PlayerStats (ex.: MOVE_SPEED, SWING_1_DAMAGE, MAX_HEALTH)
@export var STAT : StringName
## Soma ao valor base (negativo = penalidade)
@export var FLAT : float = 0.0
## Percentual sobre o total (0.1 = +10%, -0.2 = -20%)
@export var MULT : float = 0.0
