# source graph node
extends SimGraphNode

func get_node_type_name() -> String:
	return "Source (Generator)"

var total_generated: int = 0

func _ready():
	super._ready()
	if has_node("IdLabel"):
		$IdLabel.text = "Generated: 0"
	if has_node("TypeLabel"):
		$TypeLabel.text = "Ready"

# move, only init 
func run_logic():
	schedule_next()

func schedule_next():
	var td = info_window.get_node("DistributionGridContainer").time_distribution
	var sim = get_node("../../SimulationManager")	
	sim.schedule_event(td.get_interval(), next_item)

var item : SimulationItem
	
func next_item():
	var sim = get_node("../../SimulationManager")	
	item = SimulationItem.new(sim.sim_clock)
	if decide_node:
		decide_node.decide_on(item)
	else:
		item.properties["type"] = "none"
	output_ready[0].emit(self, 0)
	total_generated += 1
	if has_node("IdLabel"):
		$IdLabel.text = "Generated: %d" % total_generated
	if has_node("TypeLabel"):
		var t_str = item.properties.get("type", "none")
		$TypeLabel.text = "#%d (%s)" % [item.sim_id, t_str]
	schedule_next()

func take_output(_port: int) -> Variant:
	return item

func reset():
	total_generated = 0
	if has_node("IdLabel"):
		$IdLabel.text = "Generated: 0"
	if has_node("TypeLabel"):
		$TypeLabel.text = "Ready"
	
# decide node connections
var decide_node = null

func attach_decide(dec):
	decide_node = dec

func detach_decide(dec):
	decide_node = null
	
### serialize stuff
func get_save_data() -> Variant:
	return info_window.get_node("DistributionGridContainer").get_save_data()
	
func set_load_data(data: Variant):
	info_window.get_node("DistributionGridContainer").set_load_data(data)
	
