extends Node

var DEBUG_LOGGING: bool = OS.is_debug_build()

# Centralized event system

# Game
signal player_hit
signal player_damaged(amount: int)
signal game_over
signal game_started
signal game_paused
signal game_resumed

# Player
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal bombs_changed(new_bombs: int)
signal player_invincibility_started
signal player_invincibility_ended

# Combat
signal enemy_killed(points: int, position: Vector2, enemy_type: String)
signal boss_defeated(boss_name: String, points: int)
signal bullet_hit_player(bullet_position: Vector2)
signal bullet_hit_enemy(enemy_position: Vector2, damage: int)
signal bomb_used(position: Vector2)

# Stage
signal stage_started(stage_number: int)
signal stage_completed(stage_number: int)
signal enemy_spawned(enemy: Node, enemy_type: String)
signal boss_spawned(boss: Node, boss_name: String)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# Items
signal item_dropped(item_type: String, position: Vector2)
signal item_collected(item_type: String, value: int) 

# Cho Ren Sha 68K
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
signal stage_transition_requested(stage_number: int, duration: float)
signal background_change_requested(background_type: String, tint: Color, ambient_lighting: float)
signal particle_effect_requested(effect_name: String, duration: float)

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
	if DEBUG_LOGGING:
		print("[EventBus] Event system initialized")
	# Connect to some basic events to demonstrate signal usage
	if DEBUG_LOGGING:
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
		
		# Connect visual effects signals
		screen_shake_requested.connect(_on_screen_shake_requested)
		hit_stop_requested.connect(_on_hit_stop_requested)
		flash_requested.connect(_on_flash_requested)
		explosion_requested.connect(_on_explosion_requested)
		stage_transition_requested.connect(_on_stage_transition_requested)
		background_change_requested.connect(_on_background_change_requested)
		particle_effect_requested.connect(_on_particle_effect_requested)
		
		# Connect audio signals
		play_sound.connect(_on_play_sound)
		play_music.connect(_on_play_music)
		stop_music.connect(_on_stop_music)

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
		"flash", "screen_flash":
			flash_requested.emit(params.get("color", Color.WHITE), params.get("duration", 0.1))
		"explosion":
			explosion_requested.emit(params.get("position", Vector2.ZERO), params.get("size", 1.0))
		"stage_transition":
			stage_transition_requested.emit(params.get("stage_number", 1), params.get("duration", 1.0))
		"background_change":
			background_change_requested.emit(
				params.get("background_type", "space"),
				params.get("tint", Color.WHITE),
				params.get("ambient_lighting", 1.0)
			)
		"particle_effect":
			particle_effect_requested.emit(params.get("effect_name", ""), params.get("duration", -1.0))

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
	if DEBUG_LOGGING:
		print("[EventBus] Player hit event received")

func _on_game_over() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Game over event received")

func _on_game_started() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Game started event received")

func _on_game_paused() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Game paused event received")

func _on_game_resumed() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Game resumed event received")

func _on_lives_changed(new_lives: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Lives changed to: ", new_lives)

func _on_bombs_changed(new_bombs: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Bombs changed to: ", new_bombs)

func _on_player_invincibility_started() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Player invincibility started")

func _on_player_invincibility_ended() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Player invincibility ended")

func _on_bullet_hit_player(bullet_position: Vector2) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Bullet hit player at: ", bullet_position)

func _on_bullet_hit_enemy(enemy_position: Vector2, damage: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Bullet hit enemy at: ", enemy_position, " for ", damage, " damage")

func _on_bomb_used(position: Vector2) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Bomb used at: ", position)

func _on_stage_started(stage_number: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Stage started: ", stage_number)

func _on_stage_completed(stage_number: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Stage completed: ", stage_number)

func _on_enemy_spawned(_enemy: Node, enemy_type: String) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Enemy spawned: ", enemy_type)

func _on_boss_spawned(_boss: Node, boss_name: String) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Boss spawned: ", boss_name)

func _on_wave_started(wave_number: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Wave started: ", wave_number)

func _on_wave_completed(wave_number: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Wave completed: ", wave_number)

func _on_item_dropped(item_type: String, position: Vector2) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Item dropped: ", item_type, " at ", position)

func _on_item_collected(item_type: String, value: int) -> void:
	if DEBUG_LOGGING:
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
	if DEBUG_LOGGING:
		print("[EventBus] Rank changed to: ", new_rank)

func _on_streak_changed(current: int, max_streak: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Streak changed: ", current, "/", max_streak)

func _on_entity_spawned(_entity: Node, entity_type: String) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Entity spawned: ", entity_type)

func _on_entity_destroyed(_entity: Node, entity_type: String) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Entity destroyed: ", entity_type)

# Cho Ren Sha 68K Event Handlers
func _on_shield_gained() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Shield gained")

func _on_shield_lost() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Shield lost")

func _on_shield_absorbed() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Shield absorbed")

func _on_weapon_power_changed(new_power: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Weapon power changed to: ", new_power)

func _on_loop_incremented(new_loop: int) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Loop incremented to: ", new_loop)

func _on_life_extended(reason: String) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Life extended: ", reason)

func _on_fire_rate_boost_activated(duration: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Fire rate boost activated for ", duration, " seconds")

func _on_fire_rate_boost_ended() -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Fire rate boost ended")

# Visual Effects Event Handlers
func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Screen shake requested: intensity=", intensity, " duration=", duration)

func _on_hit_stop_requested(duration: float, scale: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Hit stop requested: duration=", duration, " scale=", scale)

func _on_flash_requested(color: Color, duration: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Flash requested: color=", color, " duration=", duration)

func _on_explosion_requested(position: Vector2, size: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Explosion requested: position=", position, " size=", size)

func _on_stage_transition_requested(stage_number: int, duration: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Stage transition requested: stage=", stage_number, " duration=", duration)

func _on_background_change_requested(background_type: String, tint: Color, ambient_lighting: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Background change requested: type=", background_type, " tint=", tint, " ambient=", ambient_lighting)

func _on_particle_effect_requested(effect_name: String, duration: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Particle effect requested: ", effect_name, " duration=", duration)

# Audio Event Handlers
func _on_play_sound(sound_name: String, volume: float) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Play sound: ", sound_name, " volume=", volume)

func _on_play_music(music_name: String, fade_in: bool) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Play music: ", music_name, " fade_in=", fade_in)

func _on_stop_music(fade_out: bool) -> void:
	if DEBUG_LOGGING:
		print("[EventBus] Stop music: fade_out=", fade_out)

func _exit_tree() -> void:
	"""Clean up signal connections to prevent memory leaks"""
	# Disconnect all internal signal connections
	if player_hit.is_connected(_on_player_hit):
		player_hit.disconnect(_on_player_hit)
	if game_over.is_connected(_on_game_over):
		game_over.disconnect(_on_game_over)
	if game_started.is_connected(_on_game_started):
		game_started.disconnect(_on_game_started)
	if game_paused.is_connected(_on_game_paused):
		game_paused.disconnect(_on_game_paused)
	if game_resumed.is_connected(_on_game_resumed):
		game_resumed.disconnect(_on_game_resumed)
	if lives_changed.is_connected(_on_lives_changed):
		lives_changed.disconnect(_on_lives_changed)
	if bombs_changed.is_connected(_on_bombs_changed):
		bombs_changed.disconnect(_on_bombs_changed)
	if player_invincibility_started.is_connected(_on_player_invincibility_started):
		player_invincibility_started.disconnect(_on_player_invincibility_started)
	if player_invincibility_ended.is_connected(_on_player_invincibility_ended):
		player_invincibility_ended.disconnect(_on_player_invincibility_ended)
	if bullet_hit_player.is_connected(_on_bullet_hit_player):
		bullet_hit_player.disconnect(_on_bullet_hit_player)
	if bullet_hit_enemy.is_connected(_on_bullet_hit_enemy):
		bullet_hit_enemy.disconnect(_on_bullet_hit_enemy)
	if bomb_used.is_connected(_on_bomb_used):
		bomb_used.disconnect(_on_bomb_used)
	if stage_started.is_connected(_on_stage_started):
		stage_started.disconnect(_on_stage_started)
	if stage_completed.is_connected(_on_stage_completed):
		stage_completed.disconnect(_on_stage_completed)
	if enemy_spawned.is_connected(_on_enemy_spawned):
		enemy_spawned.disconnect(_on_enemy_spawned)
	if boss_spawned.is_connected(_on_boss_spawned):
		boss_spawned.disconnect(_on_boss_spawned)
	if wave_started.is_connected(_on_wave_started):
		wave_started.disconnect(_on_wave_started)
	if wave_completed.is_connected(_on_wave_completed):
		wave_completed.disconnect(_on_wave_completed)
	if item_dropped.is_connected(_on_item_dropped):
		item_dropped.disconnect(_on_item_dropped)
	if item_collected.is_connected(_on_item_collected):
		item_collected.disconnect(_on_item_collected)
	if input_movement.is_connected(_on_input_movement):
		input_movement.disconnect(_on_input_movement)
	if input_shoot.is_connected(_on_input_shoot):
		input_shoot.disconnect(_on_input_shoot)
	if input_bomb.is_connected(_on_input_bomb):
		input_bomb.disconnect(_on_input_bomb)
	if input_pause.is_connected(_on_input_pause):
		input_pause.disconnect(_on_input_pause)
	if rank_changed.is_connected(_on_rank_changed):
		rank_changed.disconnect(_on_rank_changed)
	if streak_changed.is_connected(_on_streak_changed):
		streak_changed.disconnect(_on_streak_changed)
	if entity_spawned.is_connected(_on_entity_spawned):
		entity_spawned.disconnect(_on_entity_spawned)
	if entity_destroyed.is_connected(_on_entity_destroyed):
		entity_destroyed.disconnect(_on_entity_destroyed)
	
	# Disconnect Cho Ren Sha 68K signals
	if shield_gained.is_connected(_on_shield_gained):
		shield_gained.disconnect(_on_shield_gained)
	if shield_lost.is_connected(_on_shield_lost):
		shield_lost.disconnect(_on_shield_lost)
	if shield_absorbed.is_connected(_on_shield_absorbed):
		shield_absorbed.disconnect(_on_shield_absorbed)
	if weapon_power_changed.is_connected(_on_weapon_power_changed):
		weapon_power_changed.disconnect(_on_weapon_power_changed)
	if loop_incremented.is_connected(_on_loop_incremented):
		loop_incremented.disconnect(_on_loop_incremented)
	if life_extended.is_connected(_on_life_extended):
		life_extended.disconnect(_on_life_extended)
	if fire_rate_boost_activated.is_connected(_on_fire_rate_boost_activated):
		fire_rate_boost_activated.disconnect(_on_fire_rate_boost_activated)
	if fire_rate_boost_ended.is_connected(_on_fire_rate_boost_ended):
		fire_rate_boost_ended.disconnect(_on_fire_rate_boost_ended)
	
	# Disconnect visual effects signals
	if screen_shake_requested.is_connected(_on_screen_shake_requested):
		screen_shake_requested.disconnect(_on_screen_shake_requested)
	if hit_stop_requested.is_connected(_on_hit_stop_requested):
		hit_stop_requested.disconnect(_on_hit_stop_requested)
	if flash_requested.is_connected(_on_flash_requested):
		flash_requested.disconnect(_on_flash_requested)
	if explosion_requested.is_connected(_on_explosion_requested):
		explosion_requested.disconnect(_on_explosion_requested)
	
	# Disconnect audio signals
	if play_sound.is_connected(_on_play_sound):
		play_sound.disconnect(_on_play_sound)
	if play_music.is_connected(_on_play_music):
		play_music.disconnect(_on_play_music)
	if stop_music.is_connected(_on_stop_music):
		stop_music.disconnect(_on_stop_music)
