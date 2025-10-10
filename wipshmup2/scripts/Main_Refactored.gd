extends Node2D

# Main_Refactored - Simplified main scene controller
# Uses event-driven architecture with specialized systems

# System references
var player_controller: Node
var combat_system: Node
var visual_effects_system: Node
var rank_pressure_system: Node
var stage_controller: Node

# Scene references
var player: Node
var hud: Node
var game_viewport: Node

func _ready() -> void:
	add_to_group("game")
	
	# Setup rendering
	RenderingServer.set_default_clear_color(Color(0.02, 0.02, 0.05))
	
	# Initialize systems
	_initialize_systems()
	
	# Setup scene
	_setup_scene()
	
	# Connect to EventBus for high-level events
	_connect_to_events()
	
	# Start the game
	_start_game()

func _initialize_systems() -> void:
	"""Initialize all game systems"""
	# Create system nodes
	player_controller = load("res://scripts/controllers/PlayerController.gd").new()
	player_controller.name = "PlayerController"
	add_child(player_controller)
	
	combat_system = load("res://scripts/systems/CombatSystem.gd").new()
	combat_system.name = "CombatSystem"
	add_child(combat_system)
	
	visual_effects_system = load("res://scripts/systems/VisualEffectsSystem.gd").new()
	visual_effects_system.name = "VisualEffectsSystem"
	add_child(visual_effects_system)
	
	rank_pressure_system = load("res://scripts/systems/RankPressureSystem.gd").new()
	rank_pressure_system.name = "RankPressureSystem"
	add_child(rank_pressure_system)
	
	print("[Main] All systems initialized")

func _setup_scene() -> void:
	"""Setup the game scene"""
	# Get scene references
	game_viewport = $GameViewport if has_node("GameViewport") else self
	hud = $HUD
	
	# Setup EntityFactory containers
	EntityFactory.set_containers(game_viewport)
	
	# Setup background
	_setup_background()
	
	# Setup item drops
	_setup_item_drops()
	
	# Spawn player
	_spawn_player()
	
	# Setup stage controller
	_setup_stage_controller()

func _setup_background() -> void:
	"""Setup the space background"""
	var space_background = game_viewport.get_node_or_null("SpaceBackground")
	if not space_background:
		_create_simple_starfield()

func _create_simple_starfield() -> void:
	"""Create a simple starfield background"""
	var starfield = Node2D.new()
	starfield.name = "SimpleStarfield"
	game_viewport.add_child(starfield)
	game_viewport.move_child(starfield, 0)
	
	for i in range(80):
		var star = ColorRect.new()
		star.size = Vector2(1, 1)
		star.color = Color(0.7 + randf() * 0.3, 0.7 + randf() * 0.3, 0.9, randf_range(0.4, 1.0))
		star.position = Vector2(randf() * 320, randf() * 180)
		starfield.add_child(star)

func _setup_item_drops() -> void:
	"""Setup item drop system"""
	if ItemDropManager:
		ItemDropManager.item_collected.connect(_on_item_collected)

func _spawn_player() -> void:
	"""Spawn the player"""
	print("[Main] Spawning player")
	player = EntityFactory.spawn_player(Vector2(160, 150))
	player_controller.initialize(player)

func _setup_stage_controller() -> void:
	"""Setup the stage controller"""
	stage_controller = load("res://scripts/StageController.gd").new()
	stage_controller.name = "StageController"
	game_viewport.add_child(stage_controller)
	
	# Connect stage controller events
	stage_controller.enemy_killed.connect(_on_stage_enemy_killed)
	if stage_controller.has_signal("boss_defeated"):
		stage_controller.boss_defeated.connect(_on_stage_boss_defeated)
	if stage_controller.has_signal("enemy_spawned"):
		stage_controller.enemy_spawned.connect(_on_stage_enemy_spawned)
	
	# Start the stage
	stage_controller.start_run()

func _connect_to_events() -> void:
	"""Connect to EventBus for high-level game events"""
	EventBus.game_over.connect(_on_game_over)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.item_collected.connect(_on_item_collected)

func _start_game() -> void:
	"""Start the game"""
	GameState.start_game()
	EventBus.game_started.emit()

func _process(delta: float) -> void:
	"""Handle game over restart"""
	if GameState.game_over and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
		return

# Event handlers
func _on_game_over() -> void:
	"""Handle game over"""
	print("[Main] Game over triggered")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over(true)

func _on_player_damaged(amount: int) -> void:
	"""Handle player damage"""
	print("[Main] Player damaged: ", amount)
	if GameState.lives <= 0:
		EventBus.game_over.emit()

func _on_enemy_killed(points: int, position: Vector2, enemy_type: String) -> void:
	"""Handle enemy killed"""
	print("[Main] Enemy killed: ", points, " points")

func _on_boss_defeated(boss_name: String, points: int) -> void:
	"""Handle boss defeated"""
	print("[Main] Boss defeated: ", boss_name, " - ", points, " points")

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
			# Handle power-up effects
			pass

# Stage controller event handlers
func _on_stage_enemy_killed(points: int, position: Vector2) -> void:
	"""Handle enemy killed from stage controller"""
	EventBus.emit_enemy_kill(points, position, "enemy")

func _on_stage_boss_defeated() -> void:
	"""Handle boss defeated from stage controller"""
	EventBus.emit_boss_defeat("boss", 10000)

func _on_stage_enemy_spawned(enemy: Node) -> void:
	"""Handle enemy spawned from stage controller"""
	EventBus.enemy_spawned.emit(enemy, "enemy")
