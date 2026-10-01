# this example corresponds to the scenario in the Appendix of 
# Palmer et al. (2019), Ciw: An open-source discrete event simulation library, Journal of Simulation 13:1
extends Node

@export var arrival_rate : float = 10.0
@export var number_of_servers : int = 3
@export var service_rate : float = 4.0
@export var max_simulation_time : float = 800.0
@export var warmup : float = 100.0
@export var num_trials : int = 20

# we make them global in this node instead of passing them as arguments
var sim := SimulationManager.new()
var customer_queue := SimulationQueue.new()
var server := SimulationResource.new()
var td_arrival := TimeDistribution.Exponential.new(arrival_rate)
var td_server := TimeDistribution.Exponential.new(service_rate)
var c_condition := CustomerCCondition.new(self)

# record for storing data, entries are either 'id' or '[id, service_duration]'
var records : Dictionary = {}

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
func customer_arrival():
	# create arrival, each item has an id
	var item = SimulationItem.new(sim.sim_clock)
	records[item.sim_id] = sim.sim_clock
	# and push to queue
	customer_queue.push(item)
	# schedule next arrival 
	sim.schedule_event(td_arrival.get_interval(), customer_arrival)

# if the c-condition says the customer can be served 
func customer_service():
	# if the server can be acquired by the customer, the customer leaves queue
	server.acquire()
	var item = customer_queue.pop()
	# record times, each simulation item has an id
	var service_start = records[item.sim_id]
	records[item.sim_id] = [sim.sim_clock, sim.sim_clock-service_start]
	# schedule processing after service completed, (shows parameter passing, too)
	var action = customer_leaving.bind(item)
	sim.schedule_event(td_server.get_interval(), action)
	
# the customer leaves 
func customer_leaving(_item: SimulationItem):
	server.release()

func run_trial(s: int) -> float:
	seed(s)
	records.clear()
	# reset everthing for starting again 
	customer_queue.reset()
	server.reset()
	sim.reset()
	# start arrivals, important to start as event 
	sim.schedule_event(td_arrival.get_interval(), customer_arrival)
	# and simulate
	sim.simulate_synchronous()
	# process records after simulation
	var waits : Array[float] = []
	for r in records.values(): # take out unserved entries 
		if typeof(r) == TYPE_ARRAY and r[0] > warmup:
			waits.push_back(r[1])
	return waits.reduce(func(a, b): return a+b, 0) / waits.size()

func _ready() -> void:
	# godot specific for running the system, the node has to be added
	add_child(sim)
	# set up the simulation engine
	server.capacity = number_of_servers
	# run duration
	sim.run_duration = max_simulation_time
	# add the c-condition
	sim.add_c_condition(c_condition)
	# run trials 
	var trial_waits = range(num_trials).map(func(s): return run_trial(s))
	var average_waits = trial_waits.reduce(func(a, b): return a+b, 0) / trial_waits.size()
	print("Average waiting time: ", average_waits)
