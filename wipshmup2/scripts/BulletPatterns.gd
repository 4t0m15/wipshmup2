class_name BulletPatterns
extends Node

const ENEMY_BULLET_SCENE: PackedScene = preload("res://scenes/bullet/EnemyBullet.tscn")

const BASE_DENSITY_MULT: float = 0.3
const BASE_SPEED_MULT: float = 0.6
const BASE_CADENCE_MULT: float = 0.75

static func _get_density_multiplier() -> float:
	var rank_mult: float = 1.0
	if typeof(RankManager) != TYPE_NIL and RankManager.has_method("get_pattern_density_multiplier"):
		rank_mult = float(RankManager.get_pattern_density_multiplier())
	return BASE_DENSITY_MULT * rank_mult

static func _get_cadence_multiplier() -> float:
	var c: float = 1.0
	if typeof(RankManager) != TYPE_NIL and RankManager.has_method("get_pattern_cadence_multiplier"):
		c = max(0.001, float(RankManager.get_pattern_cadence_multiplier()))
	return c * BASE_CADENCE_MULT

static func _spawn_bullet(node: Node, position: Vector2, direction: Vector2, speed: float) -> void:
	# Play enemy shot sound
	var audio_manager = Engine.get_singleton("AudioManager")
	if not audio_manager:
		audio_manager = Engine.get_main_loop().get_root().get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_enemy_shot"):
		audio_manager.play_enemy_shot()
	
	var bullet: Area2D = ENEMY_BULLET_SCENE.instantiate()
	bullet.global_position = position
	bullet.set("direction", direction.normalized())
	bullet.set("speed", speed * BASE_SPEED_MULT)
	
	var scene_tree: SceneTree = node.get_tree() if is_instance_valid(node) else Engine.get_main_loop() as SceneTree
	if scene_tree and scene_tree.current_scene:
		var container := scene_tree.current_scene.get_node_or_null("GameViewport/Bullets")
		var target = container if container else scene_tree.current_scene
		target.call_deferred("add_child", bullet)
	else:
		bullet.queue_free()

static func _await_seconds(node: Node, seconds: float) -> void:
	if is_instance_valid(node):
		await node.get_tree().create_timer(seconds, false).timeout
	else:
		var ml = Engine.get_main_loop()
		if ml is SceneTree:
			await (ml as SceneTree).create_timer(seconds, false).timeout

static func fire_ring(node: Node, origin: Vector2, bullet_count: int, speed: float = 300.0, start_angle_rad: float = 0.0) -> void:
	if bullet_count <= 0: return
	var count: int = max(1, int(round(float(bullet_count) * _get_density_multiplier())))
	var step: float = PI * 2.0 / float(count)
	for i in range(count):
		var angle := start_angle_rad + step * float(i)
		_spawn_bullet(node, origin, Vector2.RIGHT.rotated(angle), speed)

static func fire_fan(node: Node, origin: Vector2, bullet_count: int, spread_degrees: float, base_angle_degrees: float, speed: float = 320.0) -> void:
	if bullet_count <= 0: return
	var count: int = max(1, int(round(float(bullet_count) * _get_density_multiplier())))
	var spread_rad: float = deg_to_rad(spread_degrees)
	var base_rad: float = deg_to_rad(base_angle_degrees)
	var start: float = base_rad - spread_rad * 0.5
	var step: float = 0.0 if count == 1 else spread_rad / float(count - 1)
	for i in range(count):
		var angle := start + step * float(i)
		_spawn_bullet(node, origin, Vector2.RIGHT.rotated(angle), speed)

static func fire_sweeping_spread(node: Node, origin_node: Node2D, start_degrees: float, end_degrees: float, duration_s: float, steps: int, bullets_per_step: int, speed: float = 300.0) -> void:
	if steps <= 0 or bullets_per_step <= 0 or duration_s <= 0.0: return
	var start_rad: float = deg_to_rad(start_degrees)
	var end_rad: float = deg_to_rad(end_degrees)
	var step_time: float = duration_s / float(steps) / _get_cadence_multiplier()
	var bps: int = max(1, int(round(float(bullets_per_step) * _get_density_multiplier())))
	
	for i in range(steps):
		if not is_instance_valid(origin_node): return
		var t: float = float(i) / float(max(steps - 1, 1))
		var angle: float = lerp(start_rad, end_rad, t)
		fire_fan(node, origin_node.global_position, bps, 20.0, rad_to_deg(angle), speed)
		await _await_seconds(node, step_time)

static func fire_aimed_beam(node: Node, origin_node: Node2D, target_node: Node2D, duration_s: float, interval_s: float = 0.05, speed: float = 1000.0) -> void:
	if duration_s <= 0.0 or interval_s <= 0.0: return
	var elapsed: float = 0.0
	var iv: float = interval_s / _get_cadence_multiplier()
	
	while elapsed < duration_s:
		if not is_instance_valid(origin_node) or not is_instance_valid(target_node): return
		var to_target: Vector2 = (target_node.global_position - origin_node.global_position).normalized()
		_spawn_bullet(node, origin_node.global_position, to_target, speed)
		await _await_seconds(node, iv)
		elapsed += iv

static func fire_cross_hatch(node: Node, origin_node: Node2D, waves: int, bullets_per_fan: int = 7, spread_degrees: float = 60.0, speed: float = 300.0, interval_s: float = 0.25) -> void:
	if waves <= 0: return
	var bpf: int = max(1, int(round(float(bullets_per_fan) * _get_density_multiplier())))
	var iv: float = interval_s / _get_cadence_multiplier()
	
	for i in range(waves):
		if not is_instance_valid(origin_node): return
		var origin: Vector2 = origin_node.global_position
		fire_fan(node, origin, bpf, spread_degrees, -45.0, speed)
		fire_fan(node, origin, bpf, spread_degrees, 135.0, speed)
		await _await_seconds(node, iv)
		if not is_instance_valid(origin_node): return
		origin = origin_node.global_position
		fire_fan(node, origin, bpf, spread_degrees, 45.0, speed)
		fire_fan(node, origin, bpf, spread_degrees, -135.0, speed)
		await _await_seconds(node, iv)

static func fire_rotating_rings(node: Node, origin_node: Node2D, bursts: int, bullets_per_ring: int = 16, speed: float = 260.0, rotation_step_degrees: float = 12.0, interval_s: float = 0.35) -> void:
	if bursts <= 0: return
	var angle: float = 0.0
	var iv: float = interval_s / _get_cadence_multiplier()
	
	for i in range(bursts):
		if not is_instance_valid(origin_node): return
		var count: int = max(1, int(round(float(bullets_per_ring) * _get_density_multiplier())))
		fire_ring(node, origin_node.global_position, count, speed, deg_to_rad(angle))
		angle += rotation_step_degrees
		await _await_seconds(node, iv)

static func fire_fixed_beam(node: Node, origin_node: Node2D, angle_degrees: float, duration_s: float, interval_s: float = 0.02, speed: float = 1100.0) -> void:
	if duration_s <= 0.0 or interval_s <= 0.0: return
	var elapsed: float = 0.0
	var dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(angle_degrees)).normalized()
	var iv: float = interval_s / _get_cadence_multiplier()
	
	while elapsed < duration_s:
		if not is_instance_valid(origin_node): return
		_spawn_bullet(node, origin_node.global_position, dir, speed)
		await _await_seconds(node, iv)
		elapsed += iv

static func fire_dual_lasers(node: Node, origin_node: Node2D, base_angle_degrees: float, separation_degrees: float, duration_s: float, interval_s: float = 0.025, speed: float = 1100.0) -> void:
	if duration_s <= 0.0 or interval_s <= 0.0: return
	var elapsed: float = 0.0
	var ang_a: float = base_angle_degrees - separation_degrees * 0.5
	var ang_b: float = base_angle_degrees + separation_degrees * 0.5
	var dir_a: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(ang_a)).normalized()
	var dir_b: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(ang_b)).normalized()
	var iv: float = interval_s / _get_cadence_multiplier()
	
	while elapsed < duration_s:
		if not is_instance_valid(origin_node): return
		var origin: Vector2 = origin_node.global_position
		_spawn_bullet(node, origin, dir_a, speed)
		_spawn_bullet(node, origin, dir_b, speed)
		await _await_seconds(node, iv)
		elapsed += iv
