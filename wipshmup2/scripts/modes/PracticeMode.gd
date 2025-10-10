extends GameMode
class_name PracticeMode

# PracticeMode - Practice specific stages or bosses
# Allows selection of specific content to practice

@export var practice_type: String = "stage"  # "stage" or "boss"
@export var practice_target: String = "1"  # Stage number or boss name
@export var infinite_lives: bool = false
@export var infinite_bombs: bool = false
@export var slow_motion: bool = false

var practice_stage: StageDefinition
var practice_boss: String

func _init() -> void:
	super._init()
	mode_name = "Practice"
	mode_description = "Practice specific stages or bosses"
	is_endless = false
	has_bosses = true
	has_stages = true
	max_stage = 1
	starting_lives = 999 if infinite_lives else 3
	starting_bombs = 999 if infinite_bombs else 3
	difficulty_scaling = 0.8  # Easier for practice
	score_multiplier = 0.5  # Lower score for practice

func _setup_mode() -> void:
	"""Setup practice mode"""
	print("[PracticeMode] Setting up practice mode")
	
	# Set practice target
	if practice_type == "stage":
		_setup_stage_practice()
	elif practice_type == "boss":
		_setup_boss_practice()
	
	# Apply practice settings
	_apply_practice_settings()

func _setup_stage_practice() -> void:
	"""Setup stage practice"""
	var stage_number = int(practice_target)
	practice_stage = StageTemplateManager.get_stage_by_number(stage_number)
	
	if not practice_stage:
		push_error("Practice stage not found: " + practice_target)
		return
	
	print("[PracticeMode] Practicing stage: ", practice_stage.stage_name)

func _setup_boss_practice() -> void:
	"""Setup boss practice"""
	practice_boss = practice_target
	
	if not BossTemplateManager.has_template(practice_boss):
		push_error("Practice boss not found: " + practice_target)
		return
	
	print("[PracticeMode] Practicing boss: ", practice_boss)

func _apply_practice_settings() -> void:
	"""Apply practice mode settings"""
	# Set rank manager to practice mode
	if RankManager and RankManager.has_method("set_mode"):
		RankManager.set_mode("practice")
	
	# Set item drop rates for practice
	if ItemDropManager and ItemDropManager.has_method("set_mode"):
		ItemDropManager.set_mode("practice")
	
	# Apply slow motion if enabled
	if slow_motion:
		Engine.time_scale = 0.5
	else:
		Engine.time_scale = 1.0

func get_next_stage() -> int:
	"""Get the next stage for practice"""
	if practice_type == "stage":
		return int(practice_target)
	elif practice_type == "boss":
		# Create boss encounter
		_create_boss_encounter()
		return 1
	
	return -1

func _create_boss_encounter() -> void:
	"""Create boss encounter for practice"""
	var boss = BossTemplateManager.create_boss(practice_boss, Vector2(160, -50))
	if boss:
		# Connect boss signals
		_connect_boss_signals(boss)
		
		# Add boss to scene
		var container = get_tree().current_scene.get_node_or_null("GameViewport/Enemies")
		if container:
			container.add_child(boss)
		else:
			get_tree().current_scene.add_child(boss)
		
		# Emit boss spawned event
		EventBus.boss_spawned.emit(boss, practice_boss)

func _connect_boss_signals(boss: Node) -> void:
	"""Connect boss signals"""
	if boss.has_signal("defeated"):
		boss.defeated.connect(_on_boss_defeated)
	if boss.has_signal("hit_player"):
		boss.hit_player.connect(_on_boss_hit_player)

func _on_boss_defeated() -> void:
	"""Handle boss defeat in practice"""
	print("[PracticeMode] Boss defeated in practice")
	
	# Emit boss defeated event
	EventBus.boss_defeated.emit()
	
	# Restart boss after delay
	await get_tree().create_timer(3.0).timeout
	_create_boss_encounter()

func _on_boss_hit_player() -> void:
	"""Handle boss hitting player in practice"""
	EventBus.player_hit.emit()

func get_practice_info() -> Dictionary:
	"""Get practice mode information"""
	return {
		"practice_type": practice_type,
		"practice_target": practice_target,
		"infinite_lives": infinite_lives,
		"infinite_bombs": infinite_bombs,
		"slow_motion": slow_motion,
		"time_scale": Engine.time_scale
	}

func set_practice_target(target_type: String, target: String) -> void:
	"""Set the practice target"""
	practice_type = target_type
	practice_target = target
	
	# Re-setup mode
	_setup_mode()

func toggle_slow_motion() -> void:
	"""Toggle slow motion mode"""
	slow_motion = not slow_motion
	_apply_practice_settings()

func toggle_infinite_lives() -> void:
	"""Toggle infinite lives"""
	infinite_lives = not infinite_lives
	GameState.lives = 999 if infinite_lives else 3

func toggle_infinite_bombs() -> void:
	"""Toggle infinite bombs"""
	infinite_bombs = not infinite_bombs
	GameState.bombs = 999 if infinite_bombs else 3
