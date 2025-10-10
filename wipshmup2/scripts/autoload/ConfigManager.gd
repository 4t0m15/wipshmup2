extends Node

# ConfigManager - Centralized configuration management
# Loads and manages all game configuration files

var configs: Dictionary = {}
var config_paths: Dictionary = {}

func _ready() -> void:
	print("[ConfigManager] Initializing configuration system")
	_load_all_configs()

func _load_all_configs() -> void:
	"""Load all configuration files"""
	# Set up config paths
	config_paths = {
		"enemies": "res://config/enemies.json",
		"stages": "res://config/stages.json",
		"bosses": "res://config/bosses.json",
		"game_balance": "res://config/game_balance.cfg",
		"audio": "res://config/audio.json",
		"visual": "res://config/visual.json"
	}
	
	# Load each config file
	for config_name in config_paths:
		_load_config(config_name, config_paths[config_name])
	
	print("[ConfigManager] Loaded ", configs.size(), " configuration files")

func _load_config(config_name: String, file_path: String) -> void:
	"""Load a specific configuration file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("Config file not found: " + file_path)
		configs[config_name] = {}
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Parse based on file extension
	if file_path.ends_with(".json"):
		configs[config_name] = JSON.parse_string(content)
	elif file_path.ends_with(".cfg"):
		configs[config_name] = _parse_cfg_file(content)
	else:
		push_warning("Unsupported config file format: " + file_path)
		configs[config_name] = {}
	
	print("[ConfigManager] Loaded config: ", config_name)

func _parse_cfg_file(content: String) -> Dictionary:
	"""Parse a CFG file into a dictionary"""
	var result = {}
	var lines = content.split("\n")
	
	for line in lines:
		line = line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		
		var parts = line.split("=", false, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			
			# Try to parse as number
			if value.is_valid_int():
				result[key] = value.to_int()
			elif value.is_valid_float():
				result[key] = value.to_float()
			elif value == "true":
				result[key] = true
			elif value == "false":
				result[key] = false
			else:
				result[key] = value
	
	return result

func get_config(config_name: String) -> Dictionary:
	"""Get a configuration dictionary"""
	return configs.get(config_name, {})

func get_config_value(config_name: String, key: String, default_value = null):
	"""Get a specific value from a configuration"""
	var config = get_config(config_name)
	return config.get(key, default_value)

func set_config_value(config_name: String, key: String, value) -> void:
	"""Set a configuration value"""
	if not configs.has(config_name):
		configs[config_name] = {}
	
	configs[config_name][key] = value

func save_config(config_name: String) -> bool:
	"""Save a configuration to file"""
	if not config_paths.has(config_name):
		push_error("No file path for config: " + config_name)
		return false
	
	var file_path = config_paths[config_name]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("Cannot write to config file: " + file_path)
		return false
	
	var content = ""
	if file_path.ends_with(".json"):
		content = JSON.stringify(configs[config_name], "\t")
	elif file_path.ends_with(".cfg"):
		content = _serialize_cfg_file(configs[config_name])
	
	file.store_string(content)
	file.close()
	
	print("[ConfigManager] Saved config: ", config_name)
	return true

func _serialize_cfg_file(config: Dictionary) -> String:
	"""Serialize a dictionary to CFG format"""
	var lines = []
	
	for key in config:
		var value = config[key]
		if value is String:
			lines.append(key + " = " + value)
		else:
			lines.append(key + " = " + str(value))
	
	return "\n".join(lines)

# Convenience methods for common configs
func get_enemy_config(enemy_type: String) -> Dictionary:
	"""Get enemy configuration"""
	var enemies = get_config("enemies")
	return enemies.get(enemy_type, {})

func get_stage_config(stage_number: int) -> Dictionary:
	"""Get stage configuration"""
	var stages = get_config("stages")
	return stages.get("stage_" + str(stage_number), {})

func get_boss_config(boss_name: String) -> Dictionary:
	"""Get boss configuration"""
	var bosses = get_config("bosses")
	return bosses.get(boss_name, {})

func get_game_balance() -> Dictionary:
	"""Get game balance configuration"""
	return get_config("game_balance")

func get_audio_config() -> Dictionary:
	"""Get audio configuration"""
	return get_config("audio")

func get_visual_config() -> Dictionary:
	"""Get visual configuration"""
	return get_config("visual")

# Hot reload for development
func reload_config(config_name: String) -> bool:
	"""Reload a specific configuration file"""
	if config_paths.has(config_name):
		_load_config(config_name, config_paths[config_name])
		return true
	return false

func reload_all_configs() -> void:
	"""Reload all configuration files"""
	configs.clear()
	_load_all_configs()
	print("[ConfigManager] Reloaded all configurations")

# Development utilities
func create_default_configs() -> void:
	"""Create default configuration files"""
	_create_default_enemies_config()
	_create_default_stages_config()
	_create_default_bosses_config()
	_create_default_game_balance_config()
	_create_default_audio_config()
	_create_default_visual_config()

func _create_default_enemies_config() -> void:
	"""Create default enemies configuration"""
	var enemies_config = {
		"basic_fighter": {
			"hp": 1,
			"points": 100,
			"speed": 50.0,
			"movement_behavior": "StraightDown",
			"attack_behavior": "AimedShot"
		},
		"sine_fighter": {
			"hp": 1,
			"points": 150,
			"speed": 40.0,
			"movement_behavior": "SineWave",
			"attack_behavior": "Fan"
		}
	}
	
	configs["enemies"] = enemies_config
	save_config("enemies")

func _create_default_stages_config() -> void:
	"""Create default stages configuration"""
	var stages_config = {
		"stage_1": {
			"name": "Stage 1",
			"waves": [
				{
					"name": "Opening Wave",
					"enemies": ["basic_fighter", "basic_fighter", "basic_fighter"]
				}
			],
			"boss": "gliath"
		}
	}
	
	configs["stages"] = stages_config
	save_config("stages")

func _create_default_bosses_config() -> void:
	"""Create default bosses configuration"""
	var bosses_config = {
		"gliath": {
			"max_hp": 60,
			"points": 5000,
			"phases": [
				{
					"hp_threshold": 0,
					"movement_behavior": "StraightDown",
					"attack_patterns": ["AimedShot"]
				}
			]
		}
	}
	
	configs["bosses"] = bosses_config
	save_config("bosses")

func _create_default_game_balance_config() -> void:
	"""Create default game balance configuration"""
	var balance_config = {
		"player_speed": 200.0,
		"player_shot_cooldown": 0.1,
		"enemy_speed_multiplier": 1.0,
		"bullet_speed_multiplier": 1.0,
		"rank_scaling": 1.0
	}
	
	configs["game_balance"] = balance_config
	save_config("game_balance")

func _create_default_audio_config() -> void:
	"""Create default audio configuration"""
	var audio_config = {
		"master_volume": 1.0,
		"music_volume": 0.7,
		"sfx_volume": 0.8,
		"voice_volume": 0.9
	}
	
	configs["audio"] = audio_config
	save_config("audio")

func _create_default_visual_config() -> void:
	"""Create default visual configuration"""
	var visual_config = {
		"screen_shake_intensity": 1.0,
		"particle_effects": true,
		"glow_effects": true,
		"background_parallax": true
	}
	
	configs["visual"] = visual_config
	save_config("visual")
