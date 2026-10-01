extends Node2D

# --- Plot styling ---
@export_group("Line Style")
@export var line_width: float = 3.0
@export var line_color: Color = Color(0, 0, 0, 1)

@export_group("Point Style")
@export var show_points: bool = true
@export var point_radius: float = 7.0
@export var point_color: Color = Color(0.85, 0.22, 0.18, 1.0)
@export var point_outline: bool = true
@export var point_outline_color: Color = Color(0.15, 0.15, 0.15, 1.0)
@export var point_outline_width: float = 1.5

@export_group("Coordinate Axes")
@export var show_axes: bool = true
@export var axis_color: Color = Color(0.3, 0.3, 0.3, 1.0)
@export var axis_width: float = 2.0
@export var arrow_size: float = 8.0
@export var show_ticks: bool = true
@export var tick_size: float = 6.0

@export_group("Axis Values & Grid")
@export var show_axis_values: bool = true
@export var value_font_size: int = 18
@export var value_color: Color = Color(0.25, 0.25, 0.25, 1.0)
@export var y_ticks_count: int = 4
@export var show_grid: bool = true
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.12)
@export var custom_font: Font = null
@export var hide_legacy_labels: bool = true

@export_group("Margins")
@export var margin_left: float = 80.0
@export var margin_right: float = 50.0
@export var margin_top: float = 40.0
@export var margin_bottom: float = 65.0

@onready var line: Line2D = $PlotLine2D
@onready var max_label: Label = $MaxLabel
@onready var min_label: Label = $MinLabel

var _points: PackedVector2Array = []
var _x_values: Array = []
var _data_min: float = 0.0
var _data_max: float = 0.0
var _has_data: bool = false

func _ready() -> void:
	if line:
		line.width = line_width
		line.default_color = line_color
		line.show_behind_parent = true
	if hide_legacy_labels:
		if max_label:
			max_label.visible = false
		if min_label:
			min_label.visible = false
	queue_redraw()

func _draw() -> void:
	if show_axes:
		_draw_axes()
	if show_points and not _points.is_empty():
		_draw_data_points()

func _draw_axes() -> void:
	var bounds = _get_plot_bounds()
	var origin: Vector2 = bounds.origin
	var x_end: Vector2 = bounds.x_end
	var y_end: Vector2 = bounds.y_end
	var font: Font = custom_font if custom_font else ThemeDB.fallback_font

	# X-axis line with arrow
	var x_target = x_end + Vector2(arrow_size * 2.0, 0.0)
	_draw_arrow(origin, x_target, arrow_size, axis_color)

	# Y-axis line with arrow
	var y_target = y_end - Vector2(0.0, arrow_size * 2.0)
	_draw_arrow(origin, y_target, arrow_size, axis_color)

	if not show_ticks:
		return

	# --- Y-axis ticks and values ---
	if _has_data and _data_max > _data_min:
		var count = max(2, y_ticks_count)
		for k in range(count):
			var frac = float(k) / float(count - 1)
			var y = origin.y - frac * bounds.height
			var val = _data_min + frac * (_data_max - _data_min)

			# Tick mark to the left
			draw_line(Vector2(origin.x - tick_size, y), Vector2(origin.x, y), axis_color, 1.5)

			# Subtle horizontal grid line
			if show_grid and frac > 0.0:
				draw_line(Vector2(origin.x, y), Vector2(x_end.x, y), grid_color, 1.0)

			# Numerical value
			if show_axis_values and font:
				var txt = "%0.1f" % val if (_data_max - _data_min) < 50.0 else "%0.0f" % val
				var str_sz = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, value_font_size)
				var pos = Vector2(origin.x - tick_size - 4.0 - str_sz.x, y + str_sz.y * 0.35)
				draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, value_font_size, value_color)
	else:
		# Fallback before data
		draw_line(Vector2(origin.x - tick_size, origin.y), Vector2(origin.x, origin.y), axis_color, 1.5)
		draw_line(Vector2(origin.x - tick_size, y_end.y), Vector2(origin.x, y_end.y), axis_color, 1.5)

	# --- X-axis ticks and values ---
	var total_pts = _points.size()
	if total_pts > 0:
		var step = 1
		if total_pts > 12:
			step = 2
		if total_pts > 24:
			step = 5

		for i in range(total_pts):
			var pt = _points[i]
			# Tick mark pointing downward
			draw_line(Vector2(pt.x, origin.y), Vector2(pt.x, origin.y + tick_size), axis_color, 1.5)

			# Value text below tick
			var should_label = (i % step == 0) or (i == total_pts - 1)
			if show_axis_values and font and should_label:
				var val_str = str(_x_values[i]) if i < _x_values.size() else str(i + 1)
				var str_sz = font.get_string_size(val_str, HORIZONTAL_ALIGNMENT_LEFT, -1, value_font_size)
				var pos = Vector2(pt.x - str_sz.x * 0.5, origin.y + tick_size + str_sz.y + 2.0)
				draw_string(font, pos, val_str, HORIZONTAL_ALIGNMENT_LEFT, -1, value_font_size, value_color)

func _draw_arrow(from: Vector2, to: Vector2, size: float, color: Color) -> void:
	var dir = (to - from).normalized()
	if dir == Vector2.ZERO:
		return
	var normal = Vector2(-dir.y, dir.x)
	var tip = to
	var left = to - dir * size + normal * (size * 0.5)
	var right = to - dir * size - normal * (size * 0.5)
	
	draw_line(from, to - dir * (size * 0.5), color, axis_width)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)

func _draw_data_points() -> void:
	for pt in _points:
		draw_circle(pt, point_radius, point_color)
		if point_outline:
			draw_arc(pt, point_radius, 0.0, TAU, 32, point_outline_color, point_outline_width, true)

func _get_plot_bounds() -> Dictionary:
	var viewport_size = get_viewport_rect().size
	var plot_h = viewport_size.y
	# Use full remaining width to the right edge of the window
	var available_w = max(400.0, viewport_size.x - global_position.x)
	var origin_x = margin_left
	var origin_y = plot_h - margin_bottom
	var end_x = available_w - margin_right
	var end_y = margin_top
	return {
		"origin": Vector2(origin_x, origin_y),
		"x_end": Vector2(end_x, origin_y),
		"y_end": Vector2(origin_x, end_y),
		"width": end_x - origin_x,
		"height": origin_y - end_y
	}

func clear() -> void:
	if line:
		line.points = PackedVector2Array()
	_points.clear()
	_x_values.clear()
	_has_data = false
	queue_redraw()

func plot(y_values: Array, x_step := -1.0, x_values: Array = []):
	if y_values.is_empty():
		clear()
		return

	if line:
		line.width = line_width
		line.default_color = line_color
		line.show_behind_parent = true

	var bounds = _get_plot_bounds()
	var plot_width = bounds.width
	var plot_height = bounds.height

	# 1. Compute Data Bounds
	var data_max = y_values.max()
	var data_min = y_values.min()
	var data_range = data_max - data_min

	if max_label:
		max_label.text = "Max: %0.2f" % data_max
	if min_label:
		min_label.text = "Min: %0.2f" % data_min

	# Avoid division by zero if all values are the same
	if data_range == 0:
		data_range = 1.0

	# 2. Compute Scaling Factors
	var actual_x_step = x_step
	if x_step <= 0:
		actual_x_step = plot_width / max(1, y_values.size() - 1)

	var y_scale = plot_height / data_range

	# 3. Build Points
	var pts: PackedVector2Array = []
	pts.resize(y_values.size())

	for i in y_values.size():
		var x = bounds.origin.x + i * actual_x_step
		var val_normalized = (y_values[i] - data_min) * y_scale
		var y = bounds.origin.y - val_normalized
		pts[i] = Vector2(x, y)

	line.points = pts
	_points = pts
	_x_values = x_values.duplicate()
	_data_min = data_min
	_data_max = data_max
	_has_data = true
	queue_redraw()
