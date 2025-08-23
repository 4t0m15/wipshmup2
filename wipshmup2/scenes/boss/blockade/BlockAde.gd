extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

func _init() -> void:
	phases_total = 3
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
		3:
			_start_phase3()

func _start_phase1() -> void:
	# Crane-constructed claw sub-boss simulated as wide sprays
	var self_node: Node2D = self
	var shoulder: Node2D = $Shoulder
	call_deferred("_phase1_task", self_node, shoulder, current_phase)

func _phase1_task(self_node: Node2D, shoulder: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(shoulder):
			BP.fire_fan(self_node, shoulder.global_position, 11, 80.0, 90.0, 320.0)
		await get_tree().create_timer(0.45, false).timeout

func _start_phase2() -> void:
	# Stormtrooper-like mech: shotgun and backpack mines
	var self_node: Node2D = self
	var gun: Node2D = $Gun
	var pack: Node2D = $Backpack
	call_deferred("_phase2_task", self_node, gun, pack, current_phase)

func _phase2_task(self_node: Node2D, gun: Node2D, pack: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(gun):
			BP.fire_fan(self_node, gun.global_position, 13, 100.0, 90.0, 330.0)
		if is_instance_valid(pack):
			BP.fire_ring(self_node, pack.global_position, 8, 240.0, 0.0)
		await get_tree().create_timer(0.5, false).timeout

func _start_phase3() -> void:
	# Final: dual-pronged lasers across screen
	var self_node: Node2D = self
	var emitter: Node2D = $Emitter
	call_deferred("_phase3_task", self_node, emitter, current_phase)

func _phase3_task(self_node: Node2D, emitter: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(emitter):
			await BP.fire_dual_lasers(self_node, emitter, 90.0, 30.0, 0.45, 0.02, 1150.0)
		await get_tree().create_timer(0.4, false).timeout


