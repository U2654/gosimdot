class_name MainProcessingStage
extends Node

signal log_msg(txt: String)

signal item_ready(item: SimulationItem)

var number_of_servers := 3

# we make them global in this node instead of passing them as arguments
var sim : SimulationManager
var td_server_setup : TimeDistribution
var td_server_no_setup : TimeDistribution

var item_served : Dictionary = {}

var servers : Array[SimulationResource]
var item_queue := SimulationQueue.new()
var c_condition : SimulationCCondition

var last_finished = []

# inner class for c-condition to have all in one file 
class MainProcessingStageCCondition extends SimulationCCondition:
	var _parent : Node
	var _free_server_idx : int

	# watch servers and queue for changes to check condition
	func _init(p: Node):
		_parent = p
		for s in _parent.servers:
			watch(s)
		watch(_parent.item_queue)

	# trigger execution if a server is available and item in the queue
	func is_true() -> bool:
		if not _parent.item_queue.is_empty():
			for i in range(_parent.servers.size()):
				if _parent.servers[i].is_available():
					_free_server_idx = i
					return true
		return false

	# execution calls customer_service
	func execute():
		_parent.process_item(_free_server_idx)

# source: schedule arrivals of customers
func item_arrival(item: SimulationItem):
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " arrival nb: " + str(item.sim_id) + " type " + item.properties["type"])
	# push to queue
	item_queue.push(item)

# if the c-condition says the item can be processed 
func process_item(server_id : int):
	# if the server is free, the item is processed
	servers[server_id].acquire()
	var item = item_queue.pop()
	item_served[server_id].append(item)
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " serving nb: " + str(item.sim_id) + " type " + item.properties["type"] + " server: " + str(server_id))
	# schedule processing after service completed  
	var action := move_forward_item.bind(server_id, item)

	if last_finished[server_id] != item.properties["type"]:
		sim.schedule_event(td_server_setup.get_interval(), action)
	else:
		sim.schedule_event(td_server_no_setup.get_interval(), action)

# the item leaves 
func move_forward_item(server_id: int, item: SimulationItem):
	servers[server_id].release()
	item_served[server_id].pop_front()
	last_finished[server_id] = item.properties["type"]
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " leaving nb: " + str(item.sim_id) + " type " + item.properties["type"])
	item_ready.emit(item)
	
func _ready() -> void:
	for i in range(number_of_servers):
		servers.append(SimulationResource.new())
		item_served[i] = []
		last_finished.append(null)
	# add the c-condition
	c_condition = MainProcessingStageCCondition.new(self)
	sim.add_c_condition(c_condition)
	
func reset():
	item_queue.reset()
	for s in servers:
		s.reset()
	for i in item_served:
		item_served[i] = []
