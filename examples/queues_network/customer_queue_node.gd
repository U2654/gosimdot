class_name CustomerQueueNode
extends Node

@export var number_of_servers : int = 1

signal customer_ready(item: SimulationItem)

# we make them global in this node instead of passing them as arguments
var sim : SimulationManager
var td_server : TimeDistribution

var customer_queue := SimulationQueue.new()
var server := SimulationResource.new()
var c_condition := CustomerCCondition.new(self)

# inner class for c-condition to have all in one file 
class CustomerCCondition extends SimulationCCondition:
	var _parent : Node

	# watch server and queue for changes to check condition
	func _init(p: Node):
		_parent = p
		watch(_parent.server)
		watch(_parent.customer_queue)

	# trigger execution if server is available and customer in the queue
	func is_true() -> bool:
		if (_parent.server.is_available() and not _parent.customer_queue.is_empty()):
			return true
		return false

	# execution calls customer_service
	func execute():
		_parent.customer_service()

# source: schedule arrivals of customers
func customer_arrival(item: SimulationItem):
	# create arrival
#	var item = SimulationItem.new(sim.sim_clock)
#	print(name, ": clock: ", sim.sim_clock, " arrival nb: ", item.sim_id)
	# and push to queue
	customer_queue.push(item)
	# schedule next arrival 
	#sim.schedule_event(td_arrival.get_interval(), customer_arrival)

# if the c-condition says the customer can be served 
func customer_service():
	# if the server can be acquired by the customer, the customer leaves queue
	server.acquire()
	var item = customer_queue.pop()
	# record times
#	print(name, ": clock: ", sim.sim_clock, " serving nb: ", item.sim_id, " available server: ", number_of_servers-server.used)
	# schedule processing after service completed  
	var action = customer_leaving.bind(item)
	sim.schedule_event(td_server.get_interval(), action)
	
# the customer leaves 
func customer_leaving(item: SimulationItem):
	server.release()
#	print(name, ": clock: ", sim.sim_clock, " leaving nb: ", item.sim_id)	
	customer_ready.emit(item)
	
func _ready() -> void:
	server.capacity = number_of_servers
	# add the c-condition
	sim.add_c_condition(c_condition)
	
func reset():
	customer_queue.reset()
	server.reset()
