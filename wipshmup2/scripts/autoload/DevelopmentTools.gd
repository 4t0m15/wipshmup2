extends Node

# DevelopmentTools - Enhanced development and debugging tools
# Provides hot reloading, debug overlays, and development aids

signal hot_reload_completed(resource_path: String)
signal debug_toggle_changed(enabled: bool)
# signal performance_data_updated(metrics: Dictionary)  # Reserved for future use

# Development state
var debug_mode: bool = false
var performance_monitoring: bool = false
var hot_reload_enabled: bool = false
var auto_save_enabled: bool = false

# Debug overlays
var debug_overlay: Control = null
var performance_overlay: Control = null
var fps_label: Label = null
var memory_label: Label = null
var bullet_count_label: Label = null
var stability_label: Label = null

# Hot reload system
var watched_resources: Array[String] = []
var resource_timestamps: Dictionary = {}
var reload_timer: Timer = null

# Auto-save system
var auto_save_timer: Timer = null
var auto_save_interval: float = 30.0  # seconds

func _ready() -> void:
	print("[DevelopmentTools] Development tools initialized")
	_setup_hot_reload()
	_setup_auto_save()
	_create_debug_overlays()
	_connect_events()

func _setup_hot_reload() -> void:
	"""Setup hot reload system"""
	reload_timer = Timer.new()
	reload_timer.wait_time = 1.0  # Check every second
	reload_timer.timeout.connect(_check_resource_changes)
	add_child(reload_timer)
	
	# Watch common resource types
	_watch_resource_directory("res://scripts/")
	_watch_resource_directory("res://scenes/")
	_watch_resource_directory("res://shaders/")
	_watch_resource_directory("res://config/")

func _setup_auto_save() -> void:
	"""Setup auto-save system"""
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(_auto_save_game_state)
	add_child(auto_save_timer)

func _create_debug_overlays() -> void:
	"""Create debug overlays"""
	_create_debug_overlay()
	_create_performance_overlay()

func _create_debug_overlay() -> void:
	"""Create debug information overlay"""
	debug_overlay = Control.new()
	debug_overlay.name = "DebugOverlay"
	debug_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	debug_overlay.z_index = 1000
	debug_overlay.visible = false
	
	# Create debug panel
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(300, 200)
	panel.position = Vector2(10, 10)
	
	# Create VBox for debug info
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Debug labels
	fps_label = Label.new()
	fps_label.text = "FPS: --"
	vbox.add_child(fps_label)
	
	memory_label = Label.new()
	memory_label.text = "Memory: --"
	vbox.add_child(memory_label)
	
	bullet_count_label = Label.new()
	bullet_count_label.text = "Bullets: --"
	vbox.add_child(bullet_count_label)
	
	stability_label = Label.new()
	stability_label.text = "Stability: --"
	vbox.add_child(stability_label)
	
	debug_overlay.add_child(panel)
	get_tree().current_scene.add_child(debug_overlay)

func _create_performance_overlay() -> void:
	"""Create performance monitoring overlay"""
	performance_overlay = Control.new()
	performance_overlay.name = "PerformanceOverlay"
	performance_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	performance_overlay.z_index = 999
	performance_overlay.visible = false
	
	# Create performance panel
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.size = Vector2(250, 150)
	panel.position = Vector2(-260, 10)
	
	# Create VBox for performance info
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Performance labels
	var perf_label = Label.new()
	perf_label.text = "Performance Metrics"
	perf_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(perf_label)
	
	var frame_time_label = Label.new()
	frame_time_label.text = "Frame Time: --"
	vbox.add_child(frame_time_label)
	
	var draw_calls_label = Label.new()
	draw_calls_label.text = "Draw Calls: --"
	vbox.add_child(draw_calls_label)
	
	var physics_time_label = Label.new()
	physics_time_label.text = "Physics Time: --"
	vbox.add_child(physics_time_label)
	
	performance_overlay.add_child(panel)
	get_tree().current_scene.add_child(performance_overlay)

func _connect_events() -> void:
	"""Connect to game events"""
	if EventBus:
		EventBus.game_started.connect(_on_game_started)
		EventBus.game_over.connect(_on_game_over)
		EventBus.stage_started.connect(_on_stage_started)

func _watch_resource_directory(path: String) -> void:
	"""Watch a directory for changes"""
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with("."):
				var full_path = path + file_name
				if dir.current_is_dir():
					_watch_resource_directory(full_path + "/")
				else:
					watched_resources.append(full_path)
					resource_timestamps[full_path] = FileAccess.get_modified_time(full_path)
			file_name = dir.get_next()

func _check_resource_changes() -> void:
	"""Check for resource changes"""
	if not hot_reload_enabled:
		return
	
	for resource_path in watched_resources:
		var current_time = FileAccess.get_modified_time(resource_path)
		var last_time = resource_timestamps.get(resource_path, 0)
		
		if current_time > last_time:
			_reload_resource(resource_path)
			resource_timestamps[resource_path] = current_time

func _reload_resource(resource_path: String) -> void:
	"""Reload a changed resource"""
	print("[DevelopmentTools] Hot reloading: ", resource_path)
	
	# Handle different resource types
	if resource_path.ends_with(".gd"):
		_reload_script(resource_path)
	elif resource_path.ends_with(".tscn"):
		_reload_scene(resource_path)
	elif resource_path.ends_with(".gdshader"):
		_reload_shader(resource_path)
	elif resource_path.ends_with(".json") or resource_path.ends_with(".cfg"):
		_reload_config(resource_path)
	
	hot_reload_completed.emit(resource_path)

func _reload_script(script_path: String) -> void:
	"""Reload a script"""
	# Scripts are automatically reloaded by Godot
	print("[DevelopmentTools] Script reloaded: ", script_path)

func _reload_scene(scene_path: String) -> void:
	"""Reload a scene"""
	# Scenes need manual reloading
	var scene = load(scene_path)
	if scene:
		print("[DevelopmentTools] Scene reloaded: ", scene_path)

func _reload_shader(shader_path: String) -> void:
	"""Reload a shader"""
	# Shaders are automatically reloaded by Godot
	print("[DevelopmentTools] Shader reloaded: ", shader_path)

func _reload_config(config_path: String) -> void:
	"""Reload a config file"""
	# Notify managers to reload configs
	if ConfigManager and ConfigManager.has_method("reload_config"):
		ConfigManager.reload_config(config_path)

func _auto_save_game_state() -> void:
	"""Auto-save game state"""
	if not auto_save_enabled:
		return
	
	# Save game state to file
	var save_data = {
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": _get_game_state_snapshot(),
		"player_state": _get_player_state_snapshot()
	}
	
	var save_file = FileAccess.open("user://auto_save.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("[DevelopmentTools] Auto-save completed")

func _get_game_state_snapshot() -> Dictionary:
	"""Get current game state snapshot"""
	if GameState:
		return {
			"lives": GameState.lives,
			"bombs": GameState.bombs,
			"score": GameState.score,
			"current_stage": GameState.current_stage,
			"current_wave": GameState.current_wave
		}
	return {}

func _get_player_state_snapshot() -> Dictionary:
	"""Get current player state snapshot"""
	if GameState:
		return {
			"position": GameState.player_position,
			"invincible": GameState.player_invincible
		}
	return {}

func _update_debug_overlay() -> void:
	"""Update debug overlay with current information"""
	if not debug_overlay or not debug_overlay.visible:
		return
	
	# Update FPS
	if fps_label:
		var fps = Engine.get_frames_per_second()
		fps_label.text = "FPS: " + str(fps)
	
	# Update memory
	if memory_label:
		var memory = float(OS.get_static_memory_usage()) / float(1024 * 1024)
		memory_label.text = "Memory: " + str(memory) + " MB"
	
	# Update bullet count
	if bullet_count_label:
		var bullets = get_tree().get_nodes_in_group("player_bullet") + get_tree().get_nodes_in_group("enemy_bullet")
		bullet_count_label.text = "Bullets: " + str(bullets.size())
	
	# Update stability
	if stability_label:
		var stability_score = 100.0
		var stability_manager = get_node_or_null("/root/StabilityManager")
		if stability_manager and stability_manager.has_method("get_performance_metrics"):
			var metrics = stability_manager.get_performance_metrics()
			stability_score = metrics.get("stability_score", 100.0)
		stability_label.text = "Stability: " + str(stability_score) + "%"

func _update_performance_overlay() -> void:
	"""Update performance overlay"""
	if not performance_overlay or not performance_overlay.visible:
		return
	
	# Update performance metrics
	var _metrics = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	# Additional performance data would be added here

func _process(_delta: float) -> void:
	"""Update development tools"""
	if debug_mode:
		_update_debug_overlay()
	
	if performance_monitoring:
		_update_performance_overlay()

# Public API
func toggle_debug_mode() -> void:
	"""Toggle debug mode"""
	debug_mode = !debug_mode
	debug_overlay.visible = debug_mode
	debug_toggle_changed.emit(debug_mode)
	print("[DevelopmentTools] Debug mode: ", debug_mode)

func toggle_performance_monitoring() -> void:
	"""Toggle performance monitoring"""
	performance_monitoring = !performance_monitoring
	performance_overlay.visible = performance_monitoring
	print("[DevelopmentTools] Performance monitoring: ", performance_monitoring)

func enable_hot_reload(enabled: bool) -> void:
	"""Enable/disable hot reload"""
	hot_reload_enabled = enabled
	if enabled:
		reload_timer.start()
	else:
		reload_timer.stop()
	print("[DevelopmentTools] Hot reload: ", enabled)

func enable_auto_save(enabled: bool) -> void:
	"""Enable/disable auto-save"""
	auto_save_enabled = enabled
	if enabled:
		auto_save_timer.start()
	else:
		auto_save_timer.stop()
	print("[DevelopmentTools] Auto-save: ", enabled)

func force_hot_reload() -> void:
	"""Force hot reload of all watched resources"""
	for resource_path in watched_resources:
		_reload_resource(resource_path)

func get_development_info() -> Dictionary:
	"""Get development information"""
	return {
		"debug_mode": debug_mode,
		"performance_monitoring": performance_monitoring,
		"hot_reload_enabled": hot_reload_enabled,
		"auto_save_enabled": auto_save_enabled,
		"watched_resources": watched_resources.size(),
		"resource_timestamps": resource_timestamps.size()
	}

func _on_game_started() -> void:
	"""Handle game started event"""
	if OS.is_debug_build():
		print("[DevelopmentTools] Game started - development tools active")

func _on_game_over() -> void:
	"""Handle game over event"""
	if OS.is_debug_build():
		print("[DevelopmentTools] Game over - development tools active")

func _on_stage_started(stage_number: int) -> void:
	"""Handle stage started event"""
	if OS.is_debug_build():
		print("[DevelopmentTools] Stage started: ", stage_number)

func _exit_tree() -> void:
	"""Cleanup on exit"""
	if reload_timer:
		reload_timer.queue_free()
	if auto_save_timer:
		auto_save_timer.queue_free()
	
	watched_resources.clear()
	resource_timestamps.clear()
