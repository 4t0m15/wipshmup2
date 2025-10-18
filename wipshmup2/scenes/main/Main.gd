extends Node2D

# Scene references
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/stages/StageController.gd")
const SPACE_BACKGROUND_SCRIPT: Script = preload("res://scripts/backgrounds/SpaceBackground.gd")
const ITEM_DROP_MANAGER_SCRIPT: Script = preload("res://scripts/core/ItemDropManager.gd")

var player: Node
var hud: Node
var stage_controller: StageController
var space_background: Node
var item_drop_manager: Node
var bgm_player: AudioStreamPlayer
var item_popup: Node

# Triangle item collection tracking
var _collected_items: Array[String] = []
var _collection_timer: Timer

var game_over := false
# Use GameState for all game state - remove local duplicates

# Rank pressure
var rank_manager: Node
var base_background_color: Color = Color.WHITE
var rank_pressure_system: Node

# Streak system now handled by GameState

var shot_cooldown := 0.1
var bullet_timer: Timer
var player_hurtbox: Area2D
var game_viewport: Node
var screen_shake: Node
var _perf_watchdog_timer: Timer
const MAX_ENEMY_BULLETS_ALLOWED: int = 400  # Increased from 160
const MAX_TOTAL_BULLETS_ALLOWED: int = 500  # Increased from 220

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
	_setup_game_mode()

	# Screen shake hooked to the game viewport root so all children move together
	screen_shake = get_node_or_null("ScreenShake")
	if not screen_shake:
		screen_shake = load("res://scripts/ui/ScreenShake.gd").new()
		add_child(screen_shake)
		var target_2d: Node2D = game_viewport if game_viewport is Node2D else self
		screen_shake.set_target(target_2d)
	
	# Setup visual clarity systems
	call_deferred("_setup_visual_clarity_systems")

	# Instantiate centralized VisualEffectsSystem (reuses nodes if they exist)
	var vfx_system = get_node_or_null("VisualEffectsSystem")
	if not vfx_system:
		vfx_system = load("res://scripts/systems/VisualEffectsSystem.gd").new()
		vfx_system.name = "VisualEffectsSystem"
		add_child(vfx_system)

	hud = $HUD
	item_popup = $ItemPopup
	
	# Setup triangle item collection timer
	_collection_timer = Timer.new()
	_collection_timer.wait_time = 0.1  # Small delay to collect multiple items
	_collection_timer.one_shot = true
	_collection_timer.timeout.connect(_show_collected_items)
	add_child(_collection_timer)
	
	# HUD will be updated automatically via EventBus signals from GameState
	
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
func _setup_game_mode() -> void:
	# Setup game mode
	var current_mode = GameModeManager.get_current_mode()
	if not current_mode:
		print("[Main] No active game mode, starting default stage controller")
		# Ensure sane starting state when launching without a GameMode (Freeplay)
		GameState.reset_game()
		_setup_stage_controller()
		return
	
	print("[Main] Active game mode: ", current_mode.mode_name)
	
	# Check if this is boss rush mode
	if current_mode is BossRushMode:
		print("[Main] Starting boss rush mode")
		_setup_boss_rush_mode()
	else:
		print("[Main] Starting stage controller for mode: ", current_mode.mode_name)
		_setup_stage_controller()

func _setup_boss_rush_mode() -> void:
	# Setup boss rush mode
	# Add BossRushMode to the scene tree
	var current_mode = GameModeManager.get_current_mode()
	if current_mode and is_instance_valid(current_mode) and current_mode is BossRushMode:
		var container = game_viewport if game_viewport else self
		if container and is_instance_valid(container):
			container.add_child(current_mode)
			print("[Main] Added BossRushMode to scene tree")
	
	# Monitor for boss spawns to show health bar
	_start_boss_monitoring()
	
	# Start lightweight performance watchdog to prevent runaway node counts
	_start_perf_watchdog()
	
	# Connect existing bullets
	if is_inside_tree():
		for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
			if bullet and is_instance_valid(bullet):
				_connect_enemy_bullet(bullet)
	
	# Start the boss rush mode progression after a short delay to ensure scene is ready
	call_deferred("_start_boss_rush_progression")

func _start_boss_rush_progression() -> void:
	# Start boss rush progression
	print("[Main] Starting boss rush progression")
	if GameModeManager.current_mode and GameModeManager.current_mode is BossRushMode:
		GameModeManager.current_mode.get_next_stage()
	else:
		push_error("[Main] No active boss rush mode found")

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

	# Start lightweight performance watchdog to prevent runaway node counts
	_start_perf_watchdog()

	# Connect existing bullets
	if is_inside_tree():
		for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
			if bullet and is_instance_valid(bullet):
				_connect_enemy_bullet(bullet)

func _spawn_player() -> void:
	print("[Main] Spawning player")
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(160, 150)
	var container = game_viewport if game_viewport else self
	container.add_child(player)

	player_hurtbox = player.get_node_or_null("Hurtbox")
	if player_hurtbox:
		print("[Main] Found existing player hurtbox")
		player_hurtbox.add_to_group("player_hurtbox")
		player_hurtbox.monitoring = true
		player_hurtbox.monitorable = true
		player_hurtbox.collision_layer = 1   # Player layer
		player_hurtbox.collision_mask = 2    # Enemy bullet layer
	else:
		print("[Main] Creating new player hurtbox")
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
		player_hurtbox.collision_layer = 1   # Player layer
		player_hurtbox.collision_mask = 2    # Enemy bullet layer

	if player and is_instance_valid(player):
		if player.has_signal("damaged") and not player.is_connected("damaged", Callable(self, "_on_player_damaged")):
			player.connect("damaged", Callable(self, "_on_player_damaged"))
			print("[Main] Connected to player 'damaged' signal")
		if player.has_signal("hit") and not player.is_connected("hit", Callable(self, "_on_player_hit")):
			player.connect("hit", Callable(self, "_on_player_hit"))
			print("[Main] Connected to player 'hit' signal")

func _process(_delta: float) -> void:
	# Handle game over restart in _process (UI-related) - with tree safety check
	if game_over and Input.is_action_just_pressed("ui_accept"):
		if is_inside_tree():
			get_tree().reload_current_scene()
		return

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
			# Emit input_shoot so rank can respond to shots
			EventBus.input_shoot.emit(true)

	# Bomb usage (X key or Left Shift)
	if Input.is_action_just_pressed("bomb") and GameState.bombs > 0:
		_use_bomb()

# HUD update methods removed - now handled by EventBus signals from GameState

func _on_enemy_killed(points: int, enemy_position: Vector2, enemy_type: String = "enemy") -> void:
	"""Handle enemy killed event"""
	# Use GameState for score and streak management
	GameState.add_score(points)
	GameState.update_streak()
	
	# Try to drop items when enemies are killed using actual enemy position
	if item_drop_manager:
		item_drop_manager.try_drop_item(enemy_position, points, enemy_type)

	# Screen shake: low base intensity, scaled logarithmically by streak
	var shake_mult := _get_shake_scale_from_streak()
	EventBus.emit_visual_effect("screen_shake", {"intensity": 0.5 * shake_mult, "duration": 0.05})

func _on_boss_defeated() -> void:
	"""Handle boss defeated event"""
	var boss_score = 10000
	GameState.add_score(boss_score)
	var shake_mult := _get_shake_scale_from_streak()
	EventBus.emit_visual_effect("screen_shake", {"intensity": 1.5 * shake_mult, "duration": 0.22})

func _on_item_collected(item_type: String, value: int) -> void:
	"""Handle item collection"""
	match item_type:
		"SCORE_SMALL", "SCORE_LARGE":
			GameState.add_score(value)
		"LIFE_EXTEND":
			GameState.add_lives(1)
		"BOMB":
			GameState.add_bombs(1)
		"POWER_UP", "SHIELD":
			# Handle power-up effects here
			pass
		# Triangle item types
		"HEART", "FIRE_RATE", "BOMB":
			# Collect triangle items for batch display
			_collected_items.append(item_type)
			_collection_timer.start()  # Restart timer for batch collection
			print("[Main] Triangle item collected: ", item_type)

func _show_collected_items() -> void:
	"""Show popup with all collected triangle items"""
	if _collected_items.size() > 0 and item_popup and item_popup.has_method("show_items_collected"):
		item_popup.show_items_collected(_collected_items)
		print("[Main] Showing collected items: ", _collected_items)
		_collected_items.clear()

func _fire_bullet() -> void:
	"""Fire a bullet from the player"""
	if not player or not is_instance_valid(player):
		return
	
	# Safety check: ensure we're still in the tree
	if not is_inside_tree():
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
	if GameState.bombs <= 0:
		return

	GameState.use_bomb()
	
	print("[Main] BOMB USED! Remaining bombs: ", GameState.bombs)

	# Create visual flash effect
	_create_bomb_flash()

	# Destroy all enemies - with tree safety check
	if is_inside_tree():
		var enemies = get_tree().get_nodes_in_group("enemy")
		print("[Main] Destroying ", enemies.size(), " enemies with bomb")
		for enemy in enemies:
			if enemy and is_instance_valid(enemy):
				# Award points for bomb kills
				if enemy.has_method("take_damage"):
					enemy.take_damage(999, "bomb")
				elif enemy.has_method("die"):
					enemy.die()
				else:
					enemy.queue_free()
	
	# Destroy all enemy bullets - with tree safety check
	if is_inside_tree():
		var bullets = get_tree().get_nodes_in_group("enemy_bullet")
		print("[Main] Destroying ", bullets.size(), " enemy bullets with bomb")
		for bullet in bullets:
			if bullet and is_instance_valid(bullet):
				bullet.queue_free()

	# Screen shake for impact
	var shake_mult := _get_shake_scale_from_streak()
	EventBus.emit_visual_effect("screen_shake", {"intensity": 1.5 * shake_mult, "duration": 0.25})

func _create_bomb_flash() -> void:
	"""Request a white flash effect for bomb usage via EventBus"""
	EventBus.emit_visual_effect("flash", {"color": Color(1.0, 1.0, 1.0, 0.8), "duration": 0.3})

func _on_player_damaged(amount: int) -> void:
	print("[Main] _on_player_damaged called: amount=", amount, " current_lives=", GameState.lives, " game_over=", game_over)
	
	if game_over:
		print("[Main] Game already over, ignoring damage")
		return
	
	# Use GameState for damage handling
	GameState.take_lives(amount)
	print("[Main] Lives after damage: ", GameState.lives)
	
	# Damage causes a subtle shake; still scaled by current streak for feedback
	var shake_mult := _get_shake_scale_from_streak()
	EventBus.emit_visual_effect("screen_shake", {"intensity": 0.9 * shake_mult, "duration": 0.10})

	# Breaking the streak on damage feels fair; reset chain
	GameState.break_streak()
	
	if GameState.lives <= 0:
		print("[Main] No lives left, triggering game over")
		_on_player_hit()
	else:
		print("[Main] Player has ", GameState.lives, " lives remaining")

func _on_player_hit() -> void:
	print("[Main] _on_player_hit called, game_over=", game_over)
	# Only trigger game over if no lives remain
	if game_over:
		print("[Main] Game already over, ignoring hit")
		return
	if GameState.lives > 0:
		print("[Main] Player hit but still has lives=", GameState.lives)
		return
	print("[Main] Setting game_over=true")
	game_over = true
	GameState.trigger_game_over()
	if hud and hud.has_method("show_game_over"):
		print("[Main] Showing game over screen")
		hud.show_game_over(true)
	else:
		print("[Main] ERROR: HUD or show_game_over method not found!")

func _on_enemy_spawned(enemy: Area2D) -> void:
	if not is_instance_valid(enemy):
		print("[Main] _on_enemy_spawned called with invalid enemy")
		return
	
	print("[Main] Enemy spawned, connecting signals")
	
	# Connect enemy hit_player signal if it exists
	if enemy and is_instance_valid(enemy) and enemy.has_signal("hit_player") and not enemy.is_connected("hit_player", Callable(self, "_on_enemy_hit_player")):
		enemy.connect("hit_player", Callable(self, "_on_enemy_hit_player"))
		print("[Main] Connected enemy hit_player signal")

	# Monitor for bullets spawned by this enemy
	var connect_child := func(node: Node):
		if node.is_in_group("enemy_bullet"):
			_connect_enemy_bullet(node)

	if not enemy.is_connected("child_entered_tree", connect_child):
		enemy.child_entered_tree.connect(connect_child)

func _connect_enemy_bullet(bullet: Area2D) -> void:
	if not bullet or not is_instance_valid(bullet):
		print("[Main] _connect_enemy_bullet called with invalid bullet")
		return
	
	# SIMPLIFIED: Only connect hit_player signal - no fallback logic
	if bullet.has_signal("hit_player"):
		# Avoid duplicate connections
		if not bullet.is_connected("hit_player", Callable(self, "_on_enemy_bullet_hit_player")):
			bullet.connect("hit_player", Callable(self, "_on_enemy_bullet_hit_player"))
			print("[Main] Connected bullet hit_player signal at position: ", bullet.position)
		else:
			print("[Main] Bullet hit_player already connected")
	else:
		print("[Main] WARNING: Enemy bullet missing hit_player signal!")

func _on_enemy_bullet_hit_player() -> void:
	print("[Main] _on_enemy_bullet_hit_player triggered!")
	if player and is_instance_valid(player):
		if player.has_method("take_damage"):
			print("[Main] Calling player.take_damage(1)")
			player.take_damage(1)
			
			# Trigger hit-stop for better feedback via EventBus
			EventBus.emit_visual_effect("hit_stop", {"duration": 0.05, "scale": 1.0})
		else:
			print("[Main] ERROR: Player missing take_damage method!")
	else:
		print("[Main] ERROR: Player invalid when bullet hit!")

func _on_enemy_hit_player() -> void:
	print("[Main] _on_enemy_hit_player triggered (enemy collision)!")
	if player and is_instance_valid(player):
		if player.has_method("take_damage"):
			player.take_damage(1)
			
			# Trigger hit-stop for enemy collision via EventBus
			EventBus.emit_visual_effect("hit_stop", {"duration": 0.08, "scale": 1.2})

func _setup_visual_clarity_systems() -> void:
	"""Setup visual clarity enhancement systems"""
	# Handled by VisualEffectsSystem (reuses or creates DangerIndicator + VisualSettings)
	
	# Add COMPREHENSIVE bullet readability background dimming
	var bg_dim = preload("res://scripts/bullet_readability/BackgroundDimManager.gd").new()
	bg_dim.name = "BackgroundDimManager"
	add_child(bg_dim)
	
	print("[Main] Visual clarity systems initialized (including bullet readability)")
	# Remove immediate player damage call here to avoid early hit-stop trigger on start

func _get_shake_scale_from_streak() -> float:
	# Logarithmic scale: 1 + k * ln(1 + streak)
	var k: float = 0.18
	var streak: float = float(GameState.chain_count)
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
	
	# Check for bosses with tree safety check
	if is_inside_tree():
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
					boss.connect("defeated", Callable(self, "_on_boss_health_depleted").bind(boss))
				elif boss.has_signal("killed"):
					boss.connect("killed", Callable(self, "_on_boss_health_depleted").bind(boss))

func _on_boss_health_depleted(_boss: Node) -> void:
	"""Handle when a boss is defeated"""
	if is_instance_valid(hud) and hud.has_method("hide_boss_health"):
		hud.hide_boss_health()

func _setup_rank_pressure_system() -> void:
	"""Initialize the rank pressure system"""
	# Instantiate RankPressureSystem if missing
	if not rank_pressure_system:
		rank_pressure_system = load("res://scripts/systems/RankPressureSystem.gd").new()
		rank_pressure_system.name = "RankPressureSystem"
		add_child(rank_pressure_system)

func _start_perf_watchdog() -> void:
	"""Start a periodic watchdog that prunes runaway objects"""
	if _perf_watchdog_timer:
		return
	_perf_watchdog_timer = Timer.new()
	_perf_watchdog_timer.wait_time = 1.0
	_perf_watchdog_timer.autostart = true
	_perf_watchdog_timer.timeout.connect(_perf_watchdog_tick)
	add_child(_perf_watchdog_timer)

func _perf_watchdog_tick() -> void:
	# Count bullets and prune if exceeding thresholds
	var enemy_bullets: Array = get_tree().get_nodes_in_group("enemy_bullet")
	var player_bullets: Array = get_tree().get_nodes_in_group("player_bullet")
	var total_bullets := enemy_bullets.size() + player_bullets.size()

	if enemy_bullets.size() > MAX_ENEMY_BULLETS_ALLOWED:
		var excess := enemy_bullets.size() - MAX_ENEMY_BULLETS_ALLOWED
		for i in range(min(excess, enemy_bullets.size())):
			var b = enemy_bullets[i]
			if b and is_instance_valid(b):
				b.queue_free()

	if total_bullets > MAX_TOTAL_BULLETS_ALLOWED:
		var excess_total := total_bullets - MAX_TOTAL_BULLETS_ALLOWED
		# Prefer removing enemy bullets first, then player bullets if needed
		var enemy_to_remove: int = min(excess_total, enemy_bullets.size())
		for i in range(enemy_to_remove):
			var eb = enemy_bullets[i]
			if eb and is_instance_valid(eb):
				eb.queue_free()
		excess_total -= enemy_to_remove
		if excess_total > 0:
			var player_to_remove: int = min(excess_total, player_bullets.size())
			for i in range(player_to_remove):
				var pb = player_bullets[i]
				if pb and is_instance_valid(pb):
					pb.queue_free()

### _apply_rank_pressure removed; logic now handled by RankPressureSystem
