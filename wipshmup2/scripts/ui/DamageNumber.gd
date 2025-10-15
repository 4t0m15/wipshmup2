class_name DamageNumber
extends Node2D

@export var lifetime: float = 1.0
@export var float_speed: float = 30.0
@export var fade_speed: float = 1.0

var _damage_value: int = 0
var _age: float = 0.0
var _label: Label

func _ready() -> void:
	# Create label for damage number
	_label = Label.new()
	_label.text = str(_damage_value)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0, 0.8))
	_label.add_theme_constant_override("outline_size", 2)
	add_child(_label)
	
	# Start floating animation
	_start_floating_animation()

func _process(delta: float) -> void:
	_age += delta
	
	# Update position (float upward)
	position.y -= float_speed * delta
	
	# Update alpha (fade out)
	var alpha = 1.0 - (_age / lifetime)
	modulate.a = alpha
	
	# Scale effect (start small, grow, then shrink)
	var scale_factor = 1.0
	if _age < 0.2:
		scale_factor = _age / 0.2  # Grow in first 0.2s
	else:
		scale_factor = 1.0 - ((_age - 0.2) / (lifetime - 0.2)) * 0.3  # Shrink slightly
	
	scale = Vector2(scale_factor, scale_factor)
	
	# Remove when lifetime expires
	if _age >= lifetime:
		queue_free()

func set_damage(value: int) -> void:
	_damage_value = value
	if _label:
		_label.text = str(_damage_value)

func set_color(color: Color) -> void:
	if _label:
		_label.add_theme_color_override("font_color", color)

func _start_floating_animation() -> void:
	# Add slight random horizontal movement
	var random_offset = randf_range(-10.0, 10.0)
	position.x += random_offset
	
	# Add slight random vertical offset
	position.y += randf_range(-5.0, 5.0)

# Static function to create damage numbers
static func create_damage_number(parent: Node, spawn_position: Vector2, damage: int, color: Color = Color(1.0, 0.8, 0.2, 1.0)) -> DamageNumber:
	var damage_number = DamageNumber.new()
	damage_number.global_position = spawn_position
	damage_number.set_damage(damage)
	damage_number.set_color(color)
	parent.add_child(damage_number)
	return damage_number
