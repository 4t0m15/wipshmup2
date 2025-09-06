extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/StageController.gd")
const CRT_SHADER: Shader = preload("res://shaders/crt.gdshader")
const DITHER_SHADER: Shader = preload("res://shaders/dither_viewport.gdshader")
const BACKGROUND_INTEGRATION_SCRIPT: Script = preload("res://scripts/BackgroundIntegration.gd")

# Game state variables
var stage_controller: Node
var player: Node
var hud: Node
var bgm_player: AudioStreamPlayer
var background_integration: BackgroundIntegration
var game_over: bool = false
var lives: int = 3
var bombs: int = 3
var score: int = 0

# Chain system variables
var chain_count: int = 0
var max_chain: int = 0
var last_kill_time: float = 0.0
var chain_timeout: float = 2.0  # 2 seconds to maintain chain

# Medal system variables
var medal_level: int = 0

# Scoring multipliers
var base_score_multiplier: float = 1.0
var chain_bonus_multiplier: float = 1.0
var medal_bonus_multiplier: float = 1.0

# Developer mode variables
var dev_mode: bool = false
var dev_invincibility: bool = false
var dev_audio_muted: bool = false

# Internal variables
var _backslash_was_pressed: bool = false
var _next_bomb_score: int = 25000     # More frequent bombs
var _next_extend_score: int = 500000  # More frequent extends
# var _next_medal_score: int = 100000   # Medal upgrade threshold - reserved for future use

func _ready() -> void:
	# Start in windowed mode; fullscreen can cause issues on some platforms/drivers
	# Use Command+F (macOS) or Alt+Enter (others) to toggle fullscreen from the editor.
	add_to_group("game")

	# Initialize GameViewport with proper settings
	_setup_game_viewport()

	# Initialize enhanced background system
	_setup_enhanced_background()

	_spawn_player()
	# Use StageController instead of random spawns
	stage_controller = STAGE_CONTROLLER_SCRIPT.new()
	$GameViewport.add_child(stage_controller)

	# Create enemy container for proper spawning
	var enemy_container = Node2D.new()
	enemy_container.name = "Enemies"
	$GameViewport.add_child(enemy_container)

	# Create bullet container for proper spawning
	var bullet_container = Node2D.new()
	bullet_container.name = "Bullets"
	$GameViewport.add_child(bullet_container)

	stage_controller.enemy_killed.connect(_on_enemy_killed)
	if stage_controller.has_signal("boss_defeated"):
		stage_controller.boss_defeated.connect(_on_boss_defeated)

	# Wait a frame to ensure containers are ready
	await get_tree().process_frame
	stage_controller.start_run()
	# HUD
	hud = $HUD
	print("Initial bombs: ", bombs)  # Debug log
	print("Initial scoring system initialized")  # Debug log
	_update_score_label()
	_update_lives_display()
	_update_bomb_display()
	_update_chain_display()
	_update_medal_display()
	# BGM
	bgm_player = $BGMPlayer
	# Medal system removed: no HUD medal hooks
	# Hook 50 TPS tick to HUD display (TPS averaged inside HUD)
	var tm := get_node_or_null("/root/TickManager")
	if tm and tm.has_signal("tick"):
		# HUD listens to tick itself; no need to connect here
		pass

	# Connect GameViewport to display after a frame
	call_deferred("_connect_viewport_display")

	# Enable post-processing after first frame
	call_deferred("_enable_postfx")

	# Optimize rendering pipeline
	call_deferred("_optimize_rendering_pipeline")

func _setup_enhanced_background():
	"""Setup the enhanced background system"""
	print("MainEnhanced: Setting up enhanced background system")

	# Create background integration manager
	background_integration = BACKGROUND_INTEGRATION_SCRIPT.new()
	background_integration.name = "BackgroundIntegration"
	add_child(background_integration)

	# Get the background manager from the enhanced background scene
	var enhanced_bg = $GameViewport.get_node("EnhancedBackground")
	if enhanced_bg and enhanced_bg.has_method("get_script"):
		var script = enhanced_bg.get_script()
		if script == preload("res://scripts/BackgroundManager.gd"):
			background_integration.set_background_manager(enhanced_bg)
			print("MainEnhanced: Background manager connected")
		else:
			print("MainEnhanced: Warning - Enhanced background not found or invalid")
	else:
		print("MainEnhanced: Warning - Enhanced background not found or invalid")

	# Set up game manager reference
	background_integration.set_game_manager(self)

	# Initialize with starting environment
	background_integration.update_score(score)
	background_integration.update_stage(1)

func _setup_game_viewport() -> void:
	# Configure GameViewport for proper rendering
	$GameViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	$GameViewport.size = Vector2i(320, 180)
	$GameViewport.transparent_bg = false
	print("GameViewport configured: size=", $GameViewport.size,
		" update_mode=", $GameViewport.render_target_update_mode)

func _connect_viewport_display() -> void:
	# Wait for viewport to be ready
	await get_tree().process_frame

	# Connect GameViewport to display
	var viewport_texture = $GameViewport.get_texture()
	if viewport_texture:
		$GameDisplay.texture = viewport_texture
		print("GameViewport texture connected to display: ", viewport_texture)
	else:
		print("ERROR: GameViewport texture is null!")
		# Retry after another frame
		call_deferred("_connect_viewport_display")

func _enable_postfx() -> void:
	# Wait for GameViewport to be fully ready
	await get_tree().process_frame
	await get_tree().process_frame

	# Order: build dither first, then CRT reads from it
	_enable_dither()
	await _enable_crt()

	# Always show the post-processed view (shaders permanently enabled)
	$GameDisplay.visible = false
	$PostFX/CRT.visible = true
	$PostDitherViewport/DitherPass.visible = true
	# Ensure viewport updates are always enabled for shaders
	$PostDitherViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("Post-processing permanently enabled - shaders active")

func _enable_dither() -> void:
	var dither_node := $PostDitherViewport/DitherPass
	var src_viewport := $GameViewport
	var dither_viewport := $PostDitherViewport

	if not (is_instance_valid(dither_node)
		and is_instance_valid(src_viewport)
		and is_instance_valid(dither_viewport)):
		print("ERROR: Dither nodes not found!")
		return

	# Configure dither viewport
	dither_viewport.size = Vector2i(320, 180)
	dither_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	dither_viewport.transparent_bg = false

	# Wait for source viewport to be ready
	await get_tree().process_frame

	# Render GameViewport into PostDitherViewport via a ColorRect using our
	# dither shader that samples an explicit uniform.
	var tex: Texture2D = src_viewport.get_texture()
	if tex == null:
		print("ERROR: GameViewport texture is null; retrying dither setup...")
		# Retry after another frame
		call_deferred("_enable_dither")
		return

	var mat := ShaderMaterial.new()
	mat.shader = DITHER_SHADER
	# Bind source texture into the explicit sampler uniform
	mat.set_shader_parameter("tex", tex)
	# More subtle dither effect for better visibility
	mat.set_shader_parameter("grayscale", false)
	mat.set_shader_parameter("dither_strength", 0.2)  # Reduced for better visibility
	mat.set_shader_parameter("min_dither_brightness", 0.05)
	mat.set_shader_parameter("color_a", Color(0.05, 0.05, 0.05, 1))
	mat.set_shader_parameter("color_b", Color(0.95, 0.95, 0.95, 1))
	mat.set_shader_parameter("bayer_mode", 4)
	mat.set_shader_parameter("dither_repeat", 1.0)
	dither_node.material = mat

	print("Dither shader setup complete with texture: ", tex)
	return

func _enable_crt() -> void:
	var crt := $PostFX/CRT
	var dither_viewport := $PostDitherViewport

	if not is_instance_valid(crt) or not is_instance_valid(dither_viewport):
		print("ERROR: CRT or DitherViewport not found!")
		return

	# Wait for dither viewport to be ready
	await get_tree().process_frame
	await get_tree().process_frame

	print("Setting up CRT with viewport: ", dither_viewport.get_path())

	# Create CRT material
	var crt_mat := ShaderMaterial.new()
	crt_mat.shader = CRT_SHADER
	crt_mat.set_shader_parameter("tex", dither_viewport.get_texture())
	crt_mat.set_shader_parameter("mask_type", 1)  # Dots
	crt_mat.set_shader_parameter("curve", 0.1)
	crt_mat.set_shader_parameter("sharpness", 0.8)
	crt_mat.set_shader_parameter("color_offset", 0.1)
	crt_mat.set_shader_parameter("mask_brightness", 0.9)
	crt_mat.set_shader_parameter("scanline_brightness", 0.9)
	crt_mat.set_shader_parameter("min_scanline_thickness", 0.6)
	crt_mat.set_shader_parameter("aspect", 0.5625)  # 16:9
	crt_mat.set_shader_parameter("wobble_strength", 0.1)

	crt.material = crt_mat
	print("CRT shader setup complete")

func _optimize_rendering_pipeline() -> void:
	# Optimize rendering settings
	$GameViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	$PostDitherViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Set up proper viewport sizing
	$GameViewport.size = Vector2i(320, 180)
	$PostDitherViewport.size = Vector2i(320, 180)

	print("Rendering pipeline optimized")

func _spawn_player() -> void:
	# Spawn player at the bottom center of the screen
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(160, 150)  # Bottom center
	$GameViewport.add_child(player)
	print("Player spawned at: ", player.position)

func _on_enemy_killed(enemy_score: int, _enemy_position: Vector2) -> void:
	# Update score with chain system
	var current_time = Time.get_time_dict_from_system()
	var time_since_last_kill = current_time.second - last_kill_time

	# Reset chain if too much time has passed
	if time_since_last_kill > chain_timeout:
		chain_count = 0

	# Increment chain
	chain_count += 1
	max_chain = max(max_chain, chain_count)
	last_kill_time = current_time.second

	# Calculate score with multipliers
	var base_score = enemy_score
	var chain_bonus = 1.0 + (chain_count - 1) * 0.1
	var medal_bonus = 1.0 + medal_level * 0.2

	var final_score = int(base_score * chain_bonus * medal_bonus)
	score += final_score

	# Update background system with new score
	if background_integration:
		background_integration.update_score(score)

	# Check for score-based rewards
	_check_score_rewards()

	# Update HUD
	_update_score_label()
	_update_chain_display()
	_update_medal_display()

	print("Enemy killed! Score: ", final_score, " Chain: ", chain_count, " Total: ", score)

func _on_boss_defeated() -> void:
	# Special boss defeat handling
	var boss_score = 10000
	score += boss_score

	# Trigger special background effects for boss defeat
	if background_integration:
		background_integration.trigger_boss_effects()

	_update_score_label()
	print("Boss defeated! Bonus score: ", boss_score)

func _check_score_rewards() -> void:
	# Check for bomb rewards
	if score >= _next_bomb_score:
		bombs += 1
		_next_bomb_score += 25000
		_update_bomb_display()
		print("Bomb reward! Bombs: ", bombs)

	# Check for life rewards
	if score >= _next_extend_score:
		lives += 1
		_next_extend_score += 500000
		_update_lives_display()
		print("Life reward! Lives: ", lives)

func _update_score_label() -> void:
	if hud and hud.has_method("update_score"):
		hud.update_score(score)

func _update_lives_display() -> void:
	if hud and hud.has_method("update_lives"):
		hud.update_lives(lives)

func _update_bomb_display() -> void:
	if hud and hud.has_method("update_bombs"):
		hud.update_bombs(bombs)

func _update_chain_display() -> void:
	if hud and hud.has_method("update_chain"):
		hud.update_chain(chain_count, max_chain)

func _update_medal_display() -> void:
	if hud and hud.has_method("update_medal"):
		hud.update_medal(medal_level)

func _input(event: InputEvent) -> void:
	# Developer mode toggle
	if event.is_action_pressed("ui_cancel") and event.keycode == KEY_BACKSLASH:
		if not _backslash_was_pressed:
			dev_mode = !dev_mode
			_backslash_was_pressed = true
			print("Developer mode: ", dev_mode)
	else:
		_backslash_was_pressed = false

	# Developer mode features
	if dev_mode:
		if event.is_action_pressed("ui_accept"):
			# Toggle invincibility
			dev_invincibility = !dev_invincibility
			if player:
				player.dev_invincibility = dev_invincibility
			print("Dev invincibility: ", dev_invincibility)

		if event.is_action_pressed("ui_select"):
			# Toggle audio
			dev_audio_muted = !dev_audio_muted
			if bgm_player:
				bgm_player.volume_db = -80.0 if dev_audio_muted else 0.0
			print("Dev audio muted: ", dev_audio_muted)

		if event.is_action_pressed("ui_up"):
			# Add score
			score += 1000
			_update_score_label()
			if background_integration:
				background_integration.update_score(score)
			print("Dev: Added 1000 score")

		if event.is_action_pressed("ui_down"):
			# Trigger combat effects
			if background_integration:
				background_integration.trigger_combat_effects()
			print("Dev: Triggered combat effects")

func _process(_delta: float) -> void:
	# Update background system
	if background_integration:
		# Adjust intensity based on game state
		var intensity = 1.0
		if chain_count > 5:
			intensity = 1.2 + (chain_count - 5) * 0.1
		if game_over:
			intensity = 0.5

		background_integration.set_intensity(intensity)
