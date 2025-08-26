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
	if leader_node.has_method("get_velocity"):
		leader_velocity = leader_node.call("get_velocity")

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
	var player = _find_player()
	if not player or not leader_node:
		return false

	var distance_to_leader = global_position.distance_to(leader_node.global_position)
	var player_to_leader_distance = player.global_position.distance_to(leader_node.global_position)
	var player_to_escort_distance = player.global_position.distance_to(global_position)

	# Engage if player is closer to leader than escort is, and within range
	var within_range = player_to_escort_distance < escort_range * 2.0
	if player_to_leader_distance < distance_to_leader and within_range:
		return randf() < protectiveness  # Random chance based on protectiveness

	return false

func _execute_formation_break(delta: float) -> void:
	# Move toward player to intercept
	var player = _find_player()
	if player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * speed * 1.5 * delta

		# Check if close enough to engage
		if global_position.distance_to(player.global_position) < 100.0:
			set_state(EscortState.ENGAGING)
	else:
		# No player found, return to formation
		set_state(EscortState.RETURNING)

func engage_threats(delta: float) -> void:
	time_since_engagement += delta

	# Engage the player more aggressively
	var player = _find_player()
	if player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * speed * 1.3 * delta

		# Fire more frequently while engaging
		if fire_pattern != -1 and time_since_engagement > 1.0:
			_fire_straight_shot()  # More aggressive firing

	# Return to formation after engagement period
	if time_since_engagement > 5.0 or not player:
		set_state(EscortState.RETURNING)

func return_to_formation(delta: float) -> void:
	return_timer += delta

	if return_timer > 2.0:  # Give time to disengage
		set_state(EscortState.FORMATION)
		return_timer = 0.0
		time_since_engagement = 0.0

	# Move back toward formation
	if leader_node:
		var direction = (leader_node.global_position - global_position).normalized()
		global_position += direction * speed * delta

func screen_formation(delta: float) -> void:
	# Screen ahead of the formation
	if leader_node:
		var leader_direction = Vector2.DOWN  # Default down
		if leader_node.has_method("get_velocity"):
			var velocity = leader_node.call("get_velocity")
			if velocity.length() > 10.0:
				leader_direction = velocity.normalized()

		var screen_position = leader_node.global_position + leader_direction * escort_range
		var direction = (screen_position - global_position).normalized()
		var distance = global_position.distance_to(screen_position)

		if distance > 10.0:
			global_position += direction * speed * 0.8 * delta

func set_state(new_state: int) -> void:
	if escort_state != new_state:
		escort_state = new_state
		_on_state_changed(new_state)

func _on_state_changed(new_state: int) -> void:
	match new_state:
		EscortState.FORMATION:
			# Return to normal behavior
			pass
		EscortState.BREAKING:
			# Prepare to break formation
			pass
		EscortState.ENGAGING:
			# Start engaging
			time_since_engagement = 0.0
		EscortState.RETURNING:
			# Return to formation
			return_timer = 0.0
		EscortState.SCREENING:
			# Screen formation
			pass

# Formation commands from leader
func set_formation_state(state: String) -> void:
	match state:
		"break":
			set_state(EscortState.BREAKING)
		"defend":
			set_state(EscortState.FORMATION)
		"screen":
			set_state(EscortState.SCREENING)

func rally_to_leader(_leader_position: Vector2) -> void:
	if leader_node:
		set_state(EscortState.RETURNING)

func break_from_formation() -> void:
	set_state(EscortState.BREAKING)

func join_formation(new_formation_id: String) -> void:
	formation_id = new_formation_id
	set_state(EscortState.RETURNING)

func leader_destroyed() -> void:
	# Leader destroyed, become independent
	leader_node = null
	set_state(EscortState.FORMATION)
	# Could implement logic to find new leader or act independently

func set_leader(new_leader: Node2D) -> void:
	leader_node = new_leader
	if leader_node:
		last_leader_position = leader_node.global_position

func get_escort_state() -> String:
	match escort_state:
		EscortState.FORMATION:
			return "formation"
		EscortState.BREAKING:
			return "breaking"
		EscortState.ENGAGING:
			return "engaging"
		EscortState.RETURNING:
			return "returning"
		EscortState.SCREENING:
			return "screening"
	return "unknown"
