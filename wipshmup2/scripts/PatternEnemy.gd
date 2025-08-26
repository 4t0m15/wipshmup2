class_name PatternEnemy
extends Area2D

signal killed(points: int)
signal hit_player

# Movement patterns
enum Movement {
	STRAIGHT,
	SINE,
	ZIGZAG,
	DIAGONAL_LEFT,
	DIAGONAL_RIGHT,
	DIVE,
	PAUSE_SHOOT,
	SIDE_SWEEPER,
	BACK_AND_FORTH,
	CIRCLE
}

# Firing patterns
enum Fire {
	NONE,
	AIMED_SHOT_PERIODIC,
	RING_BURST,
	FAN_SPREAD,
	SWEEPING_SPREAD,
	CROSS_HATCH,
	ROTATING_RINGS,
	FIXED_BEAM_BURSTS,
	DUAL_LASERS,
	SHOTGUN
}

# Constants
const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/bullet/EnemyBullet.tscn")

# Base stats
@export var speed: float = 120.0
@export var hp: int = 1
@export var points: int = 100
@export var sprite_target_height_px: float = 18.0

@export var movement: int = Movement.STRAIGHT
@export var amplitude_px: float = 48.0
@export var frequency_hz: float = 1.0
@export var horizontal_speed: float = 90.0
@export var zigzag_period_s: float = 0.6
@export var pause_time_s: float = 0.6

@export var fire: int = Fire.NONE
@export var fire_interval_s: float = 1.6
@export var bullets_per_burst: int = 6
@export var bullet_speed: float = 250.0
@export var initial_fire_delay_s: float = 0.0
@export var fire_jitter_s: float = 0.2

var _time_alive: float = 0.0
var _zigzag_timer: float = 0.0
var _zigzag_dir: float = 1.0
var _base_x: float = 0.0
var _firing_task_running: bool = false

func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
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
	_base_x = global_position.x
	if fire != Fire.NONE:
		_fire_loop()

func _physics_process(delta: float) -> void:
	_time_alive += delta
	position = position.round()
	match movement:
		Movement.STRAIGHT:
			position.y += speed * delta
		Movement.SINE:
			position.y += speed * delta
			var x_offset := sin(_time_alive * TAU * frequency_hz) * amplitude_px
			global_position.x = _base_x + x_offset
		Movement.ZIGZAG:
			position.y += speed * delta
			_zigzag_timer += delta
			if _zigzag_timer >= zigzag_period_s:
				_zigzag_timer = 0.0
				_zigzag_dir *= -1.0
			global_position.x += horizontal_speed * _zigzag_dir * delta
		Movement.DIAGONAL_LEFT:
			position += Vector2(-horizontal_speed, speed) * delta
		Movement.DIAGONAL_RIGHT:
			position += Vector2(horizontal_speed, speed) * delta
		Movement.DIVE:
			# Speed up over time
			var dive_mul: float = 1.0 + min(2.5, _time_alive)
			position.y += speed * dive_mul * delta
		Movement.PAUSE_SHOOT:
			# Alternate pause and nudge down
			if fmod(_time_alive, pause_time_s * 2.0) < pause_time_s:
				# hold position
				pass
			else:
				position.y += speed * delta
		Movement.SIDE_SWEEPER:
			position.y += speed * 0.7 * delta
			global_position.x += horizontal_speed * sin(_time_alive * TAU * frequency_hz) * delta
		Movement.BACK_AND_FORTH:
			position.y += speed * 0.85 * delta
			var phase := int(floor(_time_alive / zigzag_period_s))
			var dir := 1.0 if (phase % 2) == 0 else -1.0
			global_position.x += horizontal_speed * dir * delta
		Movement.CIRCLE:
			var r := amplitude_px
			var ang := _time_alive * TAU * frequency_hz
			global_position = Vector2(_base_x + cos(ang) * r, global_position.y + speed * 0.5 * delta)

	var view := get_viewport().get_visible_rect()
	if position.y > view.size.y + 64 or position.x < -64 or position.x > view.size.x + 64:
		queue_free()

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		emit_signal("killed", points)
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
		var cadence: float = 1.0
		var bullet_speed_mult: float = 1.0
		var rm := get_node_or_null("/root/RankManager")
		if rm:
			if rm.has_method("get_pattern_cadence_multiplier"):
				cadence = max(0.001, float(rm.get_pattern_cadence_multiplier()))
			if rm.has_method("get_bullet_speed_multiplier"):
				bullet_speed_mult = float(rm.get_bullet_speed_multiplier())
		var interval := fire_interval_s / cadence
		var jitter: float = randf_range(-fire_jitter_s * 0.5, fire_jitter_s * 0.5)
		var wait_time: float = max(0.02, interval + jitter)
		if initial_fire_delay_s > 0.0:
			wait_time = max(wait_time, initial_fire_delay_s)
			initial_fire_delay_s = 0.0
		await get_tree().create_timer(wait_time, false).timeout
		if not is_instance_valid(self):
			break
		match fire:
			Fire.NONE:
				pass
			Fire.AIMED_SHOT_PERIODIC:
				var p: Node2D = _find_player()
				if p:
					_spawn_single_aimed(p, bullet_speed * bullet_speed_mult)
			Fire.RING_BURST:
				BulletPatterns.fire_ring(
					self,
					global_position,
					max(1, bullets_per_burst),
					bullet_speed * bullet_speed_mult
				)
			Fire.FAN_SPREAD:
				BulletPatterns.fire_fan(
					self,
					global_position,
					max(2, bullets_per_burst),
					40.0,
					90.0,
					bullet_speed * bullet_speed_mult
				)
			Fire.SWEEPING_SPREAD:
				await BulletPatterns.fire_sweeping_spread(
					self,
					self,
					60.0,
					120.0,
					0.5,
					5,
					max(2, int(ceil(bullets_per_burst * 0.5))),
					bullet_speed * bullet_speed_mult
				)
			Fire.CROSS_HATCH:
				await BulletPatterns.fire_cross_hatch(
					self,
					self,
					2,
					max(3, int(ceil(bullets_per_burst * 0.6))),
					60.0,
					bullet_speed * bullet_speed_mult,
					0.18
				)
			Fire.ROTATING_RINGS:
				await BulletPatterns.fire_rotating_rings(
					self,
					self,
					2,
					max(6, bullets_per_burst),
					bullet_speed * 0.8 * bullet_speed_mult,
					10.0,
					0.25
				)
			Fire.FIXED_BEAM_BURSTS:
				await BulletPatterns.fire_fixed_beam(
					self,
					self,
					90.0,
					0.15,
					0.02,
					900.0 * bullet_speed_mult
				)
			Fire.DUAL_LASERS:
				await BulletPatterns.fire_dual_lasers(
					self,
					self,
					90.0,
					18.0,
					0.18,
					0.025,
					900.0 * bullet_speed_mult
				)
			Fire.SHOTGUN:
				var p2: Node2D = _find_player()
				if p2:
					# 5-way cone toward the player
					var dir := (p2.global_position - global_position).angle()
					var spread := deg_to_rad(35.0)
					var count := 5
					for i in count:
						var t := float(i) / float(max(count - 1, 1))
						var ang := dir - spread * 0.5 + spread * t
						var v := Vector2.RIGHT.rotated(ang)
						_spawn_bullet(global_position, v, bullet_speed * bullet_speed_mult)
	_firing_task_running = false

func _find_player() -> Node2D:
	var root := get_tree().current_scene
	if not root:
		return null
	var players := root.get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node2D:
		return players[0]
	return null

func _spawn_single_aimed(target: Node2D, spd: float) -> void:
	if not is_instance_valid(target):
		return
	var dir := (target.global_position - global_position).normalized()
	_spawn_bullet(global_position, dir, spd)

func _spawn_bullet(origin: Vector2, direction: Vector2, spd: float) -> void:
	var bullet: Area2D = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = origin
	bullet.set("direction", direction.normalized())
	bullet.set("speed", spd)
	var root := get_tree().current_scene
	if root:
		var container := root.get_node_or_null("GameViewport/Bullets")
		if container:
			container.add_child(bullet)
		else:
			root.add_child(bullet)
	else:
		bullet.queue_free()


