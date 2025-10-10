extends Node

# GameModeManager - Manages game modes and mode switching
# Provides easy access to different game modes

var current_mode: GameMode
var available_modes: Dictionary = {}

func _ready() -> void:
	print("[GameModeManager] Initializing game modes")
	_register_available_modes()

func _register_available_modes() -> void:
	"""Register all available game modes"""
	
	# Campaign Mode
	var campaign = CampaignMode.new()
	available_modes["campaign"] = campaign
	
	# Endless Mode
	var endless = EndlessMode.new()
	available_modes["endless"] = endless
	
	# Boss Rush Mode
	var boss_rush = BossRushMode.new()
	available_modes["boss_rush"] = boss_rush
	
	# Practice Mode
	var practice = PracticeMode.new()
	available_modes["practice"] = practice
	
	print("[GameModeManager] Registered ", available_modes.size(), " game modes")

func start_mode(mode_name: String) -> bool:
	"""Start a specific game mode"""
	if not available_modes.has(mode_name):
		push_error("Game mode not found: " + mode_name)
		return false
	
	# Stop current mode if running
	if current_mode:
		stop_current_mode()
	
	# Set new mode
	current_mode = available_modes[mode_name]
	
	# Start the mode
	current_mode.start_mode()
	
	print("[GameModeManager] Started mode: ", mode_name)
	return true

func stop_current_mode() -> void:
	"""Stop the current game mode"""
	if current_mode:
		print("[GameModeManager] Stopping mode: ", current_mode.mode_name)
		current_mode = null

func get_current_mode() -> GameMode:
	"""Get the current game mode"""
	return current_mode

func get_current_mode_name() -> String:
	"""Get the current mode name"""
	if current_mode:
		return current_mode.mode_name
	return ""

func get_available_modes() -> Array[String]:
	"""Get all available mode names"""
	return available_modes.keys()

func get_mode_info(mode_name: String) -> Dictionary:
	"""Get information about a specific mode"""
	if available_modes.has(mode_name):
		return available_modes[mode_name].get_mode_info()
	return {}

func is_mode_active() -> bool:
	"""Check if a mode is currently active"""
	return current_mode != null

func get_mode_progress() -> Dictionary:
	"""Get current mode progress"""
	if current_mode:
		return current_mode.get_mode_info()
	return {}

# Convenience methods for common modes
func start_campaign() -> bool:
	"""Start campaign mode"""
	return start_mode("campaign")

func start_endless() -> bool:
	"""Start endless mode"""
	return start_mode("endless")

func start_boss_rush() -> bool:
	"""Start boss rush mode"""
	return start_mode("boss_rush")

func start_practice(stage_number: int = 1) -> bool:
	"""Start practice mode for a specific stage"""
	var practice = available_modes["practice"] as PracticeMode
	if practice:
		practice.set_practice_target("stage", str(stage_number))
		return start_mode("practice")
	return false

func start_boss_practice(boss_name: String) -> bool:
	"""Start practice mode for a specific boss"""
	var practice = available_modes["practice"] as PracticeMode
	if practice:
		practice.set_practice_target("boss", boss_name)
		return start_mode("practice")
	return false

# Mode-specific utilities
func get_campaign_progress() -> Dictionary:
	"""Get campaign progress"""
	if current_mode and current_mode is CampaignMode:
		return current_mode.get_progress()
	return {}

func get_endless_info() -> Dictionary:
	"""Get endless mode information"""
	if current_mode and current_mode is EndlessMode:
		return current_mode.get_endless_info()
	return {}

func get_boss_rush_info() -> Dictionary:
	"""Get boss rush information"""
	if current_mode and current_mode is BossRushMode:
		return current_mode.get_boss_rush_info()
	return {}

func get_practice_info() -> Dictionary:
	"""Get practice mode information"""
	if current_mode and current_mode is PracticeMode:
		return current_mode.get_practice_info()
	return {}

# Practice mode utilities
func toggle_slow_motion() -> void:
	"""Toggle slow motion in practice mode"""
	if current_mode and current_mode is PracticeMode:
		current_mode.toggle_slow_motion()

func toggle_infinite_lives() -> void:
	"""Toggle infinite lives in practice mode"""
	if current_mode and current_mode is PracticeMode:
		current_mode.toggle_infinite_lives()

func toggle_infinite_bombs() -> void:
	"""Toggle infinite bombs in practice mode"""
	if current_mode and current_mode is PracticeMode:
		current_mode.toggle_infinite_bombs()
