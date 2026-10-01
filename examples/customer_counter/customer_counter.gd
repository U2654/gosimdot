# this example corresponds to the scenario of the 8 section of 
# D. Zinoviev, Discrete Event Simulation: It's Easy with SimPy!, 2024
extends Node

@export var service_delay : float = 10.0
@export var max_simulation_time : float = 1000
@export var nb_customers : int = 10

var sim := SimulationManager.new()
var customer_queue := SimulationQueue.new()
var td_arrival := TimeDistribution.Exponential.new(1.0/service_delay)

# usually, instead of this variables, a SimulationResource should be used as server
# however, this code tries to follow the example as state above
# state variables
var counter_idle := BooleanSimulationEntity.new()

var is_sleeping := false

# condition for starting service at counter
var c_condition := CounterCCondition.new(self)

# class for monitoring boolean value in c conditions
class BooleanSimulationEntity extends SimulationEntity:
	var value: bool = true:
		set(new_value):
			if value != new_value:
				value = new_value
				state_changed.emit() 

# inner class for c-condition to have all in one file 
class CounterCCondition extends SimulationCCondition:
	var _parent : Node

	# watch idle variable and queue for changes to check condition
	func _init(p: Node):
		_parent = p
		watch(_parent.counter_idle)
		watch(_parent.customer_queue)

	# trigger execution if server is available and customer in the queue
	func is_true() -> bool:
		if (_parent.counter_idle.value and not _parent.customer_queue.is_empty()):
			return true
		return false

	# execution calls customer_service
	func execute():
		_parent.start_service()
		

func customer_arrival():
	var ticket = SimulationItem.new(sim.sim_clock)
	print("clock: ", sim.sim_clock, " arrival nb: ", ticket.sim_id)
	# and push to queue
	customer_queue.push(ticket)

# source: schedule arrivals of customers
func customer_generator():
	var event_time = 0
	for i in range(nb_customers):
		# schedule next arrival 
		sim.schedule_event(event_time, customer_arrival)
		event_time += td_arrival.get_interval()

# if the c-condition says the customer can be served 
func start_service():
	if is_sleeping:
		print("clock: ", sim.sim_clock, " operator wakes up: ")
		is_sleeping = false
	var ticket = customer_queue.pop()
	counter_idle.value = false
	# schedule processing after service completed  
	var action = finish_service.bind(ticket)
	sim.schedule_event(service_delay, action)
	
# the customer leaves 
func finish_service(ticket: SimulationItem):
	if randi_range(0, 9) == 9:
		print("clock: ", sim.sim_clock, " fails and leaves nb: ", ticket.sim_id)	
	else:
		print("clock: ", sim.sim_clock, " leaves nb: ", ticket.sim_id)	
	counter_idle.value = true
	if customer_queue.is_empty():
		is_sleeping = true
		print("clock: ", sim.sim_clock, " operator falls asleep ")

func _ready() -> void:
	# godot specific for running the system, the node has to be added
	add_child(sim)
	# run duration
	sim.run_duration = max_simulation_time

	# add the c-conditions
	sim.add_c_condition(c_condition)

	customer_generator()
	# run
	sim.simulate_synchronous()
