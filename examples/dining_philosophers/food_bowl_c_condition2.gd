class_name FoodBowlCCondition2
extends SimulationCCondition

var philosopher: Philosopher2
var food_bowl:  SimulationContainer

func _init(p: Philosopher2, fb: SimulationContainer, prio: int):
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
	
