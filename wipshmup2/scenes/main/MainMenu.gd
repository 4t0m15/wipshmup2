# Main menu: navigation and CRT viewport pipeline
# Renders at 320x180 via SubViewport; CRT shader overlays for a retro look.
extends Node2D

@onready var _buttons: Array[Button] = _collect_buttons()

@onready var _title: Label = $Canvas/Title
@onready var _flavor_text: Label = $Canvas/FlavorText
@onready var _menu_panel: PanelContainer = $Canvas/MenuPanel
@onready var _quit_image_layer: CanvasLayer = $QuitImageLayer

# Background/viewport pipeline
@onready var _bg_node = $BG

# SubViewport nodes (created at runtime)
var _viewport_container: SubViewportContainer
var _subviewport: SubViewport
var _viewport_world: Node2D
var _crt_rect: ColorRect
var _crt_material: ShaderMaterial

# CRT settings - disabled to match the actual game
var _crt_enabled: bool = false
var _crt_mask_type: int = 1

var _current_index: int = 0
var _last_move_time: float = 0.0
var _move_cooldown: float = 0.12

# Stat tracking
var _rare_message_count: int = 0
var _ultra_rare_message_count: int = 0
var _total_messages_seen: int = 0
var _menu_start_time: float = 0.0

# Minecraft-style flavor texts
const FLAVOR_TEXTS: Array[String] = [
	"Bullet Hell!",
	"Also try Touhou!",
	"Dodge everything!",
	"Now with more bullets!",
	"Adaptive difficulty!",
	"Rank goes up!",
	"Retro vibes!",
	"CRT shader included!",
	"Made with Godot!",
	"Boss rush mode!",
	"Pattern recognition!",
	"High score!",
	"One more run!",
	"Git gud!",
	"Danmaku master!",
	"Graze for points!",
	"No continues!",
	"Pixel perfect!",
	"Screenshake!",
	"More enemies!",
	"Even more bullets!",
	"WIP!",
	"90% finished!",
	"Soon™!",
	"Needs polish!",
	"Hitbox: 1 pixel!",
	"Rank 5.0 or bust!",
	"Infinite continues!",
	"Shmup is love!",
	"Cascading walls!",
	"Weaving serpent!",
	"Diamond formation!",
	"Pinwheel assault!",
	"Converging storm!",
	"Rotating spokes!",
	"Interlocking gears!",
	"Boss phase manager!",
	"Entity factory!",
	"Object pooling!",
	"Template system!",
	"Data-driven design!",
	"GDScript powered!",
	"Fullscreen mode!",
	"320x180 render!",
	"Integer scaling!",
	"Zero input lag!",
	"60 FPS or die!",
	"Vsync disabled!",
	"Shader graphics!",
	"Dither effects!",
	"Parallax scrolling!",
	"Screen wrapping!",
	"Death counter!",
	"No checkpoints!",
	"Pattern memorization!",
	"Muscle memory!",
	"Frame perfect!",
	"TAS viable!",
	"RNG manipulation!",
	"Speedrun ready!",
	"World record?",
	"Leaderboard soon!",
	"Made by Arsen!",
	"Open source!",
	"MIT licensed!",
	"Pull requests welcome!",
	"Report bugs!",
	"Feature creep!",
	"Technical debt!",
	"Needs refactoring!",
	"Works on my machine!",
	"Compiles!",
	"No crashes!*",
	"*mostly",
	"Playtested once!",
	"Ships in a day!",
	"Version 0.69!",
	"Nice version number!",
	"Easter eggs hidden!",
	"Konami code ready!",
	"Cheat codes soon!",
	"Debug mode exists!",
	"F12 for dev console!",
	"Print statements!",
	"TODO: optimize!",
	"FIXME: later!",
	"Commented code!",
	"Magic numbers!",
	"Global variables!",
	"Spaghetti code!",
	"It works, ship it!",
	"Hack: don't touch!",
	"Legacy code ahead!",
	"Do not refactor!",
	"Tests? What tests?",
	"Production ready!**",
	"**not really",
	"Alpha quality!",
	"Beta never!",
	"Release candidate!",
	"Shipping soon!",
	"Two weeks™!",
	"Notch <3 ez!",
	"More polygons!",
	"OpenGL 2.0!",
	"Now in 3D!",
	"Jagged text!",
	"Pumping water!",
	"Binding keys!",
	"Reading pixels!",
	"Redstone ready!",
	"Testificates!",
	"Procedurally generated!",
	"Smooth lighting!",
	"Moderately attractive!",
	"Play Minecraft!",
	"Déjà vu!",
	"Lemons!",
	"Where's the beef?",
	"Herbage!",
	"Create!",
	"Destroy!",
	"Survive!",
	"Thrive!",
	"Engage!",
	"Detonate!",
	"Winning!",
	"Fascinating!",
	"Crunchy!",
	"Smooth!",
	"Sublime!",
	"Fat free!",
	"Diet compatible!",
	"Kosher!",
	"Halal!",
	"Vegan friendly!",
	"Gluten free!",
	"Nut free!",
	"Soy free!",
	"GMO free!",
	"Organic!",
	"Artisanal!",
	"Hand-crafted!",
	"Small batch!",
	"Farm to table!",
	"Locally sourced!",
	"Free range!",
	"Cage free!",
]

# Rare flavor texts (1% chance)
const RARE_FLAVOR_TEXTS: Array[String] = [
	"Minceraft!",
	"This is my sister!",
	"woo, reddit!",
	"Ask me about wipshmup3!",
	"Now Java-free!",
	"Down with O.P.P.!",
	"Child's play!",
	"90% bug-free!",
	"Casual gaming!",
	"Keyboard compatible!",
	"Mouse compatible!",
	"Not on Steam!",
	"Not on itch.io!",
	"Absolutely no memes!",
	"More than 100 splash texts!",
	"Exciting!",
	"Awesome!",
	"Mundane!",
	"Hello, Arsen!",
	"ctrl+alt+del!",
	"Made by one person!",
	"In development!",
	"Not copied from anyone!",
	"Original IP!",
	"Patent pending!",
	"Trademark pending!",
	"Copyright pending!",
	"All rights reversed!",
	"This message is rare!",
	"You're lucky!",
	"0.01% chance!",
	"Rainbow text!",
	"Shiny!",
	"Golden experience!",
	"Ultra rare drop!",
	"Achievement unlocked!",
]

# Ultra-rare flavor texts (0.1% chance)
const ULTRA_RARE_FLAVOR_TEXTS: Array[String] = [
	"You found the secret!",
	"Legendary message!",
	"0.001% chance!!!",
	"Tell your friends!",
	"Screenshot this!",
	"Jackpot!",
	"Mega rare!",
	"How did you get this?",
	"The prophecy is true!",
	"This never happens!",
]

# Special date-based messages (checked first)
const SPECIAL_DATE_MESSAGES: Dictionary = {
	"01-01": "Happy New Year!",
	"02-14": "Spread the love!",
	"03-14": "Pi Day! 3.14159...",
	"04-01": "Not an April Fool!",
	"05-04": "May the 4th be with you!",
	"06-09": "Nice!",
	"07-04": "Fireworks!",
	"10-31": "Spooky season!",
	"11-01": "NaNoWriMo!",
	"12-24": "Merry Christmas Eve!",
	"12-25": "Merry Christmas!",
	"12-31": "New Year's Eve!",
}

func _ready() -> void:
	_current_index = 0
	_update_focus()
	
	_menu_start_time = Time.get_ticks_msec() / 1000.0

	_setup_viewport_and_crt()
	_start_environment_cycle()
	_setup_flavor_text()
	
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
			"BossRush":
				b.pressed.connect(_on_boss_rush_pressed)
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

func _setup_flavor_text() -> void:
	"""Set random flavor text and add wobble animation"""
	if not is_instance_valid(_flavor_text):
		return
	
	# Initial fade in
	_flavor_text.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(_flavor_text, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Pick random flavor text
	_change_flavor_text()
	
	# Add wobble animation (like Minecraft)
	var wobble_tween := create_tween().set_loops()
	wobble_tween.tween_property(_flavor_text, "rotation", -0.279253, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # -16 degrees
	wobble_tween.tween_property(_flavor_text, "rotation", -0.418879, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # -24 degrees
	
	# Add scale pulse
	var pulse_tween := create_tween().set_loops()
	pulse_tween.tween_property(_flavor_text, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(_flavor_text, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Change flavor text every 5 seconds
	var flavor_timer := Timer.new()
	flavor_timer.wait_time = 5.0
	flavor_timer.autostart = true
	flavor_timer.one_shot = false
	add_child(flavor_timer)
	flavor_timer.timeout.connect(_change_flavor_text)

func _change_flavor_text() -> void:
	"""Change to a random flavor text with a smooth transition"""
	if not is_instance_valid(_flavor_text):
		return
	
	_total_messages_seen += 1
	
	# Fade out
	var fade_out := create_tween()
	fade_out.tween_property(_flavor_text, "modulate:a", 0.3, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await fade_out.finished
	
	# Check for special date message first
	var date_msg := _get_special_date_message()
	if date_msg != "":
		_flavor_text.text = date_msg
		# Special dates get gold color
		_flavor_text.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
		# Add gentle glow effect
		_create_gentle_glow_effect()
	else:
		# 0.1% chance for ultra-rare message
		var rand_val := randf()
		if rand_val < 0.001:
			_ultra_rare_message_count += 1
			var msg := ULTRA_RARE_FLAVOR_TEXTS[randi() % ULTRA_RARE_FLAVOR_TEXTS.size()]
			# Add counter to message
			if _ultra_rare_message_count > 1:
				msg += " (x%d)" % _ultra_rare_message_count
			_flavor_text.text = msg
			# Ultra-rare gets MAXIMUM effects
			_start_rainbow_effect()
			_play_ultra_rare_sound()
			_create_mega_sparkle_effect()
			print("[MainMenu] ULTRA RARE MESSAGE #%d: %s" % [_ultra_rare_message_count, msg])
		# 1% chance for rare message
		elif rand_val < 0.01:
			_rare_message_count += 1
			_flavor_text.text = RARE_FLAVOR_TEXTS[randi() % RARE_FLAVOR_TEXTS.size()]
			# Rare messages get rainbow effect
			_start_rainbow_effect()
			_play_rare_message_sound()
			_create_sparkle_effect()
		else:
			_flavor_text.text = FLAVOR_TEXTS[randi() % FLAVOR_TEXTS.size()]
			# Randomly vary color slightly (yellow to orange range)
			var color_variant: float = randf_range(0.85, 1.0)
			_flavor_text.add_theme_color_override("font_color", Color(1.0, color_variant, 0.3, 1.0))
	
	# Fade in
	var fade_in := create_tween()
	fade_in.tween_property(_flavor_text, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _get_special_date_message() -> String:
	"""Check if today has a special message"""
	var date := Time.get_date_dict_from_system()
	var key := "%02d-%02d" % [date.month, date.day]
	if SPECIAL_DATE_MESSAGES.has(key):
		return SPECIAL_DATE_MESSAGES[key]
	
	# Check for time-of-day messages (5% chance)
	if randf() < 0.05:
		var time := Time.get_time_dict_from_system()
		var hour: int = time.hour
		if hour >= 0 and hour < 6:
			return ["Late night gaming!", "Burning the midnight oil!", "Should you be sleeping?", "Night owl mode!"][randi() % 4]
		elif hour >= 6 and hour < 12:
			return ["Good morning!", "Rise and shine!", "Early bird!", "Fresh start!"][randi() % 4]
		elif hour >= 12 and hour < 18:
			return ["Good afternoon!", "Peak gaming hours!", "Midday madness!", "Lunch break fun!"][randi() % 4]
		elif hour >= 18 and hour < 24:
			return ["Good evening!", "Prime time!", "After work chill!", "Sunset sessions!"][randi() % 4]
	
	return ""

func _start_rainbow_effect() -> void:
	"""Apply a rainbow color cycling effect for rare messages"""
	if not is_instance_valid(_flavor_text):
		return
	
	# Create a rainbow tween that cycles through colors
	var rainbow := create_tween().set_loops(5)  # Loop 5 times during the 5-second display
	rainbow.tween_method(func(hue: float):
		var color := Color.from_hsv(hue, 1.0, 1.0)
		_flavor_text.add_theme_color_override("font_color", color)
	, 0.0, 1.0, 1.0)

func _play_rare_message_sound() -> void:
	"""Play a special sound when a rare message appears"""
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_power_up"):
		am.play_power_up()
		# Play it again slightly delayed for a "shimmer" effect
		await get_tree().create_timer(0.1, false).timeout
		if am and am.has_method("play_power_up"):
			am.play_power_up()

func _play_ultra_rare_sound() -> void:
	"""Play an even more special sound for ultra-rare messages"""
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_power_up"):
		# Triple sound with rhythm
		for i in range(3):
			am.play_power_up()
			await get_tree().create_timer(0.08, false).timeout

func _create_sparkle_effect() -> void:
	"""Create a sparkle effect around the flavor text for rare messages"""
	if not is_instance_valid(_flavor_text):
		return
	
	# Get the canvas layer to add sparkles to
	var canvas_layer := _flavor_text.get_parent()
	if not canvas_layer:
		return
	
	# Create several small sparkle particles
	for i in range(12):  # More sparkles!
		var sparkle := Label.new()
		sparkle.text = "✦"
		sparkle.add_theme_font_size_override("font_size", randi_range(8, 16))
		sparkle.modulate = Color.from_hsv(randf(), 1.0, 1.0, 1.0)
		
		# Position around the flavor text
		var angle: float = (float(i) / 12.0) * TAU + randf_range(-0.2, 0.2)
		var radius: float = randf_range(40.0, 70.0)
		var base_pos := _flavor_text.position + Vector2(50, 10)  # Offset to center
		var start_pos := base_pos + Vector2(cos(angle), sin(angle)) * radius
		sparkle.position = start_pos
		
		canvas_layer.add_child(sparkle)
		
		# Animate: move outward and fade out with slight randomness
		var sparkle_tween := create_tween()
		sparkle_tween.set_parallel(true)
		var end_offset: float = randf_range(20.0, 40.0)
		sparkle_tween.tween_property(sparkle, "position", 
			start_pos + Vector2(cos(angle), sin(angle)) * end_offset, randf_range(0.6, 1.0))
		sparkle_tween.tween_property(sparkle, "modulate:a", 0.0, randf_range(0.5, 0.9))
		sparkle_tween.tween_property(sparkle, "rotation", randf_range(-TAU, TAU), randf_range(0.6, 1.0))
		sparkle_tween.tween_property(sparkle, "scale", Vector2.ONE * randf_range(0.5, 1.5), randf_range(0.6, 1.0))
		sparkle_tween.finished.connect(func(): 
			if is_instance_valid(sparkle):
				sparkle.queue_free()
		)

func _create_mega_sparkle_effect() -> void:
	"""Create an EXTREME sparkle effect for ultra-rare messages"""
	if not is_instance_valid(_flavor_text):
		return
	
	var canvas_layer := _flavor_text.get_parent()
	if not canvas_layer:
		return
	
	# Create MANY sparkles in waves
	for wave in range(3):
		await get_tree().create_timer(0.15 * float(wave), false).timeout
		
		for i in range(16):
			var sparkle := Label.new()
			sparkle.text = ["✦", "★", "✧", "⭐"][randi() % 4]
			sparkle.add_theme_font_size_override("font_size", randi_range(10, 20))
			sparkle.modulate = Color.from_hsv(randf(), 1.0, 1.0, 1.0)
			
			var angle: float = (float(i) / 16.0) * TAU + randf_range(-0.3, 0.3)
			var radius: float = randf_range(30.0, 90.0)
			var base_pos := _flavor_text.position + Vector2(50, 10)
			var start_pos := base_pos + Vector2(cos(angle), sin(angle)) * radius
			sparkle.position = start_pos
			
			canvas_layer.add_child(sparkle)
			
			var sparkle_tween := create_tween()
			sparkle_tween.set_parallel(true)
			var end_offset: float = randf_range(40.0, 80.0)
			sparkle_tween.tween_property(sparkle, "position", 
				start_pos + Vector2(cos(angle), sin(angle)) * end_offset, randf_range(0.8, 1.4))
			sparkle_tween.tween_property(sparkle, "modulate:a", 0.0, randf_range(0.7, 1.2))
			sparkle_tween.tween_property(sparkle, "rotation", randf_range(-TAU * 2, TAU * 2), randf_range(0.8, 1.4))
			sparkle_tween.tween_property(sparkle, "scale", Vector2.ONE * randf_range(0.3, 2.0), randf_range(0.8, 1.4))
			sparkle_tween.finished.connect(func(): 
				if is_instance_valid(sparkle):
					sparkle.queue_free()
			)

func _create_gentle_glow_effect() -> void:
	"""Create a subtle glow effect for special date messages"""
	if not is_instance_valid(_flavor_text):
		return
	
	# Pulse the text scale slightly larger for special dates
	var special_pulse := create_tween().set_loops()
	special_pulse.tween_property(_flavor_text, "scale", Vector2(1.12, 1.12), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	special_pulse.tween_property(_flavor_text, "scale", Vector2(1.05, 1.05), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _show_rare_stats_popup() -> void:
	"""Show a popup with rare message statistics"""
	var time_on_menu := (Time.get_ticks_msec() / 1000.0) - _menu_start_time
	var minutes := int(time_on_menu / 60.0)
	var seconds := int(time_on_menu) % 60
	
	var msg := "✨ Menu Statistics ✨\n\n"
	msg += "Messages seen: %d\n" % _total_messages_seen
	msg += "Rare: %d (1%%)\n" % _rare_message_count
	msg += "Ultra-Rare: %d (0.1%%)\n" % _ultra_rare_message_count
	msg += "Time on menu: %dm %ds\n" % [minutes, seconds]
	
	if _rare_message_count > 0 or _ultra_rare_message_count > 0:
		var total := _rare_message_count + _ultra_rare_message_count * 10
		msg += "\nLuck score: %d" % total
	else:
		msg += "\nNo rare messages yet!"
	
	_show_simple_popup(msg)

func _unhandled_input(event: InputEvent) -> void:
	var viewport = get_viewport()
	if not viewport:
		return

	# Secret key combo to show rare message stats (F3)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_show_rare_stats_popup()
		viewport.set_input_as_handled()
		return
	
	# Secret key combo to force rare message (F4)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4:
		_change_flavor_text()
		viewport.set_input_as_handled()
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
			_on_boss_rush_pressed()
		3:
			_on_quit_pressed()

func _on_freeplay_pressed() -> void:
	_play_confirm_beep()
	_transition_to_game()

func _on_campaign_pressed() -> void:
	_play_confirm_beep()
	_transition_to_campaign()

func _on_boss_rush_pressed() -> void:
	_play_confirm_beep()
	_transition_to_boss_rush()

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
	_viewport_container.stretch = false  # Disable stretch to allow manual size control
	# Use the actual viewport size for proper scaling
	var vp := get_viewport()
	if vp:
		call_deferred("_set_viewport_container_size", vp.get_visible_rect().size)
	else:
		call_deferred("_set_viewport_container_size", Vector2(320, 180))
	add_child(_viewport_container)

	_subviewport = SubViewport.new()
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Use the actual viewport size for proper scaling
	if vp:
		call_deferred("_set_subviewport_size", vp.get_visible_rect().size)
	else:
		call_deferred("_set_subviewport_size", Vector2(320, 180))
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
	# Use the actual viewport size for proper scaling
	if vp:
		call_deferred("_set_crt_rect_size", vp.get_visible_rect().size)
	else:
		call_deferred("_set_crt_rect_size", Vector2(320, 180))
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
	_crt_material.set_shader_parameter("curve", 0.03)  # Reduced from 0.09 - less curvature for better readability
	_crt_material.set_shader_parameter("sharpness", 0.9)  # Increased from 0.7 - sharper text
	_crt_material.set_shader_parameter("mask_type", _crt_mask_type)
	_crt_material.set_shader_parameter("mask_brightness", 0.98)  # Increased from 0.9 - less darkening
	_crt_material.set_shader_parameter("scanline_brightness", 0.99)  # Increased from 0.95 - less visible scanlines
	_crt_material.set_shader_parameter("min_scanline_thickness", 0.75)  # Increased from 0.55 - thinner scanlines
	_crt_material.set_shader_parameter("wobble_strength", 0.005)  # Reduced from 0.02 - less wobble
	_crt_material.set_shader_parameter("gamma", 1.02)  # Reduced from 1.05 - less color shift

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

func _set_viewport_container_size(size: Vector2) -> void:
	if is_instance_valid(_viewport_container):
		# Avoid overriding anchor-driven size; use custom minimum instead
		_viewport_container.custom_minimum_size = size

func _set_subviewport_size(size: Vector2) -> void:
	if is_instance_valid(_subviewport):
		_subviewport.size = size

func _set_crt_rect_size(size: Vector2) -> void:
	if is_instance_valid(_crt_rect):
		# Avoid overriding anchor-driven size; use custom minimum instead
		_crt_rect.custom_minimum_size = size

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

func _transition_to_boss_rush() -> void:
	# Start boss rush mode via GameModeManager
	GameModeManager.start_boss_rush()
	# Transition to main game scene
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))

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
