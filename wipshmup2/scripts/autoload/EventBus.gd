extends Node

# EventBus - Centralized event system for the shmup game
# Replaces scattered signal connections with a clean event-driven architecture

# Game Events
signal player_hit
signal player_damaged(amount: int)
signal game_over
signal game_started
signal game_paused
signal game_resumed

# Player State Events
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal bombs_changed(new_bombs: int)
signal player_invincibility_started
signal player_invincibility_ended

# Combat Events
signal enemy_killed(points: int, position: Vector2, enemy_type: String)
signal boss_defeated(boss_name: String, points: int)
signal bullet_hit_player(bullet_position: Vector2)
signal bullet_hit_enemy(enemy_position: Vector2, damage: int)
signal bomb_used(position: Vector2)

# Stage Events
signal stage_started(stage_number: int)
signal stage_completed(stage_number: int)
signal enemy_spawned(enemy: Node, enemy_type: String)
signal boss_spawned(boss: Node, boss_name: String)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# Item Events
signal item_dropped(item_type: String, position: Vector2)
signal item_collected(item_type: String, value: int)

# Visual Effects Events
signal screen_shake_requested(intensity: float, duration: float)
signal hit_stop_requested(duration: float, scale: float)
signal flash_requested(color: Color, duration: float)
signal explosion_requested(position: Vector2, size: float)

# Audio Events
signal play_sound(sound_name: String, volume: float = 1.0)
signal play_music(music_name: String, fade_in: bool = true)
signal stop_music(fade_out: bool = true)

# Input Events
signal input_movement(direction: Vector2)
signal input_shoot(pressed: bool)
signal input_bomb(pressed: bool)
signal input_pause(pressed: bool)

# Rank/Progress Events
signal rank_changed(new_rank: float)
signal streak_changed(current: int, max_streak: int)
signal chain_broken

# Utility Events
signal entity_spawned(entity: Node, entity_type: String)
signal entity_destroyed(entity: Node, entity_type: String)

func _ready() -> void:
	print("[EventBus] Event system initialized")

# Convenience methods for common event patterns
func emit_player_damage(amount: int) -> void:
	player_damaged.emit(amount)
	if amount > 0:
		chain_broken.emit()

func emit_enemy_kill(points: int, position: Vector2, enemy_type: String = "enemy") -> void:
	enemy_killed.emit(points, position, enemy_type)
	score_changed.emit(GameState.score + points)

func emit_boss_defeat(boss_name: String, points: int) -> void:
	boss_defeated.emit(boss_name, points)
	score_changed.emit(GameState.score + points)

func emit_visual_effect(effect_type: String, params: Dictionary) -> void:
	match effect_type:
		"screen_shake":
			screen_shake_requested.emit(params.get("intensity", 1.0), params.get("duration", 0.1))
		"hit_stop":
			hit_stop_requested.emit(params.get("duration", 0.05), params.get("scale", 1.0))
		"flash":
			flash_requested.emit(params.get("color", Color.WHITE), params.get("duration", 0.1))
		"explosion":
			explosion_requested.emit(params.get("position", Vector2.ZERO), params.get("size", 1.0))

func emit_audio(sound_type: String, params: Dictionary = {}) -> void:
	match sound_type:
		"player_shot":
			play_sound.emit("player_shot", params.get("volume", 0.3))
		"enemy_shot":
			play_sound.emit("enemy_shot", params.get("volume", 0.25))
		"enemy_death":
			play_sound.emit("enemy_death", params.get("volume", 0.4))
		"player_hit":
			play_sound.emit("player_hit", params.get("volume", 0.6))
		"bomb_use":
			play_sound.emit("bomb_use", params.get("volume", 0.5))
		"boss_hit":
			play_sound.emit("boss_hit", params.get("volume", 0.5))
