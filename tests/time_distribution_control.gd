extends Control

# This will hold our final "bar heights"
var processed_data: Array = []

func _ready() -> void:
	var randoms : Array[float] = []
	for i in range(1000):
		randoms.append(randf())
	save_floats_as_text("randoms.txt", randoms)
		
	var lambda: = 1.5
	var tde := TimeDistribution.Exponential.new(lambda)

	var tdu := TimeDistribution.Uniform.new(0.0, 1.0)

	var tdt := TimeDistribution.Triangular.new(0.0, 1.0, 0.5)

	var td := TimeDistribution.Normal.new(4, 2.5)


	# 1. Generate some dummy raw data (e.g., 1000 random scores)
	var raw_values = []
	for i in range(10000):
		# randfn creates a natural "bell curve" distribution
		raw_values.append(td.get_interval())
	
	# 2. Process that data into 15 bins (bars)
	processed_data = prepare_histogram_data(raw_values, 50)
	
	# 3. Tell Godot to trigger the _draw() function
	queue_redraw()

func prepare_histogram_data(values: Array, bin_count: int) -> Array:
	var bins = []
	bins.resize(bin_count)
	bins.fill(0)
	
	if values.is_empty():
		return bins

	var min_v = values.min()
	var max_v = values.max()
	var value_range = max_v - min_v

	# Handle case where all numbers are identical
	if value_range == 0:
		bins[0] = values.size()
		return bins

	for val in values:
		# Map the value to a bin index 0 to (bin_count - 1)
		var bin_idx = int((val - min_v) / value_range * bin_count)
		bin_idx = clamp(bin_idx, 0, bin_count - 1)
		bins[bin_idx] += 1
		
	return bins

func _draw() -> void:
	if processed_data.is_empty():
		return
		
	var spacing = 4.0
	var total_width = size.x
	var total_height = size.y
	
	var bar_width = total_width / processed_data.size()
	var max_freq = processed_data.max()

	for i in range(processed_data.size()):
		# Normalize height: (current_bin / max_bin) * UI_height
		var bar_height = (float(processed_data[i]) / max_freq) * total_height
		
		# Calculate the rectangle
		# X = index * width
		# Y = total_height - bar_height (to draw from bottom up)
		var rect = Rect2(
			i * bar_width, 
			total_height - bar_height, 
			bar_width - spacing, 
			bar_height
		)
		
		# Draw the bar
		draw_rect(rect, Color.BLUE)
		
		
func save_floats_as_text(path: String, float_list: Array[float]):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		# Option A: Save as a single JSON line (easiest for arrays)
		#file.store_line(JSON.stringify(float_list))
		
		# Option B: Save one number per line (if preferred)
		for f in float_list:
			file.store_line(str(f))
		
		file.close()
	else:
		print("Error opening file: ", FileAccess.get_open_error())
