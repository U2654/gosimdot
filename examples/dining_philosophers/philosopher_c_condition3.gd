class_name PhilosopherCCondition3
extends SimulationCCondition

var philosopher: Philosopher3
var chopstick:  SimulationResource

func _init(p: Philosopher3, cs: SimulationResource, prio: int):
	super()
	priority = prio
	philosopher = p
	chopstick = cs
	# Watch the resource: if it is released,  evaluate
	watch(cs)
	watch(p)

func is_true() -> bool:
	return philosopher.can_acquire(chopstick)

func execute():
	philosopher.on_resource_acquired(chopstick)
	
