# bass class for c conditions
class_name SimulationCCondition
extends RefCounted

# for conditions id
static var _counter : int = 0

# condition id
var sim_id : int = 0

# if something observed changes, this is forwarded by this
signal request_evaluation

# higher number = processed first in the c phase
@export var priority: int = 0

#var last_time_checked : float = 0.0 

func _init():
	sim_id = _counter
	_counter += 1

# is called if something related to the c condition has changed
# to evaluate the current condition and if it is true, to run execute
# must be overridden 
func is_true() -> bool:
	return false

# function to be executed if c condition is true
# must be overridden
func execute():
	pass

# simple way to bind this condition to entity changes
func watch(entity: SimulationEntity):
	entity.state_changed.connect(_on_entity_state_changed)

func _on_entity_state_changed():
	request_evaluation.emit()

func check():
	request_evaluation.emit()
