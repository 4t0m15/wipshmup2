extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 52.0
@export var move_speed: float = 60.0

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
	# Gentle strafe in both phases
	var dir := 1.0 if int(Time.get_ticks_msec() / 2200.0) % 2 == 0 else -1.0
	global_position.x += move_speed * dir * delta
	if global_position.x < 28.0:
		global_position.x = 28.0
	elif global_position.x > view.size.x - 28.0:
		global_position.x = view.size.x - 28.0

func _start_phase1() -> void:
	# Heavy turret arrays and helicopter pads: rotating rings and crosshatch
	var self_node: Node2D = self
	var turret_a: Node2D = $TurretA
	var turret_b: Node2D = $TurretB
	call_deferred("_phase1_task", self_node, turret_a, turret_b, current_phase)

func _phase1_task(
		self_node: Node2D,
		turret_a: Node2D,
		turret_b: Node2D,
		phase_snapshot: int
	) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(turret_a):
			await BP.fire_rotating_rings(self_node, turret_a, 1, 16, 250.0, 15.0, 0.0)
		if is_instance_valid(turret_b):
			await BP.fire_rotating_rings(self_node, turret_b, 1, 16, 250.0, -15.0, 0.0)
		BP.fire_cross_hatch(self_node, self_node, 2, 7, 65.0, 280.0, 0.22)
		await get_tree().create_timer(0.6, false).timeout

func _start_phase2() -> void:
	# Spider-like mech: side strafes and circular rings with rush charges
	var self_node: Node2D = self
	call_deferred("_phase2_task", self_node, current_phase)

func _phase2_task(self_node: Node2D, phase_snapshot: int) -> void:
	var rush_toggle := false
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		BP.fire_ring(self_node, self_node.global_position, 20, 260.0, 0.0)
		await get_tree().create_timer(0.3, false).timeout
		# Occasional rush forward then back
		rush_toggle = !rush_toggle
		if rush_toggle:
			var original_y := self_node.global_position.y
			create_tween().tween_property(self_node, "global_position:y", original_y + 24.0, 0.25)
			await get_tree().create_timer(0.25, false).timeout
			create_tween().tween_property(self_node, "global_position:y", original_y, 0.25)
			await get_tree().create_timer(0.25, false).timeout
		await get_tree().create_timer(0.35, false).timeout
