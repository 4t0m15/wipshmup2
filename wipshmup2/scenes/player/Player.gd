extends CharacterBody2D

signal hit

@export var speed: float = 400.0
@export var fire_cooldown_s: float = 0.08
@export var sprite_target_height_px: float = 20.0
@export var focus_speed_multiplier: float = 0.4
@export var invuln_blink_interval_s: float = 0.08
@export var small_icons_per_level: int = 5

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet/Bullet.tscn")

var _can_fire: bool = true
var _alive: bool = true
var _invulnerable: bool = false
var _shot_level: int = 1 # 1..5
var _small_shot_icons_collected: int = 0
var _option_count: int = 0 # 0..4

func _ready() -> void:
	add_to_group("player")
	if has_node("Hurtbox"):
		$Hurtbox.add_to_group("player_hurtbox")
		$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	# Normalize sprite size to target height
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		if spr and spr.texture:
			var tex_size: Vector2i = spr.texture.get_size()
			if tex_size.y > 0:
				var s: float = sprite_target_height_px / float(tex_size.y)
				spr.scale = Vector2(s, s)

func _physics_process(_delta: float) -> void:
	if not _alive:
		return
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	var focusing := (InputMap.has_action("focus") and Input.is_action_pressed("focus")) or Input.is_key_pressed(KEY_SHIFT)
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
	if not _can_fire or not _alive:
		return
	_can_fire = false
	var root := get_tree().current_scene
	var container := root.get_node_or_null("GameViewport/Bullets") if root else null
	var bullets_fired: int = 0
	# Main shot pattern based on level
	var patterns := _get_shot_pattern_dirs(_shot_level)
	for dir in patterns:
		var b: Area2D = BULLET_SCENE.instantiate()
		b.global_position = global_position + Vector2(0, -20)
		b.set("direction", dir)
		if container:
			container.add_child(b)
		else:
			root.add_child(b)
		bullets_fired += 1
	# Options add extra straight shots
	var offsets := _get_option_offsets(_option_count)
	for off in offsets:
		var b2: Area2D = BULLET_SCENE.instantiate()
		b2.global_position = global_position + off
		b2.set("direction", Vector2.UP)
		if container:
			container.add_child(b2)
		else:
			root.add_child(b2)
		bullets_fired += 1
	# Rank hook
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("on_shot_fired"):
		rm.on_shot_fired(float(max(1, bullets_fired)))
	await get_tree().create_timer(fire_cooldown_s, false).timeout
	_can_fire = true

func _get_shot_pattern_dirs(level: int) -> Array:
	match clamp(level, 1, 5):
		1:
			return [Vector2.UP]
		2:
			return [Vector2.UP, Vector2.UP.rotated(deg_to_rad(-10)), Vector2.UP.rotated(deg_to_rad(10))]
		3:
			return [Vector2.UP.rotated(deg_to_rad(-12)), Vector2.UP, Vector2.UP.rotated(deg_to_rad(12))]
		4:
			return [Vector2.UP.rotated(deg_to_rad(-15)), Vector2.UP.rotated(deg_to_rad(-5)), Vector2.UP.rotated(deg_to_rad(5)), Vector2.UP.rotated(deg_to_rad(15))]
		5:
			return [Vector2.UP.rotated(deg_to_rad(-18)), Vector2.UP.rotated(deg_to_rad(-9)), Vector2.UP, Vector2.UP.rotated(deg_to_rad(9)), Vector2.UP.rotated(deg_to_rad(18))]
	return [Vector2.UP]

func _get_option_offsets(count: int) -> Array:
	var c: int = clamp(count, 0, 4)
	match c:
		0:
			return []
		1:
			return [Vector2(-10, -18)]
		2:
			return [Vector2(-12, -18), Vector2(12, -18)]
		3:
			return [Vector2(-14, -18), Vector2(0, -24), Vector2(14, -18)]
		4:
			return [Vector2(-16, -18), Vector2(-6, -22), Vector2(6, -22), Vector2(16, -18)]
	return []

func die() -> void:
	if not _alive:
		return
	_alive = false
	emit_signal("hit")
	queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if _invulnerable:
		return
	if area.is_in_group("enemy") or area.is_in_group("enemy_bullet"):
		die()

func start_invulnerability(duration_s: float = 1.2) -> void:
	if _invulnerable:
		return
	_invulnerable = true
	var end_time := Time.get_ticks_msec() + int(duration_s * 1000.0)
	while Time.get_ticks_msec() < end_time and is_instance_valid(self):
		if has_node("Sprite2D"):
			$Sprite2D.visible = not $Sprite2D.visible
		await get_tree().create_timer(invuln_blink_interval_s, false).timeout
	if has_node("Sprite2D"):
		$Sprite2D.visible = true
	_invulnerable = false

func apply_shot_item(is_large: bool) -> void:
	if is_large:
		_shot_level = clamp(_shot_level + 1, 1, 5)
	else:
		_small_shot_icons_collected += 1
		if _small_shot_icons_collected >= max(1, small_icons_per_level):
			_small_shot_icons_collected = 0
			_shot_level = clamp(_shot_level + 1, 1, 5)

func apply_option_item() -> void:
	_option_count = clamp(_option_count + 1, 0, 4)
