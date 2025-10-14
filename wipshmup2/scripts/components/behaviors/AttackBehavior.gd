extends Node
class_name AttackBehavior

# Base class for enemy attack behaviors
# Handles bullet patterns and firing logic

@export var fire_rate: float = 1.0  # Shots per second
@export var bullet_speed: float = 140.0
@export var bullet_damage: int = 1

var enemy: Node2D
var fire_timer: float = 0.0
var can_fire: bool = true

func _ready() -> void:
	# Find the enemy parent
	enemy = get_parent()
	if not enemy:
		push_error("AttackBehavior must be a child of an enemy node")
		return
	
	# Apply rank-based scaling
	_apply_rank_scaling()

func _physics_process(delta: float) -> void:
	if not enemy or not is_instance_valid(enemy):
		return
	
	_update_attack(delta)

func _update_attack(delta: float) -> void:
	# Update fire timer
	if fire_timer > 0.0:
		fire_timer -= delta
	else:
		can_fire = true
	
	# Override in subclasses for specific attack patterns
	_handle_attack(delta)

func _handle_attack(_delta: float) -> void:
	# Override in subclasses
	pass

func _apply_rank_scaling() -> void:
	"""Apply rank-based scaling to attack parameters"""
	if RankManager and RankManager.has_method("get_pattern_cadence_multiplier"):
		var cadence_mult = RankManager.get_pattern_cadence_multiplier()
		fire_rate *= cadence_mult
	
	if RankManager and RankManager.has_method("get_bullet_speed_multiplier"):
		var speed_mult = RankManager.get_bullet_speed_multiplier()
		bullet_speed *= speed_mult

func fire_bullet(direction: Vector2, speed_override: float = -1.0) -> void:
	"""Fire a single bullet in the given direction"""
	if not can_fire:
		return
	
	var actual_speed = speed_override if speed_override > 0.0 else bullet_speed
	EntityFactory.spawn_enemy_bullet(enemy.global_position, direction, actual_speed, bullet_damage)
	
	# Reset fire timer
	fire_timer = 1.0 / fire_rate
	can_fire = false

func fire_bullet_at_target(target_position: Vector2, speed_override: float = -1.0) -> void:
	"""Fire a bullet aimed at the target position"""
	var direction = (target_position - enemy.global_position).normalized()
	fire_bullet(direction, speed_override)

func set_fire_rate(new_rate: float) -> void:
	fire_rate = new_rate

func set_bullet_speed(new_speed: float) -> void:
	bullet_speed = new_speed

func can_attack() -> bool:
	return can_fire
