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
	"""Setup COMPREHENSIVE visual clarity enhancements for bullet visibility"""
	# Auto-classify danger level if not set
	if danger_level == 1:
		var classified = DangerLevelSystem.classify_danger_level(
			speed,
			false,  # is_homing (not implemented yet)
			accel > 0.0,  # is_accelerating
			"normal"  # pattern_type
		)
		danger_level = classified
	
	# Get visual properties from DangerLevelSystem
	var props = DangerLevelSystem.get_visual_properties(danger_level, false)
	
	# Apply settings from BulletReadability autoload
	var readability = get_node_or_null("/root/BulletReadability")
	if readability:
		# Apply colorblind filter if enabled
		if readability.colorblind_mode != "none":
			props.base_color = DangerLevelSystem.apply_colorblind_filter(
				props.base_color,
				readability.colorblind_mode
			)
			props.outline_color = DangerLevelSystem.apply_colorblind_filter(
				props.outline_color,
				readability.colorblind_mode
			)
		
		# Apply high contrast mode if enabled
		if readability.high_contrast_mode:
			props = DangerLevelSystem.apply_high_contrast(false)
	
	# Apply enhanced shader to main sprite
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		var shader_material = ShaderMaterial.new()
		shader_material.shader = load("res://shaders/bullet_enhanced_readability.gdshader")
		
		# Set shader parameters from props
		shader_material.set_shader_parameter("base_color", props.base_color)
		shader_material.set_shader_parameter("outline_color", props.outline_color)
		shader_material.set_shader_parameter("glow_color", props.glow_color)
		shader_material.set_shader_parameter("outline_thickness", props.outline_thickness)
		shader_material.set_shader_parameter("enable_pulse", props.should_pulse)
		shader_material.set_shader_parameter("pulse_speed", props.pulse_rate)
		shader_material.set_shader_parameter("enable_far_glow", danger_level == 3)  # High danger only
		shader_material.set_shader_parameter("high_contrast_mode", readability.high_contrast_mode if readability else false)
		
		# Apply settings multipliers
		if readability:
			shader_material.set_shader_parameter("glow_intensity", readability.glow_intensity)
			sprite.scale = sprite.scale * readability.bullet_size_multiplier
		
		sprite.material = shader_material
	
	# Setup trail if enabled
	if has_trail and readability and readability.trail_intensity > 0.0:
		_create_trail_system()

func _update_visual_effects(delta: float) -> void:
	"""Update visual effects for better clarity with PROXIMITY BOOST"""
	# Update proximity-based glow intensity
	if has_node("Sprite2D") and $Sprite2D.material is ShaderMaterial:
		var sprite_material = $Sprite2D.material as ShaderMaterial
		
		# Calculate distance to player for proximity boost
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance_to_player = global_position.distance_to(player.global_position)
			var proximity_multiplier = DangerLevelSystem.get_proximity_glow_multiplier(distance_to_player)
			
			# Apply proximity boost to shader
			sprite_material.set_shader_parameter("proximity_boost", proximity_multiplier)
	
	# Update trail
	if has_trail and _trail_particles.size() > 0:
		_update_trail_particles(delta)

func _get_danger_color() -> Color:
	"""DEPRECATED: Get color based on danger level - Use DangerLevelSystem instead"""
	# Legacy function - now using DangerLevelSystem
	var props = DangerLevelSystem.get_visual_properties(danger_level, false)
	return props.base_color

func _create_trail_system() -> void:
	"""Create particle trail for fast bullets"""
	# TODO: Implement CPU/GPU particles based on trail_intensity setting
	pass

func _update_trail_particles(_delta: float) -> void:
	"""Update trail particle effects"""
	# TODO: Update trail positions and alpha
	pass

func set_danger_level(level: int) -> void:
	"""Set the danger level and update visual appearance"""
	danger_level = clamp(level, 1, 3)
	# Re-setup visual effects with new danger level
	_setup_visual_effects()
