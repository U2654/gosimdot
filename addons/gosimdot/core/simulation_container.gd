class_name SimulationContainer
extends SimulationEntity

@export var capacity: float = 0.0

# the current love how full is the container
# a change might trigger a c condition echck
var level: float = 0.0:
	set(value):
		if level != value:
			level = value
			state_changed.emit() 

func _init(cap: float, lev: float):
	super._init()
	capacity = cap
	level = lev	

# check if there is enough in container
func has_enough(amount: float, _entity = null) -> bool:
	return level >= amount

# take amount out of container
func get_amount(amount: float, _entity = null):
	# if has_enough(amount) # checked outside (hopefully)
	level -= amount

# put amount into container
func put_amount(amount: float):
	level = min(capacity, level+amount)
	
func reset():
	level = capacity
	
	
	
