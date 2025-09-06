extends Node2D
class_name BackgroundManager

# Advanced Background Manager for Enhanced Visual Experience
# Features: Multi-layer parallax, dynamic effects, environmental storytelling

signal background_changed(environment_type: String)

enum EnvironmentType {
	SPACE_DEEP,
	ASTEROID_FIELD,
	NEBULA,
	PLANET_ORBIT,
	STAR_SYSTEM,
	BASE_APPROACH,
	COMBAT_ZONE
}

# Background layer configuration
class BackgroundLayer:
	var node: Node2D
	var scroll_speed: float
	var parallax_factor: float
	var base_position: Vector2
	var texture: Texture2D
	var scale: Vector2
	var modulate: Color
	var animation_speed: float = 0.0
	var animation_type: String = "none" # "rotate", "pulse", "drift", "twinkle"
	
	func _init(n: Node2D, speed: float, factor: float, pos: Vector2, tex: Texture2D, scl: Vector2, mod: Color):
		node = n
		scroll_speed = speed
		parallax_factor = factor
		base_position = pos
		texture = tex
		scale = scl
		modulate = mod

# Current environment and state
var current_environment: EnvironmentType = EnvironmentType.SPACE_DEEP
var background_layers: Array[BackgroundLayer] = []
var star_field: Node2D
var particle_systems: Array[GPUParticles2D] = []
var dynamic_elements: Array[Node2D] = []

# Animation and effect timers
var animation_timer: float = 0.0
var environment_timer: float = 0.0
var twinkle_timer: float = 0.0

# Configuration
var base_scroll_speed: float = 30.0
var camera_offset: Vector2 = Vector2.ZERO
var intensity_multiplier: float = 1.0

func _ready():
	print("BackgroundManager: Initializing advanced background system")
	_setup_star_field()
	_setup_particle_systems()
	_create_environment(EnvironmentType.SPACE_DEEP)

func _process(delta: float):
	animation_timer += delta
	environment_timer += delta
	twinkle_timer += delta
	
	_update_parallax_scrolling(delta)
	_update_animations(delta)
	_update_particle_systems(delta)
	_update_star_field(delta)
	
	# Environment progression (changes based on score/time)
	_check_environment_progression()

func _setup_star_field():
	"""Create a dynamic star field with twinkling effects"""
	star_field = Node2D.new()
	star_field.name = "StarField"
	add_child(star_field)
	
	# Create multiple star layers for depth
	for i in range(3):
		var star_layer = Node2D.new()
		star_layer.name = "StarLayer_" + str(i)
		star_field.add_child(star_layer)
		
		# Create stars for this layer
		_create_star_layer(star_layer, i)

func _create_star_layer(layer: Node2D, depth: int):
	"""Create stars for a specific depth layer"""
	var star_count = 20 + depth * 10
	var star_size = 1.0 + depth * 0.5
	var star_brightness = 0.3 + depth * 0.2
	
	for i in range(star_count):
		var star = ColorRect.new()
		star.size = Vector2(star_size, star_size)
		star.color = Color(star_brightness, star_brightness, star_brightness, 1.0)
		star.position = Vector2(
			randf() * 400,
			randf() * 200
		)
		layer.add_child(star)

func _setup_particle_systems():
	"""Setup particle systems for cosmic effects"""
	# Cosmic dust particles
	var dust_particles = GPUParticles2D.new()
	dust_particles.name = "CosmicDust"
	dust_particles.emitting = true
	dust_particles.amount = 50
	dust_particles.lifetime = 10.0
	dust_particles.process_material = _create_dust_material()
	dust_particles.position = Vector2(160, 90)
	add_child(dust_particles)
	particle_systems.append(dust_particles)
	
	# Energy particles
	var energy_particles = GPUParticles2D.new()
	energy_particles.name = "EnergyParticles"
	energy_particles.emitting = true
	energy_particles.amount = 30
	energy_particles.lifetime = 5.0
	energy_particles.process_material = _create_energy_material()
	energy_particles.position = Vector2(160, 90)
	add_child(energy_particles)
	particle_systems.append(energy_particles)

func _create_dust_material() -> ParticleProcessMaterial:
	"""Create material for cosmic dust particles"""
	var dust_material = ParticleProcessMaterial.new()
	dust_material.direction = Vector3(0, 1, 0)
	dust_material.initial_velocity_min = 5.0
	dust_material.initial_velocity_max = 15.0
	dust_material.gravity = Vector3(0, 0, 0)
	dust_material.scale_min = 0.5
	dust_material.scale_max = 2.0
	dust_material.color = Color(0.3, 0.2, 0.4, 0.3)
	return dust_material

func _create_energy_material() -> ParticleProcessMaterial:
	"""Create material for energy particles"""
	var energy_material = ParticleProcessMaterial.new()
	energy_material.direction = Vector3(0, 1, 0)
	energy_material.initial_velocity_min = 10.0
	energy_material.initial_velocity_max = 25.0
	energy_material.gravity = Vector3(0, 0, 0)
	energy_material.scale_min = 1.0
	energy_material.scale_max = 3.0
	energy_material.color = Color(0.2, 0.6, 1.0, 0.6)
	return energy_material

func _create_environment(env_type: EnvironmentType):
	"""Create a specific environment with appropriate layers and effects"""
	current_environment = env_type
	
	# Clear existing layers
	_clear_background_layers()
	
	match env_type:
		EnvironmentType.SPACE_DEEP:
			_create_space_deep_environment()
		EnvironmentType.ASTEROID_FIELD:
			_create_asteroid_field_environment()
		EnvironmentType.NEBULA:
			_create_nebula_environment()
		EnvironmentType.PLANET_ORBIT:
			_create_planet_orbit_environment()
		EnvironmentType.STAR_SYSTEM:
			_create_star_system_environment()
		EnvironmentType.BASE_APPROACH:
			_create_base_approach_environment()
		EnvironmentType.COMBAT_ZONE:
			_create_combat_zone_environment()
	
	background_changed.emit(EnvironmentType.keys()[env_type])
	print("BackgroundManager: Created environment: ", EnvironmentType.keys()[env_type])

func _create_space_deep_environment():
	"""Create deep space environment with distant stars and cosmic dust"""
	# Far background - distant galaxy
	var galaxy = _create_background_sprite("res://assets/Space/Galaxy_frame_001.png")
	galaxy.position = Vector2(160, 90)
	galaxy.scale = Vector2(0.08, 0.08)
	galaxy.modulate = Color(0.4, 0.3, 0.6, 0.8)
	_add_background_layer(galaxy, 5.0, 0.1)
	
	# Mid background - nebula clouds
	var nebula = _create_background_sprite("res://assets/Space/Galaxy_frame_001.png")
	nebula.position = Vector2(80, 60)
	nebula.scale = Vector2(0.06, 0.06)
	nebula.modulate = Color(0.2, 0.1, 0.4, 0.6)
	_add_background_layer(nebula, 15.0, 0.3)
	
	# Near background - space junk
	var space_junk = _create_background_sprite("res://assets/Space/SpaceJunk_frame_001.png")
	space_junk.position = Vector2(240, 120)
	space_junk.scale = Vector2(0.04, 0.04)
	space_junk.modulate = Color(0.6, 0.5, 0.7, 0.9)
	_add_background_layer(space_junk, 25.0, 0.6)

func _create_asteroid_field_environment():
	"""Create asteroid field environment with moving rocks"""
	# Background asteroids
	for i in range(5):
		var asteroid = _create_background_sprite("res://assets/Space/Asteroid_frame_001.png")
		asteroid.position = Vector2(randf() * 320, randf() * 180)
		asteroid.scale = Vector2(0.03 + randf() * 0.02, 0.03 + randf() * 0.02)
		asteroid.modulate = Color(0.7, 0.6, 0.5, 0.8)
		_add_background_layer(asteroid, 20.0 + randf() * 10.0, 0.4)
	
	# Foreground asteroids
	for i in range(3):
		var asteroid = _create_background_sprite("res://assets/Space/Asteroid_frame_001.png")
		asteroid.position = Vector2(randf() * 320, randf() * 180)
		asteroid.scale = Vector2(0.05 + randf() * 0.03, 0.05 + randf() * 0.03)
		asteroid.modulate = Color(0.8, 0.7, 0.6, 1.0)
		_add_background_layer(asteroid, 35.0 + randf() * 15.0, 0.8)

func _create_nebula_environment():
	"""Create nebula environment with colorful gas clouds"""
	# Primary nebula
	var nebula1 = _create_background_sprite("res://assets/Space/Galaxy_frame_001.png")
	nebula1.position = Vector2(160, 90)
	nebula1.scale = Vector2(0.12, 0.12)
	nebula1.modulate = Color(0.8, 0.3, 0.6, 0.7)
	_add_background_layer(nebula1, 10.0, 0.2, "pulse")
	
	# Secondary nebula
	var nebula2 = _create_background_sprite("res://assets/Space/Galaxy_frame_001.png")
	nebula2.position = Vector2(80, 120)
	nebula2.scale = Vector2(0.08, 0.08)
	nebula2.modulate = Color(0.3, 0.6, 0.8, 0.5)
	_add_background_layer(nebula2, 15.0, 0.4, "drift")

func _create_planet_orbit_environment():
	"""Create planet orbit environment with large celestial bodies"""
	# Planet
	var planet = _create_background_sprite("res://assets/Space/Planet_1.png")
	planet.position = Vector2(280, 140)
	planet.scale = Vector2(0.08, 0.08)
	planet.modulate = Color(0.9, 0.8, 0.7, 1.0)
	_add_background_layer(planet, 8.0, 0.1, "rotate")
	
	# Sun
	var sun = _create_background_sprite("res://assets/Space/Sun.png")
	sun.position = Vector2(40, 40)
	sun.scale = Vector2(0.1, 0.1)
	sun.modulate = Color(1.0, 0.9, 0.7, 1.0)
	_add_background_layer(sun, 5.0, 0.05, "pulse")

func _create_star_system_environment():
	"""Create star system environment with multiple celestial bodies"""
	# Multiple planets
	for i in range(3):
		var planet = _create_background_sprite("res://assets/Space/Planet_" + str((i % 2) + 1) + ".png")
		planet.position = Vector2(50 + i * 100, 100 + sin(i) * 40)
		planet.scale = Vector2(0.04 + i * 0.01, 0.04 + i * 0.01)
		planet.modulate = Color(0.8, 0.7, 0.6, 0.9)
		_add_background_layer(planet, 12.0 + i * 5.0, 0.2 + i * 0.1)

func _create_base_approach_environment():
	"""Create base approach environment with station elements"""
	# Base structure
	var base = _create_background_sprite("res://assets/Base/BaseConcept_frame_001.png")
	base.position = Vector2(160, 90)
	base.scale = Vector2(0.08, 0.08)
	base.modulate = Color(0.7, 0.7, 0.8, 0.9)
	_add_background_layer(base, 20.0, 0.3)
	
	# Launch pad
	var launch_pad = _create_background_sprite("res://assets/Base/LaunchPad_N2.png")
	launch_pad.position = Vector2(160, 150)
	launch_pad.scale = Vector2(0.06, 0.06)
	launch_pad.modulate = Color(0.8, 0.8, 0.9, 1.0)
	_add_background_layer(launch_pad, 25.0, 0.5, "pulse")

func _create_combat_zone_environment():
	"""Create combat zone environment with intense effects"""
	# Explosion effects
	var explosion_bg = _create_background_sprite("res://assets/Space/Galaxy_frame_001.png")
	explosion_bg.position = Vector2(160, 90)
	explosion_bg.scale = Vector2(0.1, 0.1)
	explosion_bg.modulate = Color(1.0, 0.3, 0.2, 0.6)
	_add_background_layer(explosion_bg, 30.0, 0.4, "pulse")
	
	# Debris
	for i in range(4):
		var debris = _create_background_sprite("res://assets/Space/SpaceJunk_frame_001.png")
		debris.position = Vector2(randf() * 320, randf() * 180)
		debris.scale = Vector2(0.03 + randf() * 0.02, 0.03 + randf() * 0.02)
		debris.modulate = Color(0.8, 0.4, 0.3, 0.8)
		_add_background_layer(debris, 40.0 + randf() * 20.0, 0.7)

func _create_background_sprite(texture_path: String) -> Sprite2D:
	"""Create a background sprite with the specified texture"""
	var sprite = Sprite2D.new()
	var texture = load(texture_path)
	if texture:
		sprite.texture = texture
	else:
		print("BackgroundManager: Warning - Could not load texture: ", texture_path)
	return sprite

func _add_background_layer(sprite: Sprite2D, scroll_speed: float, parallax_factor: float, animation_type: String = "none"):
	"""Add a background layer with specified properties"""
	add_child(sprite)
	var layer = BackgroundLayer.new(sprite, scroll_speed, parallax_factor, sprite.position, sprite.texture, sprite.scale, sprite.modulate)
	layer.animation_type = animation_type
	background_layers.append(layer)

func _clear_background_layers():
	"""Clear all existing background layers"""
	for layer in background_layers:
		if is_instance_valid(layer.node):
			layer.node.queue_free()
	background_layers.clear()

func _update_parallax_scrolling(delta: float):
	"""Update parallax scrolling for all background layers"""
	for layer in background_layers:
		if not is_instance_valid(layer.node):
			continue
			
		# Calculate parallax offset
		var parallax_offset = camera_offset * layer.parallax_factor
		
		# Update position with scrolling and parallax
		layer.node.position.y += layer.scroll_speed * delta * intensity_multiplier
		layer.node.position.x = layer.base_position.x + parallax_offset.x
		
		# Reset position when off screen
		if layer.node.position.y > 200:
			layer.node.position.y = -200
			# Randomize horizontal position for variety
			layer.node.position.x = randf() * 320

func _update_animations(delta: float):
	"""Update animations for background elements"""
	for layer in background_layers:
		if not is_instance_valid(layer.node):
			continue
			
		match layer.animation_type:
			"rotate":
				layer.node.rotation += delta * 0.5
			"pulse":
				var pulse_factor = 1.0 + sin(animation_timer * 2.0) * 0.2
				layer.node.scale = layer.scale * pulse_factor
			"drift":
				layer.node.position.x += sin(animation_timer * 0.5) * delta * 10.0
			"twinkle":
				var twinkle_factor = 0.5 + sin(animation_timer * 3.0 + layer.node.position.x * 0.01) * 0.5
				layer.node.modulate.a = twinkle_factor

func _update_particle_systems(_delta: float):
	"""Update particle systems"""
	for particles in particle_systems:
		if is_instance_valid(particles):
			# Adjust particle intensity based on environment
			match current_environment:
				EnvironmentType.COMBAT_ZONE:
					particles.emitting = true
					particles.amount = 100
				EnvironmentType.NEBULA:
					particles.emitting = true
					particles.amount = 80
				_:
					particles.emitting = true
					particles.amount = 50

func _update_star_field(delta: float):
	"""Update star field with twinkling effects"""
	if not is_instance_valid(star_field):
		return
		
	for i in range(star_field.get_child_count()):
		var layer = star_field.get_child(i)
		if not is_instance_valid(layer):
			continue
			
		# Update star positions (slow drift)
		for star in layer.get_children():
			if star is ColorRect:
				star.position.y += delta * (2.0 + i * 1.0)
				if star.position.y > 200:
					star.position.y = -20
					star.position.x = randf() * 320
				
				# Twinkling effect
				var twinkle = 0.3 + sin(twinkle_timer * 2.0 + star.position.x * 0.01) * 0.2
				star.color = Color(twinkle, twinkle, twinkle, 1.0)

func _check_environment_progression():
	"""Check if environment should change based on game progression"""
	# This would typically be called by the game manager based on score, time, or stage
	# For now, we'll implement a simple time-based progression
	if environment_timer > 30.0: # Change every 30 seconds for demo
		environment_timer = 0.0
		var next_env = (current_environment + 1) % EnvironmentType.size()
		_create_environment(next_env)

# Public API functions
func set_camera_offset(offset: Vector2):
	"""Set camera offset for parallax effects"""
	camera_offset = offset

func set_intensity(intensity: float):
	"""Set background intensity multiplier"""
	intensity_multiplier = clamp(intensity, 0.1, 2.0)

func change_environment(env_type: EnvironmentType):
	"""Manually change environment"""
	_create_environment(env_type)

func get_current_environment() -> EnvironmentType:
	"""Get current environment type"""
	return current_environment

func add_dynamic_element(element: Node2D, scroll_speed: float = 20.0):
	"""Add a dynamic background element"""
	add_child(element)
	dynamic_elements.append(element)
	
	# Create a simple layer for the dynamic element
	var layer = BackgroundLayer.new(element, scroll_speed, 0.5, element.position, null, element.scale, element.modulate)
	background_layers.append(layer)
