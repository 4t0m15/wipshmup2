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
	if current_boss_index >= boss_order.size():
		# All bosses defeated
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
	# Create boss
	var boss = BossTemplateManager.create_boss(boss_name, Vector2(160, -50))
	if boss:
		# Apply boss rush modifiers
		_apply_boss_modifiers(boss)
		
		# Connect boss signals
		_connect_boss_signals(boss)
		
		# Add boss to scene
		var container = get_tree().current_scene.get_node_or_null("GameViewport/Enemies")
		if container:
			container.add_child(boss)
		else:
			get_tree().current_scene.add_child(boss)
		
		# Emit boss spawned event
		EventBus.boss_spawned.emit(boss, boss_name)

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
		boss.defeated.connect(_on_boss_defeated)
	if boss.has_signal("hit_player"):
		boss.hit_player.connect(_on_boss_hit_player)

func _on_boss_defeated() -> void:
	"""Handle boss defeat"""
	bosses_defeated += 1
	print("[BossRushMode] Boss defeated! Total: ", bosses_defeated)
	
	# Emit boss defeated event
	EventBus.boss_defeated.emit()
	
	# Move to next boss after delay
	await get_tree().create_timer(3.0).timeout
	get_next_stage()

func _on_boss_hit_player() -> void:
	"""Handle boss hitting player"""
	EventBus.player_hit.emit()

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
