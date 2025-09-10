extends CharacterBody2D

signal hit

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet/Bullet.tscn")

@export var speed: float = 160.0
@export var fire_cooldown_s: float = 0.12
@export var focus_speed_multiplier: float = 0.4
@export var invuln_blink_interval_s: float = 0.08

var _can_fire: bool = true
var _alive: bool = true
var _invulnerable: bool = false
var _shot_level: int = 1
var _option_count: int = 0
var _dev_invincibility: bool = false

func _ready() -> void:
	add_to_group("player")
	if has_node("Hurtbox"):
		$Hurtbox.add_to_group("player_hurtbox")
		$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# Use SpriteManager to setup sprite
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		print("BEFORE SpriteManager - Player sprite: visible=", spr.visible, " scale=", spr.scale)
		print("Texture present: ", spr.texture != null)
		if spr.texture:
			print("Texture size: ", spr.texture.get_size())
		SpriteManager.auto_setup_player_sprite(spr)
		print("AFTER SpriteManager - Player sprite: visible=", spr.visible)
		print("Scale: ", spr.scale, " modulate=", spr.modulate)

		# FORCE VISIBILITY - Make sprite clearly visible (keep SpriteManager color)
		spr.visible = true
		# Let SpriteManager handle the modulate color for differentiation
		print("Player sprite setup via SpriteManager.")
	else:
		print("Player missing Sprite2D node! Creating fallback.")
		_create_fallback_sprite()

	# Remove the emergency marker since it's making the player look wrong
	# The actual player sprite should be visible now with proper scale


func _create_fallback_sprite() -> void:
	# Create a simple colored rectangle as a fallback - remove the extra fallbacks
	var fallback_rect = ColorRect.new()
	fallback_rect.size = Vector2(16, 16)  # Reasonable size
	fallback_rect.color = Color.WHITE  # White should be visible through dither
	fallback_rect.position = Vector2(-8, -8)
	add_child(fallback_rect)
	print("Created WHITE fallback sprite for player.")


func _physics_process(_delta: float) -> void:
	if not _alive: return

	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var focusing := (InputMap.has_action("focus") and
		Input.is_action_pressed("focus")) or Input.is_key_pressed(KEY_SHIFT)
	var effective_speed: float = speed * (focus_speed_multiplier if focusing else 1.0)
	velocity = input_vector * effective_speed
	move_and_slide()

	var rect := get_viewport().get_visible_rect()
	global_position.x = clampf(global_position.x, 16.0, rect.size.x - 16.0)
	global_position.y = clampf(global_position.y, 16.0, rect.size.y - 16.0)
	global_position = global_position.round()

	if Input.is_action_pressed("ui_accept"):
		_shoot()

func _shoot() -> void:
	if not _can_fire or not _alive: return
	_can_fire = false

	# Play shooting sound
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_player_shot"):
		audio_manager.play_player_shot()

	var root := get_tree().current_scene
	var container := root.get_node_or_null("GameViewport/Bullets") if root else null
	var bullets_fired: int = 0

	# Main shot pattern
	var patterns := _get_shot_pattern_dirs(_shot_level)
	for dir in patterns:
		_spawn_bullet(global_position + Vector2(0, -20), dir, container, root)
		bullets_fired += 1

	# Options add extra straight shots
	var offsets := _get_option_offsets(_option_count)
	for off in offsets:
		_spawn_bullet(global_position + off, Vector2.UP, container, root)
		bullets_fired += 1

	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("on_shot_fired"):
		rm.on_shot_fired(float(max(1, bullets_fired)))

	await get_tree().create_timer(fire_cooldown_s, false).timeout
	_can_fire = true

func _spawn_bullet(pos: Vector2, direction: Vector2, container: Node, root: Node) -> void:
	var b: Area2D = BULLET_SCENE.instantiate()
	b.global_position = pos
	b.set("direction", direction)
	var target = container if container else root
	target.add_child(b)

func _get_shot_pattern_dirs(level: int) -> Array:
	var patterns = {
		1: [Vector2.UP],
		2: [Vector2.UP, Vector2.UP.rotated(deg_to_rad(-10)), Vector2.UP.rotated(deg_to_rad(10))],
		3: [Vector2.UP.rotated(deg_to_rad(-12)), Vector2.UP, Vector2.UP.rotated(deg_to_rad(12))],
		4: [Vector2.UP.rotated(deg_to_rad(-15)), Vector2.UP.rotated(deg_to_rad(-5)),
			Vector2.UP.rotated(deg_to_rad(5)), Vector2.UP.rotated(deg_to_rad(15))],
		5: [Vector2.UP.rotated(deg_to_rad(-18)), Vector2.UP.rotated(deg_to_rad(-9)),
			Vector2.UP, Vector2.UP.rotated(deg_to_rad(9)), Vector2.UP.rotated(deg_to_rad(18))]
	}
	return patterns.get(clamp(level, 1, 5), [Vector2.UP])

func _get_option_offsets(count: int) -> Array:
	var offsets = {
		0: [],
		1: [Vector2(-10, -18)],
		2: [Vector2(-12, -18), Vector2(12, -18)],
		3: [Vector2(-14, -18), Vector2(0, -24), Vector2(14, -18)],
		4: [Vector2(-16, -18), Vector2(-6, -22), Vector2(6, -22), Vector2(16, -18)]
	}
	return offsets.get(clamp(count, 0, 4), [])

func die() -> void:
	if not _alive: return
	_alive = false
	emit_signal("hit")
	queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if _invulnerable or _dev_invincibility: return
	if area.is_in_group("enemy") or area.is_in_group("enemy_bullet"):
		die()

func start_invulnerability(duration_s: float = 1.2) -> void:
	if _invulnerable: return
	_invulnerable = true
	var end_time := Time.get_ticks_msec() + int(duration_s * 1000.0)
	while Time.get_ticks_msec() < end_time and is_instance_valid(self):
		if has_node("Sprite2D") and not _dev_invincibility:  # Don't blink in dev mode
			$Sprite2D.visible = not $Sprite2D.visible
		await get_tree().create_timer(invuln_blink_interval_s, false).timeout
	if has_node("Sprite2D"):
		$Sprite2D.visible = true
	_invulnerable = false

func increase_power_level() -> void:
	# Increase shot level (max 5)
	_shot_level = min(_shot_level + 1, 5)

	# Increase option count (max 4)
	_option_count = min(_option_count + 1, 4)

	# Play power-up sound
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_power_up"):
		audio_manager.play_power_up()


func set_dev_invincibility(enabled: bool) -> void:
	_dev_invincibility = enabled
	# If enabling dev invincibility, make sure sprite is visible
	if enabled:
		if has_node("Sprite2D"):
			$Sprite2D.visible = true
			$Sprite2D.modulate = Color.CYAN  # Tint cyan to show dev mode
		# Also handle fallback sprites
		for child in get_children():
			if child is ColorRect:
				child.color = Color.MAGENTA  # Different color for dev mode fallback
	elif not enabled:
		if has_node("Sprite2D"):
			$Sprite2D.modulate = Color.WHITE  # Reset to normal color
		# Reset fallback sprites
		for child in get_children():
			if child is ColorRect:
				child.color = Color.CYAN  # Reset fallback color
