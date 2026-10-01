class_name DiningPhilosophers
extends Node

@export var N : int = 5
var chopsticks : Array[SimulationResourceManaged] = []
var philosophers : Array[Philosopher] = []
@onready var manager : SimulationManager = $SimulationManager

func create_philosophers():
	# 1. initialize resources
	for i in range(N):
		var res = SimulationResourceManaged.new()
		res.capacity = 1
		chopsticks.append(res)

	# 2. initialize and link philosophers
	for i in range(N):
		var p = Philosopher.new()
		p.eating_time_dist = TimeDistribution.Exponential.new(1.0/10.0)
		p.thinking_time_dist = TimeDistribution.Exponential.new(1.0/10.0)
		p.taking_time_dist = TimeDistribution.Constant.new(1.0)
		p.manager = manager
		p.id = i
		
		# circular assignment
		if (i != N-1):
			p.first_chopstick = chopsticks[i]
			p.second_chopstick = chopsticks[(i + 1) % N]
		else:
			p.second_chopstick = chopsticks[i]
			p.first_chopstick = chopsticks[(i + 1) % N]

		var cond_left = PhilosopherCCondition.new(p,  chopsticks[i], 2)
		manager.add_c_condition(cond_left)

		var cond_right = PhilosopherCCondition.new(p, chopsticks[(i + 1) % N], 1) 
		manager.add_c_condition(cond_right)
			
		philosophers.append(p)

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
	return false

func get_waiting_time() -> float:
	var waiting_time = 0.0
	for p in philosophers:
		waiting_time += p.waiting_time
	return waiting_time / N
	
