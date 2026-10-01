extends DecideGraphNode

func get_node_type_name() -> String:
	return "Delay Decisions"

var assignments = {}
var plain_assignments = {}

var behaviour = false
var last_type = null

func _ready():
	super._ready()
	info_window.values_changed.connect(update_assignments)
	info_window.mode_changed.connect(change_mode)
	_update_label()

func _update_label():
	if has_node("Label"):
		var count = plain_assignments.size()
		if count > 0:
			$Label.text = "Rules: %d types" % count
		else:
			$Label.text = "Delay Rules"

func change_mode(toggled_on: bool):
	behaviour = toggled_on
	_update_label()

func decide_on(item: SimulationItem) -> TimeDistribution:
	if has_node("Label"):
		$Label.text = "Active: %s" % item.properties.get("type", "none")
	if behaviour:
		if last_type == item.properties["type"]:
			return assignments.get("unchanged", null)
		else:
			last_type = item.properties["type"]
			return assignments.get("changed", null)		
	else:
		return assignments.get(item.properties["type"], null)
	
func assign_distribution(type, td_name, td_params):
	var td = TimeDistribution.create(td_name, td_params)
	assignments[type] = td

func update_assignments(items):
	plain_assignments = items
	_update_label()
	for item in items:
		var td_string = items[item]
		if td_string == "":
			return
		var parts = td_string.split(",")
		var name = parts[0].strip_edges()
		var parameters = []
		for i in range(1, parts.size()):
			parameters.append(parts[i].strip_edges().to_float())
		assign_distribution(item, name, parameters)

func reset():
	last_type = null
	_update_label()

### serialize stuff
func get_save_data() -> Variant:
	var data = []
	data.append(behaviour)
	data.append(plain_assignments)
	return data
	
func set_load_data(data: Variant):
	if data is Array and data.size() >= 2:
		behaviour = data[0]
		plain_assignments = data[1]
	elif data is Dictionary:
		behaviour = false
		plain_assignments = data
	else:
		return
	update_assignments(plain_assignments)
	for a in plain_assignments:
		info_window.add_item(a, plain_assignments[a])
	info_window.set_behaviour_check_box(behaviour)
