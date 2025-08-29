extends CanvasLayer

var _accum_time_s: float = 0.0
var _accum_ticks: int = 0
var _rainbow_time: float = 0.0

@onready var _score_label: Label = $TopBar/HBox/ScoreLabel
@onready var _lives_label: Label = $TopBar/HBox/LivesLabel
@onready var _tps_label: Label = $TopBar/HBox/TPSLabel
@onready var _bombs_label: Label = $TopBar/HBox/BombsLabel
@onready var _overlay_dim: ColorRect = $CenterOverlay/OverlayDim
@onready var _msg_panel: PanelContainer = $CenterOverlay/MessagePanel
@onready var _msg_label: Label = $CenterOverlay/MessagePanel/VBox/MessageLabel
@onready var _hint_label: Label = $CenterOverlay/MessagePanel/VBox/HintLabel
@onready var _popup_container: VBoxContainer = $Popups
@onready var _shiba_label: Label = $ShibaLabel
@onready var _dev_info_label: Label

func _ready() -> void:
	var tm := get_node_or_null("/root/TickManager")
	if tm and tm.has_signal("tick"):
		tm.tick.connect(_on_tick)

	# Create dev info label if it doesn't exist
	if not has_node("DevInfo"):
		_dev_info_label = Label.new()
		_dev_info_label.name = "DevInfo"
		_dev_info_label.add_theme_font_size_override("font_size", 10)
		_dev_info_label.add_theme_color_override("font_color", Color.CYAN)
		_dev_info_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_dev_info_label.add_theme_constant_override("outline_size", 1)
		_dev_info_label.position = Vector2(10, 40)
		_dev_info_label.visible = false
		add_child(_dev_info_label)
	else:
		_dev_info_label = get_node("DevInfo")

func _process(delta: float) -> void:
	_rainbow_time += delta * 3.0  # Speed up the rainbow effect
	if is_instance_valid(_shiba_label):
		_shiba_label.add_theme_color_override("font_color", _get_rainbow_color(_rainbow_time))

func _get_rainbow_color(time: float) -> Color:
	# Create rainbow effect using HSV color space
	var hue = fmod(time, 1.0)  # Cycle through hue from 0 to 1
	return Color.from_hsv(hue, 1.0, 1.0)  # Full saturation and value for vibrant colors

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

func set_bombs(value: int) -> void:
	var text := "Bombs: %d" % max(0, value)
	_bombs_label.text = text

func _on_tick(dt: float) -> void:
	_accum_time_s += dt
	_accum_ticks += 1
	if _accum_time_s >= 1.0:
		var tps: float = float(_accum_ticks) / _accum_time_s
		_tps_label.text = "TPS: %d" % int(round(tps))
		_accum_time_s = 0.0
		_accum_ticks = 0

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

func set_dev_info(dev_mode: bool, invincibility: bool, audio_muted: bool) -> void:
	if is_instance_valid(_dev_info_label):
		_dev_info_label.visible = dev_mode
		if dev_mode:
			_dev_info_label.text = "DEV MODE\nInvincible: %s\nAudio: %s" % [
				"ON" if invincibility else "OFF",
				"MUTED" if audio_muted else "ON"
			]
