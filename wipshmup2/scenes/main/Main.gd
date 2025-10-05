extends Node2D

# WORKING VERSION WITH PROPER SYSTEMS

var player: Node
var hud: Node
var stage_controller: Node
var background_manager: Node
var item_drop_manager: Node
var game_over: bool = false
var lives: int = 3
var bombs: int = 3
var score: int = 0
var shot_cooldown: float = 0.1  # 100ms between shots (seconds)
var player_hurtbox: Area2D
var bullet_timer: Timer
var game_viewport: Node

# Scene references
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/StageController.gd")
const BACKGROUND_MANAGER_SCRIPT: Script = preload("res://scripts/BackgroundManager.gd")
const ITEM_DROP_MANAGER_SCRIPT: Script = preload("res://scripts/ItemDropManager.gd")

func _ready() -> void:
	print("=== GAME START WITH SYSTEMS ===")
	add_to_group("game")

	RenderingServer.set_default_clear_color(Color(0.02, 0.02, 0.05))

	bullet_timer = Timer.new()
	bullet_timer.wait_time = shot_cooldown
	bullet_timer.one_shot = true
	add_child(bullet_timer)

	game_viewport = get_node_or_null("GameViewport")

	# Setup background system
	_setup_background()

	# Setup item drop system
	_setup_item_drops()

	# Spawn player
	_spawn_player()

	# Setup stage controller for enemies
	_setup_stage_controller()

	# Setup HUD
	hud = $HUD
	_update_score_label()
	_update_lives_display()
	_update_bomb_display()

	print("Game initialized with all systems")

func _setup_background() -> void:
	"""Setup the background system"""
	# Try to create a simple starfield background first
	_create_simple_starfield()

	# Then try the complex background manager
	background_manager = BACKGROUND_MANAGER_SCRIPT.new()
	background_manager.name = "BackgroundManager"
	var container = game_viewport if game_viewport else self
	container.add_child(background_manager)

	# Move background manager to be behind everything else
	container.move_child(background_manager, 0)

	print("Background system initialized")

func _create_simple_starfield() -> void:
	"""Create a simple starfield background"""
	var starfield = Node2D.new()
	starfield.name = "SimpleStarfield"
	var container = game_viewport if game_viewport else self
	container.add_child(starfield)
	container.move_child(starfield, 0)

	# Create some simple stars
	for i in range(80):
		var star = ColorRect.new()
		star.size = Vector2(1, 1)
		star.color = Color(0.7 + randf() * 0.3, 0.7 + randf() * 0.3, 0.9, randf_range(0.4, 1.0))
		star.position = Vector2(randf() * 320, randf() * 180)
		starfield.add_child(star)

	print("Simple starfield created")

func _setup_item_drops() -> void:
	"""Setup the item drop system"""
	item_drop_manager = ITEM_DROP_MANAGER_SCRIPT.new()
	add_child(item_drop_manager)

	# Connect item collection signals
	item_drop_manager.item_collected.connect(_on_item_collected)
	print("Item drop system initialized")

func _setup_stage_controller() -> void:
	"""Setup the stage controller for enemy spawning"""
	stage_controller = STAGE_CONTROLLER_SCRIPT.new()
	add_child(stage_controller)

	# Connect enemy signals
	stage_controller.enemy_killed.connect(_on_enemy_killed)
	if stage_controller.has_signal("boss_defeated"):
		stage_controller.boss_defeated.connect(_on_boss_defeated)
	if stage_controller.has_signal("enemy_spawned"):
		stage_controller.enemy_spawned.connect(_on_enemy_spawned)

	# Start the stage system
	stage_controller.start_run()

	print("Stage controller initialized")

func _spawn_player() -> void:
	# Load the proper player scene
	const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
	player = PLAYER_SCENE.instantiate()

	# Position player
	player.position = Vector2(160, 150)  # Center bottom

	# Add to main scene
	add_child(player)

	# Ensure we have a hurtbox for enemy bullets
	player_hurtbox = player.get_node_or_null("Hurtbox")
	if player_hurtbox:
		player_hurtbox.add_to_group("player_hurtbox")
	else:
		player_hurtbox = Area2D.new()
		player_hurtbox.name = "Hurtbox"
		var collision_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 6.0
		collision_shape.shape = shape
		player_hurtbox.add_child(collision_shape)
		player.add_child(player_hurtbox)
		player_hurtbox.add_to_group("player_hurtbox")

	# Connect player damage signals
	if player.has_signal("damaged"):
		player.connect("damaged", Callable(self, "_on_player_damaged"))
	if player.has_signal("hit"):
		player.connect("hit", Callable(self, "_on_player_hit"))

	print("Player spawned at: ", player.position)

func _process(_delta: float) -> void:
	if game_over and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()

	# Simple movement
	if player and is_instance_valid(player):
		var input_vector := Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

		player.position += input_vector * 200.0 * _delta

		# Keep player on screen
		player.position.x = clamp(player.position.x, 16.0, 304.0)
		player.position.y = clamp(player.position.y, 16.0, 164.0)

	# Handle shooting (Space key) with cooldown
	if Input.is_key_pressed(KEY_SPACE) and player and is_instance_valid(player):
		if bullet_timer.is_stopped():
			_fire_bullet()
			bullet_timer.start()

	# Handle bombs (Shift key)
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

func _on_enemy_killed(points: int) -> void:
	"""Handle enemy killed event"""
	score += points
	_update_score_label()

	# Try to drop items when enemies are killed
	if item_drop_manager:
		# Get enemy position (approximate center of screen for now)
		var enemy_pos = Vector2(160, 100)
		item_drop_manager.try_drop_item(enemy_pos, points)

	print("Enemy killed! Points: ", points, " Total score: ", score)

func _on_boss_defeated() -> void:
	"""Handle boss defeated event"""
	var boss_score = 10000
	score += boss_score
	_update_score_label()
	print("Boss defeated! Bonus score: ", boss_score)

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

	print("Item collected: ", item_type, " Value: ", value)

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

	print("Bullet fired!")

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

	print("Bomb used! Enemies destroyed: ", enemies.size())

func _on_player_damaged(amount: int) -> void:
	if game_over:
		return
	lives -= amount
	lives = max(lives, 0)
	_update_lives_display()
	print("Player damaged! Lives left: ", lives)
	if lives <= 0:
		_on_player_hit()

func _on_player_hit() -> void:
	if game_over:
		return
	game_over = true
	_update_lives_display()
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over(true)
	print("Player hit! Game over")

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