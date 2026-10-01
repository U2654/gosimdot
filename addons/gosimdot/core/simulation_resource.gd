class_name SimulationResource
extends SimulationEntity

@export var capacity: int = 1
var res_owner : WeakRef = null

# the current counter how many items are used
# a change might trigger a c condition echck
var used: int = 0:
	set(value):
		if used != value:
			used = value
			state_changed.emit() 

# check if available
func is_available() -> bool:
	return used < capacity

# take one resource item
func acquire(entity = null):
	if is_available():
		if (entity != null):
			res_owner = weakref(entity)
		used += 1

# release one resource item
func release():
	used = max(0, used - 1)
	
func reset():
	used = 0
	
	
	
