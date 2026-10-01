extends Node

var nb_phils_start = 2
var nb_phils_end = 21
var nb_runs = 50000

func _ready():
	print("Headless Node Ready: ", name)
#	seed(123)
	run_all()

func run_all():
	var start_time = Time.get_ticks_msec()
	var waiting_times = []
	var sum_time = 0.0
	var n = 0
	for i in range(nb_phils_start, nb_phils_end + 1):
		# Create SimulationManager and attach it
		var sim_mg := SimulationManager.new()
		sim_mg.name = "SimulationManager"
		sim_mg.run_duration = nb_runs

		# Create philosopher system
		var phils := DiningPhilosophers3.new()
		phils.N = i
		phils.add_child(sim_mg)
		add_child(phils)

		phils.create_philosophers()

		phils.simulate_synchronous()

		# Collect result
		var wt = phils.get_waiting_time()
		sum_time += wt
		waiting_times.append(wt)
		print("Nb %d take %f" % [i, wt])
		print("timeouts ", phils.get_time_outs())

		n += 1
		# Cleanup
		for child in get_children():
			child.queue_free()
	
	print("All done:", waiting_times)
	print(sum_time, " ", sum_time/n)

	var end_time = Time.get_ticks_msec()
	print("Took: ", end_time-start_time)

	await get_tree().create_timer(1).timeout
	get_tree().quit()
