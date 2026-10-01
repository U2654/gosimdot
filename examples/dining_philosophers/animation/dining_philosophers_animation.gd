extends Node2D

# gfx for visu
@export var philosopher_scene: PackedScene
@export var fork_scene: PackedScene

@export var radius: float = 200.0

var forks2d = []
var philosophers2d = []

func _ready():
	seed(12345)
	add_visu()

# update time and philosopher state in case of state change
func on_philo_state_changed(i: int):
	$TimeLabel.text = str($DiningPhilosophers.manager.sim_clock)
	var state_name = $DiningPhilosophers.philosophers[i].get_current_state().get_state_name()
	philosophers2d[i].get_node("Label").text = str(i) + " " + state_name

# if a fork is assigned, draw it
func on_chop_state_changed(i: int):
	var fork = $DiningPhilosophers.chopsticks[i]
	var is_used = fork.used != 0
	var pos_fork = forks2d[i].global_position
	var line_2d = forks2d[i].get_node("Line2D")
	pos_fork = line_2d.to_local(pos_fork)
	var pos_phil = pos_fork
	if (is_used):
		forks2d[i].get_node("Label").text = str(i) + " to " +str(fork.res_owner.get_ref().id)
		pos_phil = philosophers2d[fork.res_owner.get_ref().id].global_position
		pos_phil = line_2d.to_local(pos_phil)
	else:
		forks2d[i].get_node("Label").text = str(i) + " X "
	line_2d.points = [pos_fork, pos_phil]
		
# draw the philosopher and forks
func add_visu():
	#  create model first
	# N can be set using the DiningPhilosophers node
	# so here it is just taken
	var N = $DiningPhilosophers.N
	$DiningPhilosophers.create_philosophers()	
	var philosophers = $DiningPhilosophers.philosophers
	var chopsticks = $DiningPhilosophers.chopsticks

	# create visualisation now
	create_philosopher_visu()
	
	# connect state changes so that visu can be updated
	for i in range(N):
		var p = philosophers[i]
		p.state_changed.connect(on_philo_state_changed.bind(i))
	
	for i in range(N):
		var c = chopsticks[i]
		c.state_changed.connect(on_chop_state_changed.bind(i))
	
func create_philosopher_visu():
	var N = $DiningPhilosophers.N
	var root = get_tree().current_scene
	var center = get_viewport_rect().size / 2
	center = root.to_local(center)
	for i in range(N):

		# spawn fork (placed between philosophers)
		var f = fork_scene.instantiate()
		# offset the fork angle by half a step to put it between philosophers
		var f_angle = (PI * 2 * i) / N 
		var f_pos = Vector2(cos(f_angle), sin(f_angle)) * (radius * 0.8)
		f.position = center + f_pos
		f.rotation = f_angle + PI/2 # Rotate to face the center
		add_child(f)
		f.get_node("Label").text = str(i)
		forks2d.append(f)

		# spawn philosopher
		var p_angle = f_angle + (PI / N)
		var p = philosopher_scene.instantiate()
		var p_pos = Vector2(cos(p_angle), sin(p_angle)) * radius
		p.position = center + p_pos
		p.rotation = p_angle + PI/2 # Rotate to face the center
		add_child(p)
		philosophers2d.append(p)

func run_all():
	while ($DiningPhilosophers.simulate_step()):
		await get_tree().create_timer(0.25).timeout
	
func _on_max_steps_line_edit_text_submitted(new_text: String) -> void:
	$DiningPhilosophers/SimulationManager.run_duration = new_text.to_float()
	
