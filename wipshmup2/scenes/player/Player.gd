extends CharacterBody2D

signal hit
signal damaged(amount: int)

var _alive: bool = true

func _ready() -> void:
	add_to_group("player")
	if has_node("Hurtbox"):
		var hurtbox := $Hurtbox
		hurtbox.add_to_group("player_hurtbox")
		# Ensure hurtbox tracks the player position
		hurtbox.position = Vector2.ZERO
	print("Simple player ready")

func _physics_process(_delta: float) -> void:
	if not _alive: return
	
	# Simple movement - this will be overridden by Main.gd
	pass

func take_damage(amount: int = 1) -> void:
	if not _alive:
		return
	damaged.emit(amount)

func die() -> void:
	if not _alive: return
	_alive = false
	hit.emit()
	queue_free()