extends Control

@export var graph_width: int = 180
@export var graph_height: int = 14
@export var max_samples: int = 240
@export var margin_right_px: int = 4
@export var margin_bottom_px: int = 4
@export var background_color: Color = Color(0.08, 0.04, 0.12, 0.75)
@export var border_color: Color = Color(0.9, 0.7, 1.0, 0.9)
@export var line_color: Color = Color(0.6, 1.0, 0.6, 0.95)
@export var target_60ms_color: Color = Color(1.0, 0.95, 0.6, 0.8)
@export var target_120ms_color: Color = Color(0.6, 0.9, 1.0, 0.6)

var _frame_times_ms: PackedFloat32Array = PackedFloat32Array()
var _max_display_ms: float = 33.33  # Clamp graph to ~30 FPS max for clarity

func _ready() -> void:
    # Size and anchoring for bottom-right placement
    size = Vector2(graph_width, graph_height)
    set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    # Place with negative offsets from the bottom-right corner
    offset_right = -float(margin_right_px)
    offset_bottom = -float(margin_bottom_px)
    offset_left = offset_right - graph_width
    offset_top = offset_bottom - graph_height
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
    # Collect frametime in milliseconds
    var ms: float = max(0.0, delta * 1000.0)
    _frame_times_ms.append(ms)
    if _frame_times_ms.size() > max_samples:
        _frame_times_ms.remove_at(0)

    # Adaptively scale up to a ceiling for readability
    var local_max: float = 0.0
    for v in _frame_times_ms:
        if v > local_max:
            local_max = v
    _max_display_ms = clamp(max(local_max, 16.67), 16.67, 50.0)

    queue_redraw()

func _draw() -> void:
    # Background panel
    var rect := Rect2(Vector2.ZERO, size)
    draw_rect(rect, background_color)
    draw_rect(rect, border_color, false, 1.0)

    if _frame_times_ms.is_empty():
        return

    # Guide lines: 60 FPS (16.67ms) and 120 FPS (8.33ms)
    var y60: float = _ms_to_y(16.67)
    var y120: float = _ms_to_y(8.33)
    draw_line(Vector2(1, y60), Vector2(size.x - 1, y60), target_60ms_color, 1.0)
    draw_line(Vector2(1, y120), Vector2(size.x - 1, y120), target_120ms_color, 1.0)

    # Plot frametimes from right to left for a trailing graph
    var available_w: int = int(size.x) - 2
    var count: int = min(_frame_times_ms.size(), available_w)
    var x: int = int(size.x) - 2
    var last_point: Vector2 = Vector2(x, _ms_to_y(_frame_times_ms[_frame_times_ms.size() - 1]))
    for i in range(count):
        var idx: int = _frame_times_ms.size() - 1 - i
        if idx < 0:
            break
        var y: float = _ms_to_y(_frame_times_ms[idx])
        var p := Vector2(x - i, y)
        if i > 0:
            draw_line(last_point, p, line_color, 1.0)
        last_point = p

func _ms_to_y(ms: float) -> float:
    # Map milliseconds to vertical pixel coordinate (lower ms -> nearer top)
    var clamped_ms: float = clamp(ms, 0.0, _max_display_ms)
    var t: float = clamped_ms / _max_display_ms
    return lerp(2.0, size.y - 2.0, t)

func configure_layout_top_right(new_width: int, new_height: int, top_y: float, right_margin: int) -> void:
    # Reconfigure size and anchor to top-right with specified top y and right margin
    graph_width = new_width
    graph_height = new_height
    size = Vector2(graph_width, graph_height)
    set_anchors_preset(Control.PRESET_TOP_RIGHT)
    offset_right = -float(max(0, right_margin))
    offset_top = max(0.0, top_y)
    offset_left = offset_right - graph_width
    offset_bottom = offset_top + graph_height


