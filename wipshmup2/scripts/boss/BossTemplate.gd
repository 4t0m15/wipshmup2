extends Resource
class_name BossTemplate

# BossTemplate - Data-driven boss definition
# Replaces hardcoded boss scripts with configurable templates

@export var boss_name: String = "Boss"
@export var max_hp: int = 60
@export var points_value: int = 5000
@export var phases: Array[BossPhase] = []
@export var sprite_key: String = "boss"

# Visual properties
@export var sprite_scale: float = 1.0
@export var glow_color: Color = Color.RED
@export var danger_level: int = 3

# Collision properties
@export var collision_radius: float = 16.0
@export var collision_layer: int = 1
@export var collision_mask: int = 0

# Special properties
@export var immune_to_bombs: bool = false
@export var immune_to_player_bullets: bool = false

func _init() -> void:
	# Create default phases if none exist
	if phases.is_empty():
		_create_default_phases()

func _create_default_phases() -> void:
	"""Create default boss phases"""
	var phase1 = BossPhase.new()
	phase1.phase_name = "Phase 1"
	phase1.hp_threshold = 0
	phase1.movement_behavior = "StraightDown"
	phase1.attack_patterns = ["AimedShot"] as Array[String]
	phase1.movement_params = {"speed": 30.0}
	phase1.attack_params = {"fire_rate": 0.5, "bullet_speed": 120.0}
	phases.append(phase1)

func get_current_phase(current_hp: int) -> BossPhase:
	"""Get the current phase based on HP"""
	for phase in phases:
		if current_hp >= phase.hp_threshold:
			return phase
	
	# Return last phase if HP is below all thresholds
	return phases[-1] if phases.size() > 0 else null

func get_phase_count() -> int:
	"""Get the total number of phases"""
	return phases.size()

func create_boss_instance() -> Node:
	"""Create a boss instance from this template"""
	# Load the appropriate boss scene based on sprite_key
	var boss_scene_path = _get_boss_scene_path()
	print("[BossTemplate] Loading boss scene: ", boss_scene_path)
	var boss_scene = load(boss_scene_path)
	if not boss_scene:
		push_error("Boss scene not found: " + boss_scene_path)
		return null
	
	print("[BossTemplate] Scene loaded, instantiating")
	var boss = boss_scene.instantiate()
	print("[BossTemplate] Boss instantiated: ", boss)
	
	# Apply template properties
	boss.set("max_hp", max_hp)
	boss.set("hp", max_hp)
	boss.set("points", points_value)
	boss.set("boss_name", boss_name)
	boss.set("immune_to_bombs", immune_to_bombs)
	boss.set("immune_to_player_bullets", immune_to_player_bullets)
	
	# Setup sprite
	_setup_boss_sprite(boss)
	
	# Setup collision
	_setup_boss_collision(boss)
	
	# Add phase management
	_add_phase_management(boss)
	
	return boss

func _setup_boss_sprite(boss: Node) -> void:
	"""Setup the boss sprite from template"""
	if boss.has_node("Sprite2D"):
		var sprite = boss.get_node("Sprite2D")
		sprite.scale = Vector2(sprite_scale, sprite_scale)
		if glow_color != Color.WHITE:
			sprite.modulate = glow_color

func _setup_boss_collision(boss: Node) -> void:
	"""Setup the boss collision from template"""
	if boss.has_node("CollisionShape2D"):
		var collision = boss.get_node("CollisionShape2D")
		if collision.shape is CircleShape2D:
			(collision.shape as CircleShape2D).radius = collision_radius
		elif collision.shape is RectangleShape2D:
			var size = Vector2(collision_radius * 2, collision_radius * 2)
			(collision.shape as RectangleShape2D).size = size
	
	# Set collision layers
	boss.collision_layer = collision_layer
	boss.collision_mask = collision_mask

func _add_phase_management(boss: Node) -> void:
	"""Add phase management script to boss"""
	var phase_manager_script = load("res://scripts/boss/BossPhaseManager.gd")
	var phase_manager = phase_manager_script.new()
	phase_manager.name = "PhaseManager"
	phase_manager.boss_template = self
	# Use call_deferred to avoid "Parent node is busy setting up children" error
	boss.add_child.call_deferred(phase_manager)

func _get_boss_scene_path() -> String:
	"""Get the boss scene path based on sprite_key"""
	# Map sprite_key to actual boss scene paths
	var scene_mapping = {
		"gliath": "res://scenes/boss/gliath/Gliath.tscn",
		"type0": "res://scenes/boss/type0/Type0.tscn", 
		"iron_casket": "res://scenes/boss/ironcasket/IronCasket.tscn",
		"bb": "res://scenes/boss/bb/BB.tscn",
		"blockade": "res://scenes/boss/blockade/BlockAde.tscn",
		"crosssinker": "res://scenes/boss/crosssinker/CrossSinker.tscn",
		"fgr": "res://scenes/boss/fgr/FGR.tscn",
		"fortress": "res://scenes/boss/fortress/Fortress.tscn",
		"grafzeppelin": "res://scenes/boss/grafzeppelin/GrafZeppelin.tscn"
	}
	
	# Return mapped path or default to BB if not found
	return scene_mapping.get(sprite_key, "res://scenes/boss/bb/BB.tscn")
