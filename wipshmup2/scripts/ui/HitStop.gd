extends Node

# Deprecated HitStop: consolidated into ScreenShake

func trigger_hit_stop(duration: float = -1.0, intensity: float = 1.0) -> void:
	var screen_shake = get_node_or_null("/root/Main/ScreenShake")
	if screen_shake and screen_shake.has_method("trigger_hit_stop"):
		screen_shake.trigger_hit_stop(duration, intensity)

func trigger_boss_hit_stop() -> void:
	trigger_hit_stop(0.1, 1.0)

func trigger_player_death_stop() -> void:
	trigger_hit_stop(0.15, 1.0)
