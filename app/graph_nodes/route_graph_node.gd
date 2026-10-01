# fork graph node
extends SimGraphNode

func get_node_type_name() -> String:
	return "Router"

var items : Array = [null, null, null, null]
var blocked : Array[bool] = [false, false, false, false]
@onready var labels := [$OutPort0Label, $OutPort1Label, $OutPort2Label, $OutPort3Label]

func _init():
	informs_input = true

func on_input_ready(other_node: SimGraphNode, other_port: int, own_port : int):
	# first check if we can take the item
	var can_take = false
	for i in range(blocked.size()):
		can_take = can_take or check_output(i)
		if not blocked[i]:
			labels[i].text = ""
	# take item if possible
	if can_take:
		var incoming_item = other_node.take_output(other_port)
		if incoming_item == null:
			return
		var start_idx := 0
		var end_idx := blocked.size()
		# if decision block use it routing
		if decide_node:
			start_idx = decide_node.decide_on(incoming_item)
			end_idx = start_idx + 1
		# now route it to the first free output port
		for i in range(start_idx, end_idx):
			if check_output(i):
				items[i] = incoming_item
				labels[i].text = str(incoming_item.sim_id)
				blocked[i] = true
				output_ready[i].emit(self, i)
				break
			else:
				if i == end_idx-1:
					pass

	
func check_output(port: int) -> bool:
	return not blocked[port] and not output_ready[port].get_connections().is_empty()

		
func on_output_ready(other_node: SimGraphNode, other_port: int, own_port : int):
	blocked[own_port] = false
	input_ready[0].emit(self, 0)

func take_output(port: int) -> Variant:
	var delivery_item = items[port]
	items[port] = null
	input_ready[0].emit(self, 0)
	return delivery_item

func reset():
	for i in range(blocked.size()):
		blocked[i] = false
		items[i] = null
		labels[i].text = ""

# decide node connections
var decide_node = null

func attach_decide(dec):
	decide_node = dec

func detach_decide(dec):
	decide_node = null
		
### serialize stuff
func get_save_data() -> Variant:
	var data = {}
	data["OutPort2Label"] = get_node("OutPort2Label").visible
	data["OutPort3Label"] = get_node("OutPort3Label").visible
	return data
	
func set_load_data(data: Variant):
	if data == null or not (data is Dictionary):
		return
	for key in data.keys():
		if has_node(key):
			get_node(key).visible = data[key]
