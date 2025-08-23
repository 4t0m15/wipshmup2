extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 54.0

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

func _start_phase1() -> void:
	# Submarine dagger form: arcing dual barrels
	var self_node: Node2D = self
	var left: Node2D = $BarrelLeft
	var right: Node2D = $BarrelRight
	call_deferred("_phase1_task", self_node, left, right, current_phase)

func _phase1_task(self_node: Node2D, left: Node2D, right: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(left):
			await BP.fire_sweeping_spread(self_node, left, -40.0, 0.0, 0.8, 8, 4, 280.0)
		if is_instance_valid(right):
			await BP.fire_sweeping_spread(self_node, right, 40.0, 0.0, 0.8, 8, 4, 280.0)
		await get_tree().create_timer(0.4, false).timeout

func _start_phase2() -> void:
	# Crab robot: two claws coordinate crossfire
	var self_node: Node2D = self
	var red: Node2D = $RedClaw
	var blue: Node2D = $BlueClaw
	call_deferred("_phase2_task", self_node, red, blue, current_phase)

func _phase2_task(self_node: Node2D, red: Node2D, blue: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(red):
			BP.fire_fan(self_node, red.global_position, 7, 50.0, 240.0, 300.0)
		if is_instance_valid(blue):
			BP.fire_fan(self_node, blue.global_position, 11, 90.0, 300.0, 280.0)
		await get_tree().create_timer(0.45, false).timeout


