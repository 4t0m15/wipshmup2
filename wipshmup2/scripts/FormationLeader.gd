class_name FormationLeader
extends ClassicEnemy

# Formation leadership properties
@export var formation_id: String = ""
@export var formation_pattern: int = 0
@export var max_formation_members: int = 5
@export var formation_spacing: float = 40.0
@export var command_range: float = 200.0

# Leadership behavior
@export var leadership_style: int = 0  # 0: Aggressive, 1: Defensive, 2: Evasive
@export var command_interval: float = 3.0  # How often to issue commands
@export var rally_point: Vector2 = Vector2.ZERO

# Internal state
var formation_manager = null
var last_command_time: float = 0.0
var formation_members: Array[Node2D] = []
var escort_units: Array[Node2D] = []
var is_formation_leader: bool = true

func _ready() -> void:
	super._ready()

	# Get formation manager reference
	formation_manager = get_node_or_null("/root/FormationManager")
	if not formation_manager:
		# Create formation manager if it doesn't exist
		formation_manager = load("res://scripts/FormationManager.gd").new()
		get_tree().root.call_deferred("add_child", formation_manager)

	# Initialize formation
	if formation_id == "":
		formation_id = "auto_" + str(get_instance_id())

	if formation_manager:
		formation_id = formation_manager.create_formation(self, formation_pattern, formation_id)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update leadership behavior
	last_command_time += delta
	if last_command_time >= command_interval:
		issue_formation_command()
		last_command_time = 0.0

	# Maintain formation cohesion
	maintain_formation()

func issue_formation_command() -> void:
	if not formation_manager or not is_formation_leader:
		return

	var formation = formation_manager.get_formation(formation_id)
	if not formation:
		return

	match leadership_style:
		0:  # Aggressive - push formation forward
			formation.formation_speed = speed * 1.2
			# Command escorts to engage threats
			command_engaging_attack()
		1:  # Defensive - maintain tight formation
			formation.formation_speed = speed * 0.8
			formation.spacing = formation_spacing * 0.8
			# Command escorts to protective positions
			command_defensive_stance()
		2:  # Evasive - spread formation for safety
			formation.formation_speed = speed * 0.9
			formation.spacing = formation_spacing * 1.2
			# Command escorts to screening positions
			command_evasive_maneuver()

func command_engaging_attack() -> void:
	# Command escorts to break formation and engage player
	for escort in escort_units:
		if escort and escort.has_method("set_formation_state"):
			escort.call("set_formation_state", "break")

func command_defensive_stance() -> void:
	# Command escorts to maintain tight protective positions
	for escort in escort_units:
		if escort and escort.has_method("set_formation_state"):
			escort.call("set_formation_state", "defend")

func command_evasive_maneuver() -> void:
	# Command escorts to spread out and screen
	for escort in escort_units:
		if escort and escort.has_method("set_formation_state"):
			escort.call("set_formation_state", "screen")

func maintain_formation() -> void:
	if not formation_manager:
		return

	var formation = formation_manager.get_formation(formation_id)
	if not formation:
		return

	# Check formation integrity
	if not formation.is_formation_intact():
		# Formation is broken, issue rally command
		if randf() < 0.1:  # 10% chance per frame to issue rally
			command_formation_rally()

func command_formation_rally() -> void:
	# Issue rally command to all formation members
	for member in formation_members:
		if member and member != self and member.has_method("rally_to_leader"):
			member.call("rally_to_leader", global_position)

func add_formation_member(member: Node2D) -> void:
	if member and not formation_members.has(member):
		formation_members.append(member)
		if formation_manager:
			formation_manager.add_member_to_formation(formation_id, member)

func add_escort_member(escort: Node2D) -> void:
	if escort and not escort_units.has(escort):
		escort_units.append(escort)
		if formation_manager:
			formation_manager.add_escort_to_formation(formation_id, escort)

func remove_formation_member(member: Node2D) -> void:
	formation_members.erase(member)
	escort_units.erase(member)
	if formation_manager:
		formation_manager.remove_from_formation(formation_id, member)

func get_formation_size() -> int:
	return formation_members.size()

func get_escort_count() -> int:
	return escort_units.size()

func set_leadership_style(new_style: int) -> void:
	leadership_style = new_style
	# Immediately issue command with new style
	issue_formation_command()

func take_damage(amount: int, source: String = "shot") -> void:
	super.take_damage(amount, source)

	# If leader takes heavy damage, formation might break
	if hp <= hp * 0.3 and randf() < 0.5:  # 50% chance when below 30% health
		break_formation()

func break_formation() -> void:
	# Break formation and let members act independently
	for member in formation_members:
		if member and member != self and member.has_method("break_formation"):
			member.call("break_formation")

	for escort in escort_units:
		if escort and escort.has_method("break_from_formation"):
			escort.call("break_from_formation")

	# Mark self as no longer leading
	is_formation_leader = false

func rally_formation() -> void:
	# Attempt to reform the formation
	is_formation_leader = true
	if formation_manager:
		formation_id = formation_manager.create_formation(self, formation_pattern)

	# Rally existing members
	for member in formation_members:
		if member and member.has_method("join_formation"):
			member.call("join_formation", formation_id)

func _on_destroyed() -> void:
	# When leader is destroyed, formation disbands
	if formation_manager:
		formation_manager.dissolve_formation(formation_id)

	# Notify all members that leader is gone
	for member in formation_members:
		if member and member != self and member.has_method("leader_destroyed"):
			member.call("leader_destroyed")

	super.take_damage(9999)  # Ensure destruction
