extends Area2D

# TriangleItem - Cho Ren Sha 68K triangle item with three pickups
# Single-pick: Touch any item = collect it, others vanish
# Triple-pick: Stay at center ~0.5s = collect all three

signal item_collected(item_type: String, value: int)

@export var rotation_speed: float = 90.0  # degrees per second
@export var drift_speed: float = 20.0   # pixels per second downward
@export var lifetime: float = 5.0       # seconds before despawn
@export var triple_pick_duration: float = 0.5  # seconds to stay at center

var _player_in_range: bool = false
var _triple_pick_timer: float = 0.0
var _lifetime_timer: float = 0.0

# Item positions around triangle
var _item_positions: Array[Vector2] = [
	Vector2(0, -20),    # Power-up (top)
	Vector2(-17, 10),   # Bomb (bottom left)
	Vector2(17, 10)     # Shield (bottom right)
]

var _item_types: Array[String] = ["POWER_UP", "BOMB", "SHIELD"]
var _item_values: Array[int] = [0, 0, 0]  # Values for each item

func _ready() -> void:
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	
	# Create visual triangle with three items
	_setup_visual_triangle()
	
	print("[TriangleItem] Triangle item spawned at ", global_position)

func _setup_visual_triangle() -> void:
	# Create triangle background
	var triangle = Polygon2D.new()
	var triangle_points = PackedVector2Array([
		Vector2(0, -25),
		Vector2(-22, 18),
		Vector2(22, 18)
	])
	triangle.polygon = triangle_points
	triangle.color = Color(1.0, 0.8, 0.0, 0.8)  # Orange triangle
	add_child(triangle)
	
	# Create three item sprites
	for i in range(3):
		var item_sprite = Sprite2D.new()
		item_sprite.position = _item_positions[i]
		
		# Simple colored circles for items
		var texture = _create_circle_texture(8, _get_item_color(i))
		item_sprite.texture = texture
		item_sprite.name = "Item_" + str(i)
		add_child(item_sprite)

func _get_item_color(index: int) -> Color:
	match index:
		0: return Color(0.0, 1.0, 0.0)  # Green for power-up
		1: return Color(1.0, 0.0, 0.0)  # Red for bomb
		2: return Color(0.0, 0.0, 1.0)  # Blue for shield
		_: return Color.WHITE

func _create_circle_texture(radius: int, color: Color) -> ImageTexture:
	var size = radius * 2
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(radius, radius)
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _process(delta: float) -> void:
	# Rotate triangle
	rotation_degrees += rotation_speed * delta
	
	# Drift downward
	position.y += drift_speed * delta
	
	# Update lifetime
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		queue_free()
		return
	
	# Handle triple-pick timing
	if _player_in_range:
		_triple_pick_timer += delta
		if _triple_pick_timer >= triple_pick_duration:
			_collect_all_items()
	else:
		_triple_pick_timer = 0.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		print("[TriangleItem] Player entered triangle range")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_triple_pick_timer = 0.0
		print("[TriangleItem] Player left triangle range")

func _collect_single_item(item_index: int) -> void:
	if item_index < 0 or item_index >= _item_types.size():
		return
	
	var item_type = _item_types[item_index]
	var item_value = _item_values[item_index]
	
	# Grant brief invincibility
	GameState.set_invincible(true)
	var invincibility_timer = Timer.new()
	invincibility_timer.wait_time = 0.3
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(func(): GameState.set_invincible(false))
	add_child(invincibility_timer)
	invincibility_timer.start()
	
	# Emit collection event
	item_collected.emit(item_type, item_value)
	EventBus.item_collected.emit(item_type, item_value)
	
	# Apply item effect
	_apply_item_effect(item_type)
	
	print("[TriangleItem] Collected single item: ", item_type)
	queue_free()

func _collect_all_items() -> void:
	# Grant brief invincibility
	GameState.set_invincible(true)
	var invincibility_timer = Timer.new()
	invincibility_timer.wait_time = 0.3
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(func(): GameState.set_invincible(false))
	add_child(invincibility_timer)
	invincibility_timer.start()
	
	# Collect all three items
	for i in range(_item_types.size()):
		var item_type = _item_types[i]
		var item_value = _item_values[i]
		
		item_collected.emit(item_type, item_value)
		EventBus.item_collected.emit(item_type, item_value)
		_apply_item_effect(item_type)
	
	print("[TriangleItem] Collected all three items (triple-pick)")
	queue_free()

func _apply_item_effect(item_type: String) -> void:
	match item_type:
		"POWER_UP":
			GameState.add_weapon_power(1)
		"BOMB":
			GameState.add_bombs(1)
		"SHIELD":
			GameState.set_shield(true)

# Called when player touches any part of the triangle
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		# Single-pick: collect first available item
		_collect_single_item(0)
