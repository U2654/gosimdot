class_name SimulationContainerManaged
extends SimulationContainer

var _queue : Array = []

# check if there is enough in container
func has_enough(amount: float, entity = null) -> bool:
	if level >= amount:
		#if _queue.is_empty() or _queue.find_custom(func(item): return item.entity.get_ref() == entity) != -1:
		if _queue.is_empty() or _queue.front().entity.get_ref()  == entity:
			return true
	_register_request(amount, entity)
	return false

# take amount out of container
func get_amount(amount: float, entity = null):
	if level >= amount:
		_queue = _queue.filter(func(item): return item.entity.get_ref() != entity)
		level -= amount

func _register_request(amount, entity):	
	for item in _queue:
		if item.entity.get_ref() == entity:
			if (item.amount != amount):
				item.amount = amount
			return
	_queue.append({"entity" : weakref(entity), "amount" : amount})
	
	
func reset():
	level = capacity
	_queue.clear()	
	
	
