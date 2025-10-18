extends Node

# RankPressureSystem - Handles visual and audio pressure based on rank
# Extracted from Main.gd to separate rank pressure concerns

var space_background: Node
var base_background_color: Color = Color.WHITE
var bgm_player: AudioStreamPlayer

func _ready() -> void:
	# Connect to EventBus for rank changes
	EventBus.rank_changed.connect(_on_rank_changed)
	EventBus.game_started.connect(_on_game_started)
	
	# Setup background reference
	_setup_background_reference()

func _setup_background_reference() -> void:
	# Find space background in the scene
	var game_viewport = get_tree().current_scene.get_node_or_null("GameViewport")
	if game_viewport:
		space_background = game_viewport.get_node_or_null("SpaceBackground")
	
	# Store base background color
	if space_background:
		base_background_color = space_background.modulate
		print("[RankPressureSystem] Background reference found")
	else:
		print("[RankPressureSystem] No background found, using default color")

func _process(delta: float) -> void:
	if not GameState.is_game_active():
		return
	
	_apply_rank_pressure(delta)

func _apply_rank_pressure(delta: float) -> void:
	"""Apply visual and audio pressure based on rank"""
	if not RankManager or not RankManager.has_method("get_multiplier"):
		return
	
	# Calculate danger level (0.0 to 1.0)
	var min_rank: float = RankManager.min_rank
	var max_rank: float = RankManager.max_rank
	var current_rank: float = RankManager.rank
	var danger_level: float = clamp((current_rank - min_rank) / (max_rank - min_rank), 0.0, 1.0)
	
	# Visual pressure - background color modulation
	_apply_background_pressure(danger_level, delta)
	
	# Visual pressure - subtle continuous shake at high rank
	_apply_continuous_shake(danger_level)
	
	# Audio pressure - music pitch increases with danger
	_apply_audio_pressure(danger_level)

func _apply_background_pressure(danger_level: float, delta: float) -> void:
	"""Apply background color pressure based on danger level"""
	if not space_background:
		return
	
	if danger_level > 0.7:
		var pressure_color = Color(1.2, 0.9, 0.9)  # Reddish tint
		space_background.modulate = base_background_color.lerp(pressure_color, (danger_level - 0.7) / 0.3)
	else:
		# Smoothly return to base color when danger is low
		space_background.modulate = space_background.modulate.lerp(base_background_color, delta * 2.0)

func _apply_continuous_shake(danger_level: float) -> void:
	"""Apply continuous screen shake at high danger levels"""
	if danger_level > 0.7:
		var shake_intensity = 2.0 * ((danger_level - 0.7) / 0.3)
		EventBus.emit_visual_effect("screen_shake", {
			"intensity": shake_intensity,
			"duration": 0.1
		})

func _apply_audio_pressure(danger_level: float) -> void:
	"""Apply audio pressure through music pitch"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_music_pitch"):
		var target_pitch = lerp(1.0, 1.15, danger_level)
		audio_manager.set_music_pitch(target_pitch)

func _on_rank_changed(new_rank: float) -> void:
	"""Handle rank changes with immediate visual feedback"""
	# Create a brief flash when rank changes significantly
	if new_rank > 2.0:  # High rank threshold
		EventBus.emit_visual_effect("flash", {
			"color": Color(1.0, 0.8, 0.2, 0.3),  # Orange flash
			"duration": 0.2
		})

func _on_game_started() -> void:
	"""Reset rank pressure when game starts"""
	# Reset background to base color
	if space_background:
		space_background.modulate = base_background_color
	
	# Reset audio pitch
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_music_pitch"):
		audio_manager.set_music_pitch(1.0)

# Utility methods for external systems
func get_danger_level() -> float:
	"""Get current danger level (0.0 to 1.0)"""
	if not RankManager or not RankManager.has_method("get_multiplier"):
		return 0.0
	
	var min_rank: float = RankManager.min_rank
	var max_rank: float = RankManager.max_rank
	var current_rank: float = RankManager.rank
	return clamp((current_rank - min_rank) / (max_rank - min_rank), 0.0, 1.0)

func is_high_danger() -> bool:
	"""Check if we're in high danger state"""
	return get_danger_level() > 0.7

func get_pressure_color() -> Color:
	"""Get the current pressure color for background"""
	var danger_level = get_danger_level()
	if danger_level > 0.7:
		var pressure_color = Color(1.2, 0.9, 0.9)
		return base_background_color.lerp(pressure_color, (danger_level - 0.7) / 0.3)
	return base_background_color
