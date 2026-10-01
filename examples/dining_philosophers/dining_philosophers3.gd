class_name DiningPhilosophers3
extends Node

@export var N : int = 5
var chopsticks : Array[SimulationResourceManaged] = []
var food_bowl : SimulationContainer
@export var food_capacity : float = 1000.0
var philosophers : Array[Philosopher3] = []
var chef : Chef
@onready var manager : SimulationManager = $SimulationManager

func create_philosophers():
	# 1. initialize resources and container
	food_bowl = SimulationContainer.new(food_capacity, food_capacity)
	for i in range(N):
		var res = SimulationResourceManaged.new()
		res.capacity = 1
		chopsticks.append(res)

	# 2. initialize and link philosophers
	for i in range(N):
		var p = Philosopher3.new()
		p.eating_time_dist = TimeDistribution.Exponential.new(1.0/10.0)
		p.thinking_time_dist = TimeDistribution.Exponential.new(1.0/10.0)
		p.taking_time_dist = TimeDistribution.Constant.new(1.0)
		p.time_out_time_dist = TimeDistribution.Constant.new(75.0)
		p.manager = manager
		p.id = i
		# add food bowl container
		p.portion = 20
		# and corresponding c condition
		var food_bowl_condition = FoodBowlCCondition3.new(p, food_bowl, 0)
		manager.add_c_condition(food_bowl_condition)
		
		# circular assignment
		if (i != N-1):
			p.first_chopstick = chopsticks[i]
			p.second_chopstick = chopsticks[(i + 1) % N]
		else:
			p.second_chopstick = chopsticks[i]
			p.first_chopstick = chopsticks[(i + 1) % N]

		var cond_left = PhilosopherCCondition3.new(p,  chopsticks[i], 2)
		manager.add_c_condition(cond_left)

		var cond_right = PhilosopherCCondition3.new(p, chopsticks[(i + 1) % N], 1) 
		manager.add_c_condition(cond_right)
			
		philosophers.append(p)

	# need the chef to fill the food bowl
	chef = Chef.new(food_bowl, TimeDistribution.Constant.new(150))
	chef.manager = manager
	chef.restart_serving()

	# now start all
	for p in philosophers:
		p.restart_state_machine()

func reset_simulation():
	for p in philosophers:
		p.reset()
	for c in chopsticks:
		c.reset()
	manager.reset()
	for p in philosophers:
		p.restart_state_machine()
	food_bowl.reset()
	chef.restart_serving()

func simulate():
	manager.simulate()
	
func simulate_synchronous():
	manager.simulate_synchronous()

func simulate_step() -> bool:
	if manager.step():
		print("current time: ", manager.sim_clock)
		return true
	else:
		print("average waiting time: ", get_waiting_time())
		print("number of time outs:", get_time_outs())
	return false

func get_waiting_time() -> float:
	var waiting_time = 0.0
	for p in philosophers:
		waiting_time += p.waiting_time
	return waiting_time / N

func get_time_outs() -> int:
	var time_outs = 0
	for p in philosophers:
		time_outs += p.time_outs
	return time_outs
	
