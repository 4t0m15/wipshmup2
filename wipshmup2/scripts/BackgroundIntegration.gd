extends Node
class_name BackgroundIntegration

# Background Integration Manager
# Handles communication between game systems and background effects

# signal environment_change_requested(environment_type: BackgroundManager.EnvironmentType)  # Reserved for future use

var background_manager: BackgroundManager
var game_manager: Node
var current_score: int = 0
var current_stage: int = 1
var intensity_level: float = 1.0

# Environment progression thresholds
const ENVIRONMENT_THRESHOLDS = {
	BackgroundManager.EnvironmentType.SPACE_DEEP: 0,
	BackgroundManager.EnvironmentType.ASTEROID_FIELD: 10000,
	BackgroundManager.EnvironmentType.NEBULA: 25000,
	BackgroundManager.EnvironmentType.PLANET_ORBIT: 50000,
	BackgroundManager.EnvironmentType.STAR_SYSTEM: 75000,
	BackgroundManager.EnvironmentType.BASE_APPROACH: 100000,
	BackgroundManager.EnvironmentType.COMBAT_ZONE: 150000
}

func _ready():
	print("BackgroundIntegration: Initializing background integration system")
	# Connect to game events
	_connect_to_game_events()

func _connect_to_game_events():
	"""Connect to various game events to trigger background changes"""
	# This would typically connect to signals from the main game manager
	# For now, we'll set up the basic structure
	pass

func set_background_manager(manager: BackgroundManager):
	"""Set the background manager reference"""
	background_manager = manager
	if background_manager:
		background_manager.background_changed.connect(_on_background_changed)

func set_game_manager(manager: Node):
	"""Set the game manager reference"""
	game_manager = manager

func update_score(new_score: int):
	"""Update score and check for environment changes"""
	current_score = new_score
	_check_environment_progression()

func update_stage(new_stage: int):
	"""Update stage and trigger appropriate environment"""
	current_stage = new_stage
	_trigger_stage_environment()

func set_intensity(intensity: float):
	"""Set background intensity based on game state"""
	intensity_level = clamp(intensity, 0.1, 2.0)
	if background_manager:
		background_manager.set_intensity(intensity_level)

func _check_environment_progression():
	"""Check if environment should change based on score"""
	if not background_manager:
		return
		
	var target_environment = BackgroundManager.EnvironmentType.SPACE_DEEP
	
	# Find the appropriate environment based on score
	for env_type in ENVIRONMENT_THRESHOLDS:
		if current_score >= ENVIRONMENT_THRESHOLDS[env_type]:
			target_environment = env_type
	
	# Change environment if needed
	if background_manager.get_current_environment() != target_environment:
		background_manager.change_environment(target_environment)
		print("BackgroundIntegration: Environment changed to ", BackgroundManager.EnvironmentType.keys()[target_environment])

func _trigger_stage_environment():
	"""Trigger environment based on stage"""
	if not background_manager:
		return
		
	var stage_environment = BackgroundManager.EnvironmentType.SPACE_DEEP
	
	match current_stage:
		1:
			stage_environment = BackgroundManager.EnvironmentType.SPACE_DEEP
		2:
			stage_environment = BackgroundManager.EnvironmentType.ASTEROID_FIELD
		3:
			stage_environment = BackgroundManager.EnvironmentType.NEBULA
		4:
			stage_environment = BackgroundManager.EnvironmentType.PLANET_ORBIT
		5:
			stage_environment = BackgroundManager.EnvironmentType.STAR_SYSTEM
		6:
			stage_environment = BackgroundManager.EnvironmentType.BASE_APPROACH
		_:
			stage_environment = BackgroundManager.EnvironmentType.COMBAT_ZONE
	
	background_manager.change_environment(stage_environment)

func _on_background_changed(environment_type: String):
	"""Handle background change events"""
	print("BackgroundIntegration: Background changed to ", environment_type)
	# Could trigger additional effects here like audio changes, particle effects, etc.

func trigger_combat_effects():
	"""Trigger intense background effects for combat"""
	if background_manager:
		background_manager.change_environment(BackgroundManager.EnvironmentType.COMBAT_ZONE)
		background_manager.set_intensity(1.5)

func trigger_boss_effects():
	"""Trigger special effects for boss battles"""
	if background_manager:
		background_manager.set_intensity(2.0)
		# Could add special boss-specific background elements here

func reset_to_calm():
	"""Reset background to calm state"""
	if background_manager:
		background_manager.set_intensity(1.0)
		# Return to appropriate environment based on current progress
		_check_environment_progression()
