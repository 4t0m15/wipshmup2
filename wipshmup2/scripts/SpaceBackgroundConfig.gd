
extends Resource

class_name SpaceBackgroundConfig

"""

SpaceBackgroundConfig.gd

Centralized configuration resource for SpaceBackground, StarBody, PlanetBody, and

CustomParallaxBackground systems.


Usage:
1. Create a new resource from this script in the editor:
   Right-click in FileSystem -> New Resource -> Select 'SpaceBackgroundConfig'.
2. Adjust values (star/planet counts, speed ranges, LOD frame mods, parallax layers, etc.).
3. In a script (e.g. a loader, stage controller, or debug console), call:
     var cfg: SpaceBackgroundConfig = load("res://path/to/MySpaceConfig.tres")
     cfg.apply_to($GameViewport/SpaceBackground)

If you change parallax layers at runtime, pass rebuild_parallax = true (default)
to clear existing layers and apply the configuration fresh.

This resource intentionally avoids direct dependencies on textures until applied,
so you can safely share / clone configs even if asset paths change. Texture lookup
is performed dynamically via load().
"""

## ---------------------------
## Parallax Layer Definition
## ---------------------------
## Instead of nesting Resources (which can clutter the inspector), we keep parallel
## arrays for texture paths and scroll scales. Both must be same size.


@export var asset_base_dir: String = "res://assets2/Space" # Base directory for parallax textures (supports migrated assets)

@export var parallax_texture_paths: Array[String] = [

	asset_base_dir + "/Galaxy.png",

	asset_base_dir + "/Sun.png"
]


@export var parallax_scroll_scales: Array[Vector2] = [
	Vector2(0.1, 0.1),
	Vector2(0.3, 0.3)
]

## Global parallax movement configuration
@export var parallax_global_scroll_speed: Vector2 = Vector2(50.0, 0.0)
@export var parallax_enable_vertical: bool = false
@export var parallax_vertical_speed: float = 30.0

## ---------------------------
## Star / Planet Spawn Counts
## ---------------------------
@export var star_count: int = 100
@export var planet_count: int = 5

## ---------------------------
## Pool Sizes
## ---------------------------
@export var star_pool_size: int = 150
@export var planet_pool_size: int = 30

## ---------------------------
## Speed Ranges
## ---------------------------
@export var star_speed_range: Vector2 = Vector2(10.0, 50.0)
@export var planet_speed_range: Vector2 = Vector2(5.0, 20.0)

## ---------------------------
## Star LOD Frame Mods
## (Higher number = fewer updates)
## ---------------------------
@export var lod_frame_mod_star_slow: int = 6
@export var lod_frame_mod_star_medium: int = 3
@export var lod_frame_mod_star_fast: int = 1

## ---------------------------
## Planet LOD Frame Mods
## ---------------------------
@export var lod_frame_mod_planet_small: int = 12
@export var lod_frame_mod_planet_medium: int = 6
@export var lod_frame_mod_planet_large: int = 3

## ---------------------------
## Planet Size / Speed Based LOD Thresholds (mirrors PlanetBody defaults)
## These are not directly applied unless you extend PlanetBody to read them.
## Included for future centralization / serialization.
## ---------------------------
@export var planet_scale_small_threshold: float = 0.03
@export var planet_scale_medium_threshold: float = 0.05
@export var planet_slow_speed_factor: float = 0.25

## ---------------------------
## Star Visual Adjustments (if integrating deeper into StarBody)
## ---------------------------
@export var star_alpha_range: Vector2 = Vector2(0.3, 1.0)
@export var star_direction_variation_y: Vector2 = Vector2(-0.2, 0.2)

## ---------------------------
## Planet Visual Adjustments (PlanetBody)
## ---------------------------
@export var planet_alpha_range: Vector2 = Vector2(0.5, 1.0)
@export var planet_direction_variation_y: Vector2 = Vector2(-0.1, 0.1)

## ---------------------------
## Debug Options
## ---------------------------
@export var auto_print_lod_summary: bool = false
@export var lod_summary_interval: float = 5.0  # Seconds
var _lod_timer: float = 0.0

func validate() -> void:
	"""
	Ensures internal arrays are consistent; call before saving if editing procedurally.
	"""
	if parallax_scroll_scales.size() != parallax_texture_paths.size():
		push_warning("SpaceBackgroundConfig: parallax arrays size mismatch; trimming to smallest.")
		var m: int = min(parallax_scroll_scales.size(), parallax_texture_paths.size())
		while parallax_scroll_scales.size() > m:
			parallax_scroll_scales.pop_back()
		while parallax_texture_paths.size() > m:
			parallax_texture_paths.pop_back()

func apply_to(space_background: Node, rebuild_parallax: bool = true) -> bool:
	"""
	Apply this configuration to a SpaceBackground instance.
	Returns true on success, false if the node is incompatible.
	"""
	if space_background == null:
		push_warning("SpaceBackgroundConfig.apply_to: space_background is null.")
		return false
	if not space_background is SpaceBackground:
		push_warning("SpaceBackgroundConfig.apply_to: target is not a SpaceBackground.")
		return false

	# Core counts / pools / ranges
	space_background.star_count = star_count
	space_background.planet_count = planet_count
	if space_background.has_variable("star_pool_size"):
		space_background.star_pool_size = star_pool_size
	if space_background.has_variable("planet_pool_size"):
		space_background.planet_pool_size = planet_pool_size
	space_background.star_speed_range = star_speed_range
	space_background.planet_speed_range = planet_speed_range

	# LOD frame mods
	space_background.lod_frame_mod_star_slow = lod_frame_mod_star_slow
	space_background.lod_frame_mod_star_medium = lod_frame_mod_star_medium
	space_background.lod_frame_mod_star_fast = lod_frame_mod_star_fast
	space_background.lod_frame_mod_planet_small = lod_frame_mod_planet_small
	space_background.lod_frame_mod_planet_medium = lod_frame_mod_planet_medium
	space_background.lod_frame_mod_planet_large = lod_frame_mod_planet_large

	# Parallax background application
	var pb = space_background.parallax_background
	if pb == null:
		# SpaceBackground's setup should create one; attempt to force creation.
		if space_background.has_method("_setup_parallax_background"):
			space_background._setup_parallax_background()
			pb = space_background.parallax_background
	if pb and pb is CustomParallaxBackground:
		pb.global_scroll_speed = parallax_global_scroll_speed
		pb.enable_vertical_scroll = parallax_enable_vertical
		pb.vertical_scroll_speed = parallax_vertical_speed
		if rebuild_parallax:
			_clear_parallax_layers(pb)
			_build_parallax_layers(pb)
	else:
		push_warning("SpaceBackgroundConfig.apply_to: Could not access CustomParallaxBackground to apply parallax layers.")

	# Optionally regenerate dynamic elements to reflect new counts
	if space_background.has_method("regenerate"):
		space_background.regenerate(star_count, planet_count)

	return true

func _clear_parallax_layers(pb: CustomParallaxBackground) -> void:
	for i in range(pb.layers.size() - 1, -1, -1):
		var layer = pb.layers[i]
		if layer and is_instance_valid(layer):
			layer.queue_free()
		pb.layers.remove_at(i)

func _build_parallax_layers(pb: CustomParallaxBackground) -> void:
	validate()
	for i in range(parallax_texture_paths.size()):
		var path := parallax_texture_paths[i]
		var scale := parallax_scroll_scales[i]
		var tex: Texture2D = null
		if path != "":
			tex = load(path)
			if tex == null:
				push_warning("SpaceBackgroundConfig: Failed to load texture at '%s'" % path)
		if tex:
			pb.add_layer(tex, scale)

func process_debug(delta: float, space_background: SpaceBackground) -> void:
	"""
	Call this every frame (e.g. from a manager or injected into SpaceBackground with a little glue)
	if auto_print_lod_summary is enabled, to periodically output LOD distributions.
	"""
	if not auto_print_lod_summary:
		return
	_lod_timer += delta
	if _lod_timer >= lod_summary_interval:
		_lod_timer = 0.0
		if space_background and space_background.is_inside_tree():
			if space_background.has_method("print_debug_lod_summary"):
				space_background.print_debug_lod_summary()

static func load_config(path: String) -> SpaceBackgroundConfig:
	"""
	Helper to safely load a config. Returns null if missing or wrong type.
	"""
	var res = null
	if path == "" or not FileAccess.file_exists(path):
		push_warning("SpaceBackgroundConfig.load_config: path invalid or does not exist: %s" % path)
		return null
	res = load(path)
	if res == null or not (res is SpaceBackgroundConfig):
		push_warning("SpaceBackgroundConfig.load_config: Resource at path is not a SpaceBackgroundConfig: %s" % path)
		return null
	return res


func duplicate_for_override() -> SpaceBackgroundConfig:

	"""

	Create a deep duplicate that you can mutate at runtime without affecting the original asset.

	"""

	var dup: SpaceBackgroundConfig = duplicate(true)

	dup.parallax_texture_paths = parallax_texture_paths.duplicate()

	dup.parallax_scroll_scales = parallax_scroll_scales.duplicate()

	return dup

func save_current_state(space_background: SpaceBackground, include_parallax: bool = true) -> void:
	"""
	Snapshot the current runtime state from a SpaceBackground instance back into this config.
	This overwrites the resource's fields so you can then save it in the editor.
	"""
	if not space_background or not (space_background is SpaceBackground):
		push_warning("SpaceBackgroundConfig.save_current_state: invalid target")
		return

	star_count = space_background.star_count
	planet_count = space_background.planet_count

	if space_background.has_variable("star_pool_size"):
		star_pool_size = space_background.star_pool_size
	if space_background.has_variable("planet_pool_size"):
		planet_pool_size = space_background.planet_pool_size

	star_speed_range = space_background.star_speed_range
	planet_speed_range = space_background.planet_speed_range

	lod_frame_mod_star_slow = space_background.lod_frame_mod_star_slow
	lod_frame_mod_star_medium = space_background.lod_frame_mod_star_medium
	lod_frame_mod_star_fast = space_background.lod_frame_mod_star_fast
	lod_frame_mod_planet_small = space_background.lod_frame_mod_planet_small
	lod_frame_mod_planet_medium = space_background.lod_frame_mod_planet_medium
	lod_frame_mod_planet_large = space_background.lod_frame_mod_planet_large

	# Parallax capture
	if include_parallax and space_background.parallax_background and space_background.parallax_background is CustomParallaxBackground:
		var pb := space_background.parallax_background
		parallax_global_scroll_speed = pb.global_scroll_speed
		parallax_enable_vertical = pb.enable_vertical_scroll
		parallax_vertical_speed = pb.vertical_scroll_speed

		# Rebuild texture path + scroll arrays from existing layers if possible
		parallax_texture_paths.clear()
		parallax_scroll_scales.clear()
		for layer in pb.layers:
			if layer and layer is CustomParallaxLayer and layer.texture:
				# Attempt to get resource path; if not saved, skip
				if layer.texture.resource_path != "":
					parallax_texture_paths.append(layer.texture.resource_path)
					if layer.has_variable("scroll_scale"):
						parallax_scroll_scales.append(layer.scroll_scale)
					else:
						parallax_scroll_scales.append(Vector2.ONE)
	validate()


func summary() -> Dictionary:
	"""
	Returns a dictionary summarizing key fields (useful for debugging or serialization).
	"""
	return {
		"stars": {
			"count": star_count,
			"pool_size": star_pool_size,
			"speed_range": star_speed_range
		},
		"planets": {
			"count": planet_count,
			"pool_size": planet_pool_size,
			"speed_range": planet_speed_range
		},
		"parallax": {
			"layers": parallax_texture_paths.size(),
			"global_scroll_speed": parallax_global_scroll_speed,
			"vertical_enabled": parallax_enable_vertical,
			"vertical_speed": parallax_vertical_speed
		},
		"lod": {
			"stars": {
				"slow": lod_frame_mod_star_slow,
				"medium": lod_frame_mod_star_medium,
				"fast": lod_frame_mod_star_fast
			},
			"planets": {
				"small": lod_frame_mod_planet_small,
				"medium": lod_frame_mod_planet_medium,
				"large": lod_frame_mod_planet_large
			}
		}
	}

func print_summary() -> void:
	var s = summary()
	print("[SpaceBackgroundConfig] Summary: ", s)
