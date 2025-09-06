

extends Node2D


class_name SpaceBackground



# Space background configuration



var parallax_background: CustomParallaxBackground
@export var config: SpaceBackgroundConfig
@export var config_auto_apply: bool = true
@export var auto_lod_summary_interval: float = 0.0
var _lod_summary_timer: float = 0.0



@export var enable_star_field: bool = true

@export var star_count: int = 100

@export var star_speed_range: Vector2 = Vector2(10.0, 50.0)

@export var enable_planets: bool = true

@export var planet_count: int = 5

@export var planet_speed_range: Vector2 = Vector2(5.0, 20.0)



# Performance settings


@export var update_frequency: float = 0.5  # Logical rate: 1.0=every frame, 0.5=every 2nd, 0.25=every 4th

var _frame_counter: int = 0




# LOD configuration (frame-skipping buckets)

@export var lod_frame_mod_star_slow: int = 6

@export var lod_frame_mod_star_medium: int = 3

@export var lod_frame_mod_star_fast: int = 1

@export var lod_frame_mod_planet_small: int = 12

@export var lod_frame_mod_planet_medium: int = 6

@export var lod_frame_mod_planet_large: int = 3

var _lod_frame: int = 0



# Internal arrays for dynamic elements

var _stars: Array[Node2D] = []

var _planets: Array[Node2D] = []

var _viewport_size: Vector2



# Object pooling configuration

@export var star_pool_size: int = 150

@export var planet_pool_size: int = 30



# Pools (inactive available objects)

var _star_pool: Array[StarBody] = []

var _planet_pool: Array[PlanetBody] = []



# Textures



var _star_texture: Texture2D



var _star_textures: Array[Texture2D] = []

var _planet_textures: Array[Texture2D] = []

@export var asset_base_dir: String = "res://assets2/Space"  # Override base directory for space art assets





func _ready():

	_viewport_size = get_viewport().get_visible_rect().size


	_load_textures()

	if config and config_auto_apply:
		config.apply_to(self)


	await _setup_parallax_background()

	_initialize_pools()

	if enable_star_field:

		_create_star_field()

	if enable_planets:

		_create_planets()



# -----------------------------

# Pool Initialization

# -----------------------------

func _initialize_pools():

	while _star_pool.size() < star_pool_size:

		_star_pool.append(_create_star(true) as StarBody)

	while _planet_pool.size() < planet_pool_size:

		_planet_pool.append(_create_planet(true) as PlanetBody)



func _get_star_from_pool() -> StarBody:

	if _star_pool.size() > 0:

		return _star_pool.pop_back()

	return _create_star(true) as StarBody



func _get_planet_from_pool() -> PlanetBody:

	if _planet_pool.size() > 0:

		return _planet_pool.pop_back()

	return _create_planet(true) as PlanetBody



# -----------------------------

# Initialization / Setup
# -----------------------------


func _load_textures():

	# Unified loader using override-able base directory (supports assets2 migration)
	_star_textures.clear()
	var star_files := [
		"SpaceJunk.png",
		"SpaceJunk_500.png"
	]
	for fn in star_files:
		var p = asset_base_dir + "/" + fn
		var tex: Texture2D = load(p)
		if tex:
			_star_textures.append(tex)
		else:
			push_warning("SpaceBackground: Missing star texture: " + p)
	if _star_textures.size() > 0:
		_star_texture = _star_textures[0]
	else:
		push_warning("SpaceBackground: No star textures loaded; stars will be invisible")



	_planet_textures.clear()

	var planet_files := [
		"Planet_1.png",
		"Planet_2.png",
		"Asteroid.png"
	]
	for fn in planet_files:
		var p = asset_base_dir + "/" + fn
		var tex: Texture2D = load(p)
		if tex:
			_planet_textures.append(tex)
		else:
			push_warning("SpaceBackground: Missing planet texture: " + p)

	_validate_loaded_textures()






func _setup_parallax_background():



	if not parallax_background:


		parallax_background = CustomParallaxBackground.new()



		parallax_background.name = "ParallaxBackground"



		add_child(parallax_background)



		await get_tree().process_frame



	elif typeof(parallax_background) != TYPE_OBJECT or not (parallax_background is CustomParallaxBackground):
		var replacement := CustomParallaxBackground.new()
		replacement.name = "ParallaxBackground"
		add_child(replacement)
		parallax_background = replacement
	parallax_background.global_scroll_speed = Vector2(50.0, 0.0)


	parallax_background.enable_vertical_scroll = false


	if parallax_background.layers.is_empty():



		parallax_background.add_layer(load(asset_base_dir + "/Galaxy.png"), Vector2(0.1, 0.1))



		parallax_background.add_layer(preload("res://assets/Space/Sun.png"), Vector2(0.3, 0.3))


# -----------------------------

# Dynamic Element Creation

# -----------------------------

func _create_star_field():


	for i in range(star_count):



		var star: StarBody = _create_star() as StarBody



		_stars.append(star)





func _create_star(for_pool: bool = false) -> Node2D:
	# Rewritten to use StarBody typed entity (replaces ad-hoc Node2D + meta usage)
	var star: StarBody = StarBody.new()
	add_child(star)  # Parent early so viewport lookups (if any) work inside initialize

	# Pick a random variant if we have multi-frame textures
	var star_texture: Texture2D = _star_texture
	if _star_textures.size() > 0:
		star_texture = _star_textures[randi() % _star_textures.size()]

	star.initialize(
		star_texture,
		star_speed_range,              # speed_range
		Vector2(0.3, 1.0),             # alpha range
		Vector2(-0.2, 0.2),            # vertical direction variance
		lod_frame_mod_star_slow,
		lod_frame_mod_star_medium,
		lod_frame_mod_star_fast,
		_viewport_size
	)
	if for_pool:
		# Immediately detach for pool storage (caller will not keep it parented)
		remove_child(star)
	return star

# -----------------------------
# Validation / Integrity
# -----------------------------
func _validate_loaded_textures() -> void:
	if _star_textures.is_empty():
		push_warning("SpaceBackground: No star textures loaded")
	if _planet_textures.is_empty():
		push_warning("SpaceBackground: No planet textures loaded")
	# Defer deeper integrity check until after parallax setup
	call_deferred("_background_integrity_check")

func _background_integrity_check() -> void:
	if not is_instance_valid(parallax_background):
		push_warning("SpaceBackground: Parallax background missing after setup")
		return
	if parallax_background.layers.is_empty():
		push_warning("SpaceBackground: No parallax layers present; consider a config or manual add_layer() calls")
	else:
		print("SpaceBackground: Integrity OK -> parallax_layers=", parallax_background.layers.size(),
			" star_textures=", _star_textures.size(), " planet_textures=", _planet_textures.size())





func _configure_star_runtime(star: Node2D):

	# Legacy function kept for backward compatibility during transition.

	# If a StarBody is passed, we just refresh it; otherwise no-op.
	if star is StarBody:
		(star as StarBody).reconfigure_for_reuse()





func _create_planets():

	var target = min(planet_count, planet_pool_size)

	for i in range(target):

		var planet: PlanetBody = _get_planet_from_pool()

		_configure_planet_runtime(planet)

		_planets.append(planet)

		# Planet already parented inside creation unless fetched from pool detached; if detached we attach once

		if planet.get_parent() == null:
			add_child(planet)





func _create_planet(for_pool: bool = false) -> Node2D:

	# Use typed PlanetBody now

	var planet: PlanetBody = PlanetBody.new()
	add_child(planet)
	planet.initialize(_planet_textures[randi() % _planet_textures.size()], _viewport_size)

	if for_pool:

		remove_child(planet)
	return planet





func _configure_planet_runtime(planet: Node2D):

	# Bridge for legacy path. Refresh if typed.

	if planet is PlanetBody:
		(planet as PlanetBody).reconfigure_for_reuse()




func _process(delta: float):


	_frame_counter += 1
	_lod_frame += 1

	if update_frequency <= 0.0:
		return
	var frames_per_update := int(round(1.0 / max(update_frequency, 0.0001)))
	frames_per_update = max(frames_per_update, 1)
	if (_frame_counter % frames_per_update) != 0:
		return



	_update_stars(delta)



	_update_planets(delta)



	_recycle_offscreen_objects()

	# Config-driven periodic LOD summary (centralized in config)
	if config:
		config.process_debug(delta, self)

	# Local optional periodic LOD summary (independent of config auto_print)
	if auto_lod_summary_interval > 0.0:
		_lod_summary_timer += delta
		if _lod_summary_timer >= auto_lod_summary_interval:
			_lod_summary_timer = 0.0
			print_debug_lod_summary()





func _update_stars(delta: float):

	for star in _stars:

		if not is_instance_valid(star):

			continue

		if star is StarBody:

			var sb: StarBody = star
			if sb.lod_mod > 1 and (_lod_frame % sb.lod_mod) != 0:
				continue

			sb.tick(delta)

			sb.wrap_if_past_left()
		else:
			# Fallback: legacy node (should phase out)
			continue





func _update_planets(delta: float):

	for planet in _planets:

		if not is_instance_valid(planet):

			continue

		if planet is PlanetBody:

			var pb: PlanetBody = planet
			if pb.lod_mod > 1 and (_lod_frame % pb.lod_mod) != 0:

				continue

			pb.tick(delta)

			pb.wrap_if_past_left()
		else:
			continue




# -----------------------------

# Control / API

# -----------------------------

func set_scroll_speed(speed: Vector2):

	if parallax_background:

		parallax_background.set_scroll_speed(speed)



func set_horizontal_scroll(enabled: bool, speed: float = 50.0):

	if parallax_background:

		parallax_background.global_scroll_speed.x = speed if enabled else 0.0



func set_vertical_scroll(enabled: bool, speed: float = 30.0):

	if parallax_background:

		parallax_background.set_vertical_scroll(enabled, speed)



func get_scroll_offset() -> Vector2:

	if parallax_background and parallax_background.has_method("get_scroll_offset"):

		return parallax_background.get_scroll_offset()

	return Vector2.ZERO



func reset_background():

	if parallax_background:

		for layer in parallax_background.layers:

			if layer and is_instance_valid(layer) and layer.has_method("reset_scroll"):

				layer.reset_scroll()

	for star in _stars:

		if is_instance_valid(star):

			star.position = Vector2(

				randf_range(-_viewport_size.x * 0.5, _viewport_size.x * 1.5),

				randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)

			)

	for planet in _planets:

		if is_instance_valid(planet):

			planet.position = Vector2(

				randf_range(-_viewport_size.x * 0.5, _viewport_size.x * 1.5),

				randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)

			)



# -----------------------------

# Utility

# -----------------------------

func clear_dynamic_elements():

	for star in _stars:

		if is_instance_valid(star):

			star.queue_free()

	for planet in _planets:

		if is_instance_valid(planet):

			planet.queue_free()

	_stars.clear()

	_planets.clear()




func regenerate(stars: int = star_count, planets: int = planet_count):

	clear_dynamic_elements()

	star_count = stars

	planet_count = planets

	if enable_star_field:

		_create_star_field()

	if enable_planets:

		_create_planets()
	print_debug_lod_summary()




func _recycle_offscreen_objects():

	for star in _stars:
		if not is_instance_valid(star):
			continue
		if star.position.x < -_viewport_size.x * 0.6:

			star.position.x = _viewport_size.x * 1.4

			star.position.y = randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)

	for planet in _planets:

		if not is_instance_valid(planet):

			continue

		if planet.position.x < -_viewport_size.x * 0.7:

			planet.position.x = _viewport_size.x * 1.5

			planet.position.y = randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)

# -----------------------------
# Debug Utilities
# -----------------------------
func print_debug_lod_summary():
	var star_summary := StarBody.lod_distribution(_stars)
	var planet_hist := PlanetBody.lod_distribution(_planets)
	print("[SpaceBackground] LOD Summary Stars=%s Planets=%s" % [str(star_summary), str(planet_hist)])
