extends Node

# VisualEffectsSystem - Centralized visual effects and juice
# Extracted from Main.gd and various other files

var screen_shake: Node
var hit_stop: Node
var danger_indicator: Node
var visual_settings: Node

func _ready() -> void:
	# Connect to EventBus for visual effects
	EventBus.screen_shake_requested.connect(_on_screen_shake_requested)
	EventBus.hit_stop_requested.connect(_on_hit_stop_requested)
	EventBus.flash_requested.connect(_on_flash_requested)
	EventBus.explosion_requested.connect(_on_explosion_requested)
	
	# Setup visual systems
	_setup_visual_systems()

func _setup_visual_systems() -> void:
	# Setup screen shake
	screen_shake = load("res://scripts/ui/ScreenShake.gd").new()
	screen_shake.name = "ScreenShake"
	add_child(screen_shake)
	
	# Setup hit-stop
	hit_stop = load("res://scripts/ui/HitStop.gd").new()
	hit_stop.name = "HitStop"
	add_child(hit_stop)
	
	# Setup danger indicator
	danger_indicator = load("res://scripts/ui/DangerIndicator.gd").new()
	danger_indicator.name = "DangerIndicator"
	add_child(danger_indicator)
	
	# Setup visual settings
	visual_settings = load("res://scripts/ui/VisualSettings.gd").new()
	visual_settings.name = "VisualSettings"
	add_child(visual_settings)
	
	print("[VisualEffectsSystem] Visual effects systems initialized")

func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	if screen_shake and screen_shake.has_method("shake"):
		screen_shake.shake(intensity, duration)

func _on_hit_stop_requested(duration: float, scale: float) -> void:
	if hit_stop and hit_stop.has_method("trigger_hit_stop"):
		hit_stop.trigger_hit_stop(duration, scale)

func _on_flash_requested(color: Color, duration: float) -> void:
	_create_flash_effect(color, duration)

func _on_explosion_requested(position: Vector2, size: float) -> void:
	_create_explosion_effect(position, size)

func _create_flash_effect(color: Color, duration: float) -> void:
	"""Create a screen flash effect"""
	var flash = ColorRect.new()
	flash.name = "FlashEffect"
	flash.color = color
	flash.size = Vector2(320, 180)
	flash.position = Vector2.ZERO
	flash.z_index = 100  # Above everything
	
	# Add to HUD or main scene
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.add_child(flash)
	else:
		get_tree().current_scene.add_child(flash)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func _create_explosion_effect(position: Vector2, size: float) -> void:
	"""Create an explosion visual effect"""
	# Load explosion scene if available
	var explosion_scene = load("res://scenes/effects/Explosion.tscn")
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = position
		explosion.scale = Vector2(size, size)
		
		var container = get_tree().current_scene.get_node_or_null("GameViewport")
		if container:
			container.add_child(explosion)
		else:
			get_tree().current_scene.add_child(explosion)
	else:
		# Fallback: create simple explosion effect
		_create_simple_explosion(position, size)

func _create_simple_explosion(position: Vector2, size: float) -> void:
	"""Create a simple explosion effect using particles or sprites"""
	var explosion = Node2D.new()
	explosion.global_position = position
	explosion.name = "SimpleExplosion"
	
	# Create expanding circle effect
	var circle = ColorRect.new()
	circle.size = Vector2(4, 4)
	circle.position = Vector2(-2, -2)
	circle.color = Color(1.0, 0.8, 0.2, 1.0)
	explosion.add_child(circle)
	
	var container = get_tree().current_scene.get_node_or_null("GameViewport")
	if container:
		container.add_child(explosion)
	else:
		get_tree().current_scene.add_child(explosion)
	
	# Animate explosion
	var tween = create_tween()
	tween.parallel().tween_property(circle, "scale", Vector2(size, size), 0.3)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

# Utility methods for common visual effects
func create_damage_number(spawn_position: Vector2, damage: int, color: Color = Color.WHITE) -> void:
	"""Create a floating damage number"""
	var damage_number = load("res://scripts/ui/DamageNumber.gd").new()
	damage_number.global_position = spawn_position
	damage_number.setup(damage, color)
	
	var container = get_tree().current_scene.get_node_or_null("GameViewport")
	if container:
		container.add_child(damage_number)
	else:
		get_tree().current_scene.add_child(damage_number)

func create_screen_flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	"""Create a quick screen flash"""
	EventBus.emit_visual_effect("flash", {
		"color": color,
		"duration": duration
	})

func create_screen_shake(intensity: float = 1.0, duration: float = 0.1) -> void:
	"""Create screen shake effect"""
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": intensity,
		"duration": duration
	})

func create_hit_stop(duration: float = 0.05, scale: float = 1.0) -> void:
	"""Create hit-stop effect"""
	EventBus.emit_visual_effect("hit_stop", {
		"duration": duration,
		"scale": scale
	})
