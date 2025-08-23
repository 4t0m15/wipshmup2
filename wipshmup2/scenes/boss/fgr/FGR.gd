extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

func _init() -> void:
	phases_total = 4
@export var move_y: float = 50.0

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
		4:
			_start_phase4()

func _start_phase1() -> void:
	# Purple brain/octopus: broad cross-hatched waves
	var self_node: Node2D = self
	call_deferred("_phase1_task", self_node, current_phase)

func _phase1_task(self_node: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		await BP.fire_cross_hatch(self_node, self_node, 2, 9, 80.0, 280.0, 0.2)
		await get_tree().create_timer(0.45, false).timeout

func _start_phase2() -> void:
	# Mandible creature: biting motion with outward arcs
	var self_node: Node2D = self
	var mouth: Node2D = $Mouth
	call_deferred("_phase2_task", self_node, mouth, current_phase)

func _phase2_task(self_node: Node2D, mouth: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(mouth):
			await BP.fire_sweeping_spread(self_node, mouth, 60.0, -60.0, 0.7, 9, 6, 300.0)
			BP.fire_ring(self_node, mouth.global_position, 12, 260.0, 0.0)
		await get_tree().create_timer(0.5, false).timeout

func _start_phase3() -> void:
	# Smaller form with dense rapid patterns
	var self_node: Node2D = self
	call_deferred("_phase3_task", self_node, current_phase)

func _phase3_task(self_node: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		await BP.fire_rotating_rings(self_node, self_node, 2, 22, 280.0, 14.0, 0.15)
		await get_tree().create_timer(0.3, false).timeout

func _start_phase4() -> void:
	# Final smaller form with very dense, rapid patterns
	var self_node: Node2D = self
	call_deferred("_phase4_task", self_node, current_phase)

func _phase4_task(self_node: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		await BP.fire_rotating_rings(self_node, self_node, 3, 26, 300.0, 18.0, 0.12)
		await get_tree().create_timer(0.25, false).timeout


