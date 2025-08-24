class_name DifficultyConfigService
extends Node

# Loads and serves difficulty tuning from a properties file.
# File format: Godot ConfigFile (ini-like), sections per difficulty.
# Example path: res://config/difficulty.cfg

@export var config_path: String = "res://config/difficulty.cfg"

var _cfg: ConfigFile = ConfigFile.new()
var _loaded: bool = false
var _current: String = "normal"
func _ready() -> void:
	_load()

func _load() -> void:
	var err: int = _cfg.load(config_path)
	if err != OK:
		_loaded = false
		# Keep defaults in memory; file may not exist in exported builds
		return
	_loaded = true
	_current = str(_cfg.get_value("general", "current_difficulty", "normal"))

func reload() -> void:
	_load()

func get_current_difficulty() -> String:
	return _current

func set_current_difficulty(difficulty_name: String, persist: bool = true) -> void:
	_current = difficulty_name
	if persist and _loaded:
		_cfg.set_value("general", "current_difficulty", difficulty_name)
		_cfg.save(config_path)

func _get_value_for_current(key: String, default_value: Variant) -> Variant:
	# Prefer per-difficulty section; fall back to normal; finally the provided default
	var value: Variant = _cfg.get_value(_current, key, null)
	if value == null:
		value = _cfg.get_value("normal", key, null)
	if value == null:
		return default_value
	return value

func get_rank_params() -> Dictionary:
	return {
		"min_rank": float(_get_value_for_current("min_rank", 1.0)),
		"max_rank": float(_get_value_for_current("max_rank", 3.0)),
		"time_rank_rate": float(_get_value_for_current("time_rank_rate", 0.01)),
		"kill_rank_rate": float(_get_value_for_current("kill_rank_rate", 0.0005))
	}

func get_multiplier_caps() -> Dictionary:
	return {
		"enemy_speed_max_mult": float(_get_value_for_current("enemy_speed_max_mult", 1.8)),
		"enemy_hp_max_mult": float(_get_value_for_current("enemy_hp_max_mult", 2.0)),
		"bullet_speed_max_mult": float(_get_value_for_current("bullet_speed_max_mult", 1.7)),
		"pattern_density_max_mult": float(_get_value_for_current("pattern_density_max_mult", 2.0)),
		"pattern_cadence_max_mult": float(_get_value_for_current("pattern_cadence_max_mult", 1.0))
	}
