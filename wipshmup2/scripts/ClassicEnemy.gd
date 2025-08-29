class_name ClassicEnemy
extends Area2D

const GameUtils = preload("res://scripts/GameUtils.gd")

signal killed(points: int)
signal hit_player

enum EnemyType { FIGHTER, BOMBER, DESTROYER, SUBMARINE, TURRET, CONVOY, ATTACKER }
enum Movement { STRAIGHT_DOWN, SIDE_TO_SIDE, DIVE_ATTACK, FORMATION, ESCORT, PATROL, ASCEND, SURFACE }
enum FirePattern { NONE, STRAIGHT_SHOT, SPREAD_3, SPREAD_5, ALTERNATING, BOMB_DROP, TRIPLE_SHOT }

const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/bullet/EnemyBullet.tscn")

@export var enemy_type: int = EnemyType.FIGHTER
@export var speed: float = 40.0
@export var hp: int = 1
@export var points: int = 100
@export var sprite_target_height_px: float = 18.0
@export var movement: int = Movement.STRAIGHT_DOWN
@export var movement_amplitude: float = 32.0
@export var movement_speed: float = 30.0
@export var patrol_distance: float = 80.0
@export var fire_pattern: int = FirePattern.STRAIGHT_SHOT
@export var fire_interval: float = 2.0
@export var bullet_speed: float = 80.0
@export var fire_delay: float = 0.0
@export var formation_offset: Vector2 = Vector2.ZERO
@export var formation_leader: Node2D = null
@export var escort_distance: float = 40.0
@export var bomb_points_override: int = -1
@export var bomb_points_multiplier: float = 10.0
@export var ignore_shot_damage: bool = false
@export var ignore_bomb_damage: bool = false

var _last_damage_source: String = "shot"
var _time_alive: float = 0.0
var _base_position: Vector2
var _movement_phase: float = 0.0
var _firing_task_running: bool = false
var _fire_timer: float = 0.0
var _current_direction: int = 1
var _initial_position: Vector2
var _dive_target: Vector2

# Performance optimizations

func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	collision_layer = 1
	collision_mask = 0
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Safety check: ensure we have collision shape
	if not has_node("CollisionShape2D"):
		push_warning("ClassicEnemy missing CollisionShape2D: " + name)
	else:
		var collision_shape = $CollisionShape2D
		if not collision_shape.shape:
			push_warning("ClassicEnemy CollisionShape2D has no shape: " + name)

	_initial_position = global_position
	_base_position = global_position

	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("get_enemy_speed_multiplier"):
		var speed_mult: float = rm.get_enemy_speed_multiplier()
		var hp_mult: float = rm.get_enemy_hp_multiplier()
		speed *= speed_mult
		hp = int(ceil(float(hp) * hp_mult))

	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		if spr and spr.texture:
			var tex_size: Vector2i = spr.texture.get_size()
			if tex_size.y > 0:
				var s: float = sprite_target_height_px / float(tex_size.y)
				spr.scale = Vector2(s, s)

	if movement == Movement.DIVE_ATTACK:
		var player = _get_cached_player()
		_dive_target = player.global_position if player else global_position + Vector2(0, 200)

	if fire_pattern != FirePattern.NONE:
		_fire_timer = fire_delay
		_fire_loop()

	# Validate collision setup after initialization
	call_deferred("_validate_collision_setup")

func _physics_process(delta: float) -> void:
	_time_alive += delta
	_movement_phase += delta

	# Apply movement pattern
	_apply_movement_pattern(delta)

	# Handle firing
	if fire_pattern != FirePattern.NONE:
		_fire_timer -= delta

	# Round position for pixel-perfect movement
	position = position.round()

	# Check bounds and cleanup
	_check_bounds_and_cleanup()

func _validate_collision_setup() -> void:
	# Ensure collision detection is working properly
	if not monitoring:
		monitoring = true

	if collision_layer != 1:
		collision_layer = 1

	if collision_mask != 0:
		collision_mask = 0

	# Ensure we're in the enemy group
	if not is_in_group("enemy"):
		add_to_group("enemy")

func _apply_movement_pattern(delta: float) -> void:
	match movement:
		Movement.STRAIGHT_DOWN:
			position.y += speed * delta
		Movement.SIDE_TO_SIDE:
			position.y += speed * 0.7 * delta
			var x_offset = sin(_movement_phase * 2.0) * movement_amplitude
			global_position.x = _initial_position.x + x_offset
		Movement.DIVE_ATTACK:
			var direction = (_dive_target - global_position).normalized()
			var dive_speed = speed * (1.0 + _time_alive * 0.5)
			position += direction * dive_speed * delta
		Movement.FORMATION:
			if formation_leader and is_instance_valid(formation_leader):
				global_position = formation_leader.global_position + formation_offset
				position.y += speed * 0.5 * delta
			else:
				position.y += speed * delta
		Movement.ESCORT:
			if formation_leader and is_instance_valid(formation_leader):
				var angle = _movement_phase * 2.0
				var offset = Vector2(cos(angle), sin(angle)) * escort_distance
				global_position = formation_leader.global_position + offset
				position.y += speed * 0.3 * delta
			else:
				position.y += speed * delta
		Movement.PATROL:
			position.y += speed * 0.6 * delta
			var patrol_x = _initial_position.x + sin(_movement_phase * 1.5) * patrol_distance
			global_position.x = patrol_x
		Movement.ASCEND:
			position.y -= speed * delta

func _check_bounds_and_cleanup() -> void:
	if GameUtils.should_cleanup(position, enemy_type == EnemyType.TURRET):
		queue_free()

func take_damage(amount: int, source: String = "shot") -> void:
	if (source == "shot" and ignore_shot_damage) or (source == "bomb" and ignore_bomb_damage):
		return

	# Safety check: ensure we're still valid
	if not is_instance_valid(self):
		return
	hp -= amount
	_last_damage_source = source
	if hp <= 0:
		# Play enemy death sound
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_enemy_death"):
			audio_manager.play_enemy_death()

		var awarded: int = points
		if _last_damage_source == "bomb":
			awarded = bomb_points_override if bomb_points_override >= 0 else \
				int(round(float(points) * max(1.0, bomb_points_multiplier)))
		emit_signal("killed", awarded)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		emit_signal("hit_player")
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("hit_player")
		queue_free()

func _fire_loop() -> void:
	if _firing_task_running: return
	_firing_task_running = true

	while is_instance_valid(self):
		if _fire_timer > 0:
			await get_tree().create_timer(_fire_timer, false).timeout
			_fire_timer = 0.0

		if not is_instance_valid(self): break
		if not _is_on_screen():
			await get_tree().create_timer(0.5, false).timeout
			continue

		match fire_pattern:
			FirePattern.STRAIGHT_SHOT: _fire_straight_shot()
			FirePattern.SPREAD_3: _fire_spread_3()
			FirePattern.SPREAD_5: _fire_spread_5()
			FirePattern.ALTERNATING: _fire_alternating()
			FirePattern.BOMB_DROP: _fire_bomb_drop()
			FirePattern.TRIPLE_SHOT: _fire_triple_shot()

		_fire_timer = fire_interval
		await get_tree().create_timer(fire_interval, false).timeout

	_firing_task_running = false

func _fire_straight_shot() -> void:
	var direction = Vector2.DOWN
	if enemy_type == EnemyType.TURRET:
		var player = _get_cached_player()
		if player:
			direction = (player.global_position - global_position).normalized()
	_spawn_bullet(direction)

func _fire_spread_3() -> void:
	var angles = [-15.0, 0.0, 15.0]
	for angle in angles:
		var direction = Vector2.DOWN.rotated(deg_to_rad(angle))
		_spawn_bullet(direction)

func _fire_spread_5() -> void:
	var angles = [-30.0, -15.0, 0.0, 15.0, 30.0]
	for angle in angles:
		var direction = Vector2.DOWN.rotated(deg_to_rad(angle))
		_spawn_bullet(direction)

func _fire_alternating() -> void:
	var angle = 20.0 * _current_direction
	var direction = Vector2.DOWN.rotated(deg_to_rad(angle))
	_spawn_bullet(direction)
	_current_direction *= -1

func _fire_bomb_drop() -> void:
	_spawn_bullet(Vector2.DOWN)

func _fire_triple_shot() -> void:
	for i in range(3):
		_spawn_bullet(Vector2.DOWN)
		await get_tree().create_timer(0.1, false).timeout

func _spawn_bullet(direction: Vector2) -> void:
	# Play enemy shot sound
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_enemy_shot"):
		audio_manager.play_enemy_shot()

	GameUtils.spawn_bullet(ENEMY_BULLET_SCENE, global_position, direction, bullet_speed, get_tree().current_scene)

# Optimized player finding with caching
func _get_cached_player() -> Node2D:
	return GameUtils.get_cached_player()

func _is_on_screen() -> bool:
	return GameUtils.is_on_screen(global_position)

func _ensure_player_bullet_hits() -> void:
	var bullets = get_tree().get_nodes_in_group("player_bullet")
	for bullet in bullets:
		if bullet and bullet.global_position.distance_to(global_position) < 16:
			take_damage(1, "shot")
			bullet.queue_free()
