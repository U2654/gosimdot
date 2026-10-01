# delay
extends SimGraphNode

func get_node_type_name() -> String:
	return "Delay (Server)"

func _init():
	informs_input = true

var waiting = false
var item : SimulationItem

var cb_other_node
var cb_other_port

class InputCheck extends SimulationEntity:
	var available := false

	func set_available(a):
		available = a
		state_changed.emit()

var input_check := InputCheck.new()

func on_input_ready(other_node: SimGraphNode, other_port: int, own_port: int):
	cb_other_node = other_node
	cb_other_port = other_port
	if resource_node:
		if not waiting and item == null:
			input_check.set_available(true)
	else:
		take_and_delay(other_node, other_port)

func take_resource():
	if not waiting and item == null and cb_other_node != null:
		resource_node.aquire(input_check)
		take_and_delay(cb_other_node, cb_other_port)

func get_duration(item: SimulationItem) -> float:
	var td : TimeDistribution
	if decide_node:
		td = decide_node.decide_on(item)
	else:
		td = info_window.get_node("DistributionGridContainer").time_distribution
	return td.get_interval()

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
		sim.schedule_event(duration, next_time.bind(other_port))
	else:
		if has_node("Label"):
			$Label.text = "Waiting..."

func next_time(port: int):
	waiting = false
	if resource_node:
		resource_node.release(self)
	output_ready[0].emit(self, 0)

func take_output(_port: int) -> Variant:
	input_check.set_available(false)
	var delivery_item = item
	item = null
	if has_node("Label"):
		$Label.text = "Status: Idle"
	if has_node("DecideLabel"):
		$DecideLabel.text = ""
	input_ready[0].emit(self, 0)
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

# decide node connections
var decide_node = null

func attach_decide(dec):
	decide_node = dec
	
func detach_decide(dec):
	decide_node = null

# resource node connections
var resource_node = null

func attach_resource(res):
	resource_node = res
	resource_node.set_callback(take_resource, input_check)

func detach_resource(dec):
	resource_node = null
	
### serialize stuff
func get_save_data() -> Variant:
	return info_window.get_node("DistributionGridContainer").get_save_data()
	
func set_load_data(data: Variant):
	info_window.get_node("DistributionGridContainer").set_load_data(data)
