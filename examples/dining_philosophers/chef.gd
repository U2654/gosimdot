class_name Chef
extends SimulationEntity

var bowl: SimulationContainer
var time_distribution : TimeDistribution
var manager : SimulationManager 

func _init(b: SimulationContainer, td):
	bowl = b
	time_distribution = td

func restart_serving():
	manager.schedule_event(time_distribution.get_interval(), replenish)

func replenish():
	if bowl.level < bowl.capacity:
		bowl.put_amount(bowl.capacity - bowl.level)
	manager.schedule_event(time_distribution.get_interval(), replenish)
	
