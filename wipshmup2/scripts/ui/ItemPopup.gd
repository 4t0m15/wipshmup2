extends Control

# ItemPopup - Shows what items were collected from triangle items

@onready var _popup_panel: Panel = $PopupPanel
@onready var _item_list: VBoxContainer = $PopupPanel/VBoxContainer/ItemList
@onready var _close_button: Button = $PopupPanel/VBoxContainer/CloseButton
@onready var _timer: Timer = $Timer

var _is_showing: bool = false

func _ready() -> void:
	# Initially hidden
	visible = false
	_popup_panel.visible = false
	
	# Connect close button
	_close_button.pressed.connect(_close_popup)
	
	# Auto-close timer
	_timer.wait_time = 3.0
	_timer.one_shot = true
	_timer.timeout.connect(_close_popup)

func show_items_collected(items: Array[String]) -> void:
	"""Show popup with collected items"""
	if _is_showing:
		return
	
	_is_showing = true
	visible = true
	_popup_panel.visible = true
	
	# Clear previous items
	for child in _item_list.get_children():
		child.queue_free()
	
	# Add collected items to list
	for item in items:
		var label = Label.new()
		label.text = _format_item_name(item)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", _get_item_color(item))
		_item_list.add_child(label)
	
	# Start auto-close timer
	_timer.start()
	
	print("[ItemPopup] Showing collected items: ", items)

func _format_item_name(item: String) -> String:
	"""Format item name for display"""
	match item:
		"HEART":
			return "❤️ +1 Heart (Life)"
		"FIRE_RATE":
			return "⚡ Fire Rate Boost (10s)"
		"BOMB":
			return "💣 +1 Bomb"
		_:
			return "❓ " + item

func _get_item_color(item: String) -> Color:
	"""Get color for item display"""
	match item:
		"HEART":
			return Color(1.0, 0.4, 0.4)  # Red
		"FIRE_RATE":
			return Color(0.4, 0.6, 1.0)  # Blue
		"BOMB":
			return Color(0.4, 1.0, 0.4)  # Green
		_:
			return Color.WHITE

func _close_popup() -> void:
	"""Close the popup"""
	_is_showing = false
	visible = false
	_popup_panel.visible = false
	_timer.stop()
	print("[ItemPopup] Popup closed")

func _input(event: InputEvent) -> void:
	"""Handle input to close popup"""
	if _is_showing and event.is_action_pressed("ui_accept"):
		_close_popup()
