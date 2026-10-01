class_name DistributionControl
extends Control

var propabilities_data = [
	{ "name": "Constant", "params": { "delay": 1.0 } },
	{ "name": "Exponential", "params": { "lambda": 0.1 } }, 
	{ "name": "Uniform", "params": { "min": 0.0, "max": 1.0 } },
	{ "name": "Triangular", "params": { "min": 0.0, "max": 1.0, "mode": 0.5 } },
	{ "name": "Normal", "params": { "mu": 0.5, "sigma": 0.5 } }
]

var time_distribution : TimeDistribution
var distribution_id = 0

@onready var option_button: OptionButton = $MarginContainer/VBoxContainer/ModelSection/DistributionOptionButton
@onready var param_container: VBoxContainer = $MarginContainer/VBoxContainer/ParamsPanel/DistributionVBoxContainer
@onready var mean_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/MeanLabel
@onready var preview_control: Control = $MarginContainer/VBoxContainer/PreviewPanel/DistributionPreview

func _ready() -> void:
	for item in propabilities_data:
		option_button.add_item(item["name"])
	option_button.item_selected.connect(_on_item_selected)
	
	if preview_control:
		preview_control.draw.connect(_on_preview_draw)
		
	_on_item_selected(0)

func _on_item_selected(index: int) -> void:
	distribution_id = index
	var distribution = propabilities_data[distribution_id]
	
	for child in param_container.get_children():
		child.queue_free()
	
	var params = distribution["params"]
	for param_name in params:
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.text = _get_param_display_name(param_name) + ":"
		label.custom_minimum_size.x = 110
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		
		var spin := SpinBox.new()
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_configure_spinbox(spin, param_name, float(params[param_name]))
		spin.value_changed.connect(_on_spin_changed.bind(param_name))
		
		var unit_label := Label.new()
		unit_label.text = "1/s" if param_name == "lambda" else "s"
		unit_label.custom_minimum_size.x = 24
		
		hbox.add_child(label)
		hbox.add_child(spin)
		hbox.add_child(unit_label)
		param_container.add_child(hbox)
		
	change_distribution()

func _get_param_display_name(key: String) -> String:
	match key:
		"delay": return "Delay (d)"
		"lambda": return "Rate (λ)"
		"min": return "Minimum (a)"
		"max": return "Maximum (b)"
		"mode": return "Mode (c)"
		"mu": return "Mean (μ)"
		"sigma": return "Std Dev (σ)"
		_: return key.capitalize()

func _configure_spinbox(spin: SpinBox, key: String, current_val: float) -> void:
	spin.step = 0.01
	spin.allow_greater = true
	spin.allow_lesser = false
	spin.min_value = 0.001 if (key == "lambda" or key == "sigma") else 0.0
	spin.max_value = 10000.0
	spin.value = current_val

func _on_spin_changed(val: float, key: String) -> void:
	var distribution = propabilities_data[distribution_id]
	distribution["params"][key] = val
	change_distribution()

func change_distribution() -> void:
	var distribution = propabilities_data[distribution_id]
	var params = distribution["params"]
	match distribution_id:
		0:
			time_distribution = TimeDistribution.Constant.new(params["delay"])
		1:
			var lam = max(0.0001, params["lambda"])
			time_distribution = TimeDistribution.Exponential.new(lam)
		2:
			var min_v = params["min"]
			var max_v = max(min_v + 0.001, params["max"])
			time_distribution = TimeDistribution.Uniform.new(min_v, max_v)
		3:
			var min_v = params["min"]
			var max_v = max(min_v + 0.001, params["max"])
			var mode_v = clamp(params["mode"], min_v, max_v)
			time_distribution = TimeDistribution.Triangular.new(min_v, max_v, mode_v)
		4:
			var sig = max(0.0001, params["sigma"])
			time_distribution = TimeDistribution.Normal.new(params["mu"], sig)
		_:
			pass
			
	_update_summary()
	if preview_control:
		preview_control.queue_redraw()

func _update_summary() -> void:
	if not mean_label:
		return
	var mean_val: float = _calculate_mean()
	mean_label.text = "Expected Mean: %.3f s" % mean_val

func _calculate_mean() -> float:
	var params = propabilities_data[distribution_id]["params"]
	match distribution_id:
		0: return float(params["delay"])
		1: return 1.0 / max(0.00001, float(params["lambda"]))
		2: return (float(params["min"]) + float(params["max"])) / 2.0
		3: return (float(params["min"]) + float(params["max"]) + float(params["mode"])) / 3.0
		4: return float(params["mu"])
		_: return 0.0

func _on_preview_draw() -> void:
	if not preview_control:
		return
	var w := preview_control.size.x
	var h := preview_control.size.y
	if w <= 10 or h <= 10:
		return
		
	# Draw background
	var bg_rect := Rect2(Vector2.ZERO, preview_control.size)
	preview_control.draw_rect(bg_rect, Color(0.95, 0.96, 0.98, 0.8), true)
	preview_control.draw_rect(bg_rect, Color(0.75, 0.78, 0.82, 1.0), false, 1.0)
	
	# Margins for axes
	var pad_left := 14.0
	var pad_right := 14.0
	var pad_top := 10.0
	var pad_bottom := 16.0
	var plot_w := w - pad_left - pad_right
	var plot_h := h - pad_top - pad_bottom
	
	# Draw baseline
	var baseline_y := pad_top + plot_h
	preview_control.draw_line(Vector2(pad_left, baseline_y), Vector2(pad_left + plot_w, baseline_y), Color(0.6, 0.65, 0.7), 1.0)
	preview_control.draw_line(Vector2(pad_left, pad_top), Vector2(pad_left, baseline_y), Color(0.6, 0.65, 0.7), 1.0)
	
	var curve_col := Color(0.18, 0.52, 0.88, 1.0)
	var fill_col := Color(0.18, 0.52, 0.88, 0.25)
	
	var params = propabilities_data[distribution_id]["params"]
	var points := PackedVector2Array()
	
	match distribution_id:
		0: # Constant: impulse bar
			var cx := pad_left + plot_w * 0.5
			preview_control.draw_line(Vector2(cx, baseline_y), Vector2(cx, pad_top + 4), curve_col, 3.0)
			preview_control.draw_circle(Vector2(cx, pad_top + 4), 4.0, curve_col)
		1: # Exponential: lambda * exp(-lambda * t)
			var steps := 40
			for s in range(steps + 1):
				var t_rel := float(s) / float(steps) # 0 to 1
				var y_rel := exp(-3.0 * t_rel) # decay curve
				var px := pad_left + t_rel * plot_w
				var py := baseline_y - y_rel * (plot_h - 4)
				points.append(Vector2(px, py))
		2: # Uniform: flat box
			var x1 := pad_left + plot_w * 0.2
			var x2 := pad_left + plot_w * 0.8
			var py := baseline_y - (plot_h * 0.7)
			points.append(Vector2(x1, baseline_y))
			points.append(Vector2(x1, py))
			points.append(Vector2(x2, py))
			points.append(Vector2(x2, baseline_y))
		3: # Triangular
			var a_x := pad_left + plot_w * 0.15
			var b_x := pad_left + plot_w * 0.85
			var c_ratio := 0.5
			var min_v: float = params["min"]
			var max_v: float = max(min_v + 0.001, params["max"])
			var mode_v: float = clamp(params["mode"], min_v, max_v)
			if max_v > min_v:
				c_ratio = clamp((mode_v - min_v) / (max_v - min_v), 0.05, 0.95)
			var c_x := a_x + (b_x - a_x) * c_ratio
			var peak_y := baseline_y - (plot_h * 0.85)
			points.append(Vector2(a_x, baseline_y))
			points.append(Vector2(c_x, peak_y))
			points.append(Vector2(b_x, baseline_y))
		4: # Normal
			var steps := 50
			for s in range(steps + 1):
				var norm_x := (float(s) / float(steps) - 0.5) * 6.0 # -3 to +3 std dev
				var norm_y := exp(-0.5 * norm_x * norm_x)
				var px := pad_left + (float(s) / float(steps)) * plot_w
				var py := baseline_y - norm_y * (plot_h * 0.85)
				points.append(Vector2(px, py))
				
	if points.size() > 1:
		# Draw filled polygon under curve
		var poly := PackedVector2Array(points)
		poly.append(Vector2(points[points.size() - 1].x, baseline_y))
		poly.append(Vector2(points[0].x, baseline_y))
		preview_control.draw_colored_polygon(poly, fill_col)
		preview_control.draw_polyline(points, curve_col, 2.0, true)

func get_save_data() -> Variant:
	var data = {}
	data["type"] = distribution_id
	var distribution = propabilities_data[distribution_id]
	var params = distribution["params"]
	for key in params:
		data[key] = params[key]
	return data
	
func set_load_data(data: Variant) -> void:
	if data == null or not (data is Dictionary) or not data.has("type"):
		return
	distribution_id = int(data["type"])
	if distribution_id < 0 or distribution_id >= propabilities_data.size():
		distribution_id = 0
	var distribution = propabilities_data[distribution_id]
	var params = distribution["params"]
	for key in params:
		if data.has(key):
			params[key] = data[key]
	if option_button:
		option_button.selected = distribution_id
	_on_item_selected(distribution_id)
