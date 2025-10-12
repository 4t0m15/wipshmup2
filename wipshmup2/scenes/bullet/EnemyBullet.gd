extends Area2D

@export var speed: float = 140.0  # Reduced from 320.0 for playable speed
@export var damage: int = 1
@export var sprite_target_height_px: float = 8.0  # Increased from 6.0 for better visibility
@export var accel: float = 0.0
@export var angular_velocity_deg: float = 0.0
@export var wiggle_amp: float = 0.0
@export var wiggle_freq: float = 0.0
@export var lifespan: float = -1.0

# Visual clarity enhancements
@export var danger_level: int = 1  # 1=low, 2=medium, 3=high danger
@export var has_trail: bool = false
@export var glow_intensity: float = 0.5

var direction: Vector2 = Vector2.DOWN
var _age: float = 0.0
var _trail_particles: Array[Node2D] = []
var _glow_sprite: Sprite2D

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 2  # Enemy bullet layer
	collision_mask = 1   # Detect player layer
	add_to_group("enemy_bullet")
	
	# Debug print removed to reduce log spam during heavy fire
	
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
	
	# Setup visual clarity enhancements
	_setup_visual_effects()

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
	
	# Update visual effects
	_update_visual_effects(delta)
	
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
	# ONLY detect player hurtbox - single detection path
	if area.is_in_group("player_hurtbox"):
		# Avoid log spam during heavy fire
		EventBus.bullet_hit_player.emit(global_position)
		queue_free()

func _on_screen_exited() -> void:
	queue_free()

func _setup_visual_effects() -> void:
	"""Setup visual clarity enhancements for bullet visibility"""
	# Create glow effect
	_glow_sprite = Sprite2D.new()
	_glow_sprite.texture = $Sprite2D.texture
	_glow_sprite.scale = $Sprite2D.scale * 1.5
	_glow_sprite.modulate = _get_danger_color()
	_glow_sprite.z_index = -1
	add_child(_glow_sprite)
	
	# Setup trail if enabled
	if has_trail:
		_create_trail_system()

func _update_visual_effects(delta: float) -> void:
	"""Update visual effects for better clarity"""
	# Update glow pulsing
	if _glow_sprite:
		var pulse = 0.8 + 0.2 * sin(_age * 10.0)
		_glow_sprite.modulate.a = pulse * glow_intensity
		_glow_sprite.modulate = _get_danger_color() * Color(1, 1, 1, _glow_sprite.modulate.a)
	
	# Update trail
	if has_trail and _trail_particles.size() > 0:
		_update_trail_particles(delta)

func _get_danger_color() -> Color:
	"""Get color based on danger level for visual clarity"""
	match danger_level:
		1: return Color(0.8, 0.8, 1.0, 1.0)  # Light blue - low danger
		2: return Color(1.0, 0.8, 0.2, 1.0)  # Yellow - medium danger  
		3: return Color(1.0, 0.3, 0.3, 1.0)  # Red - high danger
		_: return Color.WHITE

func _create_trail_system() -> void:
	"""Create particle trail for fast bullets"""
	# Simple trail implementation - could be enhanced with proper particles
	pass

func _update_trail_particles(_delta: float) -> void:
	"""Update trail particle effects"""
	# Trail particle update logic
	pass

func set_danger_level(level: int) -> void:
	"""Set the danger level and update visual appearance"""
	danger_level = clamp(level, 1, 3)
	if _glow_sprite:
		_glow_sprite.modulate = _get_danger_color()
