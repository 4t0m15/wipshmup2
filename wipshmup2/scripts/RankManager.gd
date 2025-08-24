extends Node

@export var min_rank: float = 1.0
@export var max_rank: float = 3.0
@export var time_rank_rate: float = 0.01
@export var kill_rank_rate: float = 0.0005

var rank: float = 1.0
var stage_number: int = 1

# Max multiplier caps (configurable via DifficultyConfig)
var enemy_speed_max_mult: float = 1.8
var enemy_hp_max_mult: float = 2.0
var bullet_speed_max_mult: float = 1.7
var pattern_density_max_mult: float = 2.0
var pattern_cadence_max_mult: float = 1.0

func _ready() -> void:
	# Load tuning from DifficultyConfig if available
	var dc := get_node_or_null("/root/DifficultyConfig")
	if dc and dc.has_method("get_rank_params"):
		var rp: Dictionary = dc.get_rank_params()
		min_rank = float(rp.get("min_rank", min_rank))
		max_rank = float(rp.get("max_rank", max_rank))
		time_rank_rate = float(rp.get("time_rank_rate", time_rank_rate))
		kill_rank_rate = float(rp.get("kill_rank_rate", kill_rank_rate))
	if dc and dc.has_method("get_multiplier_caps"):
		var caps: Dictionary = dc.get_multiplier_caps()
		enemy_speed_max_mult = float(caps.get("enemy_speed_max_mult", enemy_speed_max_mult))
		enemy_hp_max_mult = float(caps.get("enemy_hp_max_mult", enemy_hp_max_mult))
		bullet_speed_max_mult = float(caps.get("bullet_speed_max_mult", bullet_speed_max_mult))
		pattern_density_max_mult = float(caps.get("pattern_density_max_mult", pattern_density_max_mult))
		pattern_cadence_max_mult = float(caps.get("pattern_cadence_max_mult", pattern_cadence_max_mult))
	rank = min_rank

func _process(delta: float) -> void:
	# Gradually increase rank over time
	rank = clamp(rank + time_rank_rate * delta, min_rank, max_rank)

func reset(new_stage: int) -> void:
	stage_number = new_stage
	# Slight bump per stage to keep late stages spicier even if ordered early
	rank = clamp(1.0 + (float(stage_number) - 1.0) * 0.05, min_rank, max_rank)

func on_enemy_killed(points: int) -> void:
	# Reward aggressive play with higher rank; points scale lightly
	rank = clamp(rank + kill_rank_rate * float(points), min_rank, max_rank)

func get_enemy_speed_multiplier() -> float:
	return lerp(1.0, enemy_speed_max_mult, _normalized_rank())

func get_enemy_hp_multiplier() -> float:
	return lerp(1.0, enemy_hp_max_mult, _normalized_rank())

func get_bullet_speed_multiplier() -> float:
	return lerp(1.0, bullet_speed_max_mult, _normalized_rank())

func get_pattern_density_multiplier() -> float:
	return lerp(1.0, pattern_density_max_mult, _normalized_rank())

func get_pattern_cadence_multiplier() -> float:
	return lerp(1.0, pattern_cadence_max_mult, _normalized_rank())

func _normalized_rank() -> float:
	if max_rank <= min_rank:
		return 0.0
	return clamp((rank - min_rank) / (max_rank - min_rank), 0.0, 1.0)


