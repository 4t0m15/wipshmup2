extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 52.0

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
	# Fortress wall: heavy center cannon forces constant motion
	var self_node: Node2D = self
	var core: Node2D = $Core
	call_deferred("_phase1_task", self_node, core, current_phase)

func _phase1_task(self_node: Node2D, core: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(core):
			await BP.fire_fixed_beam(self_node, core, 90.0, 0.4, 0.02, 1150.0)
			await get_tree().create_timer(0.4, false).timeout
			await BP.fire_dual_lasers(self_node, core, 90.0, 30.0, 0.3, 0.03, 1100.0)
		await get_tree().create_timer(0.4, false).timeout

func _start_phase2() -> void:
	# Scorpion tank: pincers fire cross-diagonals to corral player
	var self_node: Node2D = self
	var left: Node2D = $PincerLeft
	var right: Node2D = $PincerRight
	call_deferred("_phase2_task", self_node, left, right, current_phase)

func _phase2_task(self_node: Node2D, left: Node2D, right: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(left):
			BP.fire_fan(self_node, left.global_position, 5, 0.0, 225.0, 300.0)
		if is_instance_valid(right):
			BP.fire_fan(self_node, right.global_position, 5, 0.0, -45.0, 300.0)
		await BP.fire_cross_hatch(self_node, self_node, 1, 6, 55.0, 280.0, 0.0)
		await get_tree().create_timer(0.5, false).timeout


