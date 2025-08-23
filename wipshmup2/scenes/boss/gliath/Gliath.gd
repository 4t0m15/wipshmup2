extends BossBase

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 48.0
@export var move_speed: float = 80.0

var _phase_task_running: bool = false

func on_enter_phase(phase: int) -> void:
	_phase_task_running = false
	await get_tree().process_frame
	_phase_task_running = true
	match phase:
		1:
			_start_phase1()
		2:
			_start_phase2()

func _physics_process(delta: float) -> void:
	# Horizontal strafe movement across the screen
	var view := get_viewport_rect()
	var target_y := move_y
	global_position.y = lerp(global_position.y, target_y, 0.08)
	var dir := 1.0 if int(Time.get_ticks_msec() / 2000.0) % 2 == 0 else -1.0
	global_position.x += move_speed * dir * delta
	if global_position.x < 32.0:
		global_position.x = 32.0
	elif global_position.x > view.size.x - 32.0:
		global_position.x = view.size.x - 32.0

func _start_phase1() -> void:
	# Phase 1: Sweeping curved streams (arcing bullet swarms)
	spawn_arc_swarm_loop()

func _start_phase2() -> void:
	# Phase 2: Continue arcing swarms + shoulder drones
	spawn_arc_swarm_loop()
	spawn_drones_loop()

func spawn_arc_swarm_loop() -> void:
	var self_node: Node2D = self
	call_deferred("_arc_swarm_task", self_node, current_phase)

func _arc_swarm_task(self_node: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		var left_angle: float = -60.0
		var right_angle: float = 60.0
		await BP.fire_sweeping_spread(self_node, self_node, left_angle, right_angle, 1.4, 10, 6, 260.0)
		await get_tree().create_timer(0.4, false).timeout
		await BP.fire_sweeping_spread(self_node, self_node, right_angle, left_angle, 1.4, 10, 6, 260.0)
		await get_tree().create_timer(0.6, false).timeout

func spawn_drones_loop() -> void:
	var self_node: Node2D = self
	var left_shoulder: Node2D = $LeftShoulder
	var right_shoulder: Node2D = $RightShoulder
	call_deferred("_drones_task", self_node, left_shoulder, right_shoulder)

func _drones_task(self_node: Node2D, left_shoulder: Node2D, right_shoulder: Node2D) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == 2:
		if is_instance_valid(left_shoulder):
			var d1: Area2D = ENEMY_SCENE.instantiate()
			d1.global_position = left_shoulder.global_position
			d1.set("speed", 180.0)
			get_tree().current_scene.add_child(d1)
		if is_instance_valid(right_shoulder):
			var d2: Area2D = ENEMY_SCENE.instantiate()
			d2.global_position = right_shoulder.global_position
			d2.set("speed", 180.0)
			get_tree().current_scene.add_child(d2)
		await get_tree().create_timer(2.0, false).timeout
