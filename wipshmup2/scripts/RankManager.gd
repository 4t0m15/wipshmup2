extends Node

@export var min_rank: float = 1.0
@export var max_rank: float = 3.0
@export var time_rank_rate: float = 0.01
@export var kill_rank_rate: float = 0.0005
@export var shot_rank_rate: float = 0.000015

@export var bomb_use_rank_add: float = 0.06
@export var death_rank_drop: float = 0.22
@export var bullet_seal_rank_rate: float = 0.0002

var rank: float = 1.0
var stage_number: int = 1

# Max multiplier caps
var multipliers = {
	"enemy_speed": 1.8,
	"enemy_hp": 2.0,
	"bullet_speed": 1.7,
	"pattern_density": 2.0,
	"pattern_cadence": 1.0
}

func _ready() -> void:
	var dc := get_node_or_null("/root/DifficultyConfig")
	if dc and dc.has_method("get_rank_params"):
		var rp: Dictionary = dc.get_rank_params()
		min_rank = float(rp.get("min_rank", min_rank))
		max_rank = float(rp.get("max_rank", max_rank))
		time_rank_rate = float(rp.get("time_rank_rate", time_rank_rate))
		kill_rank_rate = float(rp.get("kill_rank_rate", kill_rank_rate))
	
	if dc and dc.has_method("get_multiplier_caps"):
		var caps: Dictionary = dc.get_multiplier_caps()
		multipliers.enemy_speed = float(caps.get("enemy_speed_max_mult", multipliers.enemy_speed))
		multipliers.enemy_hp = float(caps.get("enemy_hp_max_mult", multipliers.enemy_hp))
		multipliers.bullet_speed = float(caps.get("bullet_speed_max_mult", multipliers.bullet_speed))
		multipliers.pattern_density = float(caps.get("pattern_density_max_mult", multipliers.pattern_density))
		multipliers.pattern_cadence = float(caps.get("pattern_cadence_max_mult", multipliers.pattern_cadence))
	
	rank = min_rank

func _process(delta: float) -> void:
	rank = clamp(rank + time_rank_rate * delta, min_rank, max_rank)

func reset(new_stage: int) -> void:
	stage_number = new_stage
	rank = clamp(1.0 + (float(stage_number) - 1.0) * 0.05, min_rank, max_rank)

func on_enemy_killed(points: int) -> void:
	rank = clamp(rank + kill_rank_rate * float(points), min_rank, max_rank)

func on_shot_fired(multiplier: float = 1.0) -> void:
	rank = clamp(rank + shot_rank_rate * max(0.0, multiplier), min_rank, max_rank)



func on_bomb_used() -> void:
	rank = clamp(rank + bomb_use_rank_add, min_rank, max_rank)

func on_player_died(current_lives: int = 0) -> void:
	var life_factor: float = clamp(1.0 - 0.05 * float(max(current_lives - 1, 0)), 0.8, 1.0)
	rank = clamp(rank - death_rank_drop * life_factor, min_rank, max_rank)

func on_bullet_sealed() -> void:
	rank = clamp(rank + bullet_seal_rank_rate, min_rank, max_rank)

func get_rank_percent() -> float:
	return clamp((rank - min_rank) / (max_rank - min_rank), 0.0, 1.0) * 100.0

func get_multiplier(type: String) -> float:
	var max_mult = multipliers.get(type, 1.0)
	var normalized = clamp((rank - min_rank) / (max_rank - min_rank), 0.0, 1.0)
	return lerp(1.0, max_mult, normalized)

func get_enemy_speed_multiplier() -> float:
	return get_multiplier("enemy_speed")

func get_enemy_hp_multiplier() -> float:
	return get_multiplier("enemy_hp")

func get_bullet_speed_multiplier() -> float:
	return get_multiplier("bullet_speed")

func get_pattern_density_multiplier() -> float:
	return get_multiplier("pattern_density")

func get_pattern_cadence_multiplier() -> float:
	return get_multiplier("pattern_cadence")


