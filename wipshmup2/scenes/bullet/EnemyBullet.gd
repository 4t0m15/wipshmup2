extends Area2D
signal hit_player

@export var speed: float = 140.0  # Reduced from 320.0 for playable speed
@export var damage: int = 1
@export var sprite_target_height_px: float = 6.0
@export var accel: float = 0.0
@export var angular_velocity_deg: float = 0.0
@export var wiggle_amp: float = 0.0
@export var wiggle_freq: float = 0.0
@export var lifespan: float = -1.0

var direction: Vector2 = Vector2.DOWN
var _age: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 2  # Enemy bullet layer
	collision_mask = 1   # Detect player layer
	add_to_group("enemy_bullet")
	
	print("[EnemyBullet] Created at position: ", position)
	
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	
	# ONLY use area_entered for hit detection - no body_entered
	area_entered.connect(_on_area_entered)
	
	# Normalize sprite size to target height
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		if spr and spr.texture:
			var tex_size: Vector2i = spr.texture.get_size()
			if tex_size.y > 0:
				var s: float = sprite_target_height_px / float(tex_size.y)
				spr.scale = Vector2(s, s)
func _physics_process(delta: float) -> void:
	_age += delta
	var speed_mult: float = 1.0
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("get_bullet_speed_multiplier"):
		speed_mult = rm.get_bullet_speed_multiplier()
	# Update speed with acceleration
	if accel != 0.0:
		speed = max(0.0, speed + accel * delta)
	# Apply angular velocity (spin)
	if angular_velocity_deg != 0.0:
		direction = direction.rotated(deg_to_rad(angular_velocity_deg) * delta).normalized()
	# Compute base displacement
	var displacement := direction * speed * speed_mult * delta
	# Apply lateral wiggle
	if wiggle_amp != 0.0 and wiggle_freq != 0.0:
		var lateral := Vector2(-direction.y, direction.x)
		displacement += lateral * (wiggle_amp * sin(_age * TAU * wiggle_freq)) * delta
	position += displacement
	position = position.round()
	if lifespan > 0.0 and _age >= lifespan:
		queue_free()
	var viewport_rect := get_viewport_rect()
	var off_top: bool = position.y < -64
	var off_bottom: bool = position.y > viewport_rect.size.y + 64
	var off_left: bool = position.x < -64
	var off_right: bool = position.x > viewport_rect.size.x + 64
	if off_top or off_bottom or off_left or off_right:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Debug: print ALL area collisions
	print("[EnemyBullet] _on_area_entered triggered! area=", area.name, " groups=", area.get_groups(), " bullet_pos=", position)
	
	# ONLY detect player hurtbox - single detection path
	if area.is_in_group("player_hurtbox"):
		print("[EnemyBullet] HIT CONFIRMED! Emitting hit_player signal")
		hit_player.emit()
		queue_free()
	else:
		print("[EnemyBullet] Not player hurtbox, ignoring")

func _on_screen_exited() -> void:
	queue_free()


