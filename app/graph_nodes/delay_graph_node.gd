# delay
extends SimGraphNode

func get_node_type_name() -> String:
	return "Delay (Server)"

func _init():
	informs_input = true

var waiting = false
var item : SimulationItem

var total_processed: int = 0
var total_busy_time: float = 0.0
var total_service_time: float = 0.0
var current_service_start_time: float = -1.0
var current_service_duration: float = 0.0
var total_blocked_time: float = 0.0
var blocked_start_time: float = -1.0

var cb_other_node
var cb_other_port

class InputCheck extends SimulationEntity:
	var available := false

	func set_available(a):
		available = a
		state_changed.emit()

var input_check := InputCheck.new()

func _get_sim_time() -> float:
	if not is_inside_tree():
		return 0.0
	var tree := get_tree()
	if tree and tree.root:
		var sim = tree.root.find_child("SimulationManager", true, false)
		if sim and ("sim_clock" in sim):
			return sim.sim_clock
	return 0.0

func _get_dist_container():
	if info_window:
		return info_window.find_child("DistributionGridContainer", true, false)
	return null

func get_utilisation() -> float:
	var sim_time = _get_sim_time()
	if sim_time <= 0.0:
		return 0.0
	var busy = total_busy_time
	if waiting and current_service_start_time >= 0.0:
		busy += max(0.0, sim_time - current_service_start_time)
	return clampf((busy / sim_time) * 100.0, 0.0, 100.0)

func get_average_service_time() -> float:
	if total_processed > 0:
		return total_service_time / float(total_processed)
	return 0.0

func get_status_text() -> String:
	if waiting:
		return "Busy (Processing #%s)" % (str(item.sim_id) if item else "?")
	elif item != null:
		return "Blocked (Output Ready)"
	else:
		return "Idle"

func _update_info_ui() -> void:
	if info_window and info_window.has_method("update_stats"):
		info_window.update_stats(
			get_status_text(),
			get_utilisation(),
			total_processed,
			get_average_service_time()
		)

func _on_info_button_pressed() -> void:
	super._on_info_button_pressed()
	_update_info_ui()

func on_input_ready(other_node: SimGraphNode, other_port: int, _own_port: int):
	cb_other_node = other_node
	cb_other_port = other_port
	if resource_node:
		if not waiting and item == null:
			input_check.set_available(true)
	else:
		take_and_delay(other_node, other_port)

func take_resource():
	if not waiting and item == null and cb_other_node != null:
		input_check.set_available(false)
		resource_node.aquire(input_check)
		take_and_delay(cb_other_node, cb_other_port)
		if item == null:
			resource_node.release(self)

func get_duration(for_item: SimulationItem) -> float:
	var td : TimeDistribution
	if decide_node:
		td = decide_node.decide_on(for_item)
	else:
		var dist = _get_dist_container()
		if dist and ("time_distribution" in dist):
			td = dist.time_distribution
	if td:
		return td.get_interval()
	return 1.0

func _ready():
	super._ready()
	if has_node("Label"):
		$Label.text = "Status: Idle"

func take_and_delay(other_node: SimGraphNode, other_port: int):
	if (!waiting and item == null):
		item = other_node.take_output(other_port)
		if item == null:
			return
		if has_node("Label"):
			$Label.text = "Processing #%s" % item.sim_id
		if has_node("DecideLabel"):
			var t_str = item.properties.get("type", "")
			$DecideLabel.text = "Type: " + t_str if t_str != "" else ""
		waiting = true
		var sim = get_node("../../SimulationManager")
		var duration = get_duration(item)
		current_service_duration = duration
		current_service_start_time = _get_sim_time()
		sim.schedule_event(duration, next_time.bind(other_port))
		_update_info_ui()
	else:
		if has_node("Label"):
			$Label.text = "Waiting..."

func next_time(_port: int):
	waiting = false
	total_processed += 1
	total_busy_time += current_service_duration
	total_service_time += current_service_duration
	current_service_start_time = -1.0
	blocked_start_time = _get_sim_time()
	if resource_node:
		resource_node.release(self)
	output_ready[0].emit(self, 0)
	_update_info_ui()

func take_output(_port: int) -> Variant:
	input_check.set_available(false)
	if blocked_start_time >= 0.0:
		total_blocked_time += max(0.0, _get_sim_time() - blocked_start_time)
		blocked_start_time = -1.0
	var delivery_item = item
	item = null
	if has_node("Label"):
		$Label.text = "Status: Idle"
	if has_node("DecideLabel"):
		$DecideLabel.text = ""
	input_ready[0].emit(self, 0)
	_update_info_ui()
	return delivery_item
	
func reset():
	waiting = false
	item = null
	cb_other_node = null
	input_check.set_available(false)
	if resource_node:
		resource_node.release(self)
	if decide_node:
		decide_node.reset()
	if has_node("Label"):
		$Label.text = "Status: Idle"
	if has_node("DecideLabel"):
		$DecideLabel.text = ""
	if has_node("ResourceLabel"):
		$ResourceLabel.text = ""
	total_processed = 0
	total_busy_time = 0.0
	total_service_time = 0.0
	current_service_start_time = -1.0
	current_service_duration = 0.0
	total_blocked_time = 0.0
	blocked_start_time = -1.0
	_update_info_ui()

# decide node connections
var decide_node = null

func attach_decide(dec):
	decide_node = dec
	
func detach_decide(_dec):
	decide_node = null

# resource node connections
var resource_node = null

func attach_resource(res):
	resource_node = res
	resource_node.set_callback(take_resource, input_check)

func detach_resource(_dec):
	resource_node = null
	
### serialize stuff
func get_save_data() -> Variant:
	var dist = _get_dist_container()
	if dist and dist.has_method("get_save_data"):
		return dist.get_save_data()
	return {}
	
func set_load_data(data: Variant):
	var dist = _get_dist_container()
	if dist and dist.has_method("set_load_data"):
		dist.set_load_data(data)
