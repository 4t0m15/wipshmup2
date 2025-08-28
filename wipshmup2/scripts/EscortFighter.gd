class_name EscortFighter
extends ClassicEnemy

# Escort behavior states
enum EscortState {
	FORMATION,      # Maintaining formation position
	BREAKING,       # Breaking to engage threats
	ENGAGING,       # Actively engaging threats
	RETURNING,      # Returning to formation
	SCREENING       # Screening for the formation
}

# Escort properties
@export var formation_id: String = ""
@export var leader_node: Node2D = null
@export var escort_position: Vector2 = Vector2.ZERO
@export var escort_range: float = 80.0
@export var protectiveness: float = 1.0  # How aggressively to protect (0-1)

# Internal state
var escort_state: int = EscortState.FORMATION
var formation_manager = null
var target_position: Vector2 = Vector2.ZERO
var last_leader_position: Vector2 = Vector2.ZERO
var time_since_engagement: float = 0.0
var return_timer: float = 0.0

func _ready() -> void:
	super._ready()

	# Get formation manager reference
	formation_manager = get_node_or_null("/root/FormationManager")

	# Set up initial escort behavior
	if leader_node:
		last_leader_position = leader_node.global_position
		calculate_escort_position()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update escort behavior
	update_escort_behavior(delta)

func update_escort_behavior(delta: float) -> void:
	if not leader_node:
		# No leader, act independently
		set_state(EscortState.FORMATION)
		return

	match escort_state:
		EscortState.FORMATION:
			maintain_formation_position(delta)
		EscortState.BREAKING:
			_execute_formation_break(delta)
		EscortState.ENGAGING:
			engage_threats(delta)
		EscortState.RETURNING:
			return_to_formation(delta)
		EscortState.SCREENING:
			screen_formation(delta)

func maintain_formation_position(delta: float) -> void:
	# Calculate escort position relative to leader
	calculate_escort_position()

	# Move toward target position
	var current_pos = global_position
	var direction = (target_position - current_pos).normalized()
	var distance = current_pos.distance_to(target_position)

	if distance > 5.0:
		var move_speed = speed * 1.1 * delta  # Escorts move slightly faster
		global_position += direction * min(move_speed, distance)

	# Check if should break formation to engage threats
	if should_engage_threats():
		set_state(EscortState.BREAKING)

func calculate_escort_position() -> void:
	if not leader_node:
		return

	# Calculate position based on leader's movement direction
	var leader_velocity = Vector2.ZERO
	# Note: get_velocity method doesn't exist, using default behavior
	
	# If leader is moving, position escort to the side and slightly behind
	if leader_velocity.length() > 10.0:
		var leader_direction = leader_velocity.normalized()
		var perpendicular = Vector2(-leader_direction.y, leader_direction.x)
		var behind_offset = -leader_direction * 20.0
		escort_position = perpendicular * escort_range + behind_offset
	else:
		# Static escort position
		escort_position = Vector2(escort_range, 0)

	target_position = leader_node.global_position + escort_position

func should_engage_threats() -> bool:
	# Check if player is threatening the formation
	var player = GameUtils.get_cached_player()
	if not player: return false
	var distance_to_player = global_position.distance_to(player.global_position)
	return distance_to_player < escort_range * 1.5 and protectiveness > 0.5

func set_state(new_state: int) -> void:
	escort_state = new_state
	time_since_engagement = 0.0

func _execute_formation_break(delta: float) -> void:
	time_since_engagement += delta
	if time_since_engagement > 0.5:
		set_state(EscortState.ENGAGING)

func engage_threats(delta: float) -> void:
	var player = GameUtils.get_cached_player()
	if not player:
		set_state(EscortState.RETURNING)
		return

	var direction = (player.global_position - global_position).normalized()
	global_position += direction * speed * 1.2 * delta

	time_since_engagement += delta
	if time_since_engagement > 3.0:
		set_state(EscortState.RETURNING)

func return_to_formation(delta: float) -> void:
	return_timer += delta
	var direction = (target_position - global_position).normalized()
	global_position += direction * speed * 0.8 * delta

	if return_timer > 2.0 or global_position.distance_to(target_position) < 10.0:
		set_state(EscortState.FORMATION)
		return_timer = 0.0

func screen_formation(delta: float) -> void:
	var screen_pos = leader_node.global_position + Vector2(escort_range * 1.5, 0)
	var direction = (screen_pos - global_position).normalized()
	global_position += direction * speed * 0.9 * delta

	if should_engage_threats():
		set_state(EscortState.BREAKING)
