# Epilepsy warning screen
extends Node2D

var _warning_label: Label

func _ready() -> void:
	# Get the warning label safely - try different paths
	_warning_label = get_node_or_null("CanvasLayer/WarningLabel")
	if not _warning_label:
		# Try alternative path
		_warning_label = get_node_or_null("WarningLabel")
	if not _warning_label:
		# Try getting from CanvasLayer directly
		var canvas_layer = get_node_or_null("CanvasLayer")
		if canvas_layer:
			_warning_label = canvas_layer.get_node_or_null("WarningLabel")
	
	if not _warning_label:
		# Debug: Check what's actually in the CanvasLayer
		var canvas_layer = get_node_or_null("CanvasLayer")
		if canvas_layer:
			push_error("[EpilepsyWarning] WarningLabel not found in CanvasLayer! CanvasLayer children: " + str(canvas_layer.get_children()))
		else:
			push_error("[EpilepsyWarning] CanvasLayer not found! Available children: " + str(get_children()))
		_go_to_main_menu()
		return
	
	# Fade in the warning
	_warning_label.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(_warning_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Wait and then proceed to main menu
	await get_tree().create_timer(3.0, false).timeout
	_go_to_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	# Allow skipping with any key press
	if event.is_pressed() and not event.is_echo():
		_go_to_main_menu()

func _go_to_main_menu() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))
