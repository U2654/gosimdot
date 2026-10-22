class_name SimGraphNode
extends BaseGraphNode

var informs_output = true
var informs_input = false

func _ready() -> void:
	super._ready()
	create_logic()

func get_node_type_name() -> String:
	return "Simulation Node"

### logic
signal output_ready_p0(node: SimGraphNode, own_port: int, other_port: int)
signal output_ready_p1(node: SimGraphNode, own_port: int, other_port: int)
signal output_ready_p2(node: SimGraphNode, own_port: int, other_port: int)
signal output_ready_p3(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p0(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p1(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p2(node: SimGraphNode, own_port: int, other_port: int)
signal input_ready_p3(node: SimGraphNode, own_port: int, other_port: int)

@onready var input_ready = [input_ready_p0, input_ready_p1, input_ready_p2, input_ready_p3]
@onready var output_ready = [output_ready_p0, output_ready_p1, output_ready_p2, output_ready_p3]

func connect_input(own_port: int, other_node: SimGraphNode, other_port: int):
	input_ready[own_port].connect(other_node.on_output_ready.bind(other_port))

func disconnect_input(own_port: int, other_node: SimGraphNode, other_port: int):
	input_ready[own_port].disconnect(other_node.on_output_ready.bind(other_port))

func connect_output(own_port: int, other_node: SimGraphNode, other_port: int):
	output_ready[own_port].connect(other_node.on_input_ready.bind(other_port))

func disconnect_output(own_port: int, other_node: SimGraphNode, other_port: int):
	output_ready[own_port].disconnect(other_node.on_input_ready.bind(other_port))

func on_input_ready(_node: SimGraphNode, _other_port: int, _own_port : int):
	pass

func on_output_ready(_node: SimGraphNode, _other_port: int, _own_port: int):
	pass

func take_output(_port: int) -> Variant:
	return null

func create_logic():
	pass

func run_logic():
	pass

func reset():
	pass
