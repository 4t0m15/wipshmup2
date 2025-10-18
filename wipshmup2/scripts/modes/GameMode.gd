extends Node
class_name GameMode

# GameMode - Base class for different game modes
# Provides common interface for campaign, endless, boss rush, etc.

@export var mode_name: String = "Game Mode"
@export var mode_description: String = "A game mode"
@export var is_endless: bool = false
@export var has_bosses: bool = true
@export var has_stages: bool = true

# Mode configuration
@export var starting_lives: int = 3
@export var starting_bombs: int = 3
@export var difficulty_scaling: float = 1.0
@export var score_multiplier: float = 1.0

# Stage progression
var current_stage: int = 1
var max_stage: int = 8
var stage_progression: Array[int] = []

func _init() -> void:
	# Set default stage progression
	stage_progression = [1, 2, 3, 4, 5, 6, 7, 8]

func start_mode() -> void:
	"""Start the game mode"""
	print("[GameMode] Starting mode: ", mode_name)
	
	# Initialize game state
	GameState.reset_game()
	# Use setters so change signals fire for HUD synchronization
	GameState.set_lives(starting_lives)
	GameState.set_bombs(starting_bombs)
	
	# Apply mode-specific setup
	_setup_mode()
	
	# Emit mode started event
	EventBus.game_started.emit()

func _setup_mode() -> void:
	"""Setup mode-specific configuration"""
	# Override in subclasses
	pass

func get_next_stage() -> int:
	"""Get the next stage number"""
	# Safety check for empty progression
	if stage_progression.is_empty():
		print("[GameMode] Stage progression is nonexistant")
		return -1
	
	if current_stage >= stage_progression.size():
		if is_endless:
			# Loop back to stage 1 with scaling
			current_stage = 1
			# Increment loop counter (Cho Ren Sha 68K mechanic)
			GameState.increment_loop()
			_apply_endless_scaling()
		else:
			# Mode complete
			_complete_mode()
			return -1
	
	# Safety check for valid index
	if current_stage < 0 or current_stage >= stage_progression.size():
		print("[GameMode] Invalid stage index: " + str(current_stage))
		return -1
	
	var stage_number = stage_progression[current_stage]
	current_stage += 1
	return stage_number

func _apply_endless_scaling() -> void:
	"""Apply endless mode scaling"""
	# Increase difficulty
	difficulty_scaling += 0.1
	
	# Apply to rank manager
	# Note: RankManager doesn't have set_difficulty_multiplier method
	# This would need to be implemented if difficulty scaling is needed

func _complete_mode() -> void:
	"""Complete the game mode"""
	print("[GameMode] Mode completed: ", mode_name)
	EventBus.game_over.emit()

func get_mode_info() -> Dictionary:
	"""Get mode information"""
	return {
		"name": mode_name,
		"description": mode_description,
		"is_endless": is_endless,
		"has_bosses": has_bosses,
		"has_stages": has_stages,
		"current_stage": current_stage,
		"max_stage": max_stage
	}

func apply_score_modifier(base_score: int) -> int:
	"""Apply score multiplier"""
	return int(base_score * score_multiplier)

func apply_difficulty_modifier(base_value: float) -> float:
	"""Apply difficulty scaling"""
	return base_value * difficulty_scaling
