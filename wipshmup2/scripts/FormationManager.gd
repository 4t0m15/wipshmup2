class_name FormationManager
extends Node

enum FormationPattern {
	LINE_HORIZONTAL, LINE_VERTICAL, V_FORMATION, DIAMOND, 
	ECHELON_LEFT, ECHELON_RIGHT, CIRCLE, COLUMN
}

enum FormationState {
	FORMING, MAINTAINING, BREAKING, REJOINING, DISBANDED
}

class Formation:
	var id: String
	var leader: Node2D
	var members: Array[Node2D]
	var pattern: int
	var state: int = FormationState.FORMING
	var spacing: float = 40.0
	var formation_speed: float = 60.0
	var center_point: Vector2
	var _cached_positions: Array[Vector2] = []
	var _position_cache_valid: bool = false

	func _init(formation_id: String, formation_leader: Node2D, formation_pattern: int):
		id = formation_id
		leader = formation_leader
		pattern = formation_pattern
		members = []
		if leader:
			members.append(leader)

	func add_member(member: Node2D) -> void:
		if member and not members.has(member):
			members.append(member)
			_position_cache_valid = false

	func remove_member(member: Node2D) -> void:
		members.erase(member)
		_position_cache_valid = false
		if member == leader and members.size() > 0:
			leader = members[0]

	func update_formation(delta: float) -> void:
		if not leader or members.size() == 0:
			return

		center_point = leader.global_position
		
		# Update member positions efficiently
		var target_positions = _get_target_positions()
		for i in range(members.size()):
			if members[i] and members[i] != leader and i < target_positions.size():
				_update_member_position(members[i], target_positions[i], delta)

	func _get_target_positions() -> Array[Vector2]:
		if _position_cache_valid and _cached_positions.size() == members.size():
			return _cached_positions
		
		_cached_positions.clear()
		var member_count = members.size()

		match pattern:
			FormationPattern.LINE_HORIZONTAL:
				for i in range(member_count):
					_cached_positions.append(center_point + Vector2((i - (member_count - 1) / 2.0) * spacing, 0))
			FormationPattern.LINE_VERTICAL:
				for i in range(member_count):
					_cached_positions.append(center_point + Vector2(0, (i - (member_count - 1) / 2.0) * spacing))
			FormationPattern.V_FORMATION:
				for i in range(member_count):
					var row = i / 3.0
					var col = i % 3
					_cached_positions.append(center_point + Vector2((col - 1) * spacing * 0.7, row * spacing * 0.8))
			FormationPattern.DIAMOND:
				var diamond_positions = [Vector2(0, -spacing), Vector2(-spacing, 0), Vector2(spacing, 0), Vector2(0, spacing)]
				for i in range(min(member_count, diamond_positions.size())):
					_cached_positions.append(center_point + diamond_positions[i])
			FormationPattern.ECHELON_LEFT:
				for i in range(member_count):
					_cached_positions.append(center_point + Vector2(-i * spacing * 0.5, i * spacing * 0.8))
			FormationPattern.ECHELON_RIGHT:
				for i in range(member_count):
					_cached_positions.append(center_point + Vector2(i * spacing * 0.5, i * spacing * 0.8))
			FormationPattern.CIRCLE:
				for i in range(member_count):
					var angle = (TAU * i) / member_count
					_cached_positions.append(center_point + Vector2(cos(angle), sin(angle)) * spacing)
			FormationPattern.COLUMN:
				for i in range(member_count):
					_cached_positions.append(center_point + Vector2(0, i * spacing))

		_position_cache_valid = true
		return _cached_positions

	func _update_member_position(member: Node2D, target_pos: Vector2, delta: float) -> void:
		var direction = (target_pos - member.global_position).normalized()
		var distance = member.global_position.distance_to(target_pos)
		if distance > 5.0:
			var move_speed = formation_speed * delta
			member.global_position += direction * min(move_speed, distance)

	func get_formation_center() -> Vector2:
		return center_point

	func get_member_count() -> int:
		return members.size()

	func is_formation_intact() -> bool:
		var target_positions = _get_target_positions()
		for i in range(members.size()):
			if i < target_positions.size() and members[i]:
				var distance = members[i].global_position.distance_to(target_positions[i])
				if distance > spacing * 0.5:
					return false
		return true

var formations: Dictionary = {}
var formation_counter: int = 0

func _ready() -> void:
	if formations == null:
		formations = {}

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

func remove_from_formation(formation_id: String, member: Node2D) -> void:
	if formations.has(formation_id):
		formations[formation_id].remove_member(member)

func dissolve_formation(formation_id: String) -> void:
	if formations.has(formation_id):
		formations.erase(formation_id)

func update_formations(delta: float) -> void:
	for formation in formations.values():
		if formation:
			formation.update_formation(delta)

func get_formation(formation_id: String) -> Formation:
	return formations.get(formation_id)

func get_all_formations() -> Array:
	return formations.values()

func create_fighter_squad(leader: Node2D, member_count: int = 3) -> String:
	var formation_id = create_formation(leader, FormationPattern.V_FORMATION)
	for i in range(member_count - 1):
		var member = _create_fighter_for_formation(leader.global_position + Vector2(i * 40, 20))
		if member:
			add_member_to_formation(formation_id, member)
	return formation_id

func _create_fighter_for_formation(_position: Vector2) -> Node2D:
	return null

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
