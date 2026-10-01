extends Control

var processed_data: Array = []
var raw_values: Array = []
var min_val: float = 0.0
var max_val: float = 0.0
var mean_val: float = 0.0

@onready var count_label: Label = get_node_or_null("../../SummaryCard/GridContainer/CountValue")
@onready var mean_label: Label = get_node_or_null("../../SummaryCard/GridContainer/MeanValue")
@onready var min_label: Label = get_node_or_null("../../SummaryCard/GridContainer/MinValue")
@onready var max_label: Label = get_node_or_null("../../SummaryCard/GridContainer/MaxValue")

func _ready() -> void:
	pass

func prepare_histogram_data(values: Array, bin_count: int) -> void:
	raw_values = values
	var bins: Array = []
	bins.resize(bin_count)
	bins.fill(0)
	
	if values.is_empty():
		processed_data = []
		min_val = 0.0
		max_val = 0.0
		mean_val = 0.0
		_update_summary_labels(0, 0.0, 0.0, 0.0)
		queue_redraw()
		return

	min_val = float(values.min())
	max_val = float(values.max())
	var sum: float = 0.0
	for v in values:
		sum += float(v)
	mean_val = sum / float(values.size())
	
	_update_summary_labels(values.size(), mean_val, min_val, max_val)

	var value_range := max_val - min_val

	if value_range == 0:
		bins[0] = values.size()
		processed_data = bins
		queue_redraw()
		return

	for val in values:
		var bin_idx: int = int((float(val) - min_val) / value_range * float(bin_count))
		bin_idx = clamp(bin_idx, 0, bin_count - 1)
		bins[bin_idx] += 1
		
	processed_data = bins
	queue_redraw()

func _update_summary_labels(count: int, mean: float, mn: float, mx: float) -> void:
	if count_label:
		count_label.text = "%d items" % count
	if mean_label:
		mean_label.text = "%.3f s" % mean
	if min_label:
		min_label.text = "%.3f s" % mn
	if max_label:
		max_label.text = "%.3f s" % mx

func _draw() -> void:
	var total_width := size.x
	var total_height := size.y
	if total_width <= 20 or total_height <= 20:
		return
		
	# Draw chart background
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.96, 0.97, 0.98, 0.9), true)
	draw_rect(bg_rect, Color(0.78, 0.81, 0.86, 1.0), false, 1.0)
	
	# Chart margins
	var pad_left := 32.0
	var pad_right := 16.0
	var pad_top := 18.0
	var pad_bottom := 28.0
	var plot_w := total_width - pad_left - pad_right
	var plot_h := total_height - pad_top - pad_bottom
	
	var baseline_y := pad_top + plot_h
	
	# Axes
	var axis_col := Color(0.55, 0.6, 0.68, 1.0)
	draw_line(Vector2(pad_left, pad_top), Vector2(pad_left, baseline_y), axis_col, 1.5)
	draw_line(Vector2(pad_left, baseline_y), Vector2(pad_left + plot_w, baseline_y), axis_col, 1.5)

	if processed_data.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(total_width * 0.5 - 60, total_height * 0.5), "No data recorded yet", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, Color(0.5, 0.55, 0.6))
		return
		
	var max_freq: int = processed_data.max()
	if max_freq <= 0:
		return

	# Draw horizontal grid line at max
	draw_line(Vector2(pad_left, pad_top), Vector2(pad_left + plot_w, pad_top), Color(0.85, 0.88, 0.92, 1.0), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(4, pad_top + 10), str(max_freq), HORIZONTAL_ALIGNMENT_RIGHT, pad_left - 8, 10, Color(0.45, 0.5, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(4, baseline_y), "0", HORIZONTAL_ALIGNMENT_RIGHT, pad_left - 8, 10, Color(0.45, 0.5, 0.55))

	var bar_count := processed_data.size()
	var bin_width := plot_w / float(bar_count)
	var spacing := 3.0
	
	var bar_fill := Color(0.22, 0.54, 0.88, 0.85)
	var bar_border := Color(0.14, 0.42, 0.74, 1.0)

	for i in range(bar_count):
		var freq: int = processed_data[i]
		if freq == 0:
			continue
		var bar_height := (float(freq) / float(max_freq)) * plot_h
		var bar_rect := Rect2(
			pad_left + i * bin_width + spacing * 0.5,
			baseline_y - bar_height,
			max(1.0, bin_width - spacing),
			bar_height
		)
		draw_rect(bar_rect, bar_fill, true)
		draw_rect(bar_rect, bar_border, false, 1.0)

	# X axis range labels
	draw_string(ThemeDB.fallback_font, Vector2(pad_left, baseline_y + 16), "%.1fs" % min_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.35, 0.4, 0.45))
	draw_string(ThemeDB.fallback_font, Vector2(pad_left + plot_w - 50, baseline_y + 16), "%.1fs" % max_val, HORIZONTAL_ALIGNMENT_RIGHT, 50, 10, Color(0.35, 0.4, 0.45))
	
	# Mean indicator line
	if max_val > min_val:
		var mean_x := pad_left + ((mean_val - min_val) / (max_val - min_val)) * plot_w
		draw_line(Vector2(mean_x, pad_top), Vector2(mean_x, baseline_y), Color(0.9, 0.35, 0.2, 0.9), 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(mean_x - 20, baseline_y + 24), "μ: %.1fs" % mean_val, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.85, 0.3, 0.15))
