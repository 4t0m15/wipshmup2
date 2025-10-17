extends Node

# CombatSystem - Handles all combat logic and damage calculation
# Extracted from Main.gd to centralize combat concerns

func _ready() -> void:
	# Connect to EventBus for combat events
	EventBus.bullet_hit_enemy.connect(_on_bullet_hit_enemy)
	EventBus.bullet_hit_player.connect(_on_bullet_hit_player)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.bomb_used.connect(_on_bomb_used)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.shield_absorbed.connect(_on_shield_absorbed)

func _on_bullet_hit_enemy(enemy_position: Vector2, damage: int) -> void:
	# Find the enemy at this position and apply damage
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.global_position.distance_to(enemy_position) < 10.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, "shot")
			break

func _on_bullet_hit_player(_bullet_position: Vector2) -> void:
	# Check if player is invincible
	if GameState.is_invincible():
		return
	
	# Apply damage to player
	GameState.take_lives(1)
	EventBus.player_damaged.emit(1)
	# Inform rank system of life loss
	if RankManager and RankManager.has_method("on_player_died"):
		RankManager.on_player_died(GameState.lives)
	
	# Start invincibility
	GameState.set_invincible(true)
	_start_invincibility_timer()

func _on_enemy_killed(points: int, position: Vector2, _enemy_type: String) -> void:
	# Update score
	GameState.add_score(points)
	
	# Update streak
	GameState.update_streak()
	
	# Screen shake for kill
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": 0.5,
		"duration": 0.05
	})
	
	# Try to drop items
	if ItemDropManager:
		ItemDropManager.try_drop_item(position, points)
	
	# Update rank
	if RankManager and RankManager.has_method("on_enemy_killed"):
		RankManager.on_enemy_killed(points)

func _on_boss_defeated(_boss_name: String, points: int) -> void:
	# Update score
	GameState.add_score(points)
	
	# Stronger screen shake for boss
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": 1.5,
		"duration": 0.22
	})
	
	# Update rank
	if RankManager and RankManager.has_method("on_boss_defeated"):
		RankManager.on_boss_defeated()

func _on_bomb_used(_position: Vector2) -> void:
	# Destroy all enemies in range
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			# Award points for bomb kills
			if enemy.has_method("take_damage"):
				enemy.take_damage(999, "bomb")
			elif enemy.has_method("die"):
				enemy.die()
			else:
				enemy.queue_free()
	
	# Destroy all enemy bullets
	var bullets = get_tree().get_nodes_in_group("enemy_bullet")
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	
	# Update rank for bomb usage
	if RankManager and RankManager.has_method("on_bomb_used"):
		RankManager.on_bomb_used()

func _on_player_hit() -> void:
	# Check if player is invincible
	if GameState.is_invincible():
		return
	
	# Apply damage
	GameState.take_lives(1)
	EventBus.player_damaged.emit(1)
	# Inform rank system of life loss
	if RankManager and RankManager.has_method("on_player_died"):
		RankManager.on_player_died(GameState.lives)
	
	# Reset Cho Ren Sha mechanics on death (minimal changes)
	GameState.reset_weapon_power()
	GameState.set_shield(false)
	
	# Start invincibility
	GameState.set_invincible(true)
	_start_invincibility_timer()
	
	# Break streak on hit
	GameState.break_streak()

func _start_invincibility_timer() -> void:
	# Start invincibility period
	var invincibility_timer = Timer.new()
	invincibility_timer.wait_time = 1.0  # 1 second of invincibility
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_end_invincibility)
	add_child(invincibility_timer)
	invincibility_timer.start()

func _end_invincibility() -> void:
	GameState.set_invincible(false)
	EventBus.player_invincibility_ended.emit()

func _on_shield_absorbed() -> void:
	"""Handle shield absorption with explosion effect"""
	print("[CombatSystem] Shield absorbed - triggering explosion effect")
	
	# Create visual explosion effect
	EventBus.emit_visual_effect("explosion", {
		"position": GameState.player_position,
		"size": 2.0
	})
	
	# Screen shake for impact
	EventBus.emit_visual_effect("screen_shake", {
		"intensity": 0.8,
		"duration": 0.15
	})
	
	# Damage nearby enemies (shield explosion effect)
	_damage_nearby_enemies(GameState.player_position, 50.0, 10)
	
	# Play shield absorption sound
	EventBus.emit_audio("shield_absorb")

func _damage_nearby_enemies(center: Vector2, radius: float, damage: int) -> void:
	"""Damage all enemies within radius of center point"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(center)
			if distance <= radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, "shield_explosion")
				print("[CombatSystem] Shield explosion damaged enemy at distance: ", distance)
