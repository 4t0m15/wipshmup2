extends GameMode
class_name EndlessMode

# EndlessMode - Infinite stages with scaling difficulty
# Stages loop with increasing difficulty

@export var difficulty_increase_rate: float = 0.1
@export var max_difficulty: float = 3.0
@export var stage_loop_count: int = 0

func _init() -> void:
	super._init()
	mode_name = "Endless"
	mode_description = "Survive as long as possible with increasing difficulty"
	is_endless = true
	has_bosses = true
	has_stages = true
	max_stage = -1  # Infinite
	starting_lives = 3
	starting_bombs = 3
	difficulty_scaling = 1.0
	score_multiplier = 1.2  # Bonus score for endless mode

func _setup_mode() -> void:
	"""Setup endless mode"""
	print("[EndlessMode] Setting up endless mode")
	
	# Set stage progression (loops through all stages)
	stage_progression = [1, 2, 3, 4, 5, 6, 7, 8]
	current_stage = 0
	stage_loop_count = 0
	
	# Reset difficulty
	difficulty_scaling = 1.0
	
	# Apply endless-specific settings
	_apply_endless_settings()

func _apply_endless_settings() -> void:
	"""Apply endless mode settings"""
	# Set rank manager to endless mode
	if RankManager and RankManager.has_method("set_mode"):
		RankManager.set_mode("endless")
	
	# Set item drop rates for endless
	if ItemDropManager and ItemDropManager.has_method("set_mode"):
		ItemDropManager.set_mode("endless")

func _apply_endless_scaling() -> void:
	"""Apply endless mode scaling"""
	super._apply_endless_scaling()
	
	# Cap difficulty scaling
	difficulty_scaling = min(difficulty_scaling, max_difficulty)
	
	# Track loop count
	stage_loop_count += 1
	
	print("[EndlessMode] Difficulty scaling: ", difficulty_scaling, " (Loop: ", stage_loop_count, ")")
	
	# Apply scaling to various systems
	_apply_difficulty_scaling()

func _apply_difficulty_scaling() -> void:
	"""Apply difficulty scaling to game systems"""
	# Scale enemy speed
	if RankManager and RankManager.has_method("set_difficulty_multiplier"):
		RankManager.set_difficulty_multiplier(difficulty_scaling)
	
	# Scale bullet patterns
	if BulletPatterns and BulletPatterns.has_method("set_difficulty_multiplier"):
		BulletPatterns.set_difficulty_multiplier(difficulty_scaling)

func get_endless_info() -> Dictionary:
	"""Get endless mode information"""
	return {
		"loop_count": stage_loop_count,
		"difficulty_scaling": difficulty_scaling,
		"max_difficulty": max_difficulty,
		"current_stage": current_stage,
		"stage_in_loop": (current_stage - 1) % stage_progression.size() + 1
	}

func get_survival_time() -> float:
	"""Get survival time in seconds"""
	return GameState.get_game_time()

func get_survival_score() -> int:
	"""Get survival score bonus"""
	var time_bonus = int(get_survival_time() * 10.0)
	var loop_bonus = stage_loop_count * 1000
	return time_bonus + loop_bonus
