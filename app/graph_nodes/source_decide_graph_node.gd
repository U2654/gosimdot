# source decide node
extends DecideGraphNode

func get_node_type_name() -> String:
	return "Source Probabilities"

var decider := Decider.ProbablisticDecider.new()

func _init():
	decider.add_option("none", 1)

func decide_on(item: SimulationItem):
	item.properties["type"] = decider.get_decision()
	if has_node("Label"):
		$Label.text = "Type: " + str(item.properties["type"])
	
func _ready():
	super._ready()
	info_window.values_changed.connect(update_decider)
	_update_label()

func _update_label():
	if has_node("Label"):
		var count = decider.options.size()
		if count > 0:
			$Label.text = "Prob: %d types" % count
		else:
			$Label.text = "Probabilities"

func update_decider(parameter):
	decider.reset()
	for tuple in parameter:
		decider.add_option(tuple[0], tuple[1]/100)
	_update_label()

func reset():
	_update_label()
		
### serialize stuff
func get_save_data() -> Variant:
	return decider.options
	
func set_load_data(data: Variant):
	if data == null or not (data is Dictionary):
		return
	decider.options = data
	for o in decider.options:
		info_window.add_item(o, decider.options[o]*100)
	
