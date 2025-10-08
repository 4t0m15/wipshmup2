# Epilepsy warning screen
extends Node2D

@onready var _warning_label: Label = $CanvasLayer/WarningLabel

func _ready() -> void:
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
