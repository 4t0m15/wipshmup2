# Campaign screen - shows message with no gameplay
extends Node2D

@onready var _message: Label = $CanvasLayer/Message

var _can_exit: bool = false

# Path to store which message was shown last
const SAVE_PATH := "user://campaign_last_message.save"

func _ready() -> void:
	# Alternate between ghost town message and jumpscare each time
	var last_was_jumpscare := _load_last_message()
	
	if last_was_jumpscare:
		_show_ghost_town_message()
		_save_last_message(false)
	else:
		_show_loading_jumpscare()
		_save_last_message(true)

func _load_last_message() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false  # Default to showing jumpscare first
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var value := file.get_8()
		file.close()
		return value == 1
	return false

func _save_last_message(was_jumpscare: bool) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_8(1 if was_jumpscare else 0)
		file.close()

func _show_ghost_town_message() -> void:
	_message.modulate.a = 0.0
	_message.text = "50000 used to live here"
	
	# Fade in the initial text
	var tw := create_tween()
	tw.tween_property(_message, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	
	# Add dots one by one with delay
	await get_tree().create_timer(0.5, false).timeout
	_message.text = "50000 used to live here."
	await get_tree().create_timer(0.4, false).timeout
	_message.text = "50000 used to live here.."
	await get_tree().create_timer(0.4, false).timeout
	_message.text = "50000 used to live here..."
	await get_tree().create_timer(0.6, false).timeout
	
	# Fade out, then show just the second part of the message with fade in
	var fade_out := create_tween()
	fade_out.tween_property(_message, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_out.finished
	
	_message.text = "now its a ghost town"
	
	var fade_in := create_tween()
	fade_in.tween_property(_message, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_in.finished
	
	_can_exit = true

func _show_loading_jumpscare() -> void:
	_message.text = "Loading..."
	_message.add_theme_font_size_override("font_size", 12)
	_message.modulate.a = 0.0
	
	# Fade in loading text
	var tw := create_tween()
	tw.tween_property(_message, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Wait a moment, then JUMPSCARE
	await get_tree().create_timer(2.5, false).timeout
	
	# JUMPSCARE!
	_message.text = "GET A JOB!"
	_message.add_theme_font_size_override("font_size", 32)
	_message.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	_message.modulate.a = 1.0
	_message.scale = Vector2(1.5, 1.5)
	
	# Play a sound effect if available
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_explosion"):
		am.play_explosion()
	
	# Shake the message
	var shake_tween := create_tween()
	shake_tween.set_loops(5)
	shake_tween.tween_property(_message, "position:x", _message.position.x + 10, 0.05)
	shake_tween.tween_property(_message, "position:x", _message.position.x - 10, 0.05)
	
	await get_tree().create_timer(0.5, false).timeout
	_can_exit = true

func _unhandled_input(event: InputEvent) -> void:
	# Allow returning to main menu with any key press
	if _can_exit and event.is_pressed() and not event.is_echo():
		_return_to_menu()

func _return_to_menu() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))

