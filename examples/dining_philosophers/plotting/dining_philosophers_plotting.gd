extends Control

var nb_phils_start = 2
var nb_phils_end = 21
var nb_runs = 10000
var is_running = false

func run_phil_simulation():
#	seed(12345)
	if is_running:
		return;
	is_running = true
	var scene_root = get_tree().current_scene
	var waiting_times = []
	for i in range(nb_phils_start, nb_phils_end+1):
		var sim_mg = SimulationManager.new()
		sim_mg.run_duration = nb_runs
		sim_mg.name = "SimulationManager"

		var phils := DiningPhilosophers3.new()
		phils.add_child(sim_mg)
		scene_root.add_child(phils)

		phils.N = i
		phils.create_philosophers()
		
		phils.simulate_synchronous()
		print("Nb " + str(i) + " take " + str(phils.get_waiting_time()))
		print("timeouts ", phils.get_time_outs())
		waiting_times.append(phils.get_waiting_time())

		phils.queue_free()

	var line_2d = scene_root.get_node("HBoxContainer/PlotArea/PlotCanvas")
	line_2d.plot(waiting_times, -1.0, range(nb_phils_start, nb_phils_end + 1))
	is_running = false

func _on_number_runs_line_edit_text_submitted(new_text: String) -> void:
	nb_runs = new_text.to_int()
	
func _on_pf_line_edit_text_submitted(new_text: String) -> void:
	nb_phils_start = new_text.to_int()
	
func _on_pt_line_edit_text_submitted(new_text: String) -> void:
	nb_phils_end = new_text.to_int()

func _on_run_button_pressed() -> void:
	run_phil_simulation()
