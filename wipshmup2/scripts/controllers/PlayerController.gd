extends Node

# PlayerController - Handles player input and movement
# Extracted from Main.gd to separate concerns

var player: Node
var bullet_timer: Timer
var is_initialized: bool = false

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)
	EventBus.player_damaged.connect(_on_player_damaged)
	bullet_timer = Timer.new()
	bullet_timer.wait_time = GameState.shot_cooldown
	bullet_timer.one_shot = true
	add_child(bullet_timer)
	EventBus.fire_rate_boost_activated.connect(_on_fire_rate_boost_activated)
	EventBus.fire_rate_boost_ended.connect(_on_fire_rate_boost_ended)
func initialize(player_node: Node) -> void:
	player = player_node
	is_initialized = true
	print("[PlayerController] Player controller initialized")
func _process(delta: float) -> void:
	if not is_initialized or not GameState.is_game_active():
		return
	_handle_movement(delta)
	_handle_shooting()
	_handle_bomb()
	_handle_debug_input()
func _handle_movement(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var new_position = player.position + input_vector * GameState.player_speed * delta
	GameState.update_player_position(new_position)
	player.position = GameState.player_position
	
	# Emit movement event
	if input_vector.length() > 0:
		EventBus.input_movement.emit(input_vector)

func _handle_shooting() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Check if player can shoot
	if Input.is_key_pressed(KEY_SPACE) and GameState.can_shoot():
		_fire_bullet()
		GameState.record_shot()
		bullet_timer.start()
		EventBus.input_shoot.emit(true)
		EventBus.emit_audio("player_shot")

func _handle_bomb() -> void:
	if Input.is_action_just_pressed("bomb"):
		if GameState.use_bomb():
			EventBus.input_bomb.emit(true)
			_use_bomb()

func _handle_debug_input() -> void:
	# Debug input handling (only in debug builds)
	if OS.is_debug_build():
		# Debug: Press F key to spawn triangle item
		if Input.is_key_pressed(KEY_F):
			print("[PlayerController] DEBUG: Spawning triangle item")
			ItemDropManager.force_spawn_triangle_at_player()

func _fire_bullet() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Use EntityFactory to spawn bullet
	var bullet_position = player.position + Vector2(0, -10)
	EntityFactory.spawn_player_bullet(bullet_position, Vector2.UP, 400.0)

func _use_bomb() -> void:
	print("[PlayerController] BOMB USED! Remaining bombs: ", GameState.bombs)
	
	# Grant brief invincibility during bomb (Cho Ren Sha 68K mechanic)
	GameState.set_invincible(true)
	var bomb_invincibility_timer = Timer.new()
	bomb_invincibility_timer.wait_time = 0.5
	bomb_invincibility_timer.one_shot = true
	bomb_invincibility_timer.timeout.connect(func(): GameState.set_invincible(false))
	add_child(bomb_invincibility_timer)
	bomb_invincibility_timer.start()
	
	# Create visual flash effect
	EventBus.emit_visual_effect("flash", {
		"color": Color.WHITE,
		"duration": 0.3
	})
	
	# Destroy all enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	print("[PlayerController] Destroying ", enemies.size(), " enemies with bomb")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(999, "bomb")
			elif enemy.has_method("die"):
				enemy.die()
			else:
				enemy.queue_free()
	
	# Destroy all enemy bullets
	var bullets = get_tree().get_nodes_in_group("enemy_bullet")
	print("[PlayerController] Destroying ", bullets.size(), " enemy bullets with bomb")
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	
	# Screen shake for impact
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": 1.5,
		"duration": 0.25
	})
	
	EventBus.emit_audio("bomb_use")

func _on_game_started() -> void:
	# Reset any player-specific state
	pass

func _on_game_over() -> void:
	# Stop player input processing
	pass

func _on_player_damaged(_amount: int) -> void:
	# Handle player damage feedback
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": 0.9,
		"duration": 0.10
	})

func _on_fire_rate_boost_activated(_duration: float) -> void:
	"""Handle fire rate boost activation"""
	_update_fire_rate()

func _on_fire_rate_boost_ended() -> void:
	"""Handle fire rate boost ending"""
	_update_fire_rate()

func _update_fire_rate() -> void:
	"""Update bullet timer based on current fire rate multiplier"""
	var multiplier = GameState.get_fire_rate_multiplier()
	bullet_timer.wait_time = GameState.shot_cooldown / multiplier
	print("[PlayerController] Fire rate updated: multiplier = ", multiplier)
