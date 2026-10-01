# the underlying system corresponds the the example used 
# by M. Pidd, Computer Simulation in Management Science, 5th ed., Wiley, 2004
extends Node

func _ready() -> void:
	# the control 
	var sim = SimulationManager.new()
	add_child(sim)

	# two queues and two clerks
	var c_queue = SimulationQueue.new()
	var p_queue = SimulationQueue.new()
	var clerk = SimulationResource.new()
	clerk.capacity = 2
	
	# arrival and service time distributions for phone and personal
	var phone_arrival = TimeDistribution.Constant.new(10)
	var phone_service = TimeDistribution.Constant.new(15)
	var personal_arrival = TimeDistribution.Constant.new(12)
	var personal_service = TimeDistribution.Constant.new(15)

	# create the specific c conditions
	var c_personal = ClerkTaskCondition.new(sim, clerk, p_queue, 2, "Personal", personal_service, personal_arrival)
	var c_phone = ClerkTaskCondition.new(sim, clerk, c_queue, 1, "Phone", phone_service, phone_arrival)
	
	sim.add_c_condition(c_personal)
	sim.add_c_condition(c_phone)	

	# start the arrival streams
	sim.schedule_event(personal_arrival.get_interval(), c_personal.schedule_arrival)
	sim.schedule_event(phone_arrival.get_interval(), c_phone.schedule_arrival)
	
	# run
	sim.run_duration = 100
	var finished = sim.simulation_finished
	sim.simulate()
	await finished
	
	# and print stats
	c_personal.print_stats()
	c_phone.print_stats()

	await get_tree().create_timer(1).timeout
	for child in get_children():
		child.queue_free()
	
	get_tree().quit()
