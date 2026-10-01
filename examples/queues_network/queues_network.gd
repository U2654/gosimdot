# this example corresponds to the scenario of Tutorial II: A Network of Queues of Ciw
extends Node

const num_trials := 1000

@export var cold_food_arrival_rate : float = 0.3
@export var hot_food_arrival_rate : float = 0.2

@export var max_simulation_time : float = 200.0

var sim := SimulationManager.new()

var cold_food_queue := CustomerQueueNode.new()
var hot_food_queue := CustomerQueueNode.new()
var till_queue :=  CustomerQueueNode.new()

var td_cold_food_arrival : TimeDistribution
var td_hot_food_arrival : TimeDistribution

var leave_cold_decider : Decider

var num_completed : int = 0

func _ready() -> void:
	add_child(sim)

	cold_food_queue.name = "Cold"
	cold_food_queue.sim = sim
	cold_food_queue.number_of_servers = 1
	cold_food_queue.td_server = TimeDistribution.Exponential.new(1.0)
	td_cold_food_arrival = TimeDistribution.Exponential.new(cold_food_arrival_rate)

	add_child(cold_food_queue)

	hot_food_queue.name = "Hot"
	hot_food_queue.sim = sim
	hot_food_queue.number_of_servers = 2
	hot_food_queue.td_server = TimeDistribution.Exponential.new(0.4)
	td_hot_food_arrival = TimeDistribution.Exponential.new(hot_food_arrival_rate)
	add_child(hot_food_queue)
	
	till_queue.name = "Till"
	till_queue.sim = sim
	till_queue.td_server = TimeDistribution.Exponential.new(0.5)

	till_queue.number_of_servers = 2
	add_child(till_queue)
	
	cold_food_queue.customer_ready.connect(customer_finished_cold_food)
	hot_food_queue.customer_ready.connect(customer_finished_hot_food)
	till_queue.customer_ready.connect(customer_leaves)

	leave_cold_decider = Decider.ProbablisticDecider.new()
	leave_cold_decider.add_option("till", 0.7)
	leave_cold_decider.add_option("hot", 0.3)

	var start_time = Time.get_ticks_msec()
	sim.run_duration = max_simulation_time
	var cb = []
	for i in range(num_trials):
		run_trial()
		cb.append(num_completed)
		num_completed = 0
	var cbs = cb.reduce(func(a, b): return a+b, 0)
	print("average: ", float(cbs) / cb.size())
	print("min: ", cb.min())
	print("max: ", cb.max())
	var end_time = Time.get_ticks_msec()
	print("Took: ", end_time-start_time)

func run_trial():	
	sim.schedule_event(td_cold_food_arrival.get_interval(), cold_food_customer_enters)
	sim.schedule_event(td_hot_food_arrival.get_interval(), hot_food_customer_enters)

	sim.simulate_synchronous()

	sim.reset()
	cold_food_queue.reset()
	hot_food_queue.reset()
	till_queue.reset()

func cold_food_customer_enters():
	var customer = SimulationItem.new(sim.sim_clock)
#	print(customer.sim_id, " goes to cold food")
	cold_food_queue.customer_arrival(customer)
	# schedule next arrival 
	sim.schedule_event(td_cold_food_arrival.get_interval(), cold_food_customer_enters)

func hot_food_customer_enters():
	var customer = SimulationItem.new(sim.sim_clock)
#	print(customer.sim_id, " goes to hot food")
	hot_food_queue.customer_arrival(customer)
	# schedule next arrival 
	sim.schedule_event(td_hot_food_arrival.get_interval(), hot_food_customer_enters)

func customer_finished_cold_food(customer: SimulationItem):
	if (leave_cold_decider.get_decision() == "hot"):
#		print(customer.sim_id, " finished cold food and goes to hot food")
		hot_food_queue.customer_arrival(customer)
	else:
#		print(customer.sim_id, " finished cold food and goes to till")
		till_queue.customer_arrival(customer)
		
func customer_finished_hot_food(customer: SimulationItem):
#	print(customer.sim_id, " finished hot food and goes to till")
	till_queue.customer_arrival(customer)

func customer_leaves(customer: SimulationItem):
#	print(customer.sim_id, "  leaves")
	if (sim.sim_clock < 180.0):
		num_completed += 1
