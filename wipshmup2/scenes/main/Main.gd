extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const STAGE_CONTROLLER_SCRIPT: Script = preload("res://scripts/StageController.gd")
const CRT_SHADER: Shader = preload("res://shaders/crt.gdshader")
const DITHER_SHADER: Shader = preload("res://shaders/dither_viewport.gdshader")

var score: int = 0
var game_over: bool = false
var lives: int = 3
var bombs: int = 3
var bomb_shards: int = 0
var player: CharacterBody2D
var stage_controller: Node
var hud: CanvasLayer

var _next_extend_score: int = 1000000

func _ready() -> void:
	# Start in windowed mode; fullscreen can cause issues on some platforms/drivers
	# Use Command+F (macOS) or Alt+Enter (others) to toggle fullscreen from the editor.
	add_to_group("game")
	_spawn_player()
	# Use StageController instead of random spawns
	stage_controller = STAGE_CONTROLLER_SCRIPT.new()
	$GameViewport.add_child(stage_controller)
	stage_controller.enemy_killed.connect(_on_enemy_killed)
	stage_controller.start_run()
	# HUD
	hud = $HUD
	_update_score_label()
	_update_lives_display()
	_update_bomb_display()
	# Hook medal value to HUD
	var idm := get_node_or_null("/root/ItemDropManager")
	if idm:
		if idm.has_signal("medal_value_changed"):
			idm.medal_value_changed.connect(func(v: int):
				if is_instance_valid(hud):
					hud.call_deferred("set_medal_value", v)
			)
		# Initialize HUD medal value
		if idm.has_method("get_medal_value"):
			var mv: int = idm.get_medal_value()
			if is_instance_valid(hud):
				hud.call_deferred("set_medal_value", mv)
	# Hook 50 TPS tick to HUD display (TPS averaged inside HUD)
	var tm := get_node_or_null("/root/TickManager")
	if tm and tm.has_signal("tick"):
		# HUD listens to tick itself; no need to connect here
		pass
	# Enable post-processing after first frame
	call_deferred("_enable_postfx")

func _enable_postfx() -> void:
	# Order: build dither first, then CRT reads from it
	_enable_dither()
	await _enable_crt()

func _enable_dither() -> void:
	var dither_node := $PostDitherViewport/DitherPass
	var src_viewport := $GameViewport
	var dither_viewport := $PostDitherViewport
	if not (is_instance_valid(dither_node)
		and is_instance_valid(src_viewport)
		and is_instance_valid(dither_viewport)):
		return
	# Render GameViewport into PostDitherViewport via a ColorRect using our
	# dither shader that samples an explicit uniform.
	var tex: Texture2D = src_viewport.get_texture()
	var mat := ShaderMaterial.new()
	mat.shader = DITHER_SHADER
	# Bind source texture into the explicit sampler uniform
	if tex == null:
		push_error("GameViewport texture is null; cannot apply dither shader.")
		return
	mat.set_shader_parameter("tex", tex)
	# Force strict black-and-white high-contrast output
	mat.set_shader_parameter("grayscale", true)
	mat.set_shader_parameter("dither_strength", 1.0)
	mat.set_shader_parameter("min_dither_brightness", 0.0)
	mat.set_shader_parameter("color_a", Color(0, 0, 0, 1))
	mat.set_shader_parameter("color_b", Color(1, 1, 1, 1))
	mat.set_shader_parameter("bayer_mode", 8)
	mat.set_shader_parameter("dither_repeat", 1.0)
	dither_node.material = mat
	# Ensure the dither output renders into PostDitherViewport
	dither_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return
func _enable_crt() -> void:
	var crt := $PostFX/CRT
	var dither_viewport := $PostDitherViewport
	if not is_instance_valid(crt) or not is_instance_valid(dither_viewport):
		print("ERROR: CRT or GameViewport not found!")
		return
	# Wait more frames for SubViewport to be fully ready
	for i in 5:
		await get_tree().process_frame
	print("Setting up CRT with viewport: ", dither_viewport.get_path())
	# Use the dithered SubViewport's texture as input to CRT
	var viewport_texture: Texture2D = dither_viewport.get_texture()
	# Ensure the dither viewport updates
	dither_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Create CRT shader material
	var mat := ShaderMaterial.new()
	if CRT_SHADER:
		mat.shader = CRT_SHADER
		# Set the viewport texture as the input
		mat.set_shader_parameter("tex", viewport_texture)
		# More conservative CRT settings to see content better
		mat.set_shader_parameter("mask_type", 0)  # Null mask first
		mat.set_shader_parameter("curve", 0.0)    # No curve for now
		mat.set_shader_parameter("sharpness", 1.0) # Max sharpness
		mat.set_shader_parameter("color_offset", 0.0) # No offset
		mat.set_shader_parameter("mask_brightness", 1.0)
		mat.set_shader_parameter("scanline_brightness", 1.0)
		mat.set_shader_parameter("min_scanline_thickness", 1.0) # Thick scanlines
		mat.set_shader_parameter("aspect", 0.5625)  # 180/320 = 0.5625
		mat.set_shader_parameter("wobble_strength", 0.0)
		crt.material = mat
		crt.visible = true
		print("CRT setup complete!")
	else:
		print("ERROR: CRT_SHADER not loaded!")

func _process(_delta: float) -> void:
	if game_over and Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
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
	# Spawn invulnerability window
	if player and player.has_method("start_invulnerability"):
		player.call_deferred("start_invulnerability", 1.2)

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

func _on_spawn_timer_timeout() -> void:
	# Disabled: StageController handles enemy spawns
	pass

func _on_enemy_killed(points: int) -> void:
	score += points
	_update_score_label()
	_check_extends()

func _on_enemy_hit_player() -> void:
	_on_player_hit()

func _on_player_hit() -> void:
	if game_over:
		return

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
		hud.call_deferred("set_bombs", bombs, bomb_shards)

func _use_bomb() -> void:
	if game_over:
		return
	if bombs <= 0:
		return
	bombs -= 1
	if is_instance_valid(hud):
		hud.call_deferred("set_bombs", bombs, bomb_shards)
	var rm2 := get_node_or_null("/root/RankManager")
	if rm2 and rm2.has_method("on_bomb_used"):
		rm2.on_bomb_used()
	# Clear enemy bullets
	var root := get_tree().current_scene
	if root:
		var bullets := root.get_tree().get_nodes_in_group("enemy_bullet")
		for b in bullets:
			if b and b is Node:
				(b as Node).call_deferred("queue_free")
		# Apply bomb AoE damage to enemies and mark kills as bomb
		var enemies := root.get_tree().get_nodes_in_group("enemy")
		for e in enemies:
			if e and e is Node and not (e as Node).is_in_group("boss"):
				if (e as Node).has_method("take_damage"):
					# Moderate bomb damage; enemies can be tuned via hp
					(e as Node).call_deferred("take_damage", 8, "bomb")
	# Small safety invulnerability
	if is_instance_valid(player) and player.has_method("start_invulnerability"):
		player.call_deferred("start_invulnerability", 0.8)

func add_score(amount: int) -> void:
	score += amount
	_update_score_label()
	_check_extends()

func _check_extends() -> void:
	while score >= _next_extend_score:
		lives += 1
		_next_extend_score += 1000000
		_update_lives_display()

func _update_bomb_display() -> void:
	if is_instance_valid(hud):
		hud.call("set_bombs", bombs, bomb_shards)

func add_bomb_shards(count: int) -> void:
	bomb_shards = max(0, bomb_shards + count)
	while bomb_shards >= 40:
		bombs += 1
		bomb_shards -= 40
	_update_bomb_display()
