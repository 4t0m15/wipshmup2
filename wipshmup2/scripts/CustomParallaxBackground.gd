
extends Node2D

class_name CustomParallaxBackground



# Parallax layer configuration

@export var layers: Array[CustomParallaxLayer] = []

@export var global_scroll_speed: Vector2 = Vector2(50.0, 0.0)  # Horizontal scrolling by default

@export var enable_vertical_scroll: bool = false


@export var vertical_scroll_speed: float = 30.0
@export var asset_base_dir: String = "res://assets2/Space"  # Base directory for parallax textures (galaxy, planets)




# Performance settings


@export var update_frequency: float = 1.0  # Logical rate: 1.0=every frame, 0.5=every 2nd, 0.25=every 4th

var _frame_counter: int = 0




# Camera reference for smooth following

var camera: Camera2D

var last_camera_position: Vector2

var _cumulative_scroll: Vector2 = Vector2.ZERO



signal background_scrolled(offset: Vector2)



func _ready():

	# Find camera in the scene

	camera = get_viewport().get_camera_2d()

	if camera:

		last_camera_position = camera.global_position



	# Initialize layers if not set in editor

	if layers.is_empty():

		_setup_default_layers()



func _setup_default_layers():

	"""Set up default parallax layers for space background"""

	# Far background (stars/galaxy) - slowest

	var far_layer = CustomParallaxLayer.new()



	var galaxy_tex: Texture2D = load(asset_base_dir + "/Galaxy.png")
	if galaxy_tex:
		far_layer.texture = galaxy_tex
	else:
		push_warning("CustomParallaxBackground: Missing Galaxy texture at " + asset_base_dir + "/Galaxy.png")



	far_layer.scroll_scale = Vector2(0.1, 0.1)

	layers.append(far_layer)
	add_child(far_layer)

	# Mid background (planets) - medium speed
	var mid_layer = CustomParallaxLayer.new()
	mid_layer.texture = preload("res://assets/Space/Planet_1.png")

	mid_layer.scroll_scale = Vector2(0.3, 0.3)

	layers.append(mid_layer)

	add_child(mid_layer)




func _process(delta: float):

	_frame_counter += 1

	# Frame-skipping model: update_frequency expresses updates per frame baseline (1.0 = every frame, 0.5 = every 2nd, etc.)
	if update_frequency <= 0.0:
		return  # Disabled
	var frames_per_update := int(round(1.0 / max(update_frequency, 0.0001)))
	frames_per_update = max(frames_per_update, 1)
	if (_frame_counter % frames_per_update) != 0:
		return
	_update_parallax(delta)




func _update_parallax(delta: float):

	"""Update parallax scrolling based on camera movement and global scroll"""

	var scroll_offset = Vector2.ZERO



	if camera and camera.global_position != last_camera_position:

		var camera_delta = camera.global_position - last_camera_position

		scroll_offset += camera_delta

		last_camera_position = camera.global_position



	scroll_offset += global_scroll_speed * delta



	if enable_vertical_scroll:
		scroll_offset.y += vertical_scroll_speed * delta



	_cumulative_scroll += scroll_offset



	for i in range(layers.size()):

		var layer = layers[i]

		if layer and is_instance_valid(layer):

			layer.update_scroll(scroll_offset)



	background_scrolled.emit(scroll_offset)



func set_scroll_speed(speed: Vector2):

	global_scroll_speed = speed

func set_vertical_scroll(enabled: bool, speed: float = 30.0):

	enable_vertical_scroll = enabled

	vertical_scroll_speed = speed



func add_layer(texture: Texture2D, scroll_scale: Vector2):

	"""Add a new parallax layer dynamically"""

	var layer = CustomParallaxLayer.new()

	layer.texture = texture

	layer.scroll_scale = scroll_scale

	layers.append(layer)

	add_child(layer)



func remove_layer(index: int):

	"""Remove a parallax layer"""

	if index >= 0 and index < layers.size():

		var layer = layers[index]

		if layer and is_instance_valid(layer):

			layer.queue_free()

		layers.remove_at(index)



func get_scroll_offset() -> Vector2:

	"""Return the cumulative scroll applied since creation/reset"""

	return _cumulative_scroll



func reset_cumulative_scroll():

	"""Reset the accumulated scroll distance to zero (e.g. on level restart)"""

	_cumulative_scroll = Vector2.ZERO
