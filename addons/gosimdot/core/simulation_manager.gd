@icon("res://addons/gosimdot/icon.svg")
class_name SimulationManager
extends Node

# notify if the time has reached or event list is finished
signal simulation_finished

# simulation time
var sim_clock : float = 0.0
@export var run_duration : float = 100.0
# this is for the share of the display update cycle
@export var update_interval : float = 5000

# event lists, tuple of [time, callable]
var event_list: Array[Dictionary] = []

# list of all c conditons
var c_conditions: Array = []
# list of 'fired' c conditions 
var pending_c_phases: Array = []

# add c conditions and connect them to _on_condition...
func add_c_condition(c: SimulationCCondition):
	if not c_conditions.has(c):
		c_conditions.append(c)
	
	# sort: higher priority numbers move to the front of the array (index 0)
	c_conditions.sort_custom(func(a,b): return a.priority > b.priority)
		
	if not c.request_evaluation.is_connected(_on_condition_requested):
		c.request_evaluation.connect(_on_condition_requested.bind(c))

# callback function for fired / true c conditions
func _on_condition_requested(c: SimulationCCondition):
	if not pending_c_phases.has(c):
		pending_c_phases.append(c)

func c_phase():
	var changed = true
	while changed:
		changed = false
		# scan the condition list (which is already sorted by priority)
		for c in c_conditions:
			# if this condition isn't 'pending' (signaled), skip to the next
			if not pending_c_phases.has(c):
				continue
			if c.is_true():
				c.execute()
				# a state changed, restart the scan from the highest priority
				changed = true
				break 
			else:
				# the condition is false, take it out
				pending_c_phases.erase(c)
# this is an alternative instead of the above else: part
#		if not changed:
			# No more possible actions for this time-step
#			pending_c_phases.clear()

# simulate the duration given
func simulate_synchronous():
	while step():
		pass
	await get_tree().process_frame
	simulation_finished.emit()
		
# simulate the duration given
func simulate():
	if DisplayServer.get_name() == "headless":
		simulate_synchronous()
	else:	
		var t0 := Time.get_ticks_usec()
		while step():
			if Time.get_ticks_usec() - t0 > update_interval:
				await get_tree().process_frame
				t0 = Time.get_ticks_usec()
		await get_tree().process_frame
		simulation_finished.emit()
		
func compute_next_event_time():
	# priority is desired in case of time equality
	event_list.sort_custom(func(a, b):
		if a.time != b.time: 
			return a.time < b.time 
		return a.priority > b.priority)
	sim_clock = event_list.front().time
	

func a_phase() -> bool:
	if event_list.is_empty():
		return false;
	compute_next_event_time()
	# this includes the run_duration, if you want to exclude use >=
	if sim_clock > run_duration:
		return false
	return true	

func b_phase():
	while not event_list.is_empty() and event_list.front().time == sim_clock:
		var current_event = event_list.pop_front()
		current_event.activity.call()
		
# stepwise simulation of a three phases 
func step() -> bool:
	if (!a_phase()):
		return false
	b_phase()
	c_phase()
	return true

# schedule an event using time and a callable 
func schedule_event(time: float, activity : Callable, priority: int = 0):
	var event_time = sim_clock + time
	event_list.append({"activity" : activity, "time" : event_time, "priority" : priority})
	
func reset():
	pending_c_phases.clear()
	event_list.clear()
	sim_clock = 0.0
	
	
