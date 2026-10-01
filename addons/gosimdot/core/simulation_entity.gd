class_name SimulationEntity
extends RefCounted

# for entity id
static var _counter : int = 0

# condition id
var sim_id : int = 0

# any change that should be noted, in particular for c-conditions
signal state_changed 

# give each entity an id
func _init():
	sim_id = _counter
	_counter += 1
