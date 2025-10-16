extends GameMode
class_name BossRushMode

# BossRushMode - Boss-only mode
# Fight all bosses in sequence

@export var boss_order: Array[String] = ["gliath", "type0", "iron_casket"]
@export var boss_health_multiplier: float = 1.5
@export var boss_damage_multiplier: float = 1.2

var current_boss_index: int = 0
var bosses_defeated: int = 0

func _init() -> void:
	super._init()
	mode_name = "Boss Rush"
	mode_description = "Fight all bosses in sequence"
	is_endless = false
	has_bosses = true
	has_stages = false
	max_stage = boss_order.size()
	starting_lives = 5  # More lives for boss rush
	starting_bombs = 5
	difficulty_scaling = 1.0
	score_multiplier = 2.0  # Double score for boss rush

func _setup_mode() -> void:
	"""Setup boss rush mode"""
	print("[BossRushMode] Setting up boss rush mode")
	print("[BossRushMode] Boss order: ", boss_order)
	
	# Set boss progression
	current_boss_index = 0
	bosses_defeated = 0
	
	# Apply boss rush settings
	_apply_boss_rush_settings()

func _apply_boss_rush_settings() -> void:
	"""Apply boss rush mode settings"""
	# Set rank manager to boss rush mode
	if RankManager and RankManager.has_method("set_mode"):
		RankManager.set_mode("boss_rush")
	
	# Set item drop rates for boss rush
	if ItemDropManager and ItemDropManager.has_method("set_mode"):
		ItemDropManager.set_mode("boss_rush")

func get_next_stage() -> int:
	"""Get the next boss stage"""
	print("[BossRushMode] get_next_stage called, current_boss_index: ", current_boss_index, " boss_order.size(): ", boss_order.size())
	
	if current_boss_index >= boss_order.size():
		# All bosses defeated
		print("[BossRushMode] All bosses defeated, completing mode")
		_complete_mode()
		return -1
	
	var boss_name = boss_order[current_boss_index]
	print("[BossRushMode] Next boss: ", boss_name)
	
	# Create boss encounter
	_create_boss_encounter(boss_name)
	
	current_boss_index += 1
	return current_boss_index

func _create_boss_encounter(boss_name: String) -> void:
	"""Create a boss encounter"""
	print("[BossRushMode] Creating boss encounter for: ", boss_name)
	
	# Create a simple test boss first to make sure spawning works
	var test_boss = _create_simple_test_boss()
	if test_boss:
		# Use call_deferred to ensure we're in the scene tree
		call_deferred("_add_boss_to_scene", test_boss)
		print("[BossRushMode] Test boss created and will be added")
		return
	
	# Try direct scene loading
	var boss_scene_path = _get_boss_scene_path(boss_name)
	print("[BossRushMode] Loading boss scene: ", boss_scene_path)
	
	var boss_scene = load(boss_scene_path)
	if not boss_scene:
		push_error("[BossRushMode] Boss scene not found: " + boss_scene_path)
		return
	
	var boss = boss_scene.instantiate()
	if not boss:
		push_error("[BossRushMode] Failed to instantiate boss scene")
		return
	
	print("[BossRushMode] Boss instantiated: ", boss)
	boss.global_position = Vector2(160, -50)
	
	# Apply boss rush modifiers
	_apply_boss_modifiers(boss)
	
	# Connect boss signals
	_connect_boss_signals(boss)
	
	# Add boss to scene - use call_deferred to ensure tree is ready
	call_deferred("_add_boss_to_scene", boss)
	
	# Emit boss spawned event
	EventBus.boss_spawned.emit(boss, boss_name)

func _create_simple_test_boss() -> Node:
	"""Create a simple test boss to verify spawning works"""
	print("[BossRushMode] Creating simple test boss")
	
	var boss = Area2D.new()
	boss.name = "TestBoss"
	boss.add_to_group("enemy")
	boss.add_to_group("boss")
	
	# Add required boss properties for health bar using the method below
	boss.set("hp", 100)
	boss.set("max_hp", 100)
	boss.set("current_phase", 1)
	boss.set("phases_total", 1)
	boss.set("points", 10000)
	boss.set("boss_name", "TestBoss")
	
	# Create a simple colored rectangle as a test
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(64, 64)
	color_rect.color = Color.RED
	color_rect.position = Vector2(-32, -32)  # Center it on the boss
	boss.add_child(color_rect)
	print("[BossRushMode] Added red color rect as boss sprite")
	
	# Add collision for player bullets
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	collision.shape = shape
	boss.add_child(collision)
	
	# Set collision layers and masks
	boss.collision_layer = 2  # Enemy layer
	boss.collision_mask = 1   # Player bullet layer
	
	# Add boss signals
	boss.add_user_signal("defeated")
	boss.add_user_signal("hit_player")
	boss.add_user_signal("killed", [TYPE_INT, TYPE_STRING])
	
	# Add boss behavior script
	var boss_script = GDScript.new()
	boss_script.source_code = """
extends Area2D

var hp: int = 100
var max_hp: int = 100
var points: int = 10000
var boss_name: String = "TestBoss"

func _ready():
	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area):
	if area.is_in_group("player_bullet"):
		take_damage(10)
		area.queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		hit_player.emit()

func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		die()

func die():
	print("[TestBoss] Boss defeated!")
	killed.emit(points, "TestBoss")
	defeated.emit()
	queue_free()
"""
	boss.set_script(boss_script)
	
	boss.global_position = Vector2(160, 50)
	boss.visible = true
	
	print("[BossRushMode] Test boss created at position: ", boss.global_position)
	print("[BossRushMode] Test boss visible: ", boss.visible)
	return boss

func _get_boss_scene_path(boss_name: String) -> String:
	"""Get the boss scene path based on boss name"""
	var scene_mapping = {
		"gliath": "res://scenes/boss/gliath/Gliath.tscn",
		"type0": "res://scenes/boss/type0/Type0.tscn", 
		"iron_casket": "res://scenes/boss/ironcasket/IronCasket.tscn"
	}
	
	return scene_mapping.get(boss_name, "res://scenes/boss/gliath/Gliath.tscn")

func _add_boss_to_scene(boss: Node) -> void:
	"""Add boss to the scene tree safely"""
	if not boss or not is_instance_valid(boss):
		print("[BossRushMode] Boss is invalid, cannot add to scene")
		return
	
	# Check if we're in the scene tree
	if not is_inside_tree():
		push_error("[BossRushMode] BossRushMode not in scene tree")
		return
	
	# Try to get the current scene tree
	var tree = get_tree()
	if not tree:
		push_error("[BossRushMode] Cannot get scene tree")
		return
	
	var current_scene = tree.current_scene
	if not current_scene:
		push_error("[BossRushMode] No current scene")
		return
	
	print("[BossRushMode] Current scene: ", current_scene.name)
	print("[BossRushMode] Boss position before adding: ", boss.global_position)
	
	# Try to add to GameViewport/Enemies first, fallback to current scene
	var container = current_scene.get_node_or_null("GameViewport/Enemies")
	if container and is_instance_valid(container):
		container.add_child(boss)
		print("[BossRushMode] Added boss to GameViewport/Enemies at position: ", boss.global_position)
	else:
		current_scene.add_child(boss)
		print("[BossRushMode] Added boss to current scene at position: ", boss.global_position)
	
	# Make sure boss is visible and positioned correctly
	boss.visible = true
	boss.global_position = Vector2(160, 50)  # Move boss to visible area
	print("[BossRushMode] Boss visible: ", boss.visible)
	print("[BossRushMode] Boss position: ", boss.global_position)
	print("[BossRushMode] Boss groups: ", boss.get_groups())
	
	# Force update the boss position
	boss.position = Vector2(160, 50)
	print("[BossRushMode] Boss final position: ", boss.global_position)

func _apply_boss_modifiers(boss: Node) -> void:
	"""Apply boss rush modifiers to boss"""
	# Increase boss health
	if boss.has_method("set"):
		var current_hp = boss.get("hp")
		if current_hp == null:
			current_hp = 1  # Default fallback
		var new_hp = int(current_hp * boss_health_multiplier)
		boss.set("hp", new_hp)
		boss.set("max_hp", new_hp)
	
	# Increase boss damage
	if boss.has_method("set_damage_multiplier"):
		boss.set_damage_multiplier(boss_damage_multiplier)

func _connect_boss_signals(boss: Node) -> void:
	"""Connect boss signals"""
	if boss.has_signal("defeated"):
		boss.connect("defeated", Callable(self, "_on_boss_defeated").bind(boss))
	elif boss.has_signal("killed"):
		boss.connect("killed", Callable(self, "_on_boss_defeated").bind(boss))
	if boss.has_signal("hit_player"):
		boss.connect("hit_player", Callable(self, "_on_boss_hit_player"))

func _on_boss_defeated(boss: Node) -> void:
	"""Handle boss defeat"""
	bosses_defeated += 1
	print("[BossRushMode] Boss defeated! Total: ", bosses_defeated)
	
	# Drop bomb when boss is defeated
	_drop_bomb_on_boss_defeat(boss)
	
	# Emit boss defeated event with validation
	var name_val = boss.get("boss_name") if boss and boss.has_method("get") else null
	var fallback_name = boss_order[max(0, current_boss_index - 1)] if boss_order.size() > 0 else "boss"
	var boss_name: String = name_val if (name_val is String and name_val != "") else fallback_name
	var pts_val = boss.get("points") if boss and boss.has_method("get") else null
	var points: int = int(pts_val) if (typeof(pts_val) == TYPE_INT or typeof(pts_val) == TYPE_FLOAT) else 10000
	EventBus.boss_defeated.emit(boss_name, points)
	
	# Move to next boss after delay
	await get_tree().create_timer(3.0).timeout
	get_next_stage()

func _on_boss_hit_player() -> void:
	"""Handle boss hitting player"""
	EventBus.player_hit.emit()

func _drop_bomb_on_boss_defeat(boss: Node) -> void:
	"""Drop a bomb when a boss is defeated"""
	if not boss or not is_instance_valid(boss):
		return
	
	# Get boss position for bomb drop
	var boss_position = boss.global_position
	
	# Get ItemDropManager and force drop a bomb
	var item_drop_manager = get_node_or_null("/root/ItemDropManager")
	if item_drop_manager and item_drop_manager.has_method("force_drop_item"):
		# Use the BOMB item type from ItemDropManager
		var bomb_type = item_drop_manager.ItemType.BOMB
		item_drop_manager.force_drop_item(bomb_type, boss_position)
		print("[BossRushMode] Dropped bomb at boss position: ", boss_position)
	else:
		# Fallback: emit item collected signal directly
		EventBus.item_collected.emit("BOMB", 0)
		print("[BossRushMode] Fallback: Emitted bomb collection event")

func get_boss_rush_info() -> Dictionary:
	"""Get boss rush information"""
	return {
		"current_boss": boss_order[current_boss_index] if current_boss_index < boss_order.size() else "",
		"bosses_defeated": bosses_defeated,
		"total_bosses": boss_order.size(),
		"progress_percent": float(bosses_defeated) / float(boss_order.size()) * 100.0
	}

func get_boss_list() -> Array[String]:
	"""Get the list of bosses in order"""
	return boss_order.duplicate()
