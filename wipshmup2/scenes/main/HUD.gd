extends CanvasLayer

var _accum_time_s: float = 0.0
var _accum_ticks: int = 0
var _rainbow_time: float = 0.0
var _streak_timer: float = 0.0
var _streak_timeout: float = 2.0
var _streak_active: bool = false

@onready var _score_label: Label = $TopBar/HBox/ScoreLabel
@onready var _lives_label: Label = $TopBar/HBox/LivesLabel
@onready var _tps_label: Label = $TopBar/HBox/TPSLabel
@onready var _bombs_label: Label = $TopBar/HBox/BombsLabel
@onready var _streak_label: Label = $TopBar/HBox/StreakLabel
@onready var _streak_timer_bar: ProgressBar = $StreakTimer/ProgressBar
@onready var _overlay_dim: ColorRect = $CenterOverlay/OverlayDim
@onready var _msg_panel: PanelContainer = $CenterOverlay/MessagePanel
@onready var _msg_label: Label = $CenterOverlay/MessagePanel/VBox/MessageLabel
@onready var _hint_label: Label = $CenterOverlay/MessagePanel/VBox/HintLabel
@onready var _popup_container: VBoxContainer = $Popups
@onready var _shiba_label: Label = $ShibaLabel
@onready var _boss_health_bar: Control = null  # Will be created dynamically

func _ready() -> void:
	# Initialize streak timer bar
	if is_instance_valid(_streak_timer_bar):
		_streak_timer_bar.visible = false
	
	# Create boss health bar dynamically
	_create_boss_health_bar()

func _process(delta: float) -> void:
	_rainbow_time += delta * 3.0  # Speed up the rainbow effect
	if is_instance_valid(_shiba_label):
		_shiba_label.add_theme_color_override("font_color", _get_rainbow_color(_rainbow_time))
	
	# Update streak timer
	if _streak_active and _streak_timer > 0.0:
		_streak_timer -= delta
		var progress = max(0.0, _streak_timer / _streak_timeout)
		_streak_timer_bar.value = progress
		
		# Change color based on remaining time
		if progress > 0.5:
			_streak_timer_bar.modulate = Color(0.4, 1.0, 0.4, 1.0)  # Green
		elif progress > 0.25:
			_streak_timer_bar.modulate = Color(1.0, 1.0, 0.4, 1.0)  # Yellow
		else:
			_streak_timer_bar.modulate = Color(1.0, 0.4, 0.4, 1.0)  # Red
		
		if _streak_timer <= 0.0:
			_streak_active = false
			_streak_timer_bar.visible = false
	
	# Simple TPS calculation
	_accum_time_s += delta
	_accum_ticks += 1
	if _accum_time_s >= 1.0:
		var tps: float = float(_accum_ticks) / _accum_time_s
		_tps_label.text = "TPS: %d" % int(round(tps))
		_accum_time_s = 0.0
		_accum_ticks = 0

func _get_rainbow_color(time: float) -> Color:
	# Create rainbow effect using HSV color space
	var hue = fmod(time, 1.0)  # Cycle through hue from 0 to 1
	return Color.from_hsv(hue, 1.0, 1.0, 1.0)  # Full saturation and value for vibrant colors

func set_score(value: int) -> void:
	_score_label.text = "Score: %d" % value

func set_lives(value: int) -> void:
	var lives_text = ""
	for i in range(3):  # Show 3 heart slots
		if i < value:
			lives_text += "♥"  # Filled heart
		else:
			lives_text += "♡"  # Empty heart
	_lives_label.text = "Lives: %s" % lives_text

func set_bombs(value: int) -> void:
	var text := "Bombs: %d" % max(0, value)
	_bombs_label.text = text

func set_chain(current_chain: int, max_chain: int) -> void:
	if current_chain > 0:
		_streak_label.text = "Streak: %d (Best: %d)" % [current_chain, max_chain]
		# Add visual emphasis for longer streaks
		if current_chain >= 10:
			_streak_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2, 1.0))  # Red-orange for high streaks
		elif current_chain >= 5:
			_streak_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))  # Orange for medium streaks
		else:
			_streak_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4, 1.0))  # Default yellow-orange
		
		# Start/reset the streak timer
		_streak_timer = _streak_timeout
		_streak_active = true
		_streak_timer_bar.visible = true
		_streak_timer_bar.value = 1.0
		_streak_timer_bar.modulate = Color(0.4, 1.0, 0.4, 1.0)  # Start with green
	else:
		_streak_label.text = "Streak: 0 (Best: %d)" % max_chain
		_streak_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))  # Gray when no streak
		# Hide the timer bar when no streak
		_streak_active = false
		_streak_timer_bar.visible = false

func reset_streak_timer() -> void:
	# Called when streak is broken due to timeout or player getting hit
	_streak_active = false
	_streak_timer_bar.visible = false

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

func show_popup(text: String, color: Color = Color(1.0, 0.9, 0.6, 1.0)) -> void:
	if not is_instance_valid(_popup_container):
		return
	var panel := PanelContainer.new()
	panel.name = "Popup"
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.12, 0.95)
	style.border_color = Color(0.9, 0.7, 1.0, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	panel.modulate.a = 0.0
	_popup_container.add_child(panel)

	# Limit number of visible popups
	while _popup_container.get_child_count() > 4:
		var old := _popup_container.get_child(0)
		if is_instance_valid(old):
			old.queue_free()

	var fade_in := create_tween()
	fade_in.tween_property(panel, "modulate:a", 1.0, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.6, false).timeout
	if not is_instance_valid(panel):
		return

	var fade_out := create_tween()
	fade_out.tween_property(panel, "modulate:a", 0.0, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished
	if is_instance_valid(panel):
		panel.queue_free()

func _create_boss_health_bar() -> void:
	"""Create the boss health bar UI element"""
	# Load the BossHealthBar script
	var BossHealthBarScript = load("res://scripts/BossHealthBar.gd")
	if not BossHealthBarScript:
		push_error("Failed to load BossHealthBar script")
		return
	
	# Create a container for the boss health bar
	var container = Control.new()
	container.name = "BossHealthContainer"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.position = Vector2(0, 30)  # Below the top bar
	container.size = Vector2(320, 40)
	add_child(container)
	
	# Create the boss health bar
	_boss_health_bar = BossHealthBarScript.new()
	_boss_health_bar.name = "BossHealthBar"
	
	# Create required child nodes for the boss health bar
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 2)
	name_label.size = Vector2(300, 16)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	name_label.add_theme_constant_override("outline_size", 1)
	_boss_health_bar.add_child(name_label)
	
	var health_container = Control.new()
	health_container.name = "HealthContainer"
	health_container.position = Vector2(0, 20)
	health_container.size = Vector2(300, 16)
	_boss_health_bar.add_child(health_container)
	
	# Position the boss health bar in the center
	_boss_health_bar.position = Vector2(10, 0)
	_boss_health_bar.size = Vector2(300, 40)
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