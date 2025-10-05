extends Node2D

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

var current_environment: EnvironmentType = EnvironmentType.SPACE_DEEP

var layers: Array = []

func _ready():
	print("BackgroundManager: Initializing simplified background system")
	_create_environment(EnvironmentType.SPACE_DEEP)

func _process(delta: float) -> void:
	for layer in layers:
		if not layer.has("sprite"):
			continue
		var sprite: Sprite2D = layer["sprite"]
		if not is_instance_valid(sprite):
			continue
		sprite.position.y += layer["scroll_speed"] * delta
		if sprite.position.y > 220:
			sprite.position.y = -220

func _create_environment(env_type: EnvironmentType):
	current_environment = env_type
	_clear_layers()

	match env_type:
		EnvironmentType.SPACE_DEEP:
			_add_layer("res://assets/Space/Galaxy_frame_001.png", 20.0, Color(0.4, 0.3, 0.7, 0.6), Vector2(0.4, 0.4), Vector2(160, 0))
			_add_layer("res://assets/Space/SpaceJunk_frame_001.png", 35.0, Color(0.9, 0.8, 1.0, 0.8), Vector2(0.5, 0.5), Vector2(160, 90))
			_add_layer("res://assets/Space/SpaceJunk_500.png", 50.0, Color(0.6, 0.6, 0.9, 1.0), Vector2(0.6, 0.6), Vector2(160, -90))
		EnvironmentType.ASTEROID_FIELD:
			_add_layer("res://assets/Space/Asteroid_frame_001.png", 30.0, Color(0.8, 0.7, 0.6, 0.9), Vector2(0.5, 0.5), Vector2(120, 20))
			_add_layer("res://assets/Space/Asteroid_frame_001.png", 45.0, Color(1.0, 0.9, 0.7, 0.9), Vector2(0.7, 0.7), Vector2(200, -40))
			_add_layer("res://assets/Space/SpaceJunk_500.png", 60.0, Color(0.9, 0.7, 0.7, 0.6), Vector2(0.6, 0.6), Vector2(160, 100))
		EnvironmentType.NEBULA:
			_add_layer("res://assets/Space/Galaxy.png", 25.0, Color(0.8, 0.3, 0.6, 0.8), Vector2(0.5, 0.5), Vector2(160, 40))
			_add_layer("res://assets/Space/Galaxy_frame_001.png", 35.0, Color(0.3, 0.6, 0.8, 0.6), Vector2(0.6, 0.6), Vector2(100, -60))
			_add_layer("res://assets/Space/SpaceJunk_frame_001.png", 50.0, Color(0.7, 0.5, 0.9, 0.8), Vector2(0.7, 0.7), Vector2(240, 80))
		EnvironmentType.PLANET_ORBIT:
			_add_layer("res://assets/Space/Planet_1.png", 20.0, Color(0.9, 0.8, 0.7, 1.0), Vector2(0.3, 0.3), Vector2(260, 60))
			_add_layer("res://assets/Space/Sun.png", 15.0, Color(1.0, 0.9, 0.7, 1.0), Vector2(0.25, 0.25), Vector2(60, -30))
			_add_layer("res://assets/Space/SpaceJunk_500.png", 40.0, Color(0.8, 0.7, 0.9, 0.6), Vector2(0.5, 0.5), Vector2(160, 120))
		EnvironmentType.STAR_SYSTEM:
			_add_layer("res://assets/Space/Planet_1.png", 25.0, Color(0.8, 0.7, 0.6, 0.9), Vector2(0.35, 0.35), Vector2(120, 20))
			_add_layer("res://assets/Space/Planet_2.png", 30.0, Color(0.9, 0.8, 0.6, 0.9), Vector2(0.3, 0.3), Vector2(220, -40))
			_add_layer("res://assets/Space/Sun.png", 18.0, Color(1.0, 0.8, 0.5, 0.9), Vector2(0.2, 0.2), Vector2(70, 60))
		EnvironmentType.BASE_APPROACH:
			_add_layer("res://assets/Base/BaseConcept.png", 28.0, Color(0.7, 0.7, 0.9, 0.8), Vector2(0.2, 0.2), Vector2(160, -20))
			_add_layer("res://assets/Base/LaunchPad_N2.png", 45.0, Color(0.8, 0.8, 1.0, 0.9), Vector2(0.25, 0.25), Vector2(160, 60))
			_add_layer("res://assets/Space/SpaceJunk_500.png", 55.0, Color(0.6, 0.6, 0.9, 0.5), Vector2(0.5, 0.5), Vector2(160, 120))
		EnvironmentType.COMBAT_ZONE:
			_add_layer("res://assets/Space/Galaxy_frame_001.png", 35.0, Color(1.0, 0.3, 0.2, 0.7), Vector2(0.5, 0.5), Vector2(160, 0))
			_add_layer("res://assets/Space/SpaceJunk_500.png", 55.0, Color(0.9, 0.5, 0.4, 0.8), Vector2(0.6, 0.6), Vector2(120, 80))
			_add_layer("res://assets/Space/SpaceJunk_frame_001.png", 70.0, Color(1.0, 0.7, 0.6, 0.8), Vector2(0.7, 0.7), Vector2(220, -60))

	background_changed.emit(EnvironmentType.keys()[env_type])

func _add_layer(texture_path: String, scroll_speed: float, modulate: Color, scale: Vector2, position: Vector2):
	var texture := load(texture_path)
	if not texture:
		print("BackgroundManager: Warning - Could not load texture: ", texture_path)
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.scale = scale
	sprite.modulate = modulate
	sprite.z_index = -10
	add_child(sprite)

	var layer = {
		"sprite": sprite,
		"scroll_speed": scroll_speed
	}
	layers.append(layer)

func _clear_layers():
	for layer in layers:
		if layer.has("sprite") and is_instance_valid(layer.sprite):
			layer.sprite.queue_free()
	layers.clear()

func change_environment(env_type: EnvironmentType):
	_create_environment(env_type)

func set_intensity(_intensity: float):
	pass

func get_current_environment() -> EnvironmentType:
	return current_environment
