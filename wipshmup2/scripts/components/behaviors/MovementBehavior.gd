extends Node
class_name MovementBehavior

# Base class for enemy movement behaviors
# Use composition to create different enemy types

@export var speed: float = 50.0
@export var acceleration: float = 0.0
@export var max_speed: float = 200.0

var enemy: Node2D
var direction: Vector2 = Vector2.DOWN
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Find the enemy parent
	enemy = get_parent()
	if not enemy:
		push_error("MovementBehavior must be a child of an enemy node")
		return
	
	# Apply rank-based speed scaling
	_apply_rank_scaling()

func _physics_process(delta: float) -> void:
	if not enemy or not is_instance_valid(enemy):
		return
	
	_update_movement(delta)
	enemy.position += velocity * delta

func _update_movement(delta: float) -> void:
	# Override in subclasses
	pass

func _apply_rank_scaling() -> void:
	"""Apply rank-based speed scaling"""
	if RankManager and RankManager.has_method("get_enemy_speed_multiplier"):
		var speed_mult = RankManager.get_enemy_speed_multiplier()
		speed *= speed_mult

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()

func set_speed(new_speed: float) -> void:
	speed = new_speed

func get_velocity() -> Vector2:
	return velocity

func stop() -> void:
	velocity = Vector2.ZERO

func is_off_screen() -> bool:
	if not enemy:
		return false
	
	var rect = get_viewport().get_visible_rect()
	return enemy.position.y > rect.size.y + 64 or \
		   enemy.position.x < -64 or \
		   enemy.position.x > rect.size.x + 64
