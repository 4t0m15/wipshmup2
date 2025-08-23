extends BossBase

const BP := preload("res://scripts/BulletPatterns.gd")

@export var move_y: float = 54.0
@export var move_speed: float = 65.0
func _init() -> void:
	phases_total = 3

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

func _physics_process(delta: float) -> void:
	var view := get_viewport_rect()
	var target_y := move_y
	global_position.y = lerp(global_position.y, target_y, 0.08)
	var dir := 1.0 if int(Time.get_ticks_msec() / 2000.0) % 2 == 0 else -1.0
	global_position.x += move_speed * dir * delta
	if global_position.x < 28.0:
		global_position.x = 28.0
	elif global_position.x > view.size.x - 28.0:
		global_position.x = view.size.x - 28.0

func _start_phase1() -> void:
	# Aircraft carrier with multi-barrel turrets
	var self_node: Node2D = self
	var left: Node2D = $LeftTurret
	var right: Node2D = $RightTurret
	call_deferred("_phase1_task", self_node, left, right, current_phase)

func _phase1_task(self_node: Node2D, left: Node2D, right: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		if is_instance_valid(left):
			BP.fire_fan(self_node, left.global_position, 7, 50.0, 90.0, 320.0)
		if is_instance_valid(right):
			BP.fire_fan(self_node, right.global_position, 7, 50.0, 90.0, 320.0)
		await get_tree().create_timer(0.4, false).timeout

func _start_phase2() -> void:
	# Bi-armed robot: one fast small shots arm, one slow heavy shells arm, arms rotate
	var self_node: Node2D = self
	var arm_a: Node2D = $ArmA
	var arm_b: Node2D = $ArmB
	call_deferred("_phase2_task", self_node, arm_a, arm_b, current_phase)

func _phase2_task(self_node: Node2D, arm_a: Node2D, arm_b: Node2D, phase_snapshot: int) -> void:
	var swap := false
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		swap = !swap
		var fast_node := arm_a if swap else arm_b
		var slow_node := arm_b if swap else arm_a
		if is_instance_valid(fast_node):
			BP.fire_fan(self_node, fast_node.global_position, 9, 60.0, 90.0, 360.0)
		if is_instance_valid(slow_node):
			BP.fire_fan(self_node, slow_node.global_position, 3, 20.0, 90.0, 240.0)
		await get_tree().create_timer(0.45, false).timeout

func _start_phase3() -> void:
	# Final: mobile circular turret swinging across screen
	var self_node: Node2D = self
	call_deferred("_phase3_task", self_node, current_phase)

func _phase3_task(self_node: Node2D, phase_snapshot: int) -> void:
	while _phase_task_running and is_instance_valid(self_node) and current_phase == phase_snapshot:
		await BP.fire_rotating_rings(self_node, self_node, 2, 18, 260.0, 10.0, 0.2)
		await get_tree().create_timer(0.35, false).timeout
