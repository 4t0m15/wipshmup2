extends Node2D
class_name PlanetBody
"""
PlanetBody.gd
Typed planet/background body entity for the scrolling space scene.

Goals:
- Replace ad-hoc Node2D + set_meta() usage with typed properties.
- Provide deterministic LOD (Level Of Detail) categorization based on BOTH visual scale and speed.
- Integrate cleanly with pooling (initialize / reconfigure_for_reuse / wrap_if_past_left).
- Offer debug utilities to inspect distribution and runtime state.

How LOD works here:
1. Primary bucket chosen by visual size (sprite.scale.x):
   - scale < lod_size_small_threshold  -> lod_mod_small
   - scale < lod_size_medium_threshold -> lod_mod_medium
   - else                              -> lod_mod_large
2. Adjustment by relative speed percent (speed_norm):
   - If very slow (< slow_speed_factor), force smallest update frequency
     (=> larger lod_mod value == fewer updates) by taking max(lod_mod, lod_mod_small).
   - This reduces update overhead for slow + small planets.

You can drive updates in a manager:
  if _lod_frame % planet_body.lod_mod == 0:
      planet_body.tick(delta)

Typical usage:
  var p := PlanetBody.new()
  add_child(p)
  p.initialize(texture, viewport_size)

Or when reusing from a pool:
  p.reconfigure_for_reuse(optional_new_texture)

Debugging:
  Call register_for_debug() and set debug_interval_seconds > 0 to
  get periodic logs. Use print_lod_summary([...]) for a snapshot.

All numeric thresholds and ranges can be tuned in the editor or
programmatically for performance / style balancing.
"""

# -------------------------------------------------
# Exported configuration
# -------------------------------------------------
@export var base_scale_range: Vector2 = Vector2(0.02, 0.08)          # Min / Max random scale
@export var speed_range: Vector2 = Vector2(5.0, 20.0)                # Min / Max horizontal speed
@export var direction_x: float = -1.0                                # Horizontal direction (negative for leftward)
@export var direction_y_variation: Vector2 = Vector2(-0.1, 0.1)      # Random vertical drift range
@export var alpha_range: Vector2 = Vector2(0.5, 1.0)                 # Transparency range
@export var rotation_speed_range: Vector2 = Vector2(-15.0, 15.0)     # Degrees per second (randomized)
@export var wrap_margin_factor: float = 0.7                          # Factor for deciding when to wrap
@export var slow_speed_factor: float = 0.25                          # If speed < (min + factor*(span)), treat as very slow for LOD adjust

# LOD thresholds (scale-based)
@export var lod_size_small_threshold: float = 0.03
@export var lod_size_medium_threshold: float = 0.05

# LOD update frame mods (bigger = fewer updates)
@export var lod_mod_small: int = 12
@export var lod_mod_medium: int = 6
@export var lod_mod_large: int = 3

# Optional periodic debug logging
@export var debug_interval_seconds: float = 0.0

# -------------------------------------------------
# Runtime (typed) state
# -------------------------------------------------
var speed: float = 0.0
var direction: Vector2 = Vector2.LEFT
var lod_mod: int = 1
var alpha: float = 1.0
var rotation_speed_deg: float = 0.0
var sprite: Sprite2D
var _viewport_size: Vector2 = Vector2.ZERO

# Debug
var _debug_timer: float = 0.0
var _registered_for_debug: bool = false

# Internal cached ranges (for reuse)
var _cached_texture: Texture2D

# -------------------------------------------------
# Lifecycle
# -------------------------------------------------
func _ready() -> void:
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

# Full initialization for new or pooled instance.
func initialize(texture: Texture2D, viewport_size: Vector2) -> void:
	_viewport_size = viewport_size
	_cached_texture = texture
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	sprite.texture = texture





	_randomize_visuals_and_motion(true) # initial configuration




	_assign_initial_position()
	_compute_and_set_lod()

# Re-randomize for reuse (optionally with a new texture)
func reconfigure_for_reuse(texture: Texture2D = null) -> void:
	if texture:
		_cached_texture = texture
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	sprite.texture = _cached_texture
	_randomize_visuals_and_motion(false)
	_assign_initial_position()
	_compute_and_set_lod()

# -------------------------------------------------
# Randomization helpers
# -------------------------------------------------
func _randomize_visuals_and_motion(_first_time: bool) -> void:
	# Scale
	var scale_val: float = randf_range(base_scale_range.x, base_scale_range.y)
	if not sprite:
		return
	sprite.scale = Vector2(scale_val, scale_val)

	# Alpha
	alpha = randf_range(alpha_range.x, alpha_range.y)
	var c := sprite.modulate
	c.a = alpha
	sprite.modulate = c

	# Speed & direction
	speed = randf_range(speed_range.x, speed_range.y)
	direction = Vector2(direction_x, randf_range(direction_y_variation.x, direction_y_variation.y))
	rotation_speed_deg = randf_range(rotation_speed_range.x, rotation_speed_range.y)

func _assign_initial_position() -> void:
	position = Vector2(
		randf_range(-_viewport_size.x * 0.5, _viewport_size.x * 1.5),
		randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)
	)

# -------------------------------------------------
# LOD Computation
# -------------------------------------------------
func _compute_and_set_lod() -> void:
	var scale_mag: float = sprite.scale.x
	lod_mod = compute_planet_lod(
		scale_mag,
		speed,
		speed_range,
		lod_size_small_threshold,
		lod_size_medium_threshold,
		lod_mod_small,
		lod_mod_medium,
		lod_mod_large,
		slow_speed_factor
	)

# Static utility for computing planet LOD
static func compute_planet_lod(
		scale_x: float,
		speed_value: float,
		speed_range_param: Vector2,
		size_small_threshold: float,
		size_medium_threshold: float,
		mod_small: int,
		mod_medium: int,
		mod_large: int,
		slow_factor: float
	) -> int:
	var base_mod: int = mod_large
	if scale_x < size_small_threshold:
		base_mod = mod_small
	elif scale_x < size_medium_threshold:
		base_mod = mod_medium
	# Adjust for speed if very slow
	var span := speed_range_param.y - speed_range_param.x
	if span > 0.0001:
		var speed_norm: float = (speed_value - speed_range_param.x) / span
		if speed_norm < slow_factor:
			# Guarantee at least small mod (largest interval)
			base_mod = max(base_mod, mod_small)
	return max(1, base_mod)

# -------------------------------------------------
# Update logic
# -------------------------------------------------
func tick(delta: float) -> void:
	# Movement
	position += direction * speed * delta
	# Rotation
	if rotation_speed_deg != 0.0:
		rotation += deg_to_rad(rotation_speed_deg) * delta

func wrap_if_past_left() -> void:
	# Wrap horizontally for infinite scrolling illusion
	if position.x < -_viewport_size.x * wrap_margin_factor:
		position.x = _viewport_size.x * 1.5
		position.y = randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)

# -------------------------------------------------
# Debug / Instrumentation
# -------------------------------------------------
func register_for_debug() -> void:
	_registered_for_debug = true
	_debug_timer = 0.0

func unregister_for_debug() -> void:
	_registered_for_debug = false

func debug_step(delta: float) -> void:
	if not _registered_for_debug or debug_interval_seconds <= 0.0:
		return
	_debug_timer += delta
	if _debug_timer >= debug_interval_seconds:
		_debug_timer = 0.0
		print("[PlanetBody] lod_mod=%d speed=%.2f scale=%.3f pos=(%.1f, %.1f)" %
			[lod_mod, speed, sprite.scale.x, position.x, position.y])

static func lod_distribution(planets: Array) -> Dictionary:
	var histogram := {}
	for p in planets:
		if p is PlanetBody:
			var lm := (p as PlanetBody).lod_mod
			histogram[lm] = (histogram.get(lm, 0) as int) + 1
	return histogram

static func print_lod_summary(planets: Array) -> void:
	var hist := lod_distribution(planets)
	print("[PlanetBody] LOD Summary -> %s" % str(hist))

# -------------------------------------------------
# Accessors / Mutators
# -------------------------------------------------
func set_speed(new_speed: float) -> void:
	speed = clamp(new_speed, 0.0, 10000.0)
	_compute_and_set_lod()

func set_direction(new_dir: Vector2) -> void:
	direction = new_dir

func set_alpha(new_alpha: float) -> void:
	alpha = clamp(new_alpha, 0.0, 1.0)
	if sprite:
		var c := sprite.modulate
		c.a = alpha
		sprite.modulate = c

func force_lod(new_lod_mod: int) -> void:
	lod_mod = max(1, new_lod_mod)

# -------------------------------------------------
# Pool lifecycle hooks (optional integration)
# -------------------------------------------------
func on_return_to_pool() -> void:
	# Placeholder for cleanup logic (disconnect signals, etc.)
	pass

func on_fetch_from_pool() -> void:
	# Placeholder for logic when fetched from a pool
	pass

# -------------------------------------------------
# Reset / Clear
# -------------------------------------------------
func reset_state() -> void:
	speed = 0.0
	direction = Vector2.LEFT
	lod_mod = 1
	alpha = 1.0
	rotation_speed_deg = 0.0
	if sprite:
		sprite.modulate = Color(1,1,1,1)
	position = Vector2.ZERO
