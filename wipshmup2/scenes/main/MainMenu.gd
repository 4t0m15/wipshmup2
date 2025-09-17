extends Node2D

@onready var _buttons: Array[Button] = [
	$Canvas/MenuPanel/HBox/Play,
	$Canvas/MenuPanel/HBox/Options,
	$Canvas/MenuPanel/HBox/Quit
]

@onready var _title: Label = $Canvas/Title
@onready var _hint: Label = $Canvas/Hint

var _current_index: int = 0
var _last_move_time: float = 0.0
var _move_cooldown: float = 0.12
var _popup_panel: PanelContainer

func _ready() -> void:
	# Initial focus
	_current_index = 0
	_update_focus()

	# Connect buttons
	_buttons[0].pressed.connect(_on_play_pressed)
	_buttons[1].pressed.connect(_on_options_pressed)
	_buttons[2].pressed.connect(_on_quit_pressed)

	# Simple breathing animation for title to match neon vibe
	var tw := create_tween().set_loops()
	tw.tween_property(_title, "modulate:a", 0.85, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_title, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Subtle shimmer for hint so it's used and visible
	var th := create_tween().set_loops()
	th.tween_property(_hint, "modulate:a", 0.7, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	th.tween_property(_hint, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event: InputEvent) -> void:
	# If popup is open, close it on accept/cancel and swallow input
	if is_instance_valid(_popup_panel):
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_popup_panel.queue_free()
			_popup_panel = null
			_update_focus()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_left"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_activate_current()
		get_viewport().set_input_as_handled()

func _move_selection(direction: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_move_time < _move_cooldown:
		return
	_last_move_time = now

	_current_index = (_current_index + direction) % _buttons.size()
	if _current_index < 0:
		_current_index = _buttons.size() - 1
	_update_focus()
	_play_nav_beep()

func _update_focus() -> void:
	for i in range(_buttons.size()):
		var b := _buttons[i]
		if i == _current_index:
			b.grab_focus()
			# Subtle scale/shine to indicate selection
			b.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
			b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			_create_focus_tween(b)
		else:
			b.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
			b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))

func _create_focus_tween(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _activate_current() -> void:
	match _current_index:
		0:
			_on_play_pressed()
		1:
			_on_options_pressed()
		2:
			_on_quit_pressed()

func _on_play_pressed() -> void:
	_play_confirm_beep()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_options_pressed() -> void:
	_play_nav_beep()
	_show_simple_popup("Options coming soon\n- Toggle Fullscreen (Alt+Enter)\n- Audio with dev beeps")

func _on_quit_pressed() -> void:
	_play_confirm_beep()
	get_tree().quit()

func _show_simple_popup(text: String) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.12, 0.95)
	style.border_color = Color(0.9, 0.7, 1.0, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(40, 50)
	add_child(panel)

	var vb := VBoxContainer.new()
	panel.add_child(vb)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.9, 0.8, 1, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0.6, 0.8))
	label.add_theme_constant_override("outline_size", 1)
	vb.add_child(label)

	var hint := Label.new()
	hint.text = "Press Enter to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.8, 0.9, 1, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0.1, 0.3, 0.5, 0.8))
	hint.add_theme_constant_override("outline_size", 1)
	vb.add_child(hint)

	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.35)
	blocker.size = Vector2(320, 180)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = -1
	panel.add_child(blocker)

	# Track popup and close from _unhandled_input
	_popup_panel = panel

func _play_nav_beep() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_enemy_shot"):
		am.play_enemy_shot()

func _play_confirm_beep() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_power_up"):
		am.play_power_up()


