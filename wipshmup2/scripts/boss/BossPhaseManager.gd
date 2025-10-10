extends Node
class_name BossPhaseManager

# BossPhaseManager - Manages boss phases and transitions
# Handles phase changes, behavior updates, and visual effects

var boss_template: BossTemplate
var current_phase: BossPhase
var current_phase_index: int = 0
var phase_start_time: float = 0.0

# Behavior components
var movement_behavior: Node
var attack_behavior: Node

func _ready() -> void:
	# Get boss reference
	var boss = get_parent()
	if not boss:
		push_error("BossPhaseManager must be a child of a boss node")
		return
	
	# Connect to boss signals
	if boss.has_signal("damaged"):
		boss.damaged.connect(_on_boss_damaged)
	
	# Initialize first phase
	_initialize_phase()

func _initialize_phase() -> void:
	"""Initialize the current phase"""
	if not boss_template or boss_template.phases.is_empty():
		return
	
	current_phase = boss_template.get_current_phase(get_boss_hp())
	current_phase_index = boss_template.phases.find(current_phase)
	
	if current_phase:
		_apply_phase_behavior()
		_apply_phase_visuals()
		phase_start_time = Time.get_ticks_msec() / 1000.0

func _apply_phase_behavior() -> void:
	"""Apply the current phase's behavior"""
	if not current_phase:
		return
	
	var boss = get_parent()
	if not boss:
		return
	
	# Remove old behaviors
	_remove_old_behaviors()
	
	# Add movement behavior
	_add_movement_behavior()
	
	# Add attack behavior
	_add_attack_behavior()

func _remove_old_behaviors() -> void:
	"""Remove existing behavior components"""
	if movement_behavior and is_instance_valid(movement_behavior):
		movement_behavior.queue_free()
	if attack_behavior and is_instance_valid(attack_behavior):
		attack_behavior.queue_free()
	
	movement_behavior = null
	attack_behavior = null

func _add_movement_behavior() -> void:
	"""Add movement behavior for current phase"""
	if not current_phase:
		return
	
	var boss = get_parent()
	var behavior_script = current_phase.get_movement_behavior_scene()
	var new_movement_behavior = behavior_script.new()
	new_movement_behavior.name = "MovementBehavior"
	boss.add_child(new_movement_behavior)
	movement_behavior = new_movement_behavior
	
	# Apply movement parameters
	for key in current_phase.movement_params:
		if new_movement_behavior.has_method("set_" + key):
			new_movement_behavior.call("set_" + key, current_phase.movement_params[key])
		elif new_movement_behavior.get(key) != null:
			new_movement_behavior.set(key, current_phase.movement_params[key])

func _add_attack_behavior() -> void:
	"""Add attack behavior for current phase"""
	if not current_phase:
		return
	
	var boss = get_parent()
	var behavior_script = current_phase.get_attack_behavior_scene()
	attack_behavior = behavior_script.new()
	attack_behavior.name = "AttackBehavior"
	boss.add_child(attack_behavior)
	
	# Apply attack parameters
	for key in current_phase.attack_params:
		if attack_behavior.has_method("set_" + key):
			attack_behavior.call("set_" + key, current_phase.attack_params[key])
		elif attack_behavior.get(key) != null:
			attack_behavior.set(key, current_phase.attack_params[key])

func _apply_phase_visuals() -> void:
	"""Apply visual effects for current phase"""
	if not current_phase:
		return
	
	var boss = get_parent()
	current_phase.apply_visual_effects(boss)

func _on_boss_damaged(amount: int) -> void:
	"""Handle boss damage and check for phase transitions"""
	var new_hp = get_boss_hp()
	var new_phase = boss_template.get_current_phase(new_hp)
	
	# Check if phase changed
	if new_phase != current_phase:
		_transition_to_phase(new_phase)

func _transition_to_phase(new_phase: BossPhase) -> void:
	"""Transition to a new phase"""
	if not new_phase:
		return
	
	print("[BossPhaseManager] Transitioning to phase: ", new_phase.phase_name)
	
	# Update current phase
	current_phase = new_phase
	current_phase_index = boss_template.phases.find(current_phase)
	
	# Apply new phase behavior and visuals
	_apply_phase_behavior()
	_apply_phase_visuals()
	
	# Reset phase timer
	phase_start_time = Time.get_ticks_msec() / 1000.0
	
	# Emit phase change event
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": 1.0,
		"duration": 0.3
	})

func get_boss_hp() -> int:
	"""Get current boss HP"""
	var boss = get_parent()
	if boss and boss.has_method("get"):
		var hp = boss.get("hp")
		if hp == null:
			return 0
		return hp
	return 0

func get_current_phase() -> BossPhase:
	"""Get the current phase"""
	return current_phase

func get_phase_progress() -> float:
	"""Get phase progress (0.0 to 1.0)"""
	if not current_phase or current_phase.phase_duration <= 0.0:
		return 0.0
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - phase_start_time
	return min(elapsed / current_phase.phase_duration, 1.0)

func is_phase_complete() -> bool:
	"""Check if current phase is complete"""
	if not current_phase or current_phase.phase_duration <= 0.0:
		return false
	
	return get_phase_progress() >= 1.0
