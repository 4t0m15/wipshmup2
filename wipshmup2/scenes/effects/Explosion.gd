extends Node2D

@export var explosion_type: String = "normal"  # normal, boss, player_death
@export var damage_value: int = 0

var _damage_number: DamageNumber

func _ready():
	# Connect the timer signal
	$LifetimeTimer.timeout.connect(_on_lifetime_timeout)
	
	# Add some random rotation for variety
	rotation = randf() * TAU
	
	# Setup explosion based on type
	_setup_explosion_effects()

func _setup_explosion_effects() -> void:
	"""Setup visual effects based on explosion type"""
	match explosion_type:
		"normal":
			modulate = Color(1.0, 0.6, 0.2, 1.0)  # Orange
			scale = Vector2(1.0, 1.0)
		"boss":
			modulate = Color(1.0, 0.2, 0.2, 1.0)  # Red
			scale = Vector2(1.5, 1.5)
			# Add screen shake for boss explosions
			var screen_shake = get_node_or_null("/root/Main/ScreenShake")
			if screen_shake:
				screen_shake.shake(2.0, 0.3)
		"player_death":
			modulate = Color(1.0, 1.0, 1.0, 1.0)  # White
			scale = Vector2(2.0, 2.0)
			# Strong screen shake for player death
			var screen_shake = get_node_or_null("/root/Main/ScreenShake")
			if screen_shake:
				screen_shake.shake(3.0, 0.5)
	
	# Create damage number if damage value provided
	if damage_value > 0:
		_create_damage_number()

func _create_damage_number() -> void:
	"""Create floating damage number"""
	_damage_number = DamageNumber.create_damage_number(
		get_tree().current_scene,
		global_position,
		damage_value,
		_get_damage_color()
	)

func _get_damage_color() -> Color:
	"""Get color for damage number based on explosion type"""
	match explosion_type:
		"normal": return Color(1.0, 0.8, 0.2, 1.0)  # Yellow
		"boss": return Color(1.0, 0.4, 0.4, 1.0)   # Red
		"player_death": return Color(1.0, 1.0, 1.0, 1.0)  # White
		_: return Color(1.0, 0.8, 0.2, 1.0)

func set_explosion_type(type: String) -> void:
	explosion_type = type
	_setup_explosion_effects()

func set_damage_value(damage: int) -> void:
	damage_value = damage
	if _damage_number:
		_damage_number.set_damage(damage)

func _on_lifetime_timeout():
	# Remove the explosion when the timer expires
	queue_free()
