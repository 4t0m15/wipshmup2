class_name BossHealthBar
extends Control

# Visual settings
@export var bar_height: float = 4.3
@export var bar_padding: float = 1.4
@export var phase_gap: float = 0.7

# Colors
@export var bg_color: Color = Color(0.1, 0.1, 0.15, 0.9)
@export var border_color: Color = Color(0.9, 0.7, 1.0, 0.9)
@export var phase_colors: Array[Color] = [
	Color(1.0, 0.3, 0.3, 1.0),  # Phase 1 - Red
	Color(1.0, 0.5, 0.1, 1.0),  # Phase 2 - Orange
	Color(1.0, 0.8, 0.1, 1.0),  # Phase 3 - Yellow
	Color(0.5, 1.0, 0.3, 1.0),  # Phase 4 - Green
]

var _boss: Node = null
var _max_hp: int = 0
var _current_hp: int = 0
var _current_phase: int = 1
var _total_phases: int = 1
var _boss_name: String = ""

@onready var _name_label: Label = $NameLabel

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(144, 14)

func _process(_delta: float) -> void:
	if _boss and is_instance_valid(_boss):
		if _boss.has_method("get") or "hp" in _boss:
			var new_hp = _boss.hp if "hp" in _boss else _boss.get("hp")
			if new_hp != _current_hp:
				_current_hp = new_hp
				queue_redraw()
	else:
		if visible:
			hide_boss_health()

func _draw() -> void:
	if not visible or _max_hp <= 0:
		return
	
	# Draw background
	var rect = Rect2(Vector2.ZERO, size)
	draw_rect(rect, bg_color)
	
	# Draw border
	draw_rect(rect, border_color, false, 2.0)
	
	# Calculate health bar area (below the name label)
	var bar_start_y = 7.0
	var bar_width = size.x - (bar_padding * 2)
	var bar_rect = Rect2(
		Vector2(bar_padding, bar_start_y),
		Vector2(bar_width, bar_height)
	)
	
	# Draw health bar background
	draw_rect(bar_rect, Color(0.2, 0.2, 0.25, 1.0))
	
	# Calculate health per phase
	var hp_per_phase = float(_max_hp) / float(_total_phases)
	var segment_width = bar_width / float(_total_phases)
	
	# Draw each phase segment
	for phase in range(_total_phases):
		var phase_start_hp = phase * hp_per_phase
		
		# Calculate how much of this phase is filled
		var fill_amount = 0.0
		if _current_hp > phase_start_hp:
			var hp_in_phase = min(_current_hp - phase_start_hp, hp_per_phase)
			fill_amount = hp_in_phase / hp_per_phase
		
		if fill_amount > 0.0:
			var segment_x = bar_padding + (segment_width * phase)
			var segment_fill_width = (segment_width - phase_gap) * fill_amount
			
			var segment_rect = Rect2(
				Vector2(segment_x, bar_start_y),
				Vector2(segment_fill_width, bar_height)
			)
			
			# Get color for this phase
			var color_idx = (_total_phases - 1 - phase) % phase_colors.size()
			var phase_color = phase_colors[color_idx]
			
			# Add pulsing effect for current phase
			if phase == (_total_phases - _current_phase):
				var pulse = (sin(Time.get_ticks_msec() * 0.005) * 0.15) + 0.85
				phase_color = phase_color * pulse
			
			draw_rect(segment_rect, phase_color)
	
	# Draw phase separators
	for i in range(1, _total_phases):
		var sep_x = bar_padding + (segment_width * i)
		draw_line(
			Vector2(sep_x - 1, bar_start_y),
			Vector2(sep_x - 1, bar_start_y + bar_height),
			Color(0.1, 0.1, 0.15, 1.0),
			phase_gap
		)

func show_boss_health(boss: Node) -> void:
	"""Display health bar for a boss"""
	_boss = boss
	
	if not boss or not is_instance_valid(boss):
		return
	
	# Get boss properties
	_max_hp = boss.max_hp if "max_hp" in boss else 100
	_current_hp = boss.hp if "hp" in boss else _max_hp
	_current_phase = boss.current_phase if "current_phase" in boss else 1
	_total_phases = boss.phases_total if "phases_total" in boss else 1
	_boss_name = str(boss.name) if boss.name != "" else "BOSS"
	
	# Update name label
	if _name_label:
		_name_label.text = _boss_name.to_upper()
	
	# Connect to boss signals
	if boss.has_signal("phase_changed"):
		if not boss.is_connected("phase_changed", _on_boss_phase_changed):
			boss.phase_changed.connect(_on_boss_phase_changed)
	
	if boss.has_signal("defeated"):
		if not boss.is_connected("defeated", _on_boss_defeated):
			boss.defeated.connect(_on_boss_defeated)
	
	# Show with animation
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	queue_redraw()

func hide_boss_health() -> void:
	"""Hide the boss health bar"""
	if not visible:
		return
	
	# Disconnect signals if boss is valid
	if _boss and is_instance_valid(_boss):
		if _boss.has_signal("phase_changed") and _boss.is_connected("phase_changed", _on_boss_phase_changed):
			_boss.phase_changed.disconnect(_on_boss_phase_changed)
		if _boss.has_signal("defeated") and _boss.is_connected("defeated", _on_boss_defeated):
			_boss.defeated.disconnect(_on_boss_defeated)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	_boss = null

func _on_boss_phase_changed(new_phase: int) -> void:
	"""Handle boss phase change"""
	_current_phase = new_phase
	
	# Optionally recalculate max HP if boss adjusts it per phase
	if _boss and is_instance_valid(_boss):
		_current_hp = _boss.hp if "hp" in _boss else _current_hp
	
	queue_redraw()

func _on_boss_defeated() -> void:
	"""Handle boss defeat"""
	hide_boss_health()

func update_health(current: int, maximum: int) -> void:
	"""Manually update health values (alternative to auto-tracking)"""
	_current_hp = current
	_max_hp = maximum
	queue_redraw()

