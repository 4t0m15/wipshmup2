extends Node

# EntityFactory - Centralized entity spawning and management
# Handles all entity creation with proper setup and object pooling

# Scene references - loaded safely
var PLAYER_SCENE: PackedScene
var BULLET_SCENE: PackedScene
var ENEMY_BULLET_SCENE: PackedScene
var ENEMY_SCENE: PackedScene

# Safety caps - INCREASED FOR MORE CHAOS
const MAX_ENEMY_BULLETS: int = 300  # Increased from 140
const MAX_ENEMY_BULLETS_PER_SEC: int = 200  # Increased from 90

# Simple rate limiter state
var _bullet_rate_window_start_ms: int = 0
var _bullet_rate_count: int = 0

# Object pools for performance
var bullet_pool: Array[Node] = []
var enemy_bullet_pool: Array[Node] = []
var max_pool_size: int = 100

var game_viewport: Node
var bullets_container: Node
var enemies_container: Node

func _ready() -> void:
	print("[EntityFactory] Entity factory initialized")
	_load_scenes()
	_initialize_pools()

func _load_scenes() -> void:
	"""Load scene resources safely"""
	var rv := get_node_or_null("/root/ResourceValidator")
	if rv and is_instance_valid(rv) and rv.has_method("safe_load_scene"):
		PLAYER_SCENE = rv.safe_load_scene("res://scenes/player/Player.tscn")
		BULLET_SCENE = rv.safe_load_scene("res://scenes/bullet/Bullet.tscn")
		ENEMY_BULLET_SCENE = rv.safe_load_scene("res://scenes/bullet/EnemyBullet.tscn")
		ENEMY_SCENE = rv.safe_load_scene("res://scenes/enemy/Enemy.tscn")
	else:
		PLAYER_SCENE = load("res://scenes/player/Player.tscn")
		BULLET_SCENE = load("res://scenes/bullet/Bullet.tscn")
		ENEMY_BULLET_SCENE = load("res://scenes/bullet/EnemyBullet.tscn")
		ENEMY_SCENE = load("res://scenes/enemy/Enemy.tscn")
	
	# Validate critical scenes with better error handling
	if not PLAYER_SCENE:
		push_error("[EntityFactory] Failed to load player scene")
	if not BULLET_SCENE:
		push_error("[EntityFactory] Failed to load bullet scene")
	if not ENEMY_BULLET_SCENE:
		push_error("[EntityFactory] Failed to load enemy bullet scene")
	if not ENEMY_SCENE:
		push_error("[EntityFactory] Failed to load enemy scene")

func _initialize_pools() -> void:
	# Pre-populate bullet pools for performance
	if BULLET_SCENE:
		for i in range(20):
			var bullet = BULLET_SCENE.instantiate()
			if bullet and is_instance_valid(bullet):
				bullet.visible = false
				bullet.set_meta("pooled", true)
				bullet.set_meta("pool_kind", "player")
				bullet_pool.append(bullet)
		#yo pierre you wanna come out here
	if ENEMY_BULLET_SCENE:
		for i in range(20):
			var enemy_bullet = ENEMY_BULLET_SCENE.instantiate()
			if enemy_bullet and is_instance_valid(enemy_bullet):
				enemy_bullet.visible = false
				enemy_bullet.set_meta("pooled", true)
				enemy_bullet.set_meta("pool_kind", "enemy")
				enemy_bullet_pool.append(enemy_bullet)

func set_containers(game_viewport_node: Node) -> void:
	game_viewport = game_viewport_node
	bullets_container = game_viewport.get_node_or_null("Bullets")
	enemies_container = game_viewport.get_node_or_null("Enemies")
	
	if not bullets_container:
		bullets_container = Node.new()
		bullets_container.name = "Bullets"
		game_viewport.call_deferred("add_child", bullets_container)
	
	if not enemies_container:
		enemies_container = Node.new()
		enemies_container.name = "Enemies"
		game_viewport.call_deferred("add_child", enemies_container)

# Player Spawning
func spawn_player(spawn_position: Vector2 = Vector2(160, 150)) -> Node:
	var player = PLAYER_SCENE.instantiate()
	player.position = spawn_position
	
	var container = game_viewport if game_viewport else get_tree().current_scene
	container.call_deferred("add_child", player)
	
	# Setup player hurtbox
	_setup_player_hurtbox(player)
	
	# Connect player signals to EventBus
	_connect_player_signals(player)
	
	EventBus.entity_spawned.emit(player, "player")
	return player

func _setup_player_hurtbox(player: Node) -> void:
	var hurtbox = player.get_node_or_null("Hurtbox")
	if not hurtbox:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = CircleShape2D.new()
		(collision_shape.shape as CircleShape2D).radius = 6.0
		hurtbox.add_child(collision_shape)
		player.add_child(hurtbox)
	
	hurtbox.add_to_group("player_hurtbox")
	hurtbox.monitoring = true
	hurtbox.monitorable = true
	hurtbox.collision_layer = 1   # Player layer
	hurtbox.collision_mask = 2    # Enemy bullet layer

func _connect_player_signals(player: Node) -> void:
	if player.has_signal("damaged"):
		player.damaged.connect(_on_player_damaged)
	if player.has_signal("hit"):
		player.hit.connect(_on_player_hit)

func _on_player_damaged(amount: int) -> void:
	EventBus.player_damaged.emit(amount)

func _on_player_hit() -> void:
	EventBus.player_hit.emit()

# Bullet Spawning
func spawn_player_bullet(spawn_position: Vector2, direction: Vector2 = Vector2.UP, speed: float = 400.0) -> Node:
	if not BULLET_SCENE:
		push_error("[EntityFactory] Player bullet scene not loaded")
		return null
	
	var bullet = _get_pooled_bullet(bullet_pool, BULLET_SCENE)
	if not bullet or not is_instance_valid(bullet):
		push_error("[EntityFactory] Failed to get pooled bullet for player")
		return null
	
	bullet.position = spawn_position
	if bullet.has_method("set"):
		bullet.set("direction", direction)
		bullet.set("speed", speed)
	bullet.visible = true
	
	var container = _get_bullet_container()
	if container and is_instance_valid(container):
		container.call_deferred("add_child", bullet)
	else:
		push_error("EntityFactory: No valid container found for player bullet")
		if bullet.get_meta("pooled", false):
			bullet.visible = false
		else:
			bullet.queue_free()
		return null
	
	_connect_bullet_signals(bullet, "player")
	if EventBus and EventBus.has_signal("entity_spawned"):
		EventBus.entity_spawned.emit(bullet, "player_bullet")
	return bullet

func spawn_enemy_bullet(spawn_position: Vector2, direction: Vector2 = Vector2.DOWN, speed: float = 140.0, damage: int = 1) -> Node:
	if not ENEMY_BULLET_SCENE:
		push_error("[EntityFactory] Enemy bullet scene not loaded")
		return null
	
	# Global cap to prevent runaway spawning/lockups
	var container_check = _get_bullet_container()
	if container_check and is_instance_valid(container_check) and container_check.get_child_count() >= MAX_ENEMY_BULLETS:
		return null

	# Skip spawning during heavy hit-stop to avoid visible bullet walls
	if Engine.time_scale < 0.2:
		return null

	# Rate limit enemy bullet spawns
	var now_ms: int = Time.get_ticks_msec()
	if _bullet_rate_window_start_ms == 0 or now_ms - _bullet_rate_window_start_ms >= 1000:
		_bullet_rate_window_start_ms = now_ms
		_bullet_rate_count = 0
	else:
		if _bullet_rate_count >= MAX_ENEMY_BULLETS_PER_SEC:
			return null
		_bullet_rate_count += 1

	var bullet = _get_pooled_bullet(enemy_bullet_pool, ENEMY_BULLET_SCENE)
	if not bullet or not is_instance_valid(bullet):
		push_error("[EntityFactory] Failed to get pooled bullet for enemy")
		return null
	
	bullet.position = spawn_position
	if bullet.has_method("set"):
		bullet.set("direction", direction)
		bullet.set("speed", speed)
		bullet.set("damage", damage)
	bullet.visible = true
	
	var container = _get_bullet_container()
	if container and is_instance_valid(container):
		container.call_deferred("add_child", bullet)
	else:
		push_error("EntityFactory: No valid container found for enemy bullet")
		if bullet.get_meta("pooled", false):
			bullet.visible = false
		else:
			bullet.queue_free()
		return null
	
	_connect_bullet_signals(bullet, "enemy")
	if EventBus and EventBus.has_signal("entity_spawned"):
		EventBus.entity_spawned.emit(bullet, "enemy_bullet")
	return bullet

func _get_bullet_container() -> Node:
	"""Get a valid container for bullets, creating one if necessary"""
	# Try bullets_container first
	if bullets_container and is_instance_valid(bullets_container):
		return bullets_container
	
	# Try game_viewport
	if game_viewport and is_instance_valid(game_viewport):
		# Try to find or create Bullets container
		var bullets_node = game_viewport.get_node_or_null("Bullets")
		if bullets_node:
			bullets_container = bullets_node
			return bullets_container
		else:
			# Create Bullets container
			bullets_container = Node.new()
			bullets_container.name = "Bullets"
			game_viewport.add_child(bullets_container)
			return bullets_container
	
	# Fallback: try to get current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		var bullets_node = current_scene.get_node_or_null("Bullets")
		if bullets_node:
			return bullets_node
		else:
			# Create Bullets container in current scene
			bullets_container = Node.new()
			bullets_container.name = "Bullets"
			current_scene.add_child(bullets_container)
			return bullets_container
	
	return null

func _get_pooled_bullet(pool: Array, scene: PackedScene) -> Node:
	# Safety check for scene
	if not scene or not is_instance_valid(scene):
		push_error("[EntityFactory] Invalid scene provided to _get_pooled_bullet")
		return null
	
	# Try to get from pool first, cleaning up invalid entries
	var valid_bullets = []
	for bullet in pool:
		if bullet and is_instance_valid(bullet):
			if not bullet.get_parent():
				valid_bullets.append(bullet)
	
	# Update pool with only valid bullets
	pool.clear()
	pool.append_array(valid_bullets)
	
	# Return first available bullet if any
	if pool.size() > 0:
		var pooled_bullet = pool.pop_front()
		if pooled_bullet and is_instance_valid(pooled_bullet):
			return pooled_bullet
	
	# Create new if pool is empty
	var new_bullet = scene.instantiate()
	if new_bullet and is_instance_valid(new_bullet):
		new_bullet.set_meta("pooled", true)
		return new_bullet
	else:
		push_error("[EntityFactory] Failed to instantiate bullet from scene")
		return null

func _connect_bullet_signals(bullet: Node, bullet_type: String) -> void:
	if not bullet or not is_instance_valid(bullet):
		return
	
	if bullet_type == "player":
		if bullet.has_signal("area_entered"):
			if not bullet.area_entered.is_connected(_on_player_bullet_hit):
				bullet.area_entered.connect(_on_player_bullet_hit)
	elif bullet_type == "enemy":
		if bullet.has_signal("hit_player"):
			if not bullet.hit_player.is_connected(_on_enemy_bullet_hit_player):
				bullet.hit_player.connect(_on_enemy_bullet_hit_player)

func _on_player_bullet_hit(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		EventBus.bullet_hit_enemy.emit(area.global_position, 2)
		EventBus.emit_audio("enemy_shot")

func _on_enemy_bullet_hit_player() -> void:
	EventBus.bullet_hit_player.emit(Vector2.ZERO)
	EventBus.emit_audio("player_hit")

# Enemy Spawning
func spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2, properties: Dictionary = {}) -> Node:
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	
	# Apply properties
	for key in properties:
		if enemy.has_method("set") or enemy.get(key) != null:
			enemy.set(key, properties[key])
	
	var container = enemies_container if enemies_container else game_viewport
	container.call_deferred("add_child", enemy)
	
	_connect_enemy_signals(enemy)
	EventBus.entity_spawned.emit(enemy, "enemy")
	EventBus.enemy_spawned.emit(enemy, properties.get("enemy_type", "enemy"))
	return enemy

func _connect_enemy_signals(enemy: Node) -> void:
	if enemy.has_signal("killed"):
		if not enemy.killed.is_connected(_on_enemy_killed):
			enemy.killed.connect(_on_enemy_killed)
	if enemy.has_signal("hit_player"):
		if not enemy.hit_player.is_connected(_on_enemy_hit_player):
			enemy.hit_player.connect(_on_enemy_hit_player)

func _on_enemy_killed(points: int) -> void:
	EventBus.emit_enemy_kill(points, Vector2.ZERO, "enemy")
	EventBus.emit_audio("enemy_death")

func _on_enemy_hit_player() -> void:
	EventBus.player_hit.emit()
	EventBus.emit_audio("player_hit")

# Boss Spawning
func spawn_boss(boss_scene: PackedScene, spawn_position: Vector2, properties: Dictionary = {}) -> Node:
	var boss = boss_scene.instantiate()
	boss.global_position = spawn_position
	
	# Apply properties
	for key in properties:
		if boss.has_method("set") or boss.get(key) != null:
			boss.set(key, properties[key])
	
	var container = enemies_container if enemies_container else game_viewport
	container.call_deferred("add_child", boss)
	
	_connect_boss_signals(boss)
	EventBus.entity_spawned.emit(boss, "boss")
	EventBus.boss_spawned.emit(boss, properties.get("boss_name", "boss"))
	return boss

func _connect_boss_signals(boss: Node) -> void:
	if boss.has_signal("defeated"):
		if not boss.defeated.is_connected(_on_boss_defeated):
			boss.defeated.connect(_on_boss_defeated)
	if boss.has_signal("hit_player"):
		if not boss.hit_player.is_connected(_on_boss_hit_player):
			boss.hit_player.connect(_on_boss_hit_player)

func _on_boss_defeated() -> void:
	EventBus.emit_boss_defeat("boss", 10000)
	EventBus.emit_audio("enemy_death")

func _on_boss_hit_player() -> void:
	EventBus.player_hit.emit()
	EventBus.emit_audio("player_hit")

# Cleanup
func destroy_entity(entity: Node) -> void:
	if not entity or not is_instance_valid(entity):
		return
	if entity.get_meta("pooled", false):
		entity.visible = false
		# Safely detach from parent so pooled objects are eligible for reuse
		var parent := entity.get_parent()
		if parent and is_instance_valid(parent):
			parent.remove_child(entity)
		# Return to the appropriate pool if below max size
		var kind := String(entity.get_meta("pool_kind", ""))
		if kind == "player":
			if bullet_pool.size() < max_pool_size:
				bullet_pool.append(entity)
		elif kind == "enemy":
			if enemy_bullet_pool.size() < max_pool_size:
				enemy_bullet_pool.append(entity)
		# Leave instance alive (not freed) so pooling can reuse it
	else:
		entity.queue_free()
	
	EventBus.entity_destroyed.emit(entity, "entity")

func cleanup_all_entities() -> void:
	# Clean up all bullets
	var all_bullets = get_tree().get_nodes_in_group("player_bullet") + get_tree().get_nodes_in_group("enemy_bullet")
	for bullet in all_bullets:
		if bullet and is_instance_valid(bullet):
			_disconnect_bullet_signals(bullet)
			destroy_entity(bullet)
	
	# Clean up all enemies
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy):
			_disconnect_enemy_signals(enemy)
			destroy_entity(enemy)
	
	# Clean up pools
	_cleanup_pools()

func _disconnect_bullet_signals(bullet: Node) -> void:
	"""Disconnect bullet signals to prevent memory leaks"""
	if not bullet or not is_instance_valid(bullet):
		return
	
	if bullet.has_signal("area_entered") and bullet.area_entered.is_connected(_on_player_bullet_hit):
		bullet.area_entered.disconnect(_on_player_bullet_hit)
	
	if bullet.has_signal("hit_player") and bullet.hit_player.is_connected(_on_enemy_bullet_hit_player):
		bullet.hit_player.disconnect(_on_enemy_bullet_hit_player)

func _disconnect_enemy_signals(enemy: Node) -> void:
	"""Disconnect enemy signals to prevent memory leaks"""
	if not enemy or not is_instance_valid(enemy):
		return
	
	if enemy.has_signal("killed") and enemy.killed.is_connected(_on_enemy_killed):
		enemy.killed.disconnect(_on_enemy_killed)
	
	if enemy.has_signal("hit_player") and enemy.hit_player.is_connected(_on_enemy_hit_player):
		enemy.hit_player.disconnect(_on_enemy_hit_player)

func _cleanup_pools() -> void:
	"""Clean up object pools"""
	# Clean up bullet pools
	for bullet in bullet_pool:
		if bullet and is_instance_valid(bullet):
			_disconnect_bullet_signals(bullet)
			bullet.queue_free()
	bullet_pool.clear()
	
	for bullet in enemy_bullet_pool:
		if bullet and is_instance_valid(bullet):
			_disconnect_bullet_signals(bullet)
			bullet.queue_free()
	enemy_bullet_pool.clear()
