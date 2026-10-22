# queue graph node
#class_name QueueGraphNode
extends SimGraphNode

func get_node_type_name() -> String:
	return "Queue (Buffer)"

### logic	
var sim_queue : SimulationQueue
var output_free = true
var peak_count: int = 0
var total_enqueued: int = 0
var total_dequeued: int = 0
var accumulated_wait_time: float = 0.0
var last_event_time: float = 0.0
var total_wait_duration: float = 0.0
var item_entry_times: Dictionary = {}

func _init():
	informs_input = true

func create_logic():
	sim_queue = SimulationQueue.new()

func _ready():
	super._ready()
	_update_node_label()

func _get_sim_time() -> float:
	if not is_inside_tree():
		return 0.0
	var tree := get_tree()
	if tree and tree.root:
		var sim = tree.root.find_child("SimulationManager", true, false)
		if sim and ("sim_clock" in sim):
			return sim.sim_clock
	return 0.0

func _update_accumulated_wait_time() -> void:
	var current_time = _get_sim_time()
	var count = sim_queue.get_count() if sim_queue else 0
	if current_time > last_event_time:
		accumulated_wait_time += float(count) * (current_time - last_event_time)
		last_event_time = current_time

func get_average_queue_length() -> float:
	_update_accumulated_wait_time()
	var current_time = _get_sim_time()
	if current_time > 0.0:
		return accumulated_wait_time / current_time
	return 0.0

func get_average_waiting_time() -> float:
	if total_dequeued > 0:
		return total_wait_duration / float(total_dequeued)
	return 0.0

func _update_node_label():
	if has_node("Label"):
		var count = sim_queue.get_count() if sim_queue else 0
		if count > 0:
			$Label.text = "Buffer: %d items" % count
		else:
			$Label.text = "Buffer: Empty"

func _update_info_ui():
	_update_node_label()
	if info_window and info_window.has_method("update_stats"):
		info_window.update_stats(sim_queue.get_count(), peak_count, total_enqueued, total_dequeued, sim_queue._items, get_average_queue_length(), get_average_waiting_time())
	elif info_window and info_window.has_node("Label"):
		info_window.get_node("Label").text = "Queue length: " + str(sim_queue.get_count())

func _on_info_button_pressed():
	super._on_info_button_pressed()
	_update_info_ui()

func on_input_ready(other_node: SimGraphNode, other_port: int, _own_port : int):
	var item : SimulationItem = other_node.take_output(other_port)
	if item == null:
		return
	_update_accumulated_wait_time()
	item_entry_times[item] = _get_sim_time()
	sim_queue.push(item)
	total_enqueued += 1
	peak_count = max(peak_count, sim_queue.get_count())
	_update_info_ui()
	output_ready[0].emit(self, 0)
	input_ready[0].emit(self, 0)
	
func on_output_ready(_other_node: SimGraphNode, _other_port: int, _own_port : int):
	if (!sim_queue._items.is_empty()):
		output_ready[0].emit(self, 0)

func take_output(_port: int) -> Variant:
	_update_accumulated_wait_time()
	var item = sim_queue.pop()
	if item != null:
		total_dequeued += 1
		var entry_t: float = item_entry_times.get(item, _get_sim_time())
		item_entry_times.erase(item)
		total_wait_duration += max(0.0, _get_sim_time() - entry_t)
	_update_info_ui()
	return item

func reset():
	sim_queue.reset()
	peak_count = 0
	total_enqueued = 0
	total_dequeued = 0
	accumulated_wait_time = 0.0
	last_event_time = 0.0
	total_wait_duration = 0.0
	item_entry_times.clear()
	_update_info_ui()
