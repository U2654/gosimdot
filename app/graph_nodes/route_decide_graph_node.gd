# route decide node
extends DecideGraphNode

func get_node_type_name() -> String:
	return "Routing Table"

var routing = {}

func _ready():
	super._ready()
	info_window.values_changed.connect(update_decider)
	_update_label()

func _update_label():
	if has_node("Label"):
		var count = routing.size()
		if count > 0:
			$Label.text = "Routes: %d types" % count
		else:
			$Label.text = "Port Routing"

func update_decider(parameters):
	routing = parameters
	_update_label()

func decide_on(item: SimulationItem) -> int:
	var index = routing.get(item.properties.get("type", ""), 0)
	if index == null:
		index = 0
	if has_node("Label"):
		$Label.text = "-> Port %d (%s)" % [index, item.properties.get("type", "")]
	return index

func reset():
	_update_label()
	
### serialize stuff
func get_save_data() -> Variant:
	return routing
	
		
func set_load_data(data: Variant):
	if data == null or not (data is Dictionary):
		return
	routing = data
	for r in routing:
		info_window.add_item(r, routing[r])
