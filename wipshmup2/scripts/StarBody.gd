extends Node2D
class_name StarBody
"""
StarBody.gd
Typed star entity for the scrolling space background.

Purpose:
- Replaces generic Node2D + set_meta() usage with explicit typed properties.
- Encapsulates LOD (Level Of Detail) classification logic for stars.
- Provides utility helpers for pooling, recycling, and debugging.

Typical lifecycle:
1. Instance (from a pool or new).
2. call initialize(texture, speed_range, direction_variation, alpha_range, lod mods, viewport_size)
3. Each frame: call tick(delta) if LOD permits (external system decides using lod_mod)
4. If off-screen beyond left boundary: call recycle(viewport_size) or wrap()

You can integrate this into SpaceBackground by:
- Creating StarBody instead of raw Node2D in _create_star()
- Replacing meta storage with direct property access:
    star.speed
    star.direction
    star.lod_mod
    star.alpha (applied to sprite.modulate.a)

LOD Strategy:
- Stars are bucketed by relative speed percentile:
  slow (< 0.33)   -> lod_frame_mod_star_slow
  medium (< 0.66) -> lod_frame_mod_star_medium
  fast (else)     -> lod_frame_mod_star_fast

Debug Support:
- Optional periodic printing of active LOD distribution when debug_interval_seconds > 0.
"""

# -----------------------------
# Exported configuration
# -----------------------------
@export var base_scale: Vector2 = Vector2(0.02, 0.02)
@export var random_scale_jitter: float = 0.4   # +/- percentage applied to base_scale
@export var debug_interval_seconds: float = 0.0  # Set > 0 to periodically print LOD stats (requires registration via register_for_debug)

# -----------------------------
# Runtime state (typed)
# -----------------------------
var speed: float = 0.0
var direction: Vector2 = Vector2.LEFT
var lod_mod: int = 1
var alpha: float = 1.0
var sprite: Sprite2D
var _speed_range: Vector2
var _alpha_range: Vector2
var _lod_slow: int = 6
var _lod_medium: int = 3
var _lod_fast: int = 1
var _debug_timer: float = 0.0
var _registered_for_debug: bool = false

# Cached bounds (used for wrapping). Not enforced automatically; external system may choose to manage.
var _viewport_size: Vector2 = Vector2.ZERO

# -----------------------------
# Initialization
# -----------------------------
func _ready():
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

func initialize(
		texture: Texture2D,
		speed_range: Vector2,
		alpha_range: Vector2,
		direction_variation_y: Vector2,
		lod_slow: int,
		lod_medium: int,
		lod_fast: int,
		viewport_size: Vector2
	) -> void:
	"""
	Configure the star with fresh randomized parameters.
	"""
	_viewport_size = viewport_size
	_speed_range = speed_range
	_alpha_range = alpha_range
	_lod_slow = max(1, lod_slow)
	_lod_medium = max(1, lod_medium)
	_lod_fast = max(1, lod_fast)

	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

	sprite.texture = texture

	# Randomize scale
	var jitter = 1.0 + randf_range(-random_scale_jitter, random_scale_jitter)
	sprite.scale = base_scale * jitter

	# Randomize speed
	speed = randf_range(speed_range.x, speed_range.y)

	# Direction (always primarily left with slight vertical variance)
	direction = Vector2(-1.0, randf_range(direction_variation_y.x, direction_variation_y.y))

	# Alpha
	alpha = randf_range(alpha_range.x, alpha_range.y)
	sprite.modulate = Color(1, 1, 1, alpha)

	# Assign position
	position = Vector2(
		randf_range(-viewport_size.x * 0.5, viewport_size.x * 1.5),
		randf_range(-viewport_size.y * 0.5, viewport_size.y * 1.5)
	)

	# Determine LOD bucket
	lod_mod = compute_star_lod(speed, speed_range, _lod_slow, _lod_medium, _lod_fast)

func reconfigure_for_reuse() -> void:
	"""
	Lightweight refresh for pooling reuse without reallocating the sprite.
	Call this if you want to randomize speed/alpha/position again quickly.
	"""
	speed = randf_range(_speed_range.x, _speed_range.y)
	alpha = randf_range(_alpha_range.x, _alpha_range.y)
	if sprite:
		sprite.modulate.a = alpha
	lod_mod = compute_star_lod(speed, _speed_range, _lod_slow, _lod_medium, _lod_fast)
	position = Vector2(
		randf_range(-_viewport_size.x * 0.5, _viewport_size.x * 1.5),
		randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)
	)
	direction.y = randf_range(-0.2, 0.2)

# -----------------------------
# Update
# -----------------------------
func tick(delta: float) -> void:
	position += direction * speed * delta

func wrap_if_past_left(extra_margin: float = 0.6) -> void:
	if position.x < -_viewport_size.x * extra_margin:
		position.x = _viewport_size.x * 1.4
		position.y = randf_range(-_viewport_size.y * 0.5, _viewport_size.y * 1.5)

# -----------------------------
# LOD Utilities
# -----------------------------
static func compute_star_lod(speed_value: float, speed_range: Vector2, slow_mod: int, medium_mod: int, fast_mod: int) -> int:
	var span := speed_range.y - speed_range.x
	if span <= 0.0001:
		return fast_mod
	var norm := (speed_value - speed_range.x) / span
	if norm < 0.33:
		return max(1, slow_mod)
	elif norm < 0.66:
		return max(1, medium_mod)
	return max(1, fast_mod)

# -----------------------------
# Debug / Instrumentation
# -----------------------------
func register_for_debug() -> void:
	_registered_for_debug = true
	_debug_timer = 0.0

func unregister_for_debug() -> void:
	_registered_for_debug = false

func debug_step(delta: float) -> void:
	if not _registered_for_debug:
		return
	if debug_interval_seconds <= 0.0:
		return
	_debug_timer += delta
	if _debug_timer >= debug_interval_seconds:
		_debug_timer = 0.0
		print("[StarBody] lod_mod=%d speed=%.2f alpha=%.2f pos=(%.1f, %.1f)" % [lod_mod, speed, alpha, position.x, position.y])

static func lod_distribution(stars: Array) -> Dictionary:
	var counts := {
		"lod_mod_1": 0,
		"lod_other": 0
	}
	var histogram := {}
	for s in stars:
		if s is StarBody:
			var lm: int = s.lod_mod
			if not histogram.has(lm):
				histogram[lm] = 0
			histogram[lm] += 1
	for k in histogram.keys():
		if int(k) == 1:
			counts["lod_mod_1"] = histogram[k]
		else:
			counts["lod_other"] += histogram[k]
	counts["detail"] = histogram
	return counts

static func print_lod_summary(stars: Array) -> void:
	var dist := lod_distribution(stars)
	print("[StarBody] LOD Summary -> lod_mod=1: %d | others: %d | detail=%s" %
		[dist.get("lod_mod_1", 0), dist.get("lod_other", 0), str(dist.get("detail"))])

# -----------------------------
# Accessors / Helpers
# -----------------------------
func set_speed(new_speed: float) -> void:
	speed = new_speed
	lod_mod = compute_star_lod(speed, _speed_range, _lod_slow, _lod_medium, _lod_fast)

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

func get_lod_mod() -> int:
	return lod_mod

# -----------------------------
# Pool lifecycle hooks (optional)
# -----------------------------
func on_return_to_pool() -> void:
	# Placeholder for any cleanup logic (e.g. detach signals)
	pass

func on_fetch_from_pool() -> void:
	# Placeholder for any logic when taken from pool
	pass

# -----------------------------
# Resets
# -----------------------------
func reset_state() -> void:
	speed = 0.0
	direction = Vector2.LEFT
	lod_mod = 1
	alpha = 1.0
	if sprite:
		sprite.modulate = Color(1,1,1,1)
	position = Vector2.ZERO
