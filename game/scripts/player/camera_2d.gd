extends Camera2D

@export var player_path: NodePath
@export var boss_path: NodePath
@export var boundary_node_path: NodePath
@export var background_node_path: NodePath

@export_group("Distâncias (em pixels)")
@export var min_distance: float = 120.0
@export var max_distance: float = 700.0

@export_group("Valores de Zoom")
@export var close_zoom: float = 1.35
@export var far_zoom: float = 0.85
## Zoom mínimo absoluto: garante que a área visível nunca ultrapasse o fundo (sem barras cinza/marrom)
@export var min_zoom: float = 0.9

@export_group("Centralização Y no Background")
@export var center_y_on_boundary: bool = true
@export_range(0.0, 1.0, 0.05) var y_center_weight: float = 1.0  # 1.0 = no centro Y do boundary; 0.0 = segue o player em Y
@export var extra_y_offset: float = 0.0  # Ajuste fino em pixels (negativo sobe, positivo desce)

@export_group("Seguimento e Limites")
@export var use_boundary_limits: bool = true
@export var deadzone_radius: float = 20.0
@export var follow_speed: float = 8.0
@export var zoom_speed: float = 5.0
@export_range(0.0, 0.5, 0.01) var boss_look_weight: float = 0.1

var player: Node2D
var boss: Node2D
var boundary_rect: Rect2
var has_boundary: bool = false
var background_rect: Rect2
var has_background: bool = false
var background_sprite: Sprite2D
var background_screen_transform: Transform2D
var background_screen_transform_captured: bool = false

func _ready() -> void:
	if not player_path.is_empty():
		player = get_node_or_null(player_path)
	if not boss_path.is_empty():
		boss = get_node_or_null(boss_path)

	if not player:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if not boss:
		boss = get_tree().get_first_node_in_group("boss") as Node2D

	_setup_boundary()
	_setup_background()

	if is_instance_valid(player):
		global_position = _clamp_to_background(_get_desired_position())

func _setup_boundary() -> void:
	if boundary_node_path.is_empty():
		return

	var b_node := get_node_or_null(boundary_node_path)
	if not b_node:
		return

	# União de todas as CollisionShape2D retangulares do Boundary (chão + paredes laterais)
	boundary_rect = Rect2()
	for child in b_node.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var rect_shape := child.shape as RectangleShape2D
			var scaled_size: Vector2 = rect_shape.size * child.global_scale
			var r := Rect2(child.global_position - scaled_size * 0.5, scaled_size)
			if not has_boundary:
				boundary_rect = r
				has_boundary = true
			else:
				boundary_rect = boundary_rect.merge(r)

	if use_boundary_limits and has_boundary:
		limit_left = int(boundary_rect.position.x)
		limit_top = int(boundary_rect.position.y)
		limit_right = int(boundary_rect.end.x)
		limit_bottom = int(boundary_rect.end.y)
	else:
		limit_left = -10000000
		limit_top = -10000000
		limit_right = 10000000
		limit_bottom = 10000000

func _setup_background() -> void:
	if background_node_path.is_empty():
		return

	var bg := get_node_or_null(background_node_path)
	if bg is Sprite2D:
		var sprite := bg as Sprite2D
		background_sprite = sprite
		background_rect = sprite.global_transform * sprite.get_rect()
		if has_boundary and sprite.get_parent() is Parallax2D:
			background_rect = boundary_rect
		has_background = true

func _lock_background_to_viewport() -> void:
	if not is_instance_valid(background_sprite):
		return

	var canvas_transform := get_viewport().get_canvas_transform()
	if not background_screen_transform_captured:
		background_screen_transform = canvas_transform * background_sprite.global_transform
		background_screen_transform_captured = true
		return

	background_sprite.global_transform = canvas_transform.affine_inverse() * background_screen_transform

func _find_collision_shape(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		return node as CollisionShape2D
	for child in node.get_children():
		var found := _find_collision_shape(child)
		if found:
			return found
	return null

func _get_desired_position() -> Vector2:
	if not is_instance_valid(player):
		return global_position

	var desired := player.global_position
	if is_instance_valid(boss) and boss_look_weight > 0.0:
		desired = player.global_position.lerp(boss.global_position, boss_look_weight)

	if center_y_on_boundary and has_boundary:
		var bg_center_y := boundary_rect.get_center().y
		desired.y = lerpf(desired.y, bg_center_y, y_center_weight)

	desired.y += extra_y_offset
	return desired

func _get_visible_world_size() -> Vector2:
	var vp_size := Vector2(get_viewport().get_size())
	return vp_size / zoom

func _clamp_to_background(pos: Vector2) -> Vector2:
	if not has_background:
		return pos

	var visible := _get_visible_world_size()
	var half := visible * 0.5
	var min_x := background_rect.position.x + half.x
	var max_x := background_rect.end.x - half.x
	var min_y := background_rect.position.y + half.y
	var max_y := background_rect.end.y - half.y

	var result := pos
	if min_x <= max_x:
		result.x = clampf(result.x, min_x, max_x)
	else:
		result.x = background_rect.get_center().x
	if min_y <= max_y:
		result.y = clampf(result.y, min_y, max_y)
	else:
		result.y = background_rect.get_center().y
	return result

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var target_zoom_val := far_zoom
	if is_instance_valid(boss):
		var dist := player.global_position.distance_to(boss.global_position)
		var t := clampf(inverse_lerp(min_distance, max_distance, dist), 0.0, 1.0)
		target_zoom_val = lerpf(close_zoom, far_zoom, t)

	target_zoom_val = maxf(target_zoom_val, min_zoom)
	zoom = zoom.lerp(Vector2.ONE * target_zoom_val, zoom_speed * delta)

	var desired_focus := _clamp_to_background(_get_desired_position())
	var next_target := global_position
	if global_position.distance_to(desired_focus) > deadzone_radius:
		next_target = desired_focus

	global_position = global_position.lerp(next_target, follow_speed * delta)
	global_position = _clamp_to_background(global_position)
	force_update_scroll()
	_lock_background_to_viewport()
