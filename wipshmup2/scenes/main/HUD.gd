extends CanvasLayer

var _accum_time_s: float = 0.0
var _frame_count: int = 0
var _rainbow_time: float = 0.0
var _streak_timer: float = 0.0
var _streak_timeout: float = 2.0
var _streak_active: bool = false
var _rainbow_streak_active: bool = false

@onready var _score_label: Label = $TopBar/HBox/ScoreLabel
@onready var _lives_label: Label = $TopBar/HBox/LivesLabel
@onready var _fps_label: Label = $TopBar/HBox/TPSLabel
@onready var _bombs_label: Label = $TopBar/HBox/BombsLabel
@onready var _streak_label: Label = $TopBar/HBox/StreakLabel
@onready var _shield_label: Label = $TopBar/HBox/ShieldLabel
@onready var _power_label: Label = $TopBar/HBox/PowerLabel
@onready var _loop_label: Label = $TopBar/HBox/LoopLabel
@onready var _streak_timer_bar: ProgressBar = $StreakTimer/ProgressBar
@onready var _overlay_dim: ColorRect = $CenterOverlay/OverlayDim
@onready var _msg_panel: PanelContainer = $CenterOverlay/MessagePanel
@onready var _msg_label: Label = $CenterOverlay/MessagePanel/VBox/MessageLabel
@onready var _hint_label: Label = $CenterOverlay/MessagePanel/VBox/HintLabel
@onready var _popup_container: VBoxContainer = $Popups
@onready var _shiba_label: Label = $ShibaLabel
@onready var _boss_health_bar: Control = null  # Will be created dynamically
@onready var _frametime_graph: Control = null

func _ready() -> void:
	# Ensure HUD is rendered crisp by disabling any filtering
	# Set the CanvasLayer to use pixel-perfect rendering
	var canvas_layer = get_node(".")
	if canvas_layer is CanvasLayer:
		canvas_layer.follow_viewport_enabled = false
		# Force pixel-perfect rendering
		canvas_layer.transform = Transform2D.IDENTITY
	
	# Initialize streak timer bar
	if is_instance_valid(_streak_timer_bar):
		_streak_timer_bar.visible = false
	
	# Create boss health bar dynamically
	_create_boss_health_bar()

	# Create frametime graph (bottom-right, long span)
	_create_frametime_graph()
	
	# Apply high-quality font settings
	_apply_high_quality_font_settings()
	
	# Connect core game state signals
	EventBus.lives_changed.connect(_on_lives_changed)
	EventBus.bombs_changed.connect(_on_bombs_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.streak_changed.connect(_on_streak_changed)
	EventBus.chain_broken.connect(_on_chain_broken)
	
	# Connect Cho Ren Sha 68K signals - 
	#i have to give this a new name bc im sick of typing it out and maybe i should just type out the kanji -- atleast i think it kanji or maybe its katakana i have no idea, and also who gives a shit?
	EventBus.shield_gained.connect(_on_shield_gained)
	EventBus.shield_lost.connect(_on_shield_lost)
	EventBus.weapon_power_changed.connect(_on_weapon_power_changed)
	EventBus.loop_incremented.connect(_on_loop_incremented)
	EventBus.life_extended.connect(_on_life_extended)
	 
	# Initialize all displays with current GameState values
	_update_all_displays()

func _create_frametime_graph() -> void:
	var GraphScript = load("res://scripts/ui/FrameTimeGraph.gd")
	if not GraphScript:
		push_error("[HUD] Failed to load FrameTimeGraph.gd")
		return
	
	if is_instance_valid(_frametime_graph):
		return
	
	var graph: Control = GraphScript.new()
	if not graph or not is_instance_valid(graph):
		push_error("[HUD] Failed to instantiate FrameTimeGraph")
		return
	
	# Configure: slightly longer, slim, subdued background
	graph.set("graph_width", 180)
	graph.set("graph_height", 14)
	graph.set("max_samples", 240)
	graph.set("background_color", Color(0.08, 0.04, 0.12, 0.75))
	
	add_child(graph)
	_frametime_graph = graph

	# Place directly under the streak timer with a safe gap and right margin
	var top_y: float = 18.0
	if is_instance_valid(_streak_timer_bar):
		var streak_container := _streak_timer_bar.get_parent()
		if is_instance_valid(streak_container) and streak_container is Control:
			top_y = float(streak_container.offset_bottom) + 6.0
	# Match streak bar width (TopBar has 4px margins, streak timer spans 320 - 8)
	var matched_width: int = 312
	if _frametime_graph.has_method("configure_layout_top_right"):
		_frametime_graph.configure_layout_top_right(matched_width, 14, top_y, 4)

func _process(delta: float) -> void:
	# Optimized rainbow effect - only update when needed
	_rainbow_time += delta * 3.0
	var rainbow_color = _get_rainbow_color(_rainbow_time)
	
	# Update shiba label with cached color
	if is_instance_valid(_shiba_label):
		_shiba_label.add_theme_color_override("font_color", rainbow_color)
	
	# Update streak label with cached color when active
	if _rainbow_streak_active and is_instance_valid(_streak_label):
		_streak_label.add_theme_color_override("font_color", rainbow_color)
	
	# Update streak timer with optimized color calculation
	if _streak_active and _streak_timer > 0.0:
		_streak_timer -= delta
		var progress = max(0.0, _streak_timer / _streak_timeout)
		_streak_timer_bar.value = progress
		
		# Optimized color calculation - cache colors
		var timer_color: Color
		if progress > 0.5:
			timer_color = Color(0.4, 1.0, 0.4, 1.0)  # Green
		elif progress > 0.25:
			timer_color = Color(1.0, 1.0, 0.4, 1.0)  # Yellow
		else:
			timer_color = Color(1.0, 0.4, 0.4, 1.0)  # Red
		
		_streak_timer_bar.modulate = timer_color
		
		if _streak_timer <= 0.0:
			_streak_active = false
			_streak_timer_bar.visible = false
	
	# Optimized FPS calculation - reduce string operations
	_accum_time_s += delta
	_frame_count += 1
	if _accum_time_s >= 1.0:
		var fps: int = int(round(float(_frame_count) / _accum_time_s))
		# Use string interpolation for better performance
		_fps_label.text = "FPS: " + str(fps).pad_zeros(3)
		_accum_time_s = 0.0
		_frame_count = 0

func _get_rainbow_color(time: float) -> Color:
	# Create rainbow effect using HSV color space
	var hue = fmod(time, 1.0)  # Cycle through hue from 0 to 1
	return Color.from_hsv(hue, 1.0, 1.0)  # Full saturation and value for vibrant colors

func set_score(value: int) -> void:
	_score_label.text = "Score: %d" % value
	
	# Add visual feedback for score milestones
	if value > 0 and value % 10000 == 0:
		_show_score_milestone(value)

func set_lives(value: int) -> void:
	var lives_text = ""
	for i in range(3):  # Show 3 heart slots
		if i < value:
			lives_text += "♥"  # Filled heart (better symbol)
		else:
			lives_text += "♡"  # Empty heart
	_lives_label.text = "Lives: %s" % lives_text
	
	# Add visual warning when low on lives
	if value <= 1:
		_lives_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))  # Red warning
		# Add pulsing effect for low lives
		var tween = create_tween()
		tween.tween_property(_lives_label, "modulate:a", 0.5, 0.3)
		tween.tween_property(_lives_label, "modulate:a", 1.0, 0.3)
		tween.set_loops()
	else:
		_lives_label.add_theme_color_override("font_color", Color(1, 0.4, 0.6, 1))  # Normal pink

func set_bombs(value: int) -> void:
	var text := "Bombs(X): %d" % max(0, value)
	_bombs_label.text = text
	
	# Add visual warning when low on bombs
	if value <= 1:
		_bombs_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))  # Orange warning
		# Add subtle pulsing for low bombs
		var tween = create_tween()
		tween.tween_property(_bombs_label, "modulate:a", 0.7, 0.4)
		tween.tween_property(_bombs_label, "modulate:a", 1.0, 0.4)
		tween.set_loops()
	else:
		_bombs_label.add_theme_color_override("font_color", Color(0.9, 1, 0.7, 1))  # Normal green

func set_chain(current_chain: int, max_chain: int) -> void:
	if current_chain > 0:
		_streak_label.text = "S: %d (B: %d)" % [current_chain, max_chain]
		# Add visual emphasis for longer streaks
		if current_chain >= 10:
			_rainbow_streak_active = true  # Enable rainbow effect for 10+ kill streaks!
		elif current_chain >= 5:
			_rainbow_streak_active = false
			_streak_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))  # Orange for medium streaks
		else:
			_rainbow_streak_active = false
			_streak_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4, 1.0))  # Default yellow-orange
		
		# Start/reset the streak timer
		_streak_timer = _streak_timeout
		_streak_active = true
		_streak_timer_bar.visible = true
		_streak_timer_bar.value = 1.0
		_streak_timer_bar.modulate = Color(0.4, 1.0, 0.4, 1.0)  # Start with green
	else:
		_streak_label.text = "S: 0 (B: %d)" % max_chain
		_rainbow_streak_active = false
		_streak_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))  # Gray when no streak
		# Hide the timer bar when no streak
		_streak_active = false
		_streak_timer_bar.visible = false

	# Frametime graph layout handled once in _create_frametime_graph()

func reset_streak_timer() -> void:
	# Called when streak is broken due to timeout or player getting hit
	_streak_active = false
	_streak_timer_bar.visible = false
	_rainbow_streak_active = false
	#this stops the streak only being reset by the player getting hit. Yes, this was actually a bug. god i suck.
func show_message(text: String) -> void:
	_msg_label.text = text
	_msg_panel.visible = true
	_overlay_dim.visible = true

func show_game_over(is_shown: bool) -> void:
	_msg_panel.visible = is_shown
	_overlay_dim.visible = is_shown
	if is_shown:
		_msg_label.text = "Game Over"
		_hint_label.text = "Press Enter to restart"
	else:
		_hint_label.text = ""

func _show_score_milestone(score: int) -> void:
	"""Show visual feedback for score milestones"""
	var milestone_text = "MILESTONE: %d" % score
	show_popup(milestone_text, Color(1.0, 1.0, 0.3, 1.0))

# Cache popup style to avoid recreating it
var _popup_style: StyleBoxFlat = null

func show_popup(text: String, color: Color = Color(1.0, 0.9, 0.6, 1.0)) -> void:
	if not is_instance_valid(_popup_container) or not is_inside_tree():
		return
	
	# Safety check for text
	if text.is_empty():
		return
	
	# Create cached style if not exists
	if not _popup_style:
		_popup_style = StyleBoxFlat.new()
		_popup_style.bg_color = Color(0.08, 0.04, 0.12, 0.95)
		_popup_style.border_color = Color(0.9, 0.7, 1.0, 0.9)
		_popup_style.border_width_left = 1
		_popup_style.border_width_top = 1
		_popup_style.border_width_right = 1
		_popup_style.border_width_bottom = 1
		_popup_style.corner_radius_top_left = 6
		_popup_style.corner_radius_top_right = 6
		_popup_style.corner_radius_bottom_left = 6
		_popup_style.corner_radius_bottom_right = 6
	
	var panel := PanelContainer.new()
	if not panel or not is_instance_valid(panel):
		push_error("[HUD] Failed to create popup panel")
		return
	
	panel.name = "Popup"
	panel.add_theme_stylebox_override("panel", _popup_style)

	var label := Label.new()
	if not label or not is_instance_valid(label):
		push_error("[HUD] Failed to create popup label")
		panel.queue_free()
		return
	
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	panel.modulate.a = 0.0
	_popup_container.add_child(panel)

	# Limit number of visible popups safely
	var max_popups = 4
	while _popup_container.get_child_count() > max_popups:
		var old := _popup_container.get_child(0)
		if old and is_instance_valid(old):
			old.queue_free()
			# Wait one frame to ensure cleanup
			await get_tree().process_frame
		else:
			break  # Prevent infinite loop

	# Create tween safely
	var fade_in := create_tween()
	if fade_in and is_instance_valid(fade_in):
		fade_in.tween_property(panel, "modulate:a", 1.0, 0.15)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Wait safely
	if is_inside_tree():
		await get_tree().create_timer(1.6, false).timeout
	
	if not is_instance_valid(panel):
		return

	# Create fade out tween safely
	var fade_out := create_tween()
	if fade_out and is_instance_valid(fade_out):
		fade_out.tween_property(panel, "modulate:a", 0.0, 0.25)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished
	
	if is_instance_valid(panel):
		panel.queue_free()

func _set_boss_container_size(container: Control, size: Vector2) -> void:
	if is_instance_valid(container):
		container.size = size

func _set_label_size(label: Label, size: Vector2) -> void:
	if is_instance_valid(label):
		label.size = size

func _create_boss_health_bar() -> void:
	"""Create the boss health bar UI element"""
	# Load the BossHealthBar script
	var BossHealthBarScript = load("res://scripts/boss/BossHealthBar.gd")
	if not BossHealthBarScript:
		push_error("Failed to load BossHealthBar script")
		return
	
	# Create a container for the boss health bar
	var container = Control.new()
	container.name = "BossHealthContainer"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.position = Vector2(0, 30)  # Below the top bar
	container.size = Vector2(320, 16)  # Set size before adding to scene
	add_child(container)
	
	# Create the boss health bar
	_boss_health_bar = BossHealthBarScript.new()
	_boss_health_bar.name = "BossHealthBar"
	
	# Create required child nodes for the boss health bar
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 0)
	name_label.size = Vector2(144, 12)  # Set size before adding to scene
	name_label.add_theme_font_size_override("font_size", 7)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 2)
	_boss_health_bar.add_child(name_label)
	
	var health_container = Control.new()
	health_container.name = "HealthContainer"
	health_container.position = Vector2(0, 7)
	health_container.size = Vector2(144, 7)  # Set size before adding to scene
	_boss_health_bar.add_child(health_container)
	
	# Position the boss health in the center
	_boss_health_bar.position = Vector2(88, 0)
	_boss_health_bar.size = Vector2(144, 14)  # Set size before adding to scene
	_boss_health_bar.visible = false
	
	container.add_child(_boss_health_bar)

func show_boss_health(boss: Node) -> void:
	"""Show the boss health bar for a given boss"""
	if is_instance_valid(_boss_health_bar) and _boss_health_bar.has_method("show_boss_health"):
		_boss_health_bar.show_boss_health(boss)

func hide_boss_health() -> void:
	"""Hide the boss health bar"""
	if is_instance_valid(_boss_health_bar) and _boss_health_bar.has_method("hide_boss_health"):
		_boss_health_bar.hide_boss_health()

# Cho Ren Sha 68K Display Methods
func set_shield(has_shield: bool) -> void:
	"""Update shield display"""
	if has_shield:
		_shield_label.text = "Shield: ON"
		_shield_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))  # Green when active
	else:
		_shield_label.text = "Shield: OFF"
		_shield_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))  # Blue when off

func set_weapon_power(power_level: int) -> void:
	"""Update weapon power display"""
	_power_label.text = "Power: %d" % power_level
	
	# Color coding based on power level
	if power_level >= 8:
		_power_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))  # Red for max
	elif power_level >= 5:
		_power_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))  # Orange for high
	elif power_level >= 3:
		_power_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2, 1.0))  # Yellow for medium
	else:
		_power_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))  # Default orange

func set_loop(loop_number: int) -> void:
	"""Update loop display"""
	_loop_label.text = "Loop: %d" % loop_number
	
	# Color coding based on loop number
	if loop_number >= 3:
		_loop_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))  # Red for high loops
	elif loop_number >= 2:
		_loop_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))  # Orange for loop 2
	else:
		_loop_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8, 1.0))  # Pink for loop 1

# Cho Ren Sha 68K Signal Handlers
func _on_shield_gained() -> void:
	set_shield(true)
	show_popup("SHIELD ACTIVATED", Color(0.4, 1.0, 0.4, 1.0))

func _on_shield_lost() -> void:
	set_shield(false)

func _on_weapon_power_changed(new_power: int) -> void:
	set_weapon_power(new_power)
	if new_power > 1:
		show_popup("POWER UP: %d" % new_power, Color(1.0, 0.8, 0.2, 1.0))

func _on_loop_incremented(new_loop: int) -> void:
	set_loop(new_loop)
	show_popup("LOOP %d STARTED!" % new_loop, Color(1.0, 0.4, 0.8, 1.0))

func _on_life_extended(reason: String) -> void:
	if reason == "score_threshold":
		show_popup("EXTEND! +1 LIFE", Color(1.0, 0.9, 0.3, 1.0))

# Core Game State Signal Handlers
func _on_lives_changed(new_lives: int) -> void:
	set_lives(new_lives)

func _on_bombs_changed(new_bombs: int) -> void:
	set_bombs(new_bombs)

func _on_score_changed(new_score: int) -> void:
	set_score(new_score)

func _on_streak_changed(current_chain: int, max_chain: int) -> void:
	set_chain(current_chain, max_chain)

func _on_chain_broken() -> void:
	# Reset streak display when chain is broken
	set_chain(0, GameState.max_chain)

func _update_all_displays() -> void:
	"""Initialize all displays with current GameState values"""
	# Core game state
	set_lives(GameState.lives)
	set_bombs(GameState.bombs)
	set_score(GameState.score)
	set_chain(GameState.chain_count, GameState.max_chain)
	
	# Cho Ren Sha displays
	set_shield(GameState.has_shield)
	set_weapon_power(GameState.weapon_power)
	set_loop(GameState.current_loop)

func _update_cho_ren_sha_displays() -> void:
	"""Initialize Cho Ren Sha displays with current GameState values"""
	set_shield(GameState.has_shield)
	set_weapon_power(GameState.weapon_power)
	set_loop(GameState.current_loop)

func _apply_high_quality_font_settings() -> void:
	"""Apply high-quality font settings to improve readability at small sizes"""
	# Cache commonly used labels to avoid recursive traversal
	var common_labels = [
		_score_label, _lives_label, _fps_label, _bombs_label, 
		_streak_label, _shield_label, _power_label, _loop_label,
		_msg_label, _hint_label, _shiba_label
	]
	
	for label in common_labels:
		if is_instance_valid(label) and label is Label:
			# Enable font oversampling for better quality at small sizes
			label.add_theme_constant_override("outline_size", 1)
			# Use high-quality font rendering - removed null font override
			# Ensure crisp rendering
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	
	# Only do recursive search for dynamically created labels (boss health, etc.)
	var dynamic_labels = []
	_collect_labels_recursive(self, dynamic_labels, common_labels)
	
	for label in dynamic_labels:
		if is_instance_valid(label) and label is Label:
			label.add_theme_constant_override("outline_size", 1)
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

func _collect_labels_recursive(node: Node, labels: Array, exclude_labels: Array = []) -> void:
	"""Recursively collect all Label nodes, excluding already processed ones"""
	if node is Label and not node in exclude_labels:
		labels.append(node)
	
	for child in node.get_children():
		_collect_labels_recursive(child, labels, exclude_labels)

func cleanup_popups() -> void:
	"""Clean up all popups to free memory"""
	if is_instance_valid(_popup_container):
		for child in _popup_container.get_children():
			if child and is_instance_valid(child):
				child.queue_free()
		_popup_container.get_children().clear()