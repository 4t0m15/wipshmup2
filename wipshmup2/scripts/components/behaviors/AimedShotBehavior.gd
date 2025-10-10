extends AttackBehavior
class_name AimedShotBehavior

# Aimed shot behavior - fires at player position

@export var aim_lead: float = 0.5  # How far ahead to aim

func _handle_attack(delta: float) -> void:
	if can_attack():
		_fire_aimed_shot()

func _fire_aimed_shot() -> void:
	# Get player position
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		# Fire straight down if no player found
		fire_bullet(Vector2.DOWN)
		return
	
	# Calculate aim direction with lead
	var player_pos = player.global_position
	var distance = enemy.global_position.distance_to(player_pos)
	var lead_time = distance / bullet_speed * aim_lead
	
	# Predict player position
	var player_velocity = Vector2.ZERO
	if player.has_method("get_velocity"):
		player_velocity = player.get_velocity()
	
	var predicted_pos = player_pos + player_velocity * lead_time
	fire_bullet_at_target(predicted_pos)
