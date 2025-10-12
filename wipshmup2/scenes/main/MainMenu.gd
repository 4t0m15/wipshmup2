# Main menu: navigation and CRT viewport pipeline
# Renders at 320x180 via SubViewport; CRT shader overlays for a retro look.
extends Node2D

@onready var _buttons: Array[Button] = _collect_buttons()

@onready var _title: Label = $Canvas/Title
@onready var _menu_panel: PanelContainer = $Canvas/MenuPanel
@onready var _quit_image_layer: CanvasLayer = $QuitImageLayer

# Background/viewport pipeline
@onready var _bg_node = $BG

# SubViewport + CRT overlay nodes (created at runtime)
var _viewport_container: SubViewportContainer
var _subviewport: SubViewport
var _viewport_world: Node2D
var _crt_rect: ColorRect
var _crt_material: ShaderMaterial

# CRT settings
var _crt_enabled: bool = true
var _crt_mask_type: int = 1
var _crt_wobble: float = 0.02

var _current_index: int = 0
var _last_move_time: float = 0.0
var _move_cooldown: float = 0.12

func _ready() -> void:
	_current_index = 0
	_update_focus()

	_setup_viewport_and_crt()
	_start_environment_cycle()
	
	# Register BGM with AudioManager for pitch control
	var bgm = get_node_or_null("BGM")
	if bgm:
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager and audio_manager.has_method("set_music_player"):
			audio_manager.set_music_player(bgm)

	# React to viewport resize to keep CRT aspect and container coverage correct
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_size_changed):
		vp.size_changed.connect(_on_viewport_size_changed)

	# Wire button actions by name to be robust to layout changes
	for b in _buttons:
		if not is_instance_valid(b):
			continue
		match b.name:
			"Freeplay":
				b.pressed.connect(_on_freeplay_pressed)
			"Campaign":
				b.pressed.connect(_on_campaign_pressed)
			"Quit":
				b.pressed.connect(_on_quit_pressed)

	# Looping opacity tween for title
	var tw := create_tween().set_loops()
	tw.tween_property(_title, "modulate:a", 0.85, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_title, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Looping subtle scale tween for menu panel
	if is_instance_valid(_menu_panel):
		var tp := create_tween().set_loops()
		tp.tween_property(_menu_panel, "scale", Vector2(1.02, 1.02), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tp.tween_property(_menu_panel, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _unhandled_input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if not viewport:
		return

	if event.is_action_pressed("ui_up"):
		_move_selection(-1)
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
		viewport.set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_activate_current()
		viewport.set_input_as_handled()

func _move_selection(direction: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_move_time < _move_cooldown:
		return #this makes movement more fluid. maybe i should add a shop where you can disable all the stuff that improves UX but it more fun.
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
			# Apply selection styling and focus tween
			b.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
			b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			_create_focus_tween(b)
		else:
			b.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
			b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
			b.scale = Vector2.ONE

func _create_focus_tween(b: Button) -> void:
	if not is_instance_valid(b):
		return
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _activate_current() -> void:
	match _current_index:
		0:
			_on_freeplay_pressed()
		1:
			_on_campaign_pressed()
		2:
			_on_quit_pressed()

func _on_freeplay_pressed() -> void:
	_play_confirm_beep()
	_transition_to_game()

func _on_campaign_pressed() -> void:
	_play_confirm_beep()
	_transition_to_campaign()

func _on_quit_pressed() -> void:
	_play_confirm_beep()
	
	# Show the quit image layer (above CRT filter)
	if is_instance_valid(_quit_image_layer):
		_quit_image_layer.visible = true
	
	# Wait 1 second, then quit - with tree safety check
	if is_inside_tree():
		await get_tree().create_timer(1.0, false).timeout
		if is_inside_tree():
			get_tree().quit()

# Viewport/CRT helpers
func _setup_viewport_and_crt() -> void:
	# Build SubViewport pipeline to post-process the menu with CRT
	# Move BG and Canvas into SubViewport world
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "View"
	# Fill the whole viewport; SubViewport will be stretched by the container
	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport_container.size = Vector2(320, 180)
	_viewport_container.stretch = true
	add_child(_viewport_container)

	_subviewport = SubViewport.new()
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_subviewport.size = Vector2(320, 180)
	_viewport_container.add_child(_subviewport)

	_viewport_world = Node2D.new()
	_viewport_world.name = "World"
	_subviewport.add_child(_viewport_world)

	# Reparent BG and Canvas into the viewport world
	if is_instance_valid(_bg_node):
		_bg_node.get_parent().remove_child(_bg_node)
		_viewport_world.add_child(_bg_node)
	if is_instance_valid($Canvas):
		var canvas := $Canvas
		canvas.get_parent().remove_child(canvas)
		_viewport_world.add_child(canvas)

	# CRT overlay that samples the SubViewport texture
	_crt_rect = ColorRect.new()
	_crt_rect.name = "CRT"
	_crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crt_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crt_rect.size = Vector2(320, 180)
	add_child(_crt_rect)

	var crt_shader: Shader = load("res://shaders/crt.gdshader")
	_crt_material = ShaderMaterial.new()
	_crt_material.shader = crt_shader
	_crt_rect.material = _crt_material

	# Bind SubViewport texture, apply defaults, and set enabled state
	_update_crt_texture()
	_apply_crt_defaults()
	_set_crt_enabled(_crt_enabled)
	_update_crt_aspect()

func _update_crt_texture() -> void:
	if _crt_material and _subviewport:
		var tex := _subviewport.get_texture()
		if tex:
			_crt_material.set_shader_parameter("tex", tex)

func _apply_crt_defaults() -> void:
	if not _crt_material:
		return
	# Aspect is updated dynamically; set an initial safe value
	_crt_material.set_shader_parameter("aspect", 180.0 / 320.0)
	_crt_material.set_shader_parameter("curve", 0.09)
	_crt_material.set_shader_parameter("sharpness", 0.7)
	_crt_material.set_shader_parameter("mask_type", _crt_mask_type)
	_crt_material.set_shader_parameter("mask_brightness", 0.9)
	_crt_material.set_shader_parameter("scanline_brightness", 0.95)
	_crt_material.set_shader_parameter("min_scanline_thickness", 0.55)
	_crt_material.set_shader_parameter("wobble_strength", _crt_wobble)
	_crt_material.set_shader_parameter("gamma", 1.05)

func _set_crt_enabled(enabled: bool) -> void:
	_crt_enabled = enabled
	if is_instance_valid(_crt_rect):
		_crt_rect.visible = enabled

func _on_viewport_size_changed() -> void:
	# Ensure the container continues to cover the viewport and CRT aspect matches
	if is_instance_valid(_viewport_container):
		_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_update_crt_aspect()

func _update_crt_aspect() -> void:
	if not _crt_material:
		return
	var vp := get_viewport()
	if not vp:
		return
	var rect := vp.get_visible_rect()
	if rect.size.x > 0.0:
		var aspect := rect.size.y / rect.size.x
		_crt_material.set_shader_parameter("aspect", aspect)

func _start_environment_cycle() -> void:
	# Periodically adjust background while idle. Supports both BackgroundManager and SpaceBackground.
	if not is_instance_valid(_bg_node):
		return
	var env_timer := Timer.new()
	env_timer.wait_time = 4.0
	env_timer.autostart = true
	env_timer.one_shot = false
	add_child(env_timer)
	env_timer.timeout.connect(func():
		if not is_instance_valid(_bg_node):
			return
		# Legacy/environment manager path
		if _bg_node.has_method("get_current_environment") and _bg_node.has_method("change_environment"):
			var next_env := int(_bg_node.get_current_environment()) + 1
			var total := 7
			next_env = next_env % total
			_bg_node.change_environment(next_env)
		# SpaceBackground path: vary scroll and refresh distribution
		elif _bg_node.has_method("set_horizontal_scroll"):
			var speeds := [30.0, 50.0, 80.0]
			var idx := randi() % speeds.size()
			_bg_node.set_horizontal_scroll(true, speeds[idx])
			if _bg_node.has_method("reset_background"):
				_bg_node.reset_background()
		elif _bg_node.has_method("regenerate"):
			_bg_node.regenerate()
	)

func _get_menu_list() -> Node:
	if has_node("Canvas/MenuPanel/MenuList"):
		return $Canvas/MenuPanel/MenuList
	return get_node_or_null("Canvas/MenuPanel/HBox")

func _collect_buttons() -> Array[Button]:
	var list := _get_menu_list()
	var result: Array[Button] = []
	if list:
		for child in list.get_children():
			if child is Button:
				result.append(child)
	return result


pass

func _transition_to_game() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))

func _transition_to_campaign() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): get_tree().change_scene_to_file("res://scenes/main/CampaignScreen.tscn"))

func _play_nav_beep() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_enemy_shot"):
		am.play_enemy_shot()

func _play_confirm_beep() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_power_up"):
		am.play_power_up()

func _show_simple_popup(msg: String) -> void:
	# Create a simple popup label
	var popup := Label.new()
	popup.text = msg
	popup.add_theme_font_size_override("font_size", 10)
	popup.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8, 1.0))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	popup.add_theme_constant_override("outline_size", 2)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.position = Vector2(60, 100)
	popup.size = Vector2(200, 60)
	popup.modulate.a = 0.0
	add_child(popup)
	
	# Fade in
	var tw_in := create_tween()
	tw_in.tween_property(popup, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Wait and fade out
	await get_tree().create_timer(2.0, false).timeout
	if is_instance_valid(popup):
		var tw_out := create_tween()
		tw_out.tween_property(popup, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tw_out.finished
		if is_instance_valid(popup):
			popup.queue_free()
