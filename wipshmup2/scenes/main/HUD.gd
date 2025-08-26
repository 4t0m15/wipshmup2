extends CanvasLayer

var _accum_time_s: float = 0.0
var _accum_ticks: int = 0

@onready var _score_label: Label = $TopBar/HBox/ScoreLabel
@onready var _lives_label: Label = $TopBar/HBox/LivesLabel
@onready var _tps_label: Label = $TopBar/HBox/TPSLabel
@onready var _bombs_label: Label = $TopBar/HBox/BombsLabel
@onready var _medal_label: Label = $TopBar/HBox/MedalLabel
@onready var _overlay_dim: ColorRect = $CenterOverlay/OverlayDim
@onready var _msg_panel: PanelContainer = $CenterOverlay/MessagePanel
@onready var _msg_label: Label = $CenterOverlay/MessagePanel/VBox/MessageLabel
@onready var _hint_label: Label = $CenterOverlay/MessagePanel/VBox/HintLabel

func _ready() -> void:
	var tm := get_node_or_null("/root/TickManager")
	if tm and tm.has_signal("tick"):
		tm.tick.connect(_on_tick)

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

func set_bombs(value: int, shards: int = -1) -> void:
	var text := "Bombs: %d" % max(0, value)
	if shards >= 0:
		text += " (%d/40)" % shards
	_bombs_label.text = text

func set_medal_value(value: int) -> void:
	_medal_label.text = "Medal: %d" % max(0, value)

func _on_tick(dt: float) -> void:
	_accum_time_s += dt
	_accum_ticks += 1
	if _accum_time_s >= 1.0:
		var tps: float = float(_accum_ticks) / _accum_time_s
		_tps_label.text = "TPS: %d" % int(round(tps))
		_accum_time_s = 0.0
		_accum_ticks = 0


