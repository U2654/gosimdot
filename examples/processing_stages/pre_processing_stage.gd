class_name PreProcessingStage
extends Node

signal log_msg(txt: String)

@export var number_of_servers : int = 1

signal item_ready(item: SimulationItem)

# we make them global in this node instead of passing them as arguments
var sim : SimulationManager
var td_server : TimeDistribution

var item_served : Array[SimulationItem] = []
var item_queue := SimulationQueue.new()
var server := SimulationResource.new()
var c_condition : SimulationCCondition

# inner class for c-condition to have all in one file 
class PreProcessingStageCCondition extends SimulationCCondition:
	var _parent : Node

	# watch server and queue for changes to check condition
	func _init(p: Node):
		_parent = p
		watch(_parent.server)
		watch(_parent.item_queue)

	# trigger execution if server is available and customer in the queue
	func is_true() -> bool:
		if (_parent.server.is_available() and not _parent.item_queue.is_empty()):
			return true
		return false

	# execution calls customer_service
	func execute():
		_parent.process_item()

# arriving item
func item_arrival(item: SimulationItem):
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " arrival nb: " + str(item.sim_id))
	# push to queue
	item_queue.push(item)

# if the c-condition says the item can be processed 
func process_item():
	# if the server is free, the item is processed
	server.acquire()
	var item = item_queue.pop()
	item_served.append(item)
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " serving nb: " +str(item.sim_id))
	# schedule processing after service completed  
	var action = move_forward_item.bind(item)
	sim.schedule_event(td_server.get_interval(), action)
	
# the customer leaves 
func move_forward_item(item: SimulationItem):
	server.release()
	item_served.pop_front()
	log_msg.emit(name +": clock: " + str(sim.sim_clock) + " leaving nb: " + str(item.sim_id))
	item_ready.emit(item)
	
func _ready() -> void:
	server.capacity = number_of_servers
	# add the c-condition
	c_condition = PreProcessingStageCCondition.new(self)
	sim.add_c_condition(c_condition)
	
func reset():
	item_queue.reset()
	server.reset()
	item_served.clear()
