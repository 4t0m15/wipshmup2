extends Node
class_name StageController

# StageController - Data-driven stage controller
# Uses stage definitions instead of hardcoded logic

signal enemy_killed(points: int, position: Vector2)
signal stage_completed(stage_number: int)
signal boss_defeated()
signal enemy_spawned(enemy: Area2D)

var current_stage: StageDefinition
var current_wave: WaveDefinition
var current_wave_index: int = 0
var current_stage_index: int = 0

# Stage progression
var stage_order: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
var is_stage_active: bool = false
var is_boss_active: bool = false

# Wave management
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var current_spawn_index: int = 0

func _ready() -> void:
	add_to_group("stage_controller")
	print("[StageController] Initialized")

func start_run() -> void:
	"""Start the stage progression"""
	print("[StageController] Starting stage run")
	current_stage_index = 0
	_start_current_stage()

func _start_current_stage() -> void:
	"""Start the current stage"""
	if current_stage_index >= stage_order.size():
		# Loop back to stage 1
		current_stage_index = 0
	
	var stage_number = stage_order[current_stage_index]
	current_stage = StageTemplateManager.get_stage_by_number(stage_number)
	
	if not current_stage:
		push_error("Stage not found: " + str(stage_number))
		return
	
	print("[StageController] Starting stage: ", current_stage.stage_name)
	
	# Apply stage effects
	current_stage.apply_stage_effects()
	
	# Reset stage state
	is_stage_active = true
	is_boss_active = false
	current_wave_index = 0
	wave_timer = 0.0
	spawn_timer = 0.0
	current_spawn_index = 0
	
	# Start first wave
	_start_current_wave()
	
	# Emit stage started event
	EventBus.stage_started.emit(stage_number)

func _start_current_wave() -> void:
	"""Start the current wave"""
	if not current_stage or current_wave_index >= current_stage.get_wave_count():
		# All waves complete, start boss if available
		print("[StageController] All waves complete, checking for boss")
		_start_boss_encounter()
		return
	
	current_wave = current_stage.get_wave(current_wave_index)
	if not current_wave:
		push_error("Wave not found at index: " + str(current_wave_index))
		return
	
	print("[StageController] Starting wave: ", current_wave.wave_name, " with ", current_wave.get_spawn_count(), " spawns")
	
	# Reset wave state
	spawn_timer = 0.0
	current_spawn_index = 0
	
	# Emit wave started event
	EventBus.wave_started.emit(current_wave_index)

func _start_boss_encounter() -> void:
	"""Start the boss encounter"""
	if not current_stage or not current_stage.has_boss():
		# No boss, complete stage
		_complete_stage()
		return
	
	var boss_encounter = current_stage.boss_encounter
	print("[StageController] Starting boss: ", boss_encounter.boss_name)
	
	# Apply boss intro effects
	boss_encounter.apply_intro_effects()
	
	# Spawn boss after delay
	await get_tree().create_timer(current_stage.boss_delay).timeout
	
	# Create boss
	var boss = BossTemplateManager.create_boss(
		boss_encounter.get_boss_template_name(),
		boss_encounter.get_spawn_position()
	)
	
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
		EventBus.boss_spawned.emit(boss, boss_encounter.boss_name)
		is_boss_active = true

func _connect_boss_signals(boss: Node) -> void:
	"""Connect boss signals"""
	if boss.has_signal("defeated"):
		boss.defeated.connect(_on_boss_defeated)
	if boss.has_signal("hit_player"):
		boss.hit_player.connect(_on_boss_hit_player)

func _on_boss_defeated() -> void:
	"""Handle boss defeat"""
	print("[StageController] Boss defeated")
	
	# Apply boss outro effects
	if current_stage and current_stage.boss_encounter:
		current_stage.boss_encounter.apply_outro_effects()
	
	# Emit boss defeated event
	EventBus.boss_defeated.emit()
	boss_defeated.emit()
	
	# Complete stage after delay
	await get_tree().create_timer(2.0).timeout
	_complete_stage()

func _on_boss_hit_player() -> void:
	"""Handle boss hitting player"""
	EventBus.player_hit.emit()

func _complete_stage() -> void:
	"""Complete the current stage"""
	print("[StageController] Stage completed: ", current_stage.stage_name)
	
	# Emit stage completed event
	EventBus.stage_completed.emit(current_stage.stage_number)
	stage_completed.emit(current_stage.stage_number)
	
	# Move to next stage
	current_stage_index += 1
	_start_current_stage()

func _process(delta: float) -> void:
	"""Update stage progression"""
	if not is_stage_active or is_boss_active:
		return
	
	# Update wave timer
	wave_timer += delta
	
	# Check if we need to spawn enemies
	if current_wave and current_spawn_index < current_wave.get_spawn_count():
		spawn_timer += delta
		
		if spawn_timer >= current_wave.spawn_interval:
			_spawn_next_enemy()
			spawn_timer = 0.0
	
	# Check if wave is complete
	if current_wave and current_spawn_index >= current_wave.get_spawn_count():
		# Check if wave duration is complete (or if no duration limit)
		if current_wave.wave_duration < 0.0 or wave_timer >= current_wave.wave_duration:
			# Wait a bit before starting next wave
			if wave_timer < 2.0:
				return
			_complete_current_wave()

func _spawn_next_enemy() -> void:
	"""Spawn the next enemy in the current wave"""
	if not current_wave or current_spawn_index >= current_wave.get_spawn_count():
		return
	
	var spawn = current_wave.get_spawn(current_spawn_index)
	var enemy_type = spawn.get("enemy_type", "basic_fighter")
	var position = spawn.get("position", Vector2(160, -50))
	var delay = spawn.get("delay", 0.0)
	var properties = spawn.get("properties", {})
	
	# Increment BEFORE async operations to prevent double-spawning
	current_spawn_index += 1
	
	print("[StageController] Spawning enemy: ", enemy_type, " at ", position)
	
	# Wait for delay if needed
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	
	# Create enemy
	var enemy = EnemyTemplateManager.create_enemy(enemy_type, position)
	if enemy:
		print("[StageController] Enemy created successfully: ", enemy.name)
		
		# Apply properties
		for key in properties:
			if enemy.has_method("set") or enemy.get(key) != null:
				enemy.set(key, properties[key])
		
		# Add to scene
		var container = get_tree().current_scene.get_node_or_null("GameViewport/Enemies")
		if container:
			container.add_child(enemy)
			print("[StageController] Enemy added to GameViewport/Enemies")
		else:
			get_tree().current_scene.add_child(enemy)
			print("[StageController] Enemy added to current_scene")
		
		# Connect enemy signals
		_connect_enemy_signals(enemy)
		
		# Emit enemy spawned event
		EventBus.enemy_spawned.emit(enemy, enemy_type)
		enemy_spawned.emit(enemy)
	else:
		push_error("[StageController] Failed to create enemy: " + enemy_type)

func _connect_enemy_signals(enemy: Node) -> void:
	"""Connect enemy signals"""
	if enemy.has_signal("killed"):
		enemy.killed.connect(_on_enemy_killed)
	if enemy.has_signal("hit_player"):
		enemy.hit_player.connect(_on_enemy_hit_player)

func _on_enemy_killed(points: int) -> void:
	"""Handle enemy killed"""
	EventBus.emit_enemy_kill(points, Vector2.ZERO, "enemy")
	enemy_killed.emit(points, Vector2.ZERO)

func _on_enemy_hit_player() -> void:
	"""Handle enemy hitting player"""
	EventBus.player_hit.emit()

func _complete_current_wave() -> void:
	"""Complete the current wave"""
	print("[StageController] Wave completed: ", current_wave.wave_name)
	
	# Move to next wave
	current_wave_index += 1
	_start_current_wave()

# Public API
func get_current_stage() -> StageDefinition:
	"""Get the current stage definition"""
	return current_stage

func get_current_wave() -> WaveDefinition:
	"""Get the current wave definition"""
	return current_wave

func is_stage_running() -> bool:
	"""Check if a stage is currently running"""
	return is_stage_active

func is_boss_fighting() -> bool:
	"""Check if a boss is currently active"""
	return is_boss_active

func get_stage_progress() -> float:
	"""Get stage progress (0.0 to 1.0)"""
	if not current_stage:
		return 0.0
	
	var total_waves = current_stage.get_wave_count()
	if total_waves == 0:
		return 1.0
	
	return float(current_wave_index) / float(total_waves)
