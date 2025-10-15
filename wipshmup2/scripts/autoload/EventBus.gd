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

# Cho Ren Sha 68K Events
# These signals are used by HUD and other systems - not unused
signal shield_gained
signal shield_lost
signal shield_absorbed
signal weapon_power_changed(new_power: int)
signal loop_incremented(new_loop: int)
signal life_extended(reason: String)
signal fire_rate_boost_activated(duration: float)
signal fire_rate_boost_ended

# Visual Effects Events
signal screen_shake_requested(intensity: float, duration: float)
signal hit_stop_requested(duration: float, scale: float)
signal flash_requested(color: Color, duration: float)
signal explosion_requested(position: Vector2, size: float)

# Audio Events
signal play_sound(sound_name: String, volume: float)
signal play_music(music_name: String, fade_in: bool)
signal stop_music(fade_out: bool)

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
	# Connect to some basic events to demonstrate signal usage
	player_hit.connect(_on_player_hit)
	game_over.connect(_on_game_over)
	game_started.connect(_on_game_started)
	game_paused.connect(_on_game_paused)
	game_resumed.connect(_on_game_resumed)
	lives_changed.connect(_on_lives_changed)
	bombs_changed.connect(_on_bombs_changed)
	player_invincibility_started.connect(_on_player_invincibility_started)
	player_invincibility_ended.connect(_on_player_invincibility_ended)
	bullet_hit_player.connect(_on_bullet_hit_player)
	bullet_hit_enemy.connect(_on_bullet_hit_enemy)
	bomb_used.connect(_on_bomb_used)
	stage_started.connect(_on_stage_started)
	stage_completed.connect(_on_stage_completed)
	enemy_spawned.connect(_on_enemy_spawned)
	boss_spawned.connect(_on_boss_spawned)
	wave_started.connect(_on_wave_started)
	wave_completed.connect(_on_wave_completed)
	item_dropped.connect(_on_item_dropped)
	item_collected.connect(_on_item_collected)
	input_movement.connect(_on_input_movement)
	input_shoot.connect(_on_input_shoot)
	input_bomb.connect(_on_input_bomb)
	input_pause.connect(_on_input_pause)
	rank_changed.connect(_on_rank_changed)
	streak_changed.connect(_on_streak_changed)
	entity_spawned.connect(_on_entity_spawned)
	entity_destroyed.connect(_on_entity_destroyed)
	
	# Connect Cho Ren Sha 68K signals for basic logging
	shield_gained.connect(_on_shield_gained)
	shield_lost.connect(_on_shield_lost)
	shield_absorbed.connect(_on_shield_absorbed)
	weapon_power_changed.connect(_on_weapon_power_changed)
	loop_incremented.connect(_on_loop_incremented)
	life_extended.connect(_on_life_extended)
	fire_rate_boost_activated.connect(_on_fire_rate_boost_activated)
	fire_rate_boost_ended.connect(_on_fire_rate_boost_ended)

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

# Convenience methods for audio signals with defaults
func play_sound_with_defaults(sound_name: String, volume: float = 1.0) -> void:
	play_sound.emit(sound_name, volume)

func play_music_with_defaults(music_name: String, fade_in: bool = true) -> void:
	play_music.emit(music_name, fade_in)

func stop_music_with_defaults(fade_out: bool = true) -> void:
	stop_music.emit(fade_out)

# Event handlers to demonstrate signal usage
func _on_player_hit() -> void:
	print("[EventBus] Player hit event received")

func _on_game_over() -> void:
	print("[EventBus] Game over event received")

func _on_game_started() -> void:
	print("[EventBus] Game started event received")

func _on_game_paused() -> void:
	print("[EventBus] Game paused event received")

func _on_game_resumed() -> void:
	print("[EventBus] Game resumed event received")

func _on_lives_changed(new_lives: int) -> void:
	print("[EventBus] Lives changed to: ", new_lives)

func _on_bombs_changed(new_bombs: int) -> void:
	print("[EventBus] Bombs changed to: ", new_bombs)

func _on_player_invincibility_started() -> void:
	print("[EventBus] Player invincibility started")

func _on_player_invincibility_ended() -> void:
	print("[EventBus] Player invincibility ended")

func _on_bullet_hit_player(bullet_position: Vector2) -> void:
	print("[EventBus] Bullet hit player at: ", bullet_position)

func _on_bullet_hit_enemy(enemy_position: Vector2, damage: int) -> void:
	print("[EventBus] Bullet hit enemy at: ", enemy_position, " for ", damage, " damage")

func _on_bomb_used(position: Vector2) -> void:
	print("[EventBus] Bomb used at: ", position)

func _on_stage_started(stage_number: int) -> void:
	print("[EventBus] Stage started: ", stage_number)

func _on_stage_completed(stage_number: int) -> void:
	print("[EventBus] Stage completed: ", stage_number)

func _on_enemy_spawned(_enemy: Node, enemy_type: String) -> void:
	print("[EventBus] Enemy spawned: ", enemy_type)

func _on_boss_spawned(_boss: Node, boss_name: String) -> void:
	print("[EventBus] Boss spawned: ", boss_name)

func _on_wave_started(wave_number: int) -> void:
	print("[EventBus] Wave started: ", wave_number)

func _on_wave_completed(wave_number: int) -> void:
	print("[EventBus] Wave completed: ", wave_number)

func _on_item_dropped(item_type: String, position: Vector2) -> void:
	print("[EventBus] Item dropped: ", item_type, " at ", position)

func _on_item_collected(item_type: String, value: int) -> void:
	print("[EventBus] Item collected: ", item_type, " value: ", value)

func _on_input_movement(_direction: Vector2) -> void:
	# Input events are typically handled by input systems
	pass

func _on_input_shoot(_pressed: bool) -> void:
	# Input events are typically handled by input systems
	pass

func _on_input_bomb(_pressed: bool) -> void:
	# Input events are typically handled by input systems
	pass

func _on_input_pause(_pressed: bool) -> void:
	# Input events are typically handled by input systems
	pass

func _on_rank_changed(new_rank: float) -> void:
	print("[EventBus] Rank changed to: ", new_rank)

func _on_streak_changed(current: int, max_streak: int) -> void:
	print("[EventBus] Streak changed: ", current, "/", max_streak)

func _on_entity_spawned(_entity: Node, entity_type: String) -> void:
	print("[EventBus] Entity spawned: ", entity_type)

func _on_entity_destroyed(_entity: Node, entity_type: String) -> void:
	print("[EventBus] Entity destroyed: ", entity_type)

# Cho Ren Sha 68K Event Handlers
func _on_shield_gained() -> void:
	print("[EventBus] Shield gained")

func _on_shield_lost() -> void:
	print("[EventBus] Shield lost")

func _on_shield_absorbed() -> void:
	print("[EventBus] Shield absorbed")

func _on_weapon_power_changed(new_power: int) -> void:
	print("[EventBus] Weapon power changed to: ", new_power)

func _on_loop_incremented(new_loop: int) -> void:
	print("[EventBus] Loop incremented to: ", new_loop)

func _on_life_extended(reason: String) -> void:
	print("[EventBus] Life extended: ", reason)

func _on_fire_rate_boost_activated(duration: float) -> void:
	print("[EventBus] Fire rate boost activated for ", duration, " seconds")

func _on_fire_rate_boost_ended() -> void:
	print("[EventBus] Fire rate boost ended")
