extends Node

# GameState - Centralized game state management
# Replaces scattered state variables across Main.gd and other files

# Player State
var lives: int = 3
var bombs: int = 3
var score: int = 0
var player_invincible: bool = false
var player_position: Vector2 = Vector2(160, 150)

# Game Flow State
var game_over: bool = false
var game_paused: bool = false
var current_stage: int = 1
var current_wave: int = 0

# Streak System
var chain_count: int = 0
var max_chain: int = 0
var last_kill_time: float = 0.0
var chain_timeout: float = 2.0

# Game Configuration
var shot_cooldown: float = 0.1
var player_speed: float = 200.0
var screen_bounds: Rect2 = Rect2(16, 16, 288, 148)  # 320x180 with margins

# Internal state
var _last_shot_time: float = 0.0
var _game_start_time: float = 0.0

func _ready() -> void:
	print("[GameState] Game state system initialized")
	_game_start_time = Time.get_ticks_msec() / 1000.0

# Player State Management
func set_lives(new_lives: int) -> void:
	var old_lives = lives
	lives = max(0, new_lives)
	if lives != old_lives:
		EventBus.lives_changed.emit(lives)
		if lives <= 0:
			trigger_game_over()

func add_lives(amount: int) -> void:
	set_lives(lives + amount)

func take_lives(amount: int) -> void:
	set_lives(lives - amount)

func set_bombs(new_bombs: int) -> void:
	var old_bombs = bombs
	bombs = max(0, new_bombs)
	if bombs != old_bombs:
		EventBus.bombs_changed.emit(bombs)

func add_bombs(amount: int) -> void:
	set_bombs(bombs + amount)

func use_bomb() -> bool:
	if bombs > 0:
		set_bombs(bombs - 1)
		EventBus.bomb_used.emit(player_position)
		return true
	return false

func set_score(new_score: int) -> void:
	var old_score = score
	score = max(0, new_score)
	if score != old_score:
		EventBus.score_changed.emit(score)

func add_score(amount: int) -> void:
	set_score(score + amount)

# Player Invincibility
func set_invincible(invincible: bool) -> void:
	player_invincible = invincible
	if invincible:
		EventBus.player_invincibility_started.emit()
	else:
		EventBus.player_invincibility_ended.emit()

func is_invincible() -> bool:
	return player_invincible

# Game Flow Management
func start_game() -> void:
	game_over = false
	game_paused = false
	current_stage = 1
	current_wave = 0
	EventBus.game_started.emit()

func trigger_game_over() -> void:
	if not game_over:
		game_over = true
		EventBus.game_over.emit()

func pause_game() -> void:
	if not game_over:
		game_paused = true
		EventBus.game_paused.emit()

func resume_game() -> void:
	if not game_over:
		game_paused = false
		EventBus.game_resumed.emit()

func reset_game() -> void:
	lives = 3
	bombs = 3
	score = 0
	player_invincible = false
	game_over = false
	game_paused = false
	current_stage = 1
	current_wave = 0
	chain_count = 0
	max_chain = 0
	last_kill_time = 0.0
	_game_start_time = Time.get_ticks_msec() / 1000.0

# Streak System
func update_streak() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if last_kill_time > 0.0 and (current_time - last_kill_time) <= chain_timeout:
		chain_count += 1
	else:
		chain_count = 1
	
	last_kill_time = current_time
	max_chain = max(max_chain, chain_count)
	
	EventBus.streak_changed.emit(chain_count, max_chain)

func break_streak() -> void:
	chain_count = 0
	EventBus.chain_broken.emit()
	EventBus.streak_changed.emit(chain_count, max_chain)

# Stage Management
func set_stage(stage_number: int) -> void:
	current_stage = stage_number
	EventBus.stage_started.emit(stage_number)

func complete_stage() -> void:
	EventBus.stage_completed.emit(current_stage)
	current_stage += 1

func set_wave(wave_number: int) -> void:
	current_wave = wave_number
	EventBus.wave_started.emit(wave_number)

# Player Movement
func update_player_position(new_position: Vector2) -> void:
	# Clamp to screen bounds
	player_position.x = clamp(new_position.x, screen_bounds.position.x, screen_bounds.position.x + screen_bounds.size.x)
	player_position.y = clamp(new_position.y, screen_bounds.position.y, screen_bounds.position.y + screen_bounds.size.y)

func can_shoot() -> bool:
	if game_over or game_paused:
		return false
	
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - _last_shot_time) >= shot_cooldown

func record_shot() -> void:
	_last_shot_time = Time.get_ticks_msec() / 1000.0

# Utility
func get_game_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - _game_start_time

func is_game_active() -> bool:
	return not game_over and not game_paused

# Getters for external systems
func get_player_state() -> Dictionary:
	return {
		"lives": lives,
		"bombs": bombs,
		"score": score,
		"invincible": player_invincible,
		"position": player_position,
		"chain_count": chain_count,
		"max_chain": max_chain
	}

func get_game_state() -> Dictionary:
	return {
		"game_over": game_over,
		"game_paused": game_paused,
		"current_stage": current_stage,
		"current_wave": current_wave,
		"game_time": get_game_time()
	}
