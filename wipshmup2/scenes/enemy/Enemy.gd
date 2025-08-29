extends Area2D

signal killed(points: int)
signal hit_player

@export var speed: float = 60.0
@export var hp: int = 1
@export var points: int = 100
@export var sprite_target_height_px: float = 18.0

# Scoring and damage-source behavior
@export var bomb_points_override: int = -1
@export var bomb_points_multiplier: float = 10.0
@export var ignore_shot_damage: bool = false
@export var ignore_bomb_damage: bool = false

var _last_damage_source: String = "shot"

func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	collision_layer = 1
	collision_mask = 0
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Safety check: ensure we have collision shape
	if not has_node("CollisionShape2D"):
		push_warning("Enemy missing CollisionShape2D: " + name)
	else:
		var collision_shape = $CollisionShape2D
		if not collision_shape.shape:
			push_warning("Enemy CollisionShape2D has no shape: " + name)
	# Apply dynamic difficulty scaling from RankManager autoload if available
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("get_enemy_speed_multiplier"):
		var speed_mult: float = rm.get_enemy_speed_multiplier()
		var hp_mult: float = rm.get_enemy_hp_multiplier()
		speed *= speed_mult
		hp = int(ceil(float(hp) * hp_mult))
	# Normalize sprite size to target height
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		if spr and spr.texture:
			var tex_size: Vector2i = spr.texture.get_size()
			if tex_size.y > 0:
				var s: float = sprite_target_height_px / float(tex_size.y)
				spr.scale = Vector2(s, s)

	# Validate collision setup after initialization
	call_deferred("_validate_collision_setup")

func _physics_process(delta: float) -> void:
	position.y += speed * delta
	position = position.round()
	var rect := get_viewport().get_visible_rect()
	# Despawn just before bottom edge to avoid invincible edge collisions lingering
	if position.y >= rect.size.y - 2:
		queue_free()
		return
	if position.y > rect.size.y + 64:
		queue_free()

func _validate_collision_setup() -> void:
	# Ensure collision detection is working properly
	if not monitoring:
		monitoring = true

	if collision_layer != 1:
		collision_layer = 1

	if collision_mask != 0:
		collision_mask = 0

	# Ensure we're in the enemy group
	if not is_in_group("enemy"):
		add_to_group("enemy")

func take_damage(amount: int, source: String = "shot") -> void:
	# Respect invulnerability toggles per source
	if (source == "shot" and ignore_shot_damage) or (source == "bomb" and ignore_bomb_damage):
		return

	# Safety check: ensure we're still valid
	if not is_instance_valid(self):
		return

	hp -= amount
	_last_damage_source = source
	if hp <= 0:
		# Play enemy death sound
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("play_enemy_death"):
			audio_manager.play_enemy_death()

		var awarded: int = points
		if _last_damage_source == "bomb":
			if bomb_points_override >= 0:
				awarded = bomb_points_override
			else:
				awarded = int(round(float(points) * max(1.0, bomb_points_multiplier)))
		emit_signal("killed", awarded)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		emit_signal("hit_player")
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		emit_signal("hit_player")
		queue_free()
