class_name SimulationStateMachine
extends SimulationEntity

class State:
	var machine_ref: WeakRef # to SimulationStateMachine
	
	func _init(state_machine: SimulationStateMachine):
		machine_ref = weakref(state_machine)

	func get_machine() -> SimulationStateMachine:
		return machine_ref.get_ref()
	
	func enter(): 
		pass
	func exit():
		pass
	func do(_delta: float) -> int:
		return -1
	func handle_event(event_name: String) -> int:
		return -1
		
var states = {}
var current_state_id : int = -1

func get_current_state():
	return states[current_state_id]

func add_state(state_id: int, state: State):
	states[state_id] = state

# can be called in _process for update in current states
func run(_delta : float):
	if (current_state_id >= 0):
		var next_state_id = states[current_state_id].do(_delta)
		change_to(next_state_id)

func process_event(event_name: Variant):
	if (current_state_id >= 0):
		var next_state_id = states[current_state_id].handle_event(event_name)
		change_to(next_state_id)

func start_state(initial_state_id : int):
	current_state_id = initial_state_id
	if (current_state_id >= 0):
		states[current_state_id].enter()
		state_changed.emit()
			
func change_to(next_state_id: int):
	if (next_state_id >= 0):
		states[current_state_id].exit()
		current_state_id = next_state_id
		states[current_state_id].enter()
		state_changed.emit()

func cleanup():
	if (not states.is_empty()):
		states.clear()
