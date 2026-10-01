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

func _init():
	informs_input = true

func create_logic():
	sim_queue = SimulationQueue.new()

func _ready():
	super._ready()
	_update_node_label()

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
		info_window.update_stats(sim_queue.get_count(), peak_count, total_enqueued, total_dequeued, sim_queue._items)
	elif info_window and info_window.has_node("Label"):
		info_window.get_node("Label").text = "Queue length: " + str(sim_queue.get_count())

func on_input_ready(other_node: SimGraphNode, other_port: int, own_port : int):
	var item : SimulationItem = other_node.take_output(other_port)
	if item == null:
		return
	sim_queue.push(item)
	total_enqueued += 1
	peak_count = max(peak_count, sim_queue.get_count())
	_update_info_ui()
	output_ready[0].emit(self, 0)
	input_ready[0].emit(self, 0)
	
func on_output_ready(other_node: SimGraphNode, other_port: int, own_port : int):
	if (!sim_queue._items.is_empty()):
		output_ready[0].emit(self, 0)

func take_output( port: int) -> Variant:
	var item = sim_queue.pop()
	if item != null:
		total_dequeued += 1
	_update_info_ui()
	return item

func reset():
	sim_queue.reset()
	peak_count = 0
	total_enqueued = 0
	total_dequeued = 0
	_update_info_ui()
