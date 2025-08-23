extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 46.0

var _phase_task_running: bool = false

func on_enter_phase(_phase: int) -> void:
	_phase_task_running = false
	await get_tree().process_frame
	_phase_task_running = true
	_start()

func _start() -> void:
	var self_node: Node2D = self
	var emitter: Node2D = $Emitter
	call_deferred("_task", self_node, emitter)

func _task(self_node: Node2D, emitter: Node2D) -> void:
	while _phase_task_running and is_instance_valid(self_node):
		# Instant-death straight lasers simulated by fixed beams, then bullet barrages
		if is_instance_valid(emitter):
			await BP.fire_fixed_beam(self_node, emitter, 90.0, 0.35, 0.02, 1250.0)
		await get_tree().create_timer(0.2, false).timeout
		# Barrages: mix of rings and fans
		BP.fire_ring(self_node, self_node.global_position, 12, 260.0, 0.0)
		BP.fire_fan(self_node, self_node.global_position, 11, 90.0, 90.0, 300.0)
		await get_tree().create_timer(0.35, false).timeout


