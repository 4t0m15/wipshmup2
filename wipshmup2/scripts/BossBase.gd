class_name BossBase
extends Area2D

signal defeated
signal phase_changed(new_phase: int)

@export var max_hp: int = 60
@export var phases_total: int = 2
@export var points_value: int = 5000

var hp: int
var current_phase: int = 1
var _alive: bool = true

func _ready() -> void:
	add_to_group("enemy")
	monitoring = true
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	hp = max_hp
	start_battle()

func start_battle() -> void:
	current_phase = 1
	on_enter_phase(current_phase)
	emit_signal("phase_changed", current_phase)

func on_enter_phase(_phase: int) -> void:
	# To be overridden by subclasses
	pass

func transform_to_phase(new_phase: int) -> void:
	current_phase = new_phase
	on_enter_phase(current_phase)
	emit_signal("phase_changed", current_phase)

func take_damage(amount: int) -> void:
	if not _alive:
		return
	hp -= amount
	if hp <= 0:
		if current_phase < phases_total:
			# Transform to next phase with small HP refill relative to progression
			current_phase += 1
			hp = int(ceil(float(max_hp) / float(phases_total)))
			transform_to_phase(current_phase)
		else:
			die()

func die() -> void:
	if not _alive:
		return
	_alive = false
	emit_signal("defeated")
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Player collision results in hit; bullet damage is handled by Bullet.gd calling take_damage
	if area.is_in_group("player_hurtbox"):
		# Optionally damage player, but Main handles player death
		pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		pass
