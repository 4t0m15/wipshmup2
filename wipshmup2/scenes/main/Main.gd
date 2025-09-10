extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/StageController.gd")
const CRT_SHADER: Shader = preload("res://shaders/crt.gdshader")
const DITHER_SHADER: Shader = preload("res://shaders/dither_viewport.gdshader")

# Game state variables
var stage_controller: Node
var player: Node
var hud: Node
var bgm_player: AudioStreamPlayer
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
var _next_medal_score: int = 100000   # Medal upgrade threshold


func _ready() -> void:
	# Start in windowed mode; fullscreen can cause issues on some platforms/drivers
	# Use Command+F (macOS) or Alt+Enter (others) to toggle fullscreen from the editor.
	add_to_group("game")

	# Initialize GameViewport with proper settings
	_setup_game_viewport()

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

	# Use the dithered SubViewport's texture as input to CRT
	var viewport_texture: Texture2D = dither_viewport.get_texture()
	if viewport_texture == null:
		print("ERROR: Dither viewport texture is null; retrying CRT setup...")
		# Retry after another frame
		call_deferred("_enable_crt")
		return

	# Create CRT shader material
	var mat := ShaderMaterial.new()
	if CRT_SHADER:
		mat.shader = CRT_SHADER
		# Set the viewport texture as the input
		mat.set_shader_parameter("tex", viewport_texture)
		# Very subtle CRT effect for better visibility
		mat.set_shader_parameter("mask_type", 0)  # No mask
		mat.set_shader_parameter("curve", 0.0)    # No curve
		mat.set_shader_parameter("sharpness", 0.9) # Higher sharpness for better visibility
		mat.set_shader_parameter("color_offset", 0.0) # No offset
		mat.set_shader_parameter("mask_brightness", 1.0) # Full brightness
		mat.set_shader_parameter("scanline_brightness", 0.9) # Higher scanline brightness
		mat.set_shader_parameter("min_scanline_thickness", 0.9) # Thicker scanlines
		mat.set_shader_parameter("aspect", 0.5625)  # 180/320 = 0.5625
		mat.set_shader_parameter("wobble_strength", 0.0)
		# Enable global color adjustments by default for better testing visibility
		mat.set_shader_parameter("brightness", 0.08)
		mat.set_shader_parameter("contrast", 1.15)
		mat.set_shader_parameter("saturation", 1.2)
		mat.set_shader_parameter("hue_shift_degrees", 0.0)
		mat.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0))
		mat.set_shader_parameter("tint_strength", 0.0)
		mat.set_shader_parameter("invert", false)
		mat.set_shader_parameter("gamma", 1.0)
		crt.material = mat
		crt.visible = true
		print("CRT setup complete with texture: ", viewport_texture)
	else:
		print("ERROR: CRT_SHADER not loaded!")

func _process(_delta: float) -> void:
	if game_over and Input.is_action_just_pressed("ui_accept"):
		_reset_scoring_system()
		get_tree().reload_current_scene()

	# Developer mode toggle with backslash key
	var backslash_pressed = Input.is_physical_key_pressed(KEY_BACKSLASH)
	if backslash_pressed and not _backslash_was_pressed:
		_toggle_dev_mode()
	_backslash_was_pressed = backslash_pressed

	# Shaders are now always enabled - no toggle needed

	# Bomb input (fallback to X key if action not present)
	var has_bomb_action := InputMap.has_action("bomb")
	var bomb_pressed := false
	if has_bomb_action:
		bomb_pressed = Input.is_action_just_pressed("bomb")
	else:
		bomb_pressed = Input.is_key_pressed(KEY_X)
	if bomb_pressed:
		_use_bomb()

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	# Spawn player in the GameViewport, use GameViewport size for positioning
	var viewport_size := Vector2(320, 180)  # GameViewport size
	player.global_position = Vector2(viewport_size.x / 2.0, viewport_size.y - 80.0)
	player.hit.connect(_on_player_hit)
	$GameViewport.add_child(player)
	print("Player spawned at position: ", player.global_position, " in GameViewport")

	# Wait a frame then do additional debugging
	await get_tree().process_frame

	# Debug player position and visibility extensively
	if is_instance_valid(player):
		print("=== PLAYER DEBUG INFO ===")
		print("Player global_position: ", player.global_position)
		print("Player local position: ", player.position)
		print("Player visible: ", player.visible)
		print("Player z_index: ", player.z_index)
		print("Player modulate: ", player.modulate)
		print("GameViewport size: ", $GameViewport.size)
		print("GameViewport children count: ", $GameViewport.get_child_count())
		
		if player.has_node("Sprite2D"):
			var sprite = player.get_node("Sprite2D")
			print("Sprite visible: ", sprite.visible, " scale: ", sprite.scale, " texture: ", sprite.texture != null)
			print("Sprite global_position: ", sprite.global_position)
			print("Sprite modulate: ", sprite.modulate)
		
		# Count all ColorRect children (our fallbacks)
		var rect_count = 0
		for child in player.get_children():
			if child is ColorRect:
				rect_count += 1
				print("Found ColorRect fallback: size=", child.size, " color=", child.color, " z_index=", child.z_index)
		print("Total ColorRect fallbacks: ", rect_count)
		print("========================")

	# Debug: Check if player sprite is visible
	if player.has_node("Sprite2D"):
		var sprite = player.get_node("Sprite2D")
		print("Player sprite visible: ", sprite.visible, " scale: ", sprite.scale, " texture: ", sprite.texture != null)
		print("Player position: ", player.global_position, " GameViewport size: ", $GameViewport.size)
	else:
		print("Player missing Sprite2D node!")
	
	# Force player to be visible
	call_deferred("_force_player_visibility")
	
	# Spawn invulnerability window
	if player and player.has_method("start_invulnerability"):
		player.call_deferred("start_invulnerability", 1.2)

	# Apply dev mode settings to new player
	_apply_dev_invincibility_state()

func _force_player_visibility() -> void:
	"""Force the player to be visible"""
	if player and is_instance_valid(player):
		if player.has_node("Sprite2D"):
			var sprite = player.get_node("Sprite2D")
			sprite.visible = true
			sprite.modulate = Color.WHITE
			if sprite.scale.x < 0.1 or sprite.scale.y < 0.1:
				sprite.scale = Vector2(2.0, 2.0)  # Force a large scale
			print("FORCED player sprite visibility: visible=", sprite.visible, " scale=", sprite.scale)
		else:
			print("Player has no Sprite2D - creating fallback")
			# Create a very obvious fallback
			var fallback = ColorRect.new()
			fallback.size = Vector2(32, 32)
			fallback.color = Color.RED
			fallback.position = Vector2(-16, -16)
			player.add_child(fallback)
			print("Created RED fallback for player")

func _respawn_player() -> void:
	if game_over or lives <= 0:
		return

	player = PLAYER_SCENE.instantiate()
	# Spawn player in the GameViewport, use GameViewport size for positioning
	var viewport_size := Vector2(320, 180)  # GameViewport size
	player.global_position = Vector2(viewport_size.x / 2.0, viewport_size.y - 80.0)
	player.hit.connect(_on_player_hit)
	$GameViewport.add_child(player)
	# Respawn invulnerability window
	if player and player.has_method("start_invulnerability"):
		player.call_deferred("start_invulnerability", 1.2)

	# Apply dev mode settings to respawned player
	_apply_dev_invincibility_state()

func _on_spawn_timer_timeout() -> void:
	# Disabled: StageController handles enemy spawns
	pass

func _on_enemy_killed(points: int) -> void:
	# Enhanced scoring system with chain bonuses and medal multipliers
	var final_score = _calculate_enhanced_score(points)
	score += final_score

	# Update chain system
	_update_chain_system()

	# Update medal system
	_check_medal_upgrade()

	# Update displays
	_update_score_label()
	_update_chain_display()
	_update_medal_display()

	# Check for rewards
	_check_extends()
	_check_bomb_restore()

	print("Enemy killed: Base points: ", points, " Final score: ", final_score,
			" Chain: ", chain_count, " Medal: ", medal_level)

func _on_enemy_hit_player() -> void:
	_on_player_hit()

func _on_player_hit() -> void:
	if game_over:
		return

	# Play player hit sound
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_player_hit"):
		audio_manager.play_player_hit()

	# Reset chain on player hit (common in shmup games)
	_reset_chain()

	lives -= 1
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("on_player_died"):
		rm.on_player_died(lives)
	_update_lives_display()

	if lives <= 0:
		# Game over - no lives left
		game_over = true
		$GameViewport/SpawnTimer.stop()
		if is_instance_valid(hud):
			hud.call("show_game_over", true)
	else:
		# Respawn player after brief delay
		await get_tree().create_timer(1.0, false).timeout
		if not game_over:  # Check again in case game ended while waiting
			_respawn_player()

func _update_score_label() -> void:
	if is_instance_valid(hud):
		hud.call("set_score", score)

func _update_lives_display() -> void:
	if is_instance_valid(hud):
		hud.call("set_lives", lives)

func _use_bomb() -> void:
	if game_over:
		return
	if bombs <= 0:
		return

	print("Using bomb. Bombs before: ", bombs)  # Debug log

	# Play bomb sound
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_bomb_use"):
		audio_manager.play_bomb_use()

	bombs -= 1
	print("Bombs after: ", bombs)  # Debug log
	_update_bomb_display()  # Use the dedicated function for consistency
	var rm2 := get_node_or_null("/root/RankManager")
	if rm2 and rm2.has_method("on_bomb_used"):
		rm2.on_bomb_used()
	# Clear enemy bullets
	var root := get_tree().current_scene
	if root:
		var bullets := root.get_tree().get_nodes_in_group("enemy_bullet")
		for b in bullets:
			if is_instance_valid(b):
				b.call_deferred("queue_free")
		# Apply bomb AoE damage to enemies and mark kills as bomb
		var enemies := root.get_tree().get_nodes_in_group("enemy")
		for e in enemies:
			if is_instance_valid(e) and not e.is_in_group("boss"):
				if e.has_method("take_damage"):
					# Moderate bomb damage; enemies can be tuned via hp
					e.call_deferred("take_damage", 8, "bomb")
	# Small safety invulnerability
	if is_instance_valid(player) and player.has_method("start_invulnerability"):
		player.call_deferred("start_invulnerability", 0.8)

func add_score(amount: int) -> void:
	score += amount
	_update_score_label()
	_check_extends()

func add_bomb() -> void:
	bombs += 1
	_update_bomb_display()

func add_life() -> void:
	lives += 1
	_update_lives_display()

func _check_bomb_restore() -> void:
	# Check if we should restore a bomb (every 25,000 points - more frequent)
	if score >= _next_bomb_score and bombs < 3:
		print("Restoring bomb! Score: ", score, " Next bomb at: ", _next_bomb_score)  # Debug log
		# Play bomb restore sound
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_bomb_restore"):
			audio_manager.play_bomb_restore()

		bombs = min(bombs + 1, 3)  # Cap at 3 bombs
		_next_bomb_score += 25000  # Next bomb at +25k score (more frequent)
		print("Bombs after restore: ", bombs, " Next bomb at: ", _next_bomb_score)  # Debug log
		_update_bomb_display()
		# Popup: bomb restored
		if is_instance_valid(hud) and hud.has_method("show_popup"):
			hud.call_deferred("show_popup", "Bomb!")

func _check_extends() -> void:
	while score >= _next_extend_score:
		# Play extend sound
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_extend"):
			audio_manager.play_extend()

		lives += 1
		# Restore bombs on score extend (every 1,000,000 points)
		print("Score extend! Restoring bomb. Bombs before: ", bombs)  # Debug log
		bombs = min(bombs + 1, 3)  # Cap at 3 bombs
		_next_extend_score += 1000000
		print("Bombs after extend: ", bombs)  # Debug log
		_update_lives_display()
		_update_bomb_display()  # Update bomb display separately
		# Popup: life extend
		if is_instance_valid(hud) and hud.has_method("show_popup"):
			hud.call_deferred("show_popup", "Extend! ♥")

func _update_bomb_display() -> void:
	if is_instance_valid(hud):
		hud.call("set_bombs", bombs)

# Enhanced scoring system functions
func _calculate_enhanced_score(base_points: int) -> int:
	var final_score = base_points

	# Apply chain bonus (up to 3x multiplier)
	chain_bonus_multiplier = 1.0 + (chain_count * 0.1)  # +10% per kill in chain
	chain_bonus_multiplier = min(chain_bonus_multiplier, 3.0)  # Cap at 3x
	final_score = int(final_score * chain_bonus_multiplier)

	# Apply medal bonus (up to 2x multiplier)
	medal_bonus_multiplier = 1.0 + (medal_level * 0.25)  # +25% per medal level
	medal_bonus_multiplier = min(medal_bonus_multiplier, 2.0)  # Cap at 2x
	final_score = int(final_score * medal_bonus_multiplier)

	# Apply distance bonus (close-range kills get more points)
	var distance_bonus = _calculate_distance_bonus()
	final_score += distance_bonus

	return final_score

func _update_chain_system() -> void:
	var current_time = Time.get_unix_time_from_system()

	# Check if chain should continue or reset
	if current_time - last_kill_time <= chain_timeout:
		chain_count += 1
	else:
		chain_count = 1  # Reset chain

	# Update max chain if needed
	if chain_count > max_chain:
		max_chain = chain_count

	last_kill_time = current_time

func _check_medal_upgrade() -> void:
	var new_medal_level = 0

	# Medal levels based on score thresholds
	if score >= 1000000:  # 1M points
		new_medal_level = 3  # Platinum
	elif score >= 500000:   # 500K points
		new_medal_level = 2  # Gold
	elif score >= 200000:   # 200K points
		new_medal_level = 1  # Silver
	else:
		new_medal_level = 0  # Bronze

	# Check if medal level increased
	if new_medal_level > medal_level:
		medal_level = new_medal_level
		_show_medal_upgrade(new_medal_level)

func _show_medal_upgrade(new_medal_level: int) -> void:
	var medal_names = ["Bronze", "Silver", "Gold", "Platinum"]

	if is_instance_valid(hud) and hud.has_method("show_popup"):
		var message = medal_names[new_medal_level] + " Medal!"
		hud.call_deferred("show_popup", message)

	# Play medal upgrade sound
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_medal_upgrade"):
		audio_manager.play_medal_upgrade()

func _update_chain_display() -> void:
	if is_instance_valid(hud) and hud.has_method("set_chain"):
		hud.call("set_chain", chain_count, max_chain)

func _update_medal_display() -> void:
	if is_instance_valid(hud) and hud.has_method("set_medal"):
		hud.call("set_medal", medal_level)

func _reset_chain() -> void:
	# Reset chain count when player gets hit
	chain_count = 0
	_update_chain_display()
	# Also reset the HUD timer bar
	if is_instance_valid(hud) and hud.has_method("reset_streak_timer"):
		hud.call("reset_streak_timer")
	print("Chain reset due to player hit")

func _on_boss_defeated() -> void:
	# Special boss defeat handling with bonus scoring
	var boss_bonus = 50000  # Base boss bonus
	var chain_bonus = chain_count * 1000  # Bonus based on current chain
	var medal_bonus = medal_level * 5000  # Bonus based on medal level

	var total_boss_bonus = boss_bonus + chain_bonus + medal_bonus
	score += total_boss_bonus

	# Show boss defeated popup
	if is_instance_valid(hud) and hud.has_method("show_popup"):
		var message = "Boss Defeated! +" + str(total_boss_bonus) + " pts"
		hud.call_deferred("show_popup", message)

	# Update displays
	_update_score_label()
	_update_chain_display()
	_update_medal_display()

	print("Boss defeated! Bonus: ", total_boss_bonus, " Chain: ", chain_count, " Medal: ", medal_level)

func _calculate_distance_bonus() -> int:
	# Calculate distance bonus based on player position relative to screen
	# Close-range kills get bonus points (risk-reward system)
	if not is_instance_valid(player):
		return 0

	var screen_center = Vector2(160, 90)  # Half of 320x180
	var player_pos = player.global_position
	var distance = player_pos.distance_to(screen_center)
	var max_distance = 100.0  # Maximum distance for full bonus

	# Closer to center = more bonus points (up to 1000 points)
	var distance_ratio = 1.0 - (distance / max_distance)
	distance_ratio = clamp(distance_ratio, 0.0, 1.0)

	return int(distance_ratio * 1000)

func _is_player_stuck() -> bool:
	# Check if player is stuck in a dangerous position
	# This can be used for emergency bomb restoration
	if not is_instance_valid(player):
		return false

	var player_pos = player.global_position

	# Player is considered "stuck" if too close to screen edges
	var screen_bounds = Vector2(320, 180)
	var edge_threshold = 20.0

	return (player_pos.x <= edge_threshold or
			player_pos.x >= screen_bounds.x - edge_threshold or
			player_pos.y <= edge_threshold or
			player_pos.y >= screen_bounds.y - edge_threshold)

func _emergency_bomb_restore() -> void:
	# Emergency bomb restoration when player is in danger
	if bombs <= 0 and _is_player_stuck():
		print("Emergency bomb restoration!")
		bombs = 1
		_update_bomb_display()

		# Play emergency sound
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_bomb_restore"):
			audio_manager.play_bomb_restore()

func _reset_scoring_system() -> void:
	# Reset all scoring system variables when restarting
	score = 0
	chain_count = 0
	max_chain = 0
	last_kill_time = 0.0
	medal_level = 0
	_next_extend_score = 500000
	_next_bomb_score = 25000
	_next_medal_score = 100000
	base_score_multiplier = 1.0
	chain_bonus_multiplier = 1.0
	medal_bonus_multiplier = 1.0
	print("Scoring system reset")

func pause_bgm() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.stream_paused = true

func resume_bgm() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.stream_paused = false

# Developer mode functions
func _toggle_dev_mode() -> void:
	dev_mode = not dev_mode
	dev_invincibility = dev_mode
	dev_audio_muted = dev_mode

	# Apply audio muting
	_apply_dev_audio_state()

	# Apply player invincibility
	_apply_dev_invincibility_state()

	# Show dev mode status
	if is_instance_valid(hud):
		if hud.has_method("show_popup"):
			var status = "ENABLED" if dev_mode else "DISABLED"
			var popup_text = "DEV MODE %s\nInvincibility: %s\nAudio: %s" % [
				status,
				"ON" if dev_invincibility else "OFF",
				"MUTED" if dev_audio_muted else "ON"
			]
			hud.call_deferred("show_popup", popup_text, Color.CYAN if dev_mode else Color.WHITE)

		# Update persistent dev info display
		if hud.has_method("set_dev_info"):
			hud.call_deferred("set_dev_info", dev_mode, dev_invincibility, dev_audio_muted)

func _apply_dev_audio_state() -> void:
	# Mute/unmute AudioManager
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		for audio_player in audio_manager.audio_players:
			if is_instance_valid(audio_player):
				audio_player.volume_db = -80.0 if dev_audio_muted else -10.0

	# Mute/unmute BGM
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = -80.0 if dev_audio_muted else 0.0

func _apply_dev_invincibility_state() -> void:
	# Apply invincibility to current player
	if is_instance_valid(player) and player.has_method("set_dev_invincibility"):
		player.call_deferred("set_dev_invincibility", dev_invincibility)


func _optimize_rendering_pipeline() -> void:
	# Optimize rendering settings for shader-enabled performance
	var game_viewport = $GameViewport
	var dither_viewport = $PostDitherViewport

	# Set optimal viewport settings for shader pipeline
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	game_viewport.transparent_bg = false

	# Configure dither viewport for shader performance
	dither_viewport.size = Vector2i(320, 180)
	dither_viewport.transparent_bg = false
	dither_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	print("Rendering pipeline optimized for shader-enabled performance")
