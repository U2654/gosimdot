class_name FoodBowlCCondition3
extends SimulationCCondition

var philosopher: Philosopher3
var food_bowl:  SimulationContainer

func _init(p: Philosopher3, fb: SimulationContainer, prio: int):
	super()
	priority = prio
	philosopher = p
	food_bowl = fb
	# Watch the resource: if it is released,  evaluate
	watch(fb)
	watch(p)

func is_true() -> bool:
	return philosopher.can_get(food_bowl)

func execute():
	philosopher.on_container_got(food_bowl)
	
