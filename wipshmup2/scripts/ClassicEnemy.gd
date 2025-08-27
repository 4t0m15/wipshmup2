class_name ClassicEnemy
extends Area2D

signal killed(points: int)
signal hit_player

# Enemy types inspired by 1942
enum EnemyType {
	FIGHTER,        # Fast, agile fighter plane
	BOMBER,         # Heavy bomber that drops payloads
	DESTROYER,      # Ship that moves side to side
	SUBMARINE,      # Underwater enemy that surfaces
	TURRET,         # Ground turret that doesn't move
	CONVOY,         # Slow moving transport
	ATTACKER        # Kamikaze-style dive attacker
}

# Movement patterns for 1942 style
enum Movement {
	STRAIGHT_DOWN,    # Classic straight descent
	SIDE_TO_SIDE,     # Gentle side-to-side movement
	DIVE_ATTACK,      # Fast dive toward player
	FORMATION,        # Follow formation leader
	ESCORT,           # Protect formation
	PATROL,           # Side-to-side patrol pattern
	ASCEND,           # Move upward (for submarines surfacing)
	SURFACE           # Move up then level off
}

# Simple firing patterns
enum FirePattern {
	NONE,
	STRAIGHT_SHOT,     # Simple forward shot
	SPREAD_3,          # 3-way spread
	SPREAD_5,          # 5-way spread
	ALTERNATING,       # Left-right alternating shots
	BOMB_DROP,         # Drop bombs straight down
	TRIPLE_SHOT        # Three shots in quick succession
}

# Constants
const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/bullet/EnemyBullet.tscn")
const BOMB_SCENE: PackedScene = preload("res://scenes/bullet/EnemyBullet.tscn")  # Same as bullet for now

# Base stats
@export var enemy_type: int = EnemyType.FIGHTER
@export var speed: float = 80.0
@export var hp: int = 1
@export var points: int = 100
@export var sprite_target_height_px: float = 18.0

@export var movement: int = Movement.STRAIGHT_DOWN
@export var movement_amplitude: float = 32.0  # For side-to-side movement
@export var movement_speed: float = 60.0      # Horizontal movement speed
@export var patrol_distance: float = 80.0     # How far to patrol side-to-side

@export var fire_pattern: int = FirePattern.STRAIGHT_SHOT
@export var fire_interval: float = 2.0
@export var bullet_speed: float = 180.0
@export var fire_delay: float = 0.0

# Formation system
@export var formation_offset: Vector2 = Vector2.ZERO
@export var formation_leader: Node2D = null
@export var escort_distance: float = 40.0

# Scoring and damage-source behavior
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
var _current_direction: int = 1  # For alternating shots: 1 or -1
var _initial_position: Vector2
var _dive_target: Vector2

# Formation system variables
var _formation_manager = null
var _formation_id: String = ""
var _formation_leader: Node2D = null
var _formation_offset: Vector2 = Vector2.ZERO
var _is_in_formation: bool = false
var _formation_state: int = 0  # 0: in formation, 1: breaking, 2: independent, 3: rejoining
var _break_timer: float = 0.0
var _original_speed: float = 0.0
var _original_movement: int = 0

func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	# Explicit collision layers/masks to ensure bullet hits are detected reliably
	# Layer 1: enemies; Layer 2: player bullets
	collision_layer = 1
	collision_mask = 1  # detect player hurtbox (default layer 1)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Store initial position for movement calculations
	_initial_position = global_position
	_base_position = global_position

	# Apply dynamic difficulty scaling from RankManager autoload if available
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("get_enemy_speed_multiplier"):
		var speed_mult: float = rm.get_enemy_speed_multiplier()
		var hp_mult: float = rm.get_enemy_hp_multiplier()
		speed *= speed_mult
		hp = int(ceil(float(hp) * hp_mult))

	# Normalize sprite size
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		if spr and spr.texture:
			var tex_size: Vector2i = spr.texture.get_size()
			if tex_size.y > 0:
				var s: float = sprite_target_height_px / float(tex_size.y)
				spr.scale = Vector2(s, s)

	# Set up dive target for dive attacks
	if movement == Movement.DIVE_ATTACK:
		var player = _find_player()
		if player:
			_dive_target = player.global_position
		else:
			_dive_target = global_position + Vector2(0, 200)

	# Start firing if pattern is set
	if fire_pattern != FirePattern.NONE:
		_fire_timer = fire_delay
		_fire_loop()

func _physics_process(delta: float) -> void:
	_time_alive += delta
	_movement_phase += delta

	# Update formation behavior first
	_update_formation_behavior(delta)

	# Handle different enemy types with specific behaviors
	match enemy_type:
		EnemyType.TURRET:
			# Turrets don't move, just stay in place
			pass
		EnemyType.SUBMARINE:
			# Submarines move upward when surfacing
			if movement == Movement.ASCEND or movement == Movement.SURFACE:
				position.y -= speed * delta
				if movement == Movement.SURFACE and position.y <= 100:
					position.y = 100  # Stop at surface level
		_:
			# All other types use movement patterns
			_apply_movement_pattern(delta)

	# Update fire timer
	if fire_pattern != FirePattern.NONE:
		_fire_timer -= delta

	position = position.round()

	# Fallback: proactively detect overlaps with player bullets to avoid missed area_entered events
	_ensure_player_bullet_hits()

	# Check if enemy has moved off screen
	var view := get_viewport().get_visible_rect()
	# Safety: despawn just before bottom to avoid lingering, invulnerable enemies at screen edge
	if enemy_type != EnemyType.TURRET and position.y >= view.size.y - 2:
		queue_free()
		return
	if position.y > view.size.y + 64 or position.x < -64 or position.x > view.size.x + 64:
		queue_free()

func _apply_movement_pattern(delta: float) -> void:
	match movement:
		Movement.STRAIGHT_DOWN:
			position.y += speed * delta

		Movement.SIDE_TO_SIDE:
			position.y += speed * 0.7 * delta
			var x_offset = sin(_movement_phase * 2.0) * movement_amplitude
			global_position.x = _initial_position.x + x_offset

		Movement.DIVE_ATTACK:
			# Calculate direction toward target and accelerate
			var direction = (_dive_target - global_position).normalized()
			var dive_speed = speed * (1.0 + _time_alive * 0.5)  # Accelerate over time
			position += direction * dive_speed * delta

		Movement.FORMATION:
			if formation_leader and is_instance_valid(formation_leader):
				# Follow the formation leader with offset
				global_position = formation_leader.global_position + formation_offset
				position.y += speed * 0.5 * delta  # Slow descent as formation
			else:
				# If no leader, fall back to straight movement
				position.y += speed * delta

		Movement.ESCORT:
			if formation_leader and is_instance_valid(formation_leader):
				# Circle around the leader
				var angle = _movement_phase * 2.0
				var offset = Vector2(cos(angle), sin(angle)) * escort_distance
				global_position = formation_leader.global_position + offset
				position.y += speed * 0.3 * delta  # Slow movement while escorting
			else:
				position.y += speed * delta

		Movement.PATROL:
			position.y += speed * 0.6 * delta
			var patrol_x = _initial_position.x + sin(_movement_phase * 1.5) * patrol_distance
			global_position.x = patrol_x

		Movement.ASCEND:
			position.y -= speed * delta

		Movement.SURFACE:
			# Already handled in the enemy type match
			pass

func take_damage(amount: int, source: String = "shot") -> void:
	# Respect invulnerability toggles per source
	if (source == "shot" and ignore_shot_damage) or (source == "bomb" and ignore_bomb_damage):
		return
	hp -= amount
	_last_damage_source = source
	if hp <= 0:
		var awarded: int = points
		if _last_damage_source == "bomb":
			if bomb_points_override >= 0:
				awarded = bomb_points_override
			else:
				awarded = int(round(float(points) * max(1.0, bomb_points_multiplier)))
		emit_signal("killed", awarded)
		var idm := get_node_or_null("/root/ItemDropManager")
		if idm and idm.has_method("on_enemy_killed"):
			idm.on_enemy_killed(global_position, self)
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
	if _firing_task_running:
		return
	_firing_task_running = true

	while is_instance_valid(self):
		# Wait for fire timer
		if _fire_timer > 0:
			await get_tree().create_timer(_fire_timer, false).timeout
			_fire_timer = 0.0

		if not is_instance_valid(self):
			break

		# Only fire if on screen (for performance)
		if not _is_on_screen():
			await get_tree().create_timer(0.5, false).timeout
			continue

		# Fire based on pattern
		match fire_pattern:
			FirePattern.NONE:
				pass
			FirePattern.STRAIGHT_SHOT:
				_fire_straight_shot()
			FirePattern.SPREAD_3:
				_fire_spread_3()
			FirePattern.SPREAD_5:
				_fire_spread_5()
			FirePattern.ALTERNATING:
				_fire_alternating()
			FirePattern.BOMB_DROP:
				_fire_bomb_drop()
			FirePattern.TRIPLE_SHOT:
				_fire_triple_shot()

		# Reset fire timer for next shot
		_fire_timer = fire_interval
		await get_tree().create_timer(fire_interval, false).timeout

	_firing_task_running = false

# Simple fire pattern implementations
func _fire_straight_shot() -> void:
	var direction = Vector2.DOWN  # Default straight down
	if enemy_type == EnemyType.TURRET:
		# Turrets aim at player
		var player = _find_player()
		if player:
			direction = (player.global_position - global_position).normalized()
	_spawn_bullet(global_position, direction, bullet_speed)

func _fire_spread_3() -> void:
	var angles = [-15.0, 0.0, 15.0]  # 3-way spread
	for angle in angles:
		var direction = Vector2.DOWN.rotated(deg_to_rad(angle))
		_spawn_bullet(global_position, direction, bullet_speed)

func _fire_spread_5() -> void:
	var angles = [-30.0, -15.0, 0.0, 15.0, 30.0]  # 5-way spread
	for angle in angles:
		var direction = Vector2.DOWN.rotated(deg_to_rad(angle))
		_spawn_bullet(global_position, direction, bullet_speed)

func _fire_alternating() -> void:
	var angle = 20.0 * _current_direction
	var direction = Vector2.DOWN.rotated(deg_to_rad(angle))
	_spawn_bullet(global_position, direction, bullet_speed)
	_current_direction *= -1  # Switch direction for next shot

func _fire_bomb_drop() -> void:
	# Drop bomb straight down, slower than bullets
	_spawn_bullet(global_position, Vector2.DOWN, bullet_speed * 0.6)

func _fire_triple_shot() -> void:
	# Fire three shots in quick succession
	var base_direction = Vector2.DOWN
	_spawn_bullet(global_position, base_direction, bullet_speed)
	await get_tree().create_timer(0.1, false).timeout
	if is_instance_valid(self):
		_spawn_bullet(global_position, base_direction, bullet_speed)
	await get_tree().create_timer(0.1, false).timeout
	if is_instance_valid(self):
		_spawn_bullet(global_position, base_direction, bullet_speed)

func _find_player() -> Node2D:
	var root := get_tree().current_scene
	if not root:
		return null
	var players := root.get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node2D:
		return players[0]
	return null

# Simplified bullet spawning
func _spawn_bullet(origin: Vector2, direction: Vector2, spd: float) -> void:
	var bullet: Area2D = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = origin
	bullet.set("direction", direction.normalized())
	bullet.set("speed", spd)
	var root := get_tree().current_scene
	if root:
		var container := root.get_node_or_null("GameViewport/Bullets")
		if container:
			container.call_deferred("add_child", bullet)
		else:
			root.call_deferred("add_child", bullet)
	else:
		bullet.queue_free()

func _is_on_screen() -> bool:
	var view := get_viewport().get_visible_rect()
	var within_x := global_position.x >= -8 and global_position.x <= view.size.x + 8
	var within_y := global_position.y >= -8 and global_position.y <= view.size.y + 8
	return within_x and within_y

func _ensure_player_bullet_hits() -> void:
	# Extra safety: if any player bullets are overlapping, consume them and apply damage
	if not monitoring:
		return
	var overlaps := get_overlapping_areas()
	if overlaps.is_empty():
		return
	for a in overlaps:
		if a and a.is_in_group("player_bullet"):
			# Apply the same damage as Bullet.gd to keep balance consistent
			take_damage(2, "shot")
			if a and a.has_method("queue_free"):
				a.queue_free()

# Formation system methods
func join_formation(formation_id: String) -> void:
	"""Join an existing formation"""
	_formation_manager = get_node_or_null("/root/FormationManager")
	if not _formation_manager:
		return

	_formation_id = formation_id
	_is_in_formation = true
	_formation_state = 0
	_original_speed = speed
	_original_movement = movement

	# Get formation leader
	var formation = _formation_manager.get_formation(formation_id)
	if formation and formation.leader:
		_formation_leader = formation.leader
		_formation_manager.add_member_to_formation(formation_id, self)

func leave_formation() -> void:
	"""Leave the current formation"""
	if _formation_manager and _formation_id:
		_formation_manager.remove_from_formation(_formation_id, self)

	_formation_id = ""
	_formation_leader = null
	_is_in_formation = false
	_formation_state = 2  # Independent

	# Restore original behavior
	speed = _original_speed
	movement = _original_movement

func break_formation() -> void:
	"""Temporarily break from formation to engage"""
	if not _is_in_formation or _formation_state != 0:
		return

	_formation_state = 1  # Breaking
	_break_timer = 0.0

	# Temporarily increase speed and change behavior
	speed = _original_speed * 1.3

func rally_to_leader(_leader_position: Vector2) -> void:
	"""Rally back to formation leader"""
	if not _is_in_formation:
		return

	_formation_state = 3  # Rejoining
	_break_timer = 0.0

func set_formation_offset(offset: Vector2) -> void:
	"""Set the offset position within the formation"""
	_formation_offset = offset

func get_formation_state() -> String:
	"""Get current formation state as string"""
	match _formation_state:
		0: return "formation"
		1: return "breaking"
		2: return "independent"
		3: return "rejoining"
	return "unknown"

func _update_formation_behavior(delta: float) -> void:
	"""Update formation-specific behavior"""
	if not _is_in_formation:
		return

	match _formation_state:
		0:  # In formation
			_maintain_formation_position(delta)
		1:  # Breaking
			_execute_break(delta)
		3:  # Rejoining
			_execute_rejoin(delta)

func _maintain_formation_position(delta: float) -> void:
	"""Stay in formation position"""
	if not _formation_leader or not is_instance_valid(_formation_leader):
		leave_formation()
		return

	# Calculate target position based on leader
	var target_pos = _formation_leader.global_position + _formation_offset
	var current_pos = global_position
	var direction = (target_pos - current_pos).normalized()
	var distance = current_pos.distance_to(target_pos)

	# Move toward formation position
	if distance > 5.0:
		var formation_speed = _original_speed * 0.9  # Slightly slower in formation
		global_position += direction * formation_speed * delta

func _execute_break(delta: float) -> void:
	"""Execute formation break"""
	_break_timer += delta

	# After breaking, become independent for a while
	if _break_timer > 1.0:  # 1 second break time
		_formation_state = 2  # Independent
		_break_timer = 0.0

		# Random behavior while breaking
		if randf() < 0.3:  # 30% chance to dive
			_start_dive_attack()

func _execute_rejoin(delta: float) -> void:
	"""Execute formation rejoin"""
	_break_timer += delta

	# After rejoining period, return to formation
	if _break_timer > 2.0:  # 2 second rejoin time
		_formation_state = 0  # Back in formation
		_break_timer = 0.0
		speed = _original_speed

func _start_dive_attack() -> void:
	"""Start a dive attack toward player"""
	var player = _find_player()
	if player:
		_dive_target = player.global_position
		_original_movement = movement
		movement = Movement.DIVE_ATTACK
		_formation_state = 2  # Independent during dive
