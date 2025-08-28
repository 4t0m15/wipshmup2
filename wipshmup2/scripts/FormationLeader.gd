class_name FormationLeader
extends ClassicEnemy

# Formation behavior states
enum FormationState {
	FORMING,        # Moving into formation
	MAINTAINING,    # Maintaining formation
	BREAKING,       # Breaking formation to engage
	REJOINING,      # Rejoining formation
	DISBANDED       # Formation dissolved
}

# Formation properties
@export var formation_pattern: int = 0  # FormationManager.FormationPattern
@export var formation_id: String = ""
@export var formation_spacing: float = 40.0
@export var formation_speed: float = 60.0
@export var break_formation_distance: float = 100.0
@export var rejoin_formation_distance: float = 150.0

# Internal state
var formation_state: int = FormationState.FORMING
var formation_manager = null
var formation_members: Array[Node2D] = []
var target_formation_center: Vector2 = Vector2.ZERO
var time_since_formation_break: float = 0.0
var formation_break_duration: float = 5.0

# FormationLeader specific optimizations

func _ready() -> void:
	super._ready()

	# Get formation manager reference
	formation_manager = get_node_or_null("/root/FormationManager")
	if not formation_manager:
		formation_manager = load("res://scripts/FormationManager.gd").new()
		get_tree().root.add_child(formation_manager)

	# Create formation
	if formation_id == "":
		formation_id = "formation_" + str(get_instance_id())
	
	formation_manager.create_formation(self, formation_pattern, formation_id)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_formation_behavior(delta)

func update_formation_behavior(delta: float) -> void:
	match formation_state:
		FormationState.FORMING:
			form_formation(delta)
		FormationState.MAINTAINING:
			maintain_formation(delta)
		FormationState.BREAKING:
			_execute_formation_break(delta)
		FormationState.REJOINING:
			rejoin_formation(delta)
		FormationState.DISBANDED:
			# Act independently
			pass

func form_formation(delta: float) -> void:
	var direction = (target_formation_center - global_position).normalized()
	var distance = global_position.distance_to(target_formation_center)
	
	if distance > 5.0:
		global_position += direction * formation_speed * delta
	else:
		set_formation_state(FormationState.MAINTAINING)

func maintain_formation(delta: float) -> void:
	# Check if should break formation
	if should_break_formation():
		set_formation_state(FormationState.BREAKING)
		return

	# Update formation center
	target_formation_center = global_position

	# Update member positions efficiently
	for member in formation_members:
		if is_instance_valid(member):
			update_member_position(member, delta)

func should_break_formation() -> bool:
	var player = _get_cached_player()
	if not player: return false
	
	var distance_to_player = global_position.distance_to(player.global_position)
	return distance_to_player < break_formation_distance

func set_formation_state(new_state: int) -> void:
	formation_state = new_state
	time_since_formation_break = 0.0

func _execute_formation_break(delta: float) -> void:
	time_since_formation_break += delta
	
	# Command members to break formation
	for member in formation_members:
		if is_instance_valid(member):
			# Members will handle their own break behavior
			pass
	
	if time_since_formation_break > 1.0:
		set_formation_state(FormationState.REJOINING)

func rejoin_formation(delta: float) -> void:
	time_since_formation_break += delta
	
	# Check if should rejoin
	var player = _get_cached_player()
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player > rejoin_formation_distance:
			set_formation_state(FormationState.MAINTAINING)
			return

	# Command members to rejoin
	for member in formation_members:
		if is_instance_valid(member):
			# Members will handle their own rejoin behavior
			pass

	if time_since_formation_break > formation_break_duration:
		set_formation_state(FormationState.MAINTAINING)

func update_member_position(member: Node2D, delta: float) -> void:
	# Calculate target position for member
	var target_pos = calculate_member_position(member)
	var direction = (target_pos - member.global_position).normalized()
	var distance = member.global_position.distance_to(target_pos)
	
	if distance > 5.0:
		member.global_position += direction * formation_speed * delta

func calculate_member_position(member: Node2D) -> Vector2:
	# Calculate position based on formation pattern
	var member_index = formation_members.find(member)
	if member_index == -1:
		return global_position
	
	# Simple V-formation calculation
	var offset = Vector2.ZERO
	match formation_pattern:
		0:  # V_FORMATION
			if member_index == 0:
				offset = Vector2(-formation_spacing, -formation_spacing * 0.5)
			elif member_index == 1:
				offset = Vector2(formation_spacing, -formation_spacing * 0.5)
			else:
				offset = Vector2(0, -formation_spacing)
		_:  # Default line formation
			offset = Vector2((member_index - 1) * formation_spacing, 0)
	
	return global_position + offset

func add_formation_member(member: Node2D) -> void:
	if not formation_members.has(member):
		formation_members.append(member)
		formation_manager.add_member_to_formation(formation_id, member)

func remove_formation_member(member: Node2D) -> void:
	formation_members.erase(member)
	formation_manager.remove_from_formation(formation_id, member)

func dissolve_formation() -> void:
	set_formation_state(FormationState.DISBANDED)
	formation_manager.dissolve_formation(formation_id)
	formation_members.clear()

# Optimized player finding with caching
func _get_cached_player() -> Node2D:
	return GameUtils.get_cached_player()
