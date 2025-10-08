extends CharacterBody2D

signal hit
signal damaged(amount: int)

var _alive: bool = true
var _invincible: bool = false
var _invincibility_timer: float = 0.0
const INVINCIBILITY_DURATION: float = 1.0  # 1 second of invincibility after hit

func _ready() -> void:
	add_to_group("player")
	print("[Player] Player initialized")
	
	if has_node("Hurtbox"):
		var hurtbox := $Hurtbox
		hurtbox.add_to_group("player_hurtbox")
		hurtbox.monitoring = true
		hurtbox.monitorable = true
		hurtbox.collision_layer = 1   # Player layer
		hurtbox.collision_mask = 2    # Enemy bullet layer
		# Ensure hurtbox tracks the player position
		hurtbox.position = Vector2.ZERO
		print("[Player] Hurtbox configured: layer=", hurtbox.collision_layer, " mask=", hurtbox.collision_mask)
	else:
		print("[Player] WARNING: No Hurtbox node found!")

func _physics_process(delta: float) -> void:
	if not _alive: 
		return
	
	# Handle invincibility timer
	if _invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
			_invincibility_timer = 0.0
			print("[Player] Invincibility ended")
			# Make player fully visible again
			modulate = Color.WHITE
		else:
			# Blink effect during invincibility
			var blink_rate = 10.0  # blinks per second
			var alpha = 0.3 + 0.7 * abs(sin(_invincibility_timer * blink_rate * PI))
			modulate = Color(1.0, 1.0, 1.0, alpha)
	
	# Simple movement - this will be overridden by Main.gd
	pass

func take_damage(amount: int = 1) -> void:
	if not _alive:
		print("[Player] take_damage called but player not alive")
		return
	
	if _invincible:
		print("[Player] take_damage called but player is invincible - ignoring")
		return
	
	print("[Player] Taking damage: amount=", amount, " position=", position)
	
	# Start invincibility period
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	print("[Player] Invincibility activated for ", INVINCIBILITY_DURATION, " seconds")
	
	damaged.emit(amount)

func die() -> void:
	if not _alive: 
		return
	print("[Player] Player died at position: ", position)
	_alive = false
	hit.emit()
	queue_free()

func is_invincible() -> bool:
	return _invincible