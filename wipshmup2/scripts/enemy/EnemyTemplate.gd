extends Resource
class_name EnemyTemplate

# EnemyTemplate - Data-driven enemy definitions
# Replaces hardcoded enemy types with configurable templates

@export var type_name: String = "enemy"
@export var hp: int = 1
@export var points: int = 100
@export var speed: float = 50.0
@export var sprite_key: String = "enemy"

# Behavior configuration
@export var movement_behavior: String = "StraightDown"
@export var attack_behavior: String = "AimedShot"

# Movement parameters
@export var movement_params: Dictionary = {}

# Attack parameters
@export var attack_params: Dictionary = {}

# Visual parameters
@export var sprite_scale: float = 1.0
@export var glow_color: Color = Color.WHITE
@export var danger_level: int = 1

# Collision parameters
@export var collision_radius: float = 8.0
@export var collision_layer: int = 1
@export var collision_mask: int = 1

# Special properties
@export var ignore_shot_damage: bool = false
@export var ignore_bomb_damage: bool = false
@export var bomb_points_override: int = -1
@export var bomb_points_multiplier: float = 10.0

func _init() -> void:
	# Set default movement parameters
	if movement_params.is_empty():
		movement_params = {
			"speed": speed,
			"direction": Vector2.DOWN
		}
	
	# Set default attack parameters
	if attack_params.is_empty():
		attack_params = {
			"fire_rate": 1.0,
			"bullet_speed": 140.0,
			"bullet_damage": 1
		}

func get_movement_behavior_scene() -> GDScript:
	"""Get the movement behavior scene for this template"""
	match movement_behavior:
		"StraightDown":
			return load("res://scripts/components/behaviors/StraightDownBehavior.gd")
		"SineWave":
			return load("res://scripts/components/behaviors/SineWaveBehavior.gd")
		"Zigzag":
			return load("res://scripts/components/behaviors/ZigzagBehavior.gd")
		"Dive":
			return load("res://scripts/components/behaviors/DiveBehavior.gd")
		_:
			return load("res://scripts/components/behaviors/StraightDownBehavior.gd")

func get_attack_behavior_scene() -> GDScript:
	"""Get the attack behavior scene for this template"""
	match attack_behavior:
		"AimedShot":
			return load("res://scripts/components/behaviors/AimedShotBehavior.gd")
		"Fan":
			return load("res://scripts/components/behaviors/FanBehavior.gd")
		"Ring":
			return load("res://scripts/components/behaviors/RingBehavior.gd")
		_:
			return load("res://scripts/components/behaviors/AimedShotBehavior.gd")

func create_enemy_instance() -> Node:
	"""Create an enemy instance from this template"""
	# Load the base enemy scene
	var enemy_scene = load("res://scenes/enemy/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Apply template properties
	enemy.set("hp", hp)
	enemy.set("points", points)
	enemy.set("speed", speed)
	enemy.set("enemy_type", type_name)
	enemy.set("ignore_shot_damage", ignore_shot_damage)
	enemy.set("ignore_bomb_damage", ignore_bomb_damage)
	enemy.set("bomb_points_override", bomb_points_override)
	enemy.set("bomb_points_multiplier", bomb_points_multiplier)
	
	# Add movement behavior
	var movement_script = get_movement_behavior_scene()
	var movement_behavior_node = movement_script.new()
	movement_behavior_node.name = "MovementBehavior"
	enemy.add_child(movement_behavior_node)
	
	# Apply movement parameters
	for key in movement_params:
		if movement_behavior_node.has_method("set_" + key):
			movement_behavior_node.call("set_" + key, movement_params[key])
		elif movement_behavior_node.get(key) != null:
			movement_behavior_node.set(key, movement_params[key])
	
	# Add attack behavior
	var attack_script = get_attack_behavior_scene()
	var attack_behavior_node = attack_script.new()
	attack_behavior_node.name = "AttackBehavior"
	enemy.add_child(attack_behavior_node)
	
	# Apply attack parameters
	for key in attack_params:
		if attack_behavior_node.has_method("set_" + key):
			attack_behavior_node.call("set_" + key, attack_params[key])
		elif attack_behavior_node.get(key) != null:
			attack_behavior_node.set(key, attack_params[key])
	
	# Setup sprite
	_setup_enemy_sprite(enemy)
	
	# Setup collision
	_setup_enemy_collision(enemy)
	
	return enemy

func _setup_enemy_sprite(enemy: Node) -> void:
	"""Setup the enemy sprite from template"""
	if enemy.has_node("Sprite2D"):
		var sprite = enemy.get_node("Sprite2D")
		
		# Apply sprite scale
		sprite.scale = Vector2(sprite_scale, sprite_scale)
		
		# Apply glow color if needed
		if glow_color != Color.WHITE:
			sprite.modulate = glow_color

func _setup_enemy_collision(enemy: Node) -> void:
	"""Setup the enemy collision from template"""
	if enemy.has_node("CollisionShape2D"):
		var collision = enemy.get_node("CollisionShape2D")
		if collision.shape is CircleShape2D:
			(collision.shape as CircleShape2D).radius = collision_radius
		elif collision.shape is RectangleShape2D:
			var size = Vector2(collision_radius * 2, collision_radius * 2)
			(collision.shape as RectangleShape2D).size = size
	
	# Set collision layers
	enemy.collision_layer = collision_layer
	enemy.collision_mask = collision_mask
