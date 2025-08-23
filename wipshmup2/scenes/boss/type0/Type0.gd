extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 56.0
@export var move_speed_phase1: float = 70.0
@export var move_speed_phase2: float = 120.0

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
	var view := get_viewport_rect()
	var target_y := move_y
	global_position.y = lerp(global_position.y, target_y, 0.08)
	var speed := move_speed_phase1 if current_phase == 1 else move_speed_phase2
	var dir := 1.0 if int(Time.get_ticks_msec() / 1600.0) % 2 == 0 else -1.0
	global_position.x += speed * dir * delta
	if global_position.x < 32.0:
		global_position.x = 32.0
	elif global_position.x > view.size.x - 32.0:
		global_position.x = view.size.x - 32.0

func _start_phase1() -> void:
	# Phase 1: Flying boat with tail and hull weak points - arcing dual-barrels
	var self_node: Node2D = self
	var tail: Node2D = $Tail
	var hull: Node2D = $Hull
	call_deferred("_phase1_task", self_node, tail, hull, current_phase)

func _phase1_task(self_node: Node2D, tail: Node2D, hull: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		# Alternate sweeping spreads from tail and hull to simulate dual barrels
		if is_instance_valid(tail):
			await BP.fire_sweeping_spread(self_node, tail, -50.0, 20.0, 0.9, 8, 5, 280.0)
		if is_instance_valid(hull):
			await BP.fire_sweeping_spread(self_node, hull, 50.0, -20.0, 0.9, 8, 5, 280.0)
		await get_tree().create_timer(0.4, false).timeout
		# Interleave rotating rings for area denial
		if is_instance_valid(self_node):
			await BP.fire_rotating_rings(self_node, self_node, 1, 14, 240.0, 10.0, 0.0)
		await get_tree().create_timer(0.5, false).timeout

func _start_phase2() -> void:
	# Phase 2: Cyclopean aerial robot (one-eyed turret) with high-volume strafing
	var self_node: Node2D = self
	var eye: Node2D = $Eye
	call_deferred("_phase2_task", self_node, eye, current_phase)

func _phase2_task(self_node: Node2D, eye: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(eye):
			# Rapid strafing fire: alternating aimed beams and fans
			var player := self_node.get_tree().current_scene.get_node_or_null("Player")
			if player and player is Node2D:
				await BP.fire_aimed_beam(self_node, eye, player, 0.25, 0.03, 950.0)
			BP.fire_fan(self_node, eye.global_position, 11, 70.0, 90.0, 320.0)
			BP.fire_fan(self_node, eye.global_position, 11, 70.0, 270.0, 320.0)
			await get_tree().create_timer(0.25, false).timeout
			# Brief dual lasers across the screen to force repositioning
			await BP.fire_dual_lasers(self_node, eye, 90.0, 24.0, 0.25, 0.03, 1050.0)
		await get_tree().create_timer(0.4, false).timeout
