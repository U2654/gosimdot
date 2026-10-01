class_name PostProcessingStage
extends Node

signal log_msg(txt: String)

signal item_ready(item: SimulationItem)

var number_of_queues := 2

# we make them global in this node instead of passing them as arguments
var sim : SimulationManager
var td_server : TimeDistribution

var item_served : Dictionary = {}

var operator := SimulationResourceManaged.new()
var item_queues : Array[SimulationQueue]
var c_condition : SimulationCCondition

var options : Dictionary = {}

# inner class for c-condition to have all in one file 
class PostProcessingStageCCondition extends SimulationCCondition:
	var _parent : Node
	var _queue : SimulationQueue

	# watch server and queue for changes to check condition
	func _init(p: Node, queue: SimulationQueue):
		_parent = p
		_queue = queue
		watch(_parent.operator)
		watch(_queue)

	# trigger execution if server is available and customer in the queue
	func is_true() -> bool:
		if not _queue.is_empty() and _parent.operator.is_available(_queue):
			return true
		return false

	# execution calls customer_service
	func execute():
		_parent.process_item(_queue)

# new item enters
func item_arrival(item: SimulationItem):
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " arrival nb: " + str(item.sim_id) + " type: " + item.properties["type"])
	# push to queue
	var idx = options[item.properties["type"]]
	item_queues[idx].push(item)

# if the c-condition says the item can be processed 
func process_item(queue):
	# if the operator is free, the item is processed
	operator.acquire(queue)
	var item = queue.pop()
	var idx = item_queues.find(queue)
	item_served[idx].append(item)
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " serving nb: "  + str(item.sim_id) +  " type: " + item.properties["type"] + " queue: " + str(queue.sim_id))
	# schedule processing after service completed  
	var action = move_forward_item.bind(item, idx)
	sim.schedule_event(td_server.get_interval(), action)
	
# the customer leaves 
func move_forward_item(item: SimulationItem, idx: int):
	operator.release()
	item_served[idx].pop_front()
	log_msg.emit(name + ": clock: " + str(sim.sim_clock) + " leaving nb: " + str(item.sim_id) +  " type: " + item.properties["type"])
	item_ready.emit(item)
	
func _ready() -> void:
	for i in range(number_of_queues):
		item_queues.append(SimulationQueue.new())
		item_served[i] = []
	# add the c-conditions
	for i in range(number_of_queues):
		c_condition = PostProcessingStageCCondition.new(self, item_queues[i])
		sim.add_c_condition(c_condition)
	
func reset():
	for q in item_queues:
		q.reset()
	operator.reset()
	for i in item_served:
		item_served[i] = []
