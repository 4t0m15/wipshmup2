extends Node2D

# Background Test Controller
# Simple test interface for the enhanced background system

var background_manager: BackgroundManager
var current_environment: BackgroundManager.EnvironmentType = BackgroundManager.EnvironmentType.SPACE_DEEP
var auto_cycle: bool = false
var cycle_timer: float = 0.0
var cycle_interval: float = 5.0

@onready var environment_label = $UI/Control/VBoxContainer/EnvironmentLabel
@onready var intensity_label = $UI/Control/VBoxContainer/IntensityLabel
@onready var intensity_slider = $UI/Control/VBoxContainer/IntensitySlider
@onready var auto_cycle_button = $UI/Control/VBoxContainer/AutoCycleButton

func _ready():
	print("BackgroundTestController: Initializing test interface")
	
	# Get the background manager
	background_manager = $BackgroundManager
	if not background_manager:
		print("ERROR: BackgroundManager not found!")
		return
	
	# Connect UI signals
	_connect_ui_signals()
	
	# Update initial display
	_update_environment_display()
	_update_intensity_display()

func _connect_ui_signals():
	"""Connect UI button signals"""
	var buttons = [
		$UI/Control/VBoxContainer/Button1,
		$UI/Control/VBoxContainer/Button2,
		$UI/Control/VBoxContainer/Button3,
		$UI/Control/VBoxContainer/Button4,
		$UI/Control/VBoxContainer/Button5,
		$UI/Control/VBoxContainer/Button6,
		$UI/Control/VBoxContainer/Button7
	]
	
	var environments = [
		BackgroundManager.EnvironmentType.SPACE_DEEP,
		BackgroundManager.EnvironmentType.ASTEROID_FIELD,
		BackgroundManager.EnvironmentType.NEBULA,
		BackgroundManager.EnvironmentType.PLANET_ORBIT,
		BackgroundManager.EnvironmentType.STAR_SYSTEM,
		BackgroundManager.EnvironmentType.BASE_APPROACH,
		BackgroundManager.EnvironmentType.COMBAT_ZONE
	]
	
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_environment_button_pressed.bind(environments[i]))
	
	# Connect intensity slider
	intensity_slider.value_changed.connect(_on_intensity_changed)
	
	# Connect auto cycle button
	auto_cycle_button.pressed.connect(_on_auto_cycle_toggled)

func _on_environment_button_pressed(env_type: BackgroundManager.EnvironmentType):
	"""Handle environment button press"""
	current_environment = env_type
	background_manager.change_environment(env_type)
	_update_environment_display()
	print("BackgroundTestController: Changed to environment: ", BackgroundManager.EnvironmentType.keys()[env_type])

func _on_intensity_changed(value: float):
	"""Handle intensity slider change"""
	background_manager.set_intensity(value)
	_update_intensity_display()

func _on_auto_cycle_toggled():
	"""Toggle auto cycling through environments"""
	auto_cycle = !auto_cycle
	auto_cycle_button.text = "Auto Cycle (" + ("ON" if auto_cycle else "OFF") + ")"
	cycle_timer = 0.0
	print("BackgroundTestController: Auto cycle ", ("enabled" if auto_cycle else "disabled"))

func _update_environment_display():
	"""Update environment label"""
	var env_name = BackgroundManager.EnvironmentType.keys()[current_environment]
	environment_label.text = "Environment: " + env_name.replace("_", " ").capitalize()

func _update_intensity_display():
	"""Update intensity label"""
	intensity_label.text = "Intensity: " + str(intensity_slider.value)

func _process(delta: float):
	"""Update auto cycling"""
	if auto_cycle:
		cycle_timer += delta
		if cycle_timer >= cycle_interval:
			cycle_timer = 0.0
			_next_environment()

func _next_environment():
	"""Cycle to next environment"""
	var env_values = BackgroundManager.EnvironmentType.values()
	var current_index = env_values.find(current_environment)
	var next_index = (current_index + 1) % env_values.size()
	
	current_environment = env_values[next_index]
	background_manager.change_environment(current_environment)
	_update_environment_display()
	print("BackgroundTestController: Auto-cycled to: ", BackgroundManager.EnvironmentType.keys()[current_environment])

func _input(event: InputEvent):
	"""Handle keyboard input for quick testing"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.SPACE_DEEP)
			KEY_2:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.ASTEROID_FIELD)
			KEY_3:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.NEBULA)
			KEY_4:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.PLANET_ORBIT)
			KEY_5:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.STAR_SYSTEM)
			KEY_6:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.BASE_APPROACH)
			KEY_7:
				_on_environment_button_pressed(BackgroundManager.EnvironmentType.COMBAT_ZONE)
			KEY_SPACE:
				_on_auto_cycle_toggled()
			KEY_UP:
				intensity_slider.value = min(2.0, intensity_slider.value + 0.1)
			KEY_DOWN:
				intensity_slider.value = max(0.1, intensity_slider.value - 0.1)
