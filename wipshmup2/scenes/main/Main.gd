extends Node2D

# Scene references
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/StageController.gd")
const SPACE_BACKGROUND_SCRIPT: Script = preload("res://scripts/SpaceBackground.gd")
const ITEM_DROP_MANAGER_SCRIPT: Script = preload("res://scripts/ItemDropManager.gd")

var player: Node
var hud: Node
var stage_controller: StageController
var space_background: Node
var item_drop_manager: Node
var bgm_player: AudioStreamPlayer

var game_over := false
var lives := 3
var bombs := 3
var score := 0

# Rank pressure system
var rank_manager: Node
var base_background_color: Color = Color.WHITE

# Streak system for kills (used to scale screen shake)
var chain_count: int = 0
var max_chain: int = 0
var last_kill_time_s: float = 0.0
var chain_timeout: float = 2.0

var shot_cooldown := 0.1
var bullet_timer: Timer
var player_hurtbox: Area2D
var game_viewport: Node
var screen_shake: Node

func _ready() -> void:
	add_to_group("game")

	RenderingServer.set_default_clear_color(Color(0.02, 0.02, 0.05))

	bullet_timer = Timer.new()
	bullet_timer.wait_time = shot_cooldown
	bullet_timer.one_shot = true
	add_child(bullet_timer)

	game_viewport = $GameViewport if has_node("GameViewport") else self

	_setup_background()
	_setup_item_drops()
	_spawn_player()
	_setup_stage_controller()

	# Screen shake hooked to the game viewport root so all children move together
	screen_shake = load("res://scripts/ScreenShake.gd").new()
	add_child(screen_shake)
	var target_2d: Node2D = game_viewport if game_viewport is Node2D else self
	screen_shake.set_target(target_2d)

	hud = $HUD
	_update_score_label()
	_update_lives_display()
	_update_bomb_display()
	
	# Setup rank pressure system
	_setup_rank_pressure_system()

func _setup_background() -> void:
	space_background = game_viewport.get_node_or_null("SpaceBackground") if game_viewport else null
	if space_background and space_background.get_script() == SPACE_BACKGROUND_SCRIPT:
		pass
	else:
		_create_simple_starfield()
		space_background = null

func _create_simple_starfield() -> void:
	var starfield = Node2D.new()
	starfield.name = "SimpleStarfield"
	var container = game_viewport if game_viewport else self
	container.add_child(starfield)
	container.move_child(starfield, 0)

	for i in range(80):
		var star = ColorRect.new()
		star.size = Vector2(1, 1)
		star.color = Color(0.7 + randf() * 0.3, 0.7 + randf() * 0.3, 0.9, randf_range(0.4, 1.0))
		star.position = Vector2(randf() * 320, randf() * 180)
		starfield.add_child(star)

func _setup_item_drops() -> void:
	item_drop_manager = ITEM_DROP_MANAGER_SCRIPT.new()
	add_child(item_drop_manager)
	item_drop_manager.item_collected.connect(_on_item_collected)

func _setup_stage_controller() -> void:
	stage_controller = STAGE_CONTROLLER_SCRIPT.new()
	var container = game_viewport if game_viewport else self
	container.add_child(stage_controller)

	stage_controller.enemy_killed.connect(_on_enemy_killed)
	if stage_controller.has_signal("boss_defeated"):
		stage_controller.boss_defeated.connect(_on_boss_defeated)
	if stage_controller.has_signal("enemy_spawned"):
		stage_controller.enemy_spawned.connect(_on_enemy_spawned)
	
	# Monitor for boss spawns to show health bar
	_start_boss_monitoring()

	stage_controller.start_run()

	# Connect any bullets that already exist in the scene (e.g. preloaded tutorials)
	for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		_connect_enemy_bullet(bullet)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(160, 150)
	var container = game_viewport if game_viewport else self
	container.add_child(player)

	player_hurtbox = player.get_node_or_null("Hurtbox")
	if player_hurtbox:
		player_hurtbox.add_to_group("player_hurtbox")
		player_hurtbox.monitoring = true
		player_hurtbox.monitorable = true
		player_hurtbox.collision_layer = 1
		player_hurtbox.collision_mask = 1
	else:
		player_hurtbox = Area2D.new()
		player_hurtbox.name = "Hurtbox"
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = CircleShape2D.new()
		(collision_shape.shape as CircleShape2D).radius = 6.0
		player_hurtbox.add_child(collision_shape)
		player.add_child(player_hurtbox)
		player_hurtbox.add_to_group("player_hurtbox")
		player_hurtbox.monitoring = true
		player_hurtbox.monitorable = true
		player_hurtbox.collision_layer = 1
		player_hurtbox.collision_mask = 1

	if player.has_signal("damaged"):
		player.connect("damaged", Callable(self, "_on_player_damaged"))
	if player.has_signal("hit"):
		player.connect("hit", Callable(self, "_on_player_hit"))

func _process(delta: float) -> void:
	# Handle game over restart in _process (UI-related)
	if game_over and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
		return
	
	# Apply rank pressure system
	if not game_over:
		_apply_rank_pressure(delta)

func _physics_process(delta: float) -> void:
	# Skip physics if game is over
	if game_over:
		return
	
	# Player movement - handled in physics process for consistent timing
	if player and is_instance_valid(player):
		var input_vector := Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		player.position += input_vector * 200.0 * delta
		player.position.x = clamp(player.position.x, 16.0, 304.0)
		player.position.y = clamp(player.position.y, 16.0, 164.0)

	# Player shooting
	if Input.is_key_pressed(KEY_SPACE) and player and is_instance_valid(player):
		if bullet_timer.is_stopped():
			_fire_bullet()
			bullet_timer.start()

	# Bomb usage
	if Input.is_action_just_pressed("ui_cancel") and bombs > 0:
		_use_bomb()

func _update_score_label() -> void:
	if is_instance_valid(hud):
		hud.call("set_score", score)

func _update_lives_display() -> void:
	if is_instance_valid(hud):
		hud.call("set_lives", lives)

func _update_bomb_display() -> void:
	if is_instance_valid(hud):
		hud.call("set_bombs", bombs)

func _on_enemy_killed(points: int, enemy_position: Vector2) -> void:
	"""Handle enemy killed event"""
	score += points
	_update_score_label()

	# Update streak (chain) based on time between kills
	var now_s := float(Time.get_ticks_msec()) / 1000.0
	if last_kill_time_s > 0.0 and (now_s - last_kill_time_s) <= chain_timeout:
		chain_count += 1
	else:
		chain_count = 1
	last_kill_time_s = now_s
	max_chain = max(max_chain, chain_count)
	if is_instance_valid(hud) and hud.has_method("set_chain"):
		hud.set_chain(chain_count, max_chain)
	if is_instance_valid(screen_shake):
		screen_shake.shake(2.0, 0.06)

	# Try to drop items when enemies are killed using actual enemy position
	if item_drop_manager:
		item_drop_manager.try_drop_item(enemy_position, points)

	# Screen shake: low base intensity, scaled logarithmically by streak
	if is_instance_valid(screen_shake):
		var shake_mult := _get_shake_scale_from_streak()
		screen_shake.shake(0.5 * shake_mult, 0.05)

func _on_boss_defeated() -> void:
	"""Handle boss defeated event"""
	var boss_score = 10000
	score += boss_score
	_update_score_label()
	if is_instance_valid(screen_shake):
		var shake_mult := _get_shake_scale_from_streak()
		screen_shake.shake(1.5 * shake_mult, 0.22)

func _on_item_collected(item_type: String, value: int) -> void:
	"""Handle item collection"""
	match item_type:
		"SCORE_SMALL", "SCORE_LARGE":
			score += value
			_update_score_label()
		"LIFE_EXTEND":
			lives += 1
			_update_lives_display()
		"BOMB":
			bombs += 1
			_update_bomb_display()
		"POWER_UP", "SHIELD":
			# Handle power-up effects here
			pass

func _fire_bullet() -> void:
	"""Fire a bullet from the player"""
	if not player or not is_instance_valid(player):
		return

	# Load bullet scene
	const BULLET_SCENE: PackedScene = preload("res://scenes/bullet/Bullet.tscn")
	var bullet = BULLET_SCENE.instantiate()

	# Position bullet at player position
	bullet.position = player.position + Vector2(0, -10)

	# Add to bullets container
	var bullets_container = $GameViewport/Bullets
	if bullets_container:
		bullets_container.add_child(bullet)
	else:
		add_child(bullet)

func _use_bomb() -> void:
	"""Use a bomb to clear enemies"""
	if bombs <= 0:
		return

	bombs -= 1
	_update_bomb_display()

	# Destroy all enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			# Award points for bomb kills
			if enemy.has_method("take_damage"):
				enemy.take_damage(999, "bomb")
			elif enemy.has_method("die"):
				enemy.die()
			else:
				enemy.queue_free()

	if is_instance_valid(screen_shake):
		var shake_mult := _get_shake_scale_from_streak()
		screen_shake.shake(1.2 * shake_mult, 0.16)

func _on_player_damaged(amount: int) -> void:
	if game_over:
		return
	lives -= amount
	lives = max(lives, 0)
	_update_lives_display()
	# Damage causes a subtle shake; still scaled by current streak for feedback
	if is_instance_valid(screen_shake):
		var shake_mult := _get_shake_scale_from_streak()
		screen_shake.shake(0.9 * shake_mult, 0.10)

	# Breaking the streak on damage feels fair; reset chain and update HUD
	chain_count = 0
	if is_instance_valid(hud) and hud.has_method("set_chain"):
		hud.set_chain(0, max_chain)
	if lives <= 0:
		_on_player_hit()

func _on_player_hit() -> void:
	if game_over:
		return
	game_over = true
	_update_lives_display()
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over(true)

func _on_enemy_spawned(enemy: Area2D) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_signal("hit_player") and not enemy.is_connected("hit_player", Callable(self, "_on_enemy_hit_player")):
		enemy.connect("hit_player", Callable(self, "_on_enemy_hit_player"))

	var connect_child := func(node: Node):
		if node.is_in_group("enemy_bullet"):
			_connect_enemy_bullet(node)

	if not enemy.is_connected("child_entered_tree", connect_child):
		enemy.child_entered_tree.connect(connect_child)

func _connect_enemy_bullet(bullet: Area2D) -> void:
	if not bullet or not is_instance_valid(bullet):
		return
	if bullet.has_signal("hit_player"):
		# Avoid duplicate connections
		if not bullet.is_connected("hit_player", Callable(self, "_on_enemy_hit_player")):
			bullet.connect("hit_player", Callable(self, "_on_enemy_hit_player"))
	else:
		if not bullet.body_entered.is_connected(Callable(self, "_on_enemy_bullet_body_entered")):
			bullet.body_entered.connect(Callable(self, "_on_enemy_bullet_body_entered"))

func _on_enemy_bullet_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.is_in_group("player_hurtbox"):
		_on_enemy_hit_player()

func _on_enemy_hit_player() -> void:
	_on_player_damaged(1)

func _get_shake_scale_from_streak() -> float:
	# Logarithmic scale: 1 + k * ln(1 + streak)
	var k: float = 0.18
	var streak: float = float(chain_count)
	return 1.0 + k * log(1.0 + max(streak, 0.0))

func _start_boss_monitoring() -> void:
	"""Monitor for boss spawns and connect to HUD"""
	# Check periodically for new bosses
	var check_timer = Timer.new()
	check_timer.wait_time = 0.5
	check_timer.autostart = true
	check_timer.timeout.connect(_check_for_bosses)
	add_child(check_timer)

func _check_for_bosses() -> void:
	"""Check if a boss has spawned and show health bar"""
	if game_over:
		return
	
	var bosses = get_tree().get_nodes_in_group("boss")
	for boss in bosses:
		if is_instance_valid(boss) and not boss.has_meta("health_bar_shown"):
			# Mark this boss as having its health bar shown
			boss.set_meta("health_bar_shown", true)
			
			# Show the boss health bar
			if is_instance_valid(hud) and hud.has_method("show_boss_health"):
				hud.show_boss_health(boss)
			
			# Connect to boss defeated signal to hide health bar
			if boss.has_signal("defeated"):
				boss.defeated.connect(_on_boss_health_depleted.bind(boss))

func _on_boss_health_depleted(_boss: Node) -> void:
	"""Handle when a boss is defeated"""
	if is_instance_valid(hud) and hud.has_method("hide_boss_health"):
		hud.hide_boss_health()

func _setup_rank_pressure_system() -> void:
	"""Initialize the rank pressure system"""
	# Get RankManager reference
	rank_manager = get_node_or_null("/root/RankManager")
	
	# Get BGM player and register it with AudioManager
	bgm_player = get_node_or_null("BGM")
	if bgm_player:
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("set_music_player"):
			audio_manager.set_music_player(bgm_player)
	
	# Store base background color
	if is_instance_valid(space_background):
		base_background_color = space_background.modulate

func _apply_rank_pressure(delta: float) -> void:
	"""Apply visual and audio pressure based on rank"""
	if not rank_manager or not rank_manager.has_method("get_multiplier"):
		return
	
	# Calculate danger level (0.0 to 1.0)
	var min_rank: float = rank_manager.min_rank
	var max_rank: float = rank_manager.max_rank
	var current_rank: float = rank_manager.rank
	var danger_level: float = clamp((current_rank - min_rank) / (max_rank - min_rank), 0.0, 1.0)
	
	# Visual pressure - background color modulation
	if is_instance_valid(space_background) and danger_level > 0.7:
		var pressure_color = Color(1.2, 0.9, 0.9)  # Reddish tint
		space_background.modulate = base_background_color.lerp(pressure_color, (danger_level - 0.7) / 0.3)
	elif is_instance_valid(space_background):
		# Smoothly return to base color when danger is low
		space_background.modulate = space_background.modulate.lerp(base_background_color, delta * 2.0)
	
	# Visual pressure - subtle continuous shake at high rank
	if is_instance_valid(screen_shake) and danger_level > 0.7:
		var shake_intensity = 2.0 * ((danger_level - 0.7) / 0.3)
		screen_shake.shake(shake_intensity, 0.1)
	
	# Audio pressure - music pitch increases with danger
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_music_pitch"):
		var target_pitch = lerp(1.0, 1.15, danger_level)
		audio_manager.set_music_pitch(target_pitch)
