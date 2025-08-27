class_name FormationManager
extends Node

# Formation patterns for 1942-style enemy formations
enum FormationPattern {
	LINE_HORIZONTAL,    # Straight horizontal line
	LINE_VERTICAL,      # Vertical line (for entry)
	V_FORMATION,        # Classic V formation
	DIAMOND,           # Diamond pattern
	ECHELON_LEFT,      # Staggered left
	ECHELON_RIGHT,     # Staggered right
	CIRCLE,            # Circular formation
	COLUMN,            # Column formation
}

# Formation behavior states
enum FormationState {
	FORMING,           # Moving into formation
	MAINTAINING,       # Holding formation
	BREAKING,          # Breaking formation for attack
	REJOINING,         # Returning to formation
	DISBANDED          # Formation dissolved
}

class Formation:
	var id: String
	var leader: Node2D
	var members: Array[Node2D]
	var pattern: int
	var state: int = FormationState.FORMING
	var spacing: float = 40.0
	var formation_speed: float = 60.0
	var target_positions: Array[Vector2]
	var escort_positions: Array[Vector2]
	var escorts: Array[Node2D]
	var center_point: Vector2
	var break_distance: float = 80.0  # Distance at which escorts break formation

	func _init(formation_id: String, formation_leader: Node2D, formation_pattern: int):
		id = formation_id
		leader = formation_leader
		pattern = formation_pattern
		members = []
		escorts = []
		if leader:
			members.append(leader)

	func add_member(member: Node2D) -> void:
		if member and not members.has(member):
			members.append(member)

	func remove_member(member: Node2D) -> void:
		members.erase(member)
		escorts.erase(member)
		if member == leader and members.size() > 0:
			leader = members[0]  # Promote first member to leader

	func add_escort(escort: Node2D) -> void:
		if escort and not escorts.has(escort):
			escorts.append(escort)
			if not members.has(escort):
				members.append(escort)

	func update_formation(delta: float) -> void:
		if not leader or members.size() == 0:
			return

		center_point = leader.global_position

		# Update target positions based on pattern
		_update_target_positions()

		# Update member positions
		for i in range(members.size()):
			if members[i] and members[i] != leader:
				_update_member_position(members[i], i, delta)

		# Update escort positions
		for i in range(escorts.size()):
			if escorts[i]:
				_update_escort_position(escorts[i], i, delta)

	func _update_target_positions() -> void:
		target_positions.clear()
		var member_count = members.size()

		match pattern:
			FormationPattern.LINE_HORIZONTAL:
				for i in range(member_count):
					var offset = Vector2((i - (member_count - 1) / 2.0) * spacing, 0)
					target_positions.append(center_point + offset)

			FormationPattern.LINE_VERTICAL:
				for i in range(member_count):
					var offset = Vector2(0, (i - (member_count - 1) / 2.0) * spacing)
					target_positions.append(center_point + offset)

			FormationPattern.V_FORMATION:
				for i in range(member_count):
					var row = i / 3.0
					var col = i % 3
					var offset_x = (col - 1) * spacing * 0.7
					var offset_y = row * spacing * 0.8
					target_positions.append(center_point + Vector2(offset_x, offset_y))

			FormationPattern.DIAMOND:
				var positions = [
					Vector2(0, -spacing),      # Top
					Vector2(-spacing, 0),      # Left
					Vector2(spacing, 0),       # Right
					Vector2(0, spacing),       # Bottom
				]
				for pos in positions:
					if target_positions.size() < member_count:
						target_positions.append(center_point + pos)

			FormationPattern.ECHELON_LEFT:
				for i in range(member_count):
					var offset = Vector2(-i * spacing * 0.5, i * spacing * 0.8)
					target_positions.append(center_point + offset)

			FormationPattern.ECHELON_RIGHT:
				for i in range(member_count):
					var offset = Vector2(i * spacing * 0.5, i * spacing * 0.8)
					target_positions.append(center_point + offset)

			FormationPattern.CIRCLE:
				for i in range(member_count):
					var angle = (TAU * i) / member_count
					var offset = Vector2(cos(angle), sin(angle)) * spacing
					target_positions.append(center_point + offset)

			FormationPattern.COLUMN:
				for i in range(member_count):
					var offset = Vector2(0, i * spacing)
					target_positions.append(center_point + offset)

	func _update_member_position(member: Node2D, index: int, delta: float) -> void:
		if index >= target_positions.size():
			return

		var target_pos = target_positions[index]
		var current_pos = member.global_position
		var direction = (target_pos - current_pos).normalized()
		var distance = current_pos.distance_to(target_pos)

		# Smooth movement toward target position
		if distance > 5.0:
			var move_speed = formation_speed * delta
			member.global_position += direction * min(move_speed, distance)

	func _update_escort_position(escort: Node2D, index: int, delta: float) -> void:
		if not leader:
			return

		# Escorts maintain protective positions around the formation
		var escort_angles = [PI * 0.3, PI * 0.7, PI * 1.3, PI * 1.7]  # 4 escort positions
		var angle = escort_angles[index % escort_angles.size()]
		var distance = break_distance

		var target_pos = center_point + Vector2(cos(angle), sin(angle)) * distance
		var current_pos = escort.global_position
		var direction = (target_pos - current_pos).normalized()
		var move_distance = current_pos.distance_to(target_pos)

		# Escorts move faster and more responsively
		if move_distance > 10.0:
			var move_speed = (formation_speed * 1.2) * delta
			escort.global_position += direction * min(move_speed, move_distance)

	func get_formation_center() -> Vector2:
		return center_point

	func get_member_count() -> int:
		return members.size()

	func is_formation_intact() -> bool:
		# Check if all members are close to their target positions
		for i in range(members.size()):
			if i >= target_positions.size():
				continue
			if members[i]:
				var distance = members[i].global_position.distance_to(target_positions[i])
				if distance > spacing * 0.5:
					return false
		return true

# Main formation management
var formations: Dictionary = {}  # formation_id -> Formation
var formation_counter: int = 0

func _ready() -> void:
	# Set as singleton
	if formations == null:
		formations = {}
	if get_parent() == get_tree().root:
		pass  # Already at root level

func create_formation(leader: Node2D, pattern: int, formation_id: String = "") -> String:
	if not leader:
		return ""

	if formation_id == "":
		formation_id = "formation_" + str(formation_counter)
		formation_counter += 1

	var formation = Formation.new(formation_id, leader, pattern)
	formations[formation_id] = formation

	return formation_id

func add_member_to_formation(formation_id: String, member: Node2D) -> void:
	if formations.has(formation_id) and member:
		formations[formation_id].add_member(member)

func add_escort_to_formation(formation_id: String, escort: Node2D) -> void:
	if formations.has(formation_id) and escort:
		formations[formation_id].add_escort(escort)

func remove_from_formation(formation_id: String, member: Node2D) -> void:
	if formations.has(formation_id):
		formations[formation_id].remove_member(member)

func dissolve_formation(formation_id: String) -> void:
	if formations.has(formation_id):
		formations.erase(formation_id)

func update_formations(delta: float) -> void:
	for formation_id in formations.keys():
		var formation = formations[formation_id]
		if formation:
			formation.update_formation(delta)

func get_formation(formation_id: String) -> Formation:
	return formations.get(formation_id)

func get_all_formations() -> Array:
	return formations.values()

# Utility functions for creating common formations
func create_fighter_squad(leader: Node2D, member_count: int = 3) -> String:
	var formation_id = create_formation(leader, FormationPattern.V_FORMATION)

	# Add wingmen to the formation
	for i in range(member_count - 1):  # -1 because leader is already added
		# Create additional fighter enemies
		var member = _create_fighter_for_formation(leader.global_position + Vector2(i * 40, 20))
		if member:
			add_member_to_formation(formation_id, member)

	return formation_id

func create_bomber_escort(bomber: Node2D, escort_count: int = 2) -> String:
	var formation_id = create_formation(bomber, FormationPattern.LINE_HORIZONTAL)

	# Add escort fighters
	for i in range(escort_count):
		var escort = _create_fighter_for_formation(bomber.global_position + Vector2((i - escort_count/2.0) * 60, -30))
		if escort:
			add_escort_to_formation(formation_id, escort)

	return formation_id

func _create_fighter_for_formation(_position: Vector2) -> Node2D:
	# This would typically instantiate a fighter scene
	# For now, return null - will be implemented when integrating with StageController
	return null

# Formation analysis for AI decision making
func get_nearest_formation_to_point(point: Vector2) -> Formation:
	var nearest_formation: Formation = null
	var nearest_distance = INF

	for formation in formations.values():
		if formation and formation.leader:
			var distance = formation.get_formation_center().distance_to(point)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_formation = formation

	return nearest_formation

func get_formations_in_area(center: Vector2, radius: float) -> Array:
	var formations_in_area = []

	for formation in formations.values():
		if formation and formation.leader:
			if formation.get_formation_center().distance_to(center) <= radius:
				formations_in_area.append(formation)

	return formations_in_area
