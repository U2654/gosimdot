extends SimGraphNode

func get_node_type_name() -> String:
	return "Sink (Collector)"

var durations = []

func _init():
	informs_input = true

func _ready():
	super._ready()
	if has_node("Label"):
		$Label.text = "Collected: 0"
	if has_node("ItemTypeLabel"):
		$ItemTypeLabel.text = "Ready"

func _update_info_ui():
	if not info_window:
		return
	var info_lbl = info_window.find_child("InfoLabel", true, false)
	if info_lbl:
		if durations.is_empty():
			info_lbl.text = "Ready to collect simulation data"
		else:
			info_lbl.text = "Item life time: %d items collected" % durations.size()
	var hist = info_window.find_child("Histogram", true, false)
	if hist:
		hist.prepare_histogram_data(durations, 16)
		hist.queue_redraw()

func _on_info_button_pressed():
	super._on_info_button_pressed()
	_update_info_ui()

func on_input_ready(other_node: SimGraphNode, other_port: int, _own_port: int):
	var item : SimulationItem = other_node.take_output(other_port)
	if item == null:
		return
	var sim := get_node("/root/Main/SimulationManager")
	var duration = sim.sim_clock - item.time_created 

	durations.append(duration)
	_update_info_ui()

	if has_node("Label"):
		$Label.text = "Collected: %d" % durations.size()
	if has_node("ItemTypeLabel"):
		var t_str = item.properties.get("type", "none")
		$ItemTypeLabel.text = "#%d (%s)" % [item.sim_id, t_str]
	input_ready[0].emit(self, 0)


func reset():
	durations.clear()
	if has_node("Label"):
		$Label.text = "Collected: 0"
	if has_node("ItemTypeLabel"):
		$ItemTypeLabel.text = "Ready"
	_update_info_ui()
